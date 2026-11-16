<#
.SYNOPSIS
  Windows side of wsl-dotfiles: Windows Terminal, PowerToys (FancyZones, Always On Top),
  AutoHotkey DevOps script, Nerd Font, Git for Windows (credential manager).

.EXAMPLE
  # from Windows PowerShell or pwsh (WSL files are reachable via \\wsl.localhost):
  powershell -ExecutionPolicy Bypass -File \\wsl.localhost\Ubuntu-24.04\home\<you>\wsl-dotfiles\windows\setup-windows.ps1

  # only some parts / other default terminal profile:
  ... setup-windows.ps1 -DefaultProfile tmux -SkipPackages

.NOTES
  Safe to re-run. Every file it changes is backed up as *.bak.<timestamp> first.
  Run the WSL ./install.sh first — it writes the Windows Terminal profiles (bash/zsh/tmux).
#>
param(
  [ValidateSet('zsh', 'bash', 'tmux', 'keep')] [string] $DefaultProfile = 'zsh',
  [switch] $SkipPackages,
  [switch] $SkipPowerToys,
  [switch] $SkipTerminal,
  [switch] $SkipAutoHotkey
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  ! $msg" -ForegroundColor Yellow }

function Install-Pkg($id) {
  $installed = winget list --id $id --exact --accept-source-agreements 2>$null | Select-String -SimpleMatch $id
  if ($installed) { Ok "$id already installed"; return }
  winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok "$id" } else { Warn "${id}: winget exit code $LASTEXITCODE" }
}

# ------------------------------------------------------------------ packages ---------
if (-not $SkipPackages) {
  Step 'winget packages'
  $packages = @(
    'Microsoft.WindowsTerminal'       # session restore needs >= 1.21
    'Microsoft.PowerShell'            # pwsh 7 - merges settings.json that contains comments
    'AutoHotkey.AutoHotkey'           # v2
    'DEVCOM.JetBrainsMonoNerdFont'
    'Git.Git'                         # Git Credential Manager, shared with WSL
  )
  foreach ($p in $packages) { Install-Pkg $p }
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
              [Environment]::GetEnvironmentVariable('Path', 'User')
}

# ------------------------------------------------------------------ PowerToys --------
if (-not $SkipPowerToys) {
  Step 'PowerToys (install + settings via winget configure)'
  winget configure --enable 2>$null | Out-Null
  winget configure -f (Join-Path $root 'powertoys\powertoys.dsc.yaml') `
    --accept-configuration-agreements --disable-interactivity
  if ($LASTEXITCODE -ne 0) { Warn "winget configure returned $LASTEXITCODE — check the output above" }

  # FancyZones writes its data folder on first start
  $fz = Join-Path $env:LOCALAPPDATA 'Microsoft\PowerToys\FancyZones'
  if (-not (Get-Process PowerToys -ErrorAction SilentlyContinue)) {
    $pt = @("$env:LOCALAPPDATA\PowerToys\PowerToys.exe", "$env:ProgramFiles\PowerToys\PowerToys.exe") |
      Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($pt) { Start-Process $pt; Start-Sleep -Seconds 6 }
  }
  if (Test-Path $fz) {
    & (Join-Path $root 'powertoys\apply-fancyzones.ps1')
  } else {
    Warn 'FancyZones folder not there yet: open the FancyZones editor once (Win+Shift+´), then run powertoys\apply-fancyzones.ps1'
  }
}

# ------------------------------------------------------------- Windows Terminal --------
if (-not $SkipTerminal) {
  Step 'Windows Terminal (session restore, splits, layouts)'
  $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
  if ($pwsh) {
    & $pwsh.Source -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'terminal\apply-terminal.ps1') -DefaultProfile $DefaultProfile
  } else {
    Warn 'pwsh (PowerShell 7) not found — open a new terminal and run terminal\apply-terminal.ps1 with pwsh'
  }
}

# ------------------------------------------------------------------- AutoHotkey -------
if (-not $SkipAutoHotkey) {
  Step 'AutoHotkey DevOps script (+ autostart)'
  $dst = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'AutoHotkey'
  New-Item -ItemType Directory -Force $dst | Out-Null
  $script = Join-Path $dst 'devops.ahk'
  if (Test-Path $script) { Copy-Item $script "$script.bak.$(Get-Date -Format yyyyMMdd-HHmmss)" }
  Copy-Item (Join-Path $root 'autohotkey\devops.ahk') $script -Force
  $local = Join-Path $dst 'devops.local.ahk'
  if (-not (Test-Path $local)) {
    Copy-Item (Join-Path $root 'autohotkey\devops.local.example.ahk') $local
    Ok "created $local — your personal settings (never overwritten)"
  }

  $ahk = @("$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
           "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe") |
    Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $ahk) { Warn 'AutoHotkey v2 not found — install it, then rerun'; }
  else {
    $lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'devops.ahk.lnk'
    $sh = New-Object -ComObject WScript.Shell
    $s = $sh.CreateShortcut($lnk)
    $s.TargetPath = $ahk
    $s.Arguments = "`"$script`""
    $s.WorkingDirectory = $dst
    $s.Save()
    Ok "autostart: $lnk"
    Start-Process $ahk "`"$script`""
    Ok 'running — press CapsLock+H for all shortcuts'
  }
}

# ------------------------------------------------------------- clipboard + cheat sheets -
Step 'Clipboard history (Win+V) + cheat sheets for Caps+F2'
# Windows' own history (Win+V, 25 items, kept until reboot) as a second layer
New-Item -Path 'HKCU:\Software\Microsoft\Clipboard' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Clipboard' -Name 'EnableClipboardHistory' -Value 1 -Type DWord
Ok 'Windows clipboard history (Win+V) enabled'
Ok "full history: $env:USERPROFILE\.cliphist\history.jsonl (AutoHotkey Caps+Q, WSL: clip)"
# export every cheat sheet from the WSL shell (aliases, functions, tmux, nvim, …)
wsl.exe -e env NO_BLE=1 bash -ic 'keys --export' 2>$null
if ($LASTEXITCODE -eq 0) { Ok "cheat sheets in $env:USERPROFILE\.keys (Caps+F2)" }
else { Warn 'could not export cheat sheets — later in WSL: keys --export' }

Step 'done'
@"
  Next steps
   1. Restart Windows Terminal (picks up profiles + settings).
   2. FancyZones: Win+Shift+´ → choose a 'DevOps · …' layout per monitor.
   3. Workspaces (apps start at fixed positions / monitors):
      PowerToys → Workspaces → Launch editor (Win+Ctrl+´) → arrange apps → Capture → Save
      → 'Create desktop shortcut'. One workspace per monitor setup (e.g. 'Docked', 'Laptop').
   4. AutoHotkey: edit Documents\AutoHotkey\devops.local.ahk (browser, Jira URL, …), CapsLock+F5 reloads.
   5. Caps+Q clipboard history · Caps+F2 all cheat sheets · Caps+H this script's keys.
"@ | Write-Host
