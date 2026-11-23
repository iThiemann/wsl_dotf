<#
.SYNOPSIS
  Install the DevOps FancyZones layouts + Win+Ctrl+Alt+<n> quick-switch hotkeys.
.DESCRIPTION
  Merges (by uuid) into %LOCALAPPDATA%\Microsoft\PowerToys\FancyZones\custom-layouts.json
  and layout-hotkeys.json — your own layouts stay. PowerToys is stopped while the
  files are written (it would overwrite them otherwise) and started again afterwards.
  Which layout is used on which monitor is chosen in the editor (Win+Shift+´) because
  monitor IDs are machine-specific.
#>
$ErrorActionPreference = 'Stop'
$dir = Join-Path $env:LOCALAPPDATA 'Microsoft\PowerToys\FancyZones'
if (-not (Test-Path $dir)) {
  throw "FancyZones data folder missing — start PowerToys, open the FancyZones editor once (Win+Shift+´), then rerun."
}

function Read-Json($path, $default) {
  if (Test-Path $path) { return Get-Content -Raw $path | ConvertFrom-Json }
  return $default
}

$exe = Get-Process -Name PowerToys -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Path
Get-Process -Name 'PowerToys*' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

$stamp = Get-Date -Format yyyyMMdd-HHmmss

# --- layouts ---------------------------------------------------------------------------
$layoutsPath = Join-Path $dir 'custom-layouts.json'
$mine = Get-Content -Raw (Join-Path $PSScriptRoot 'fancyzones-custom-layouts.json') | ConvertFrom-Json
$cur = Read-Json $layoutsPath ([pscustomobject]@{ 'custom-layouts' = @() })
if (Test-Path $layoutsPath) { Copy-Item $layoutsPath "$layoutsPath.bak.$stamp" }
$ids = $mine.'custom-layouts' | ForEach-Object { $_.uuid }
$merged = @($cur.'custom-layouts' | Where-Object { $ids -notcontains $_.uuid }) + $mine.'custom-layouts'
[pscustomobject]@{ 'custom-layouts' = $merged } | ConvertTo-Json -Depth 16 | Set-Content -Encoding UTF8 $layoutsPath

# --- quick-switch hotkeys ----------------------------------------------------------------
$hkPath = Join-Path $dir 'layout-hotkeys.json'
$myHk = Get-Content -Raw (Join-Path $PSScriptRoot 'fancyzones-layout-hotkeys.json') | ConvertFrom-Json
$curHk = Read-Json $hkPath ([pscustomobject]@{ 'layout-hotkeys' = @() })
if (Test-Path $hkPath) { Copy-Item $hkPath "$hkPath.bak.$stamp" }
$keys = $myHk.'layout-hotkeys' | ForEach-Object { $_.key }
$mergedHk = @($curHk.'layout-hotkeys' | Where-Object { $keys -notcontains $_.key -and $ids -notcontains $_.'layout-id' }) +
            $myHk.'layout-hotkeys'
[pscustomobject]@{ 'layout-hotkeys' = $mergedHk } | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $hkPath

# --- restart PowerToys ----------------------------------------------------------------------
if (-not $exe) {
  $exe = @("$env:LOCALAPPDATA\PowerToys\PowerToys.exe", "$env:ProgramFiles\PowerToys\PowerToys.exe") |
    Where-Object { Test-Path $_ } | Select-Object -First 1
}
if ($exe) { Start-Process $exe }

Write-Host "FancyZones: $($mine.'custom-layouts'.Count) layouts installed (Win+Ctrl+Alt+1…$($keys.Count))." -ForegroundColor Green
Write-Host "Next: Win+Shift+´ → pick a layout for each monitor."
