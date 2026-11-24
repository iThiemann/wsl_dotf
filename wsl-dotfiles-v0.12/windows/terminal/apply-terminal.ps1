#Requires -Version 7
<#
.SYNOPSIS
  Merge settings.patch.jsonc into Windows Terminal's settings.json (backup first).
.DESCRIPTION
  - global keys from the patch overwrite yours, everything else is kept
  - profiles.defaults are merged key by key
  - actions / keybindings with ids User.dotfiles.* are replaced; any of YOUR keybindings
    that use one of the same keys are removed so nothing collides
  - -DefaultProfile zsh|bash|tmux|keep  sets the default profile (fragment GUIDs)
#>
param(
  [ValidateSet('zsh', 'bash', 'tmux', 'keep')] [string] $DefaultProfile = 'zsh'
)
$ErrorActionPreference = 'Stop'

$candidates = @(
  "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
  "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
  "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)
$settingsPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $settingsPath) { throw "Windows Terminal settings.json not found — start Windows Terminal once, then rerun." }

$patch    = Get-Content -Raw (Join-Path $PSScriptRoot 'settings.patch.jsonc') | ConvertFrom-Json -AsHashtable
$settings = Get-Content -Raw $settingsPath | ConvertFrom-Json -AsHashtable

$backup = "$settingsPath.bak.$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item $settingsPath $backup
Write-Host "backup: $backup"

# --- globals ------------------------------------------------------------------------
foreach ($k in $patch.Keys) {
  if ($k -in 'profiles', 'actions', 'keybindings') { continue }
  $settings[$k] = $patch[$k]
}

# --- profiles.defaults ----------------------------------------------------------------
if (-not $settings.ContainsKey('profiles')) { $settings['profiles'] = @{} }
if ($settings['profiles'] -is [System.Collections.IList]) {
  $settings['profiles'] = @{ list = $settings['profiles'] }
}
if (-not $settings['profiles'].ContainsKey('defaults')) { $settings['profiles']['defaults'] = @{} }
foreach ($k in $patch.profiles.defaults.Keys) {
  $settings['profiles']['defaults'][$k] = $patch.profiles.defaults[$k]
}

# --- actions ---------------------------------------------------------------------------
$ours = 'User.dotfiles.'
$patchUnbound = @($patch.actions | Where-Object { $_['command'] -eq 'unbound' } | ForEach-Object { $_['keys'] })
$actions = @($settings['actions'] | Where-Object {
    $_ -and -not ("$($_['id'])".StartsWith($ours)) -and
    -not ($_['command'] -eq 'unbound' -and $patchUnbound -contains $_['keys'])
  })
$settings['actions'] = $actions + $patch.actions

# --- keybindings -----------------------------------------------------------------------
$ourKeys = @($patch.keybindings | ForEach-Object { $_['keys'] }) +
           @($patch.actions | Where-Object { $_.ContainsKey('keys') } | ForEach-Object { $_['keys'] })
$kb = @($settings['keybindings'] | Where-Object {
    $_ -and -not ("$($_['id'])".StartsWith($ours)) -and ($ourKeys -notcontains $_['keys'])
  })
# legacy style: actions that carry their own "keys"
$settings['actions'] = @($settings['actions'] | ForEach-Object {
    if ($_.ContainsKey('keys') -and ($ourKeys -contains $_['keys']) -and -not "$($_['id'])".StartsWith($ours)) {
      $_.Remove('keys')
    }
    $_
  })
$settings['keybindings'] = $kb + $patch.keybindings

# --- default profile -----------------------------------------------------------------
$guids = @{
  bash = '{6a3e2f41-8c1d-4b7e-9f20-3d5a1c7e0b11}'
  zsh  = '{6a3e2f41-8c1d-4b7e-9f20-3d5a1c7e0b12}'
  tmux = '{6a3e2f41-8c1d-4b7e-9f20-3d5a1c7e0b13}'
}
if ($DefaultProfile -ne 'keep') { $settings['defaultProfile'] = $guids[$DefaultProfile] }

$settings | ConvertTo-Json -Depth 32 | Set-Content -Encoding utf8NoBOM $settingsPath
Write-Host "Windows Terminal settings updated: $settingsPath" -ForegroundColor Green
Write-Host "Default profile: $DefaultProfile. Windows Terminal picks the change up live (fragment profiles need a restart)."
