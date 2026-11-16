# Windows side — Terminal · PowerToys · AutoHotkey

Run this after the WSL `./install.sh`, because that script writes the bash/zsh/tmux terminal profiles:

```powershell
powershell -ExecutionPolicy Bypass -File \\wsl.localhost\Ubuntu-24.04\home\<you>\wsl-dotfiles\windows\setup-windows.ps1
#   -DefaultProfile zsh|bash|tmux|keep   -SkipPackages -SkipPowerToys -SkipTerminal -SkipAutoHotkey
```

You can run it again at any time, and every file it touches is backed up first.
It installs Windows Terminal, PowerShell 7, PowerToys, AutoHotkey v2, the JetBrainsMono Nerd Font and Git for Windows (for the credential manager shared with WSL).

## Windows Terminal (`terminal/`)

`apply-terminal.ps1` merges `settings.patch.jsonc` into your `settings.json`. Comments in that file explain each setting and its alternatives.
Your file loses its comments when it's rewritten; the backup keeps them.

| | |
|---|---|
| **Session restore** | `firstWindowPreference: persistedWindowLayout` reopens windows, tabs and panes, including screen contents (WT ≥ 1.21). `startOnUserLogin: true` brings everything back after a reboot. |
| **Real process restore** | Running programs don't come back with WT alone. Use the **· tmux** profile (`Alt+Shift+T`): tmux-resurrect/continuum restore sessions, windows, panes, cwd, nvim, ssh and so on. |
| `Alt+Shift+V` / `H` / `D` | split right / down / auto (same profile and directory) |
| `Alt+Shift+Z` · `X` | zoom pane · close pane |
| `Alt+←↑→↓` · `Alt+Shift+←↑→↓` | focus pane · resize pane (WT defaults) |
| `Alt+Shift+PgUp/PgDn` | swap pane left/right |
| `Alt+Shift+B` | **broadcast input** to all panes in the tab (run the same command on several hosts) |
| `Alt+Shift+1` · `2` | layouts: **Dev** (60 \| 40 stacked) · **Ops** (2 × 2) |
| `Alt+Shift+R` · `C` | rename tab · tab colour |
| `Ctrl+Shift+P` · `Win+^` | command palette · quake window |

`Alt+Space` is unbound in WT and handed to tmux (which-key menu).

## PowerToys (`powertoys/`)

- `powertoys.dsc.yaml` is applied with `winget configure`. It installs PowerToys and sets FancyZones and Always On Top declaratively, with every option commented.
  The setting that makes apps **reopen in their last zone** is `FancyzonesAppLastZoneMoveWindows`.
  `FancyzonesDisplayOrWorkAreaChangeMoveWindows` puts windows back when you dock or undock.
- `apply-fancyzones.ps1` adds six layouts and merges them with any you already have:

| `Win+Ctrl+Alt+` | Layout |
|---|---|
| 1 | Code center 25 \| 50 \| 25 |
| 2 | Editor + terminal 60 \| 40 |
| 3 | Ops board: main \| 2 × 2 |
| 4 | Focus 15 \| 70 \| 15 |
| 5 | Laptop 50 \| 50 |
| 6 | Ultrawide 20 \| 40 \| 20 \| 20 |

  Then press `Win+Shift+´` and pick a layout **per monitor**. Monitor IDs are machine-specific, so this step can't be scripted.
- **Apps starting at fixed positions on a given screen** is a job for **PowerToys Workspaces** and can't be done with a file. Arrange your apps, open `Win+Ctrl+´`, click Capture, then Save, then "Create desktop shortcut".
  Make one workspace per setup (*Docked* = laptop + external monitor, *Laptop* = laptop only). The workspace starts the apps and moves them into place.

## AutoHotkey v2 (`autohotkey/devops.ahk`)

It's copied to `Documents\AutoHotkey\` and set to start at login.
Put your own settings (browser, Jira URL, extra hotkeys) in `devops.local.ahk`; setup never overwrites that file.

**CapsLock works like the Karabiner "Caps → Hyper/Esc" rule on the Mac:**
- **tap alone** sends `Esc` (nvim, tmux, fzf, atuin, k9s, lazygit); held longer than 1 s without another key, nothing is sent
- **hold** acts as **Hyper** = Ctrl+Shift+Alt+Win. These are real modifiers, so any app can bind Hyper+X, including PowerToys and your own tools
- **Shift + tap** turns real Caps Lock on and off

Setup changes two things so this works cleanly:
- It **disables the Windows "Office key"**, which is the same Ctrl+Shift+Alt+Win combination: alone it opens the Office app, and +W/X/T/O/L open Word, Excel, Teams, Outlook and LinkedIn. Sign out and back in once.
- When run as **Administrator**, it starts AutoHotkey **elevated** at logon, so CapsLock/Hyper also work in admin windows.

These Hyper keys are avoided on purpose: **B** (Win+Ctrl+Shift+B resets the graphics driver, so the browser is on **W**) and **Esc** (Ctrl+Shift+Esc opens Task Manager, so pause is **F12**).
In Windows Terminal and WSL, a Hyper combo that AutoHotkey doesn't use arrives as Ctrl+Alt+key, because terminals cannot pass the Win modifier on.

**`Hyper+H` opens a filterable list of every shortcut**, similar to which-key.

| Hyper + | |
|---|---|
| `T W C E S A O N` | run-or-raise: Terminal, Browser (web), VS Code, Explorer, Slack, Teams, Outlook, Notes. Pressing again cycles through that app's windows. |
| `Space` | PowerToys Command Palette |
| `F` · `X` · `P` · `Tab` | maximize/restore · minimize · always on top · next monitor |
| `V` | paste as plain text |
| `J` / `⇧J` | JSON pretty / compact |
| `Y` / `⇧Y` | YAML → JSON / JSON → YAML |
| `D` / `⇧D` | base64 decode / encode (k8s secrets) |
| `W` | decode JWT (header, payload, `exp` as UTC) |
| `U` / `⇧U` | URL decode / encode |
| `Z` | epoch ↔ ISO-8601 |
| `L` / `⇧L` | lower / UPPER |
| `R` | sort + dedupe lines |
| `G` / `⇧G` | Google / GitHub code search of the selection |
| `K` | open the Jira ticket in the selection |
| `Enter` | open selection: URL, path, ticket, otherwise search |
| `Q` / `⇧Q` | **clipboard history** (Enter paste, Shift+Enter copy) / pause recording |
| `F2` | **all cheat sheets** (bash, zsh, tmux, nvim, atuin, fzf, k9s, git, Windows …; filled by `keys --export` in WSL) |
| `F5` · `F4` · `F12` | reload · edit · pause all hotkeys (CapsLock keeps working) |

`Win+Enter` opens a new terminal window, and `Win+Shift+Enter` opens a new tmux tab.

The transforms run `clipx` inside WSL (jq/python). They work on the selection, or on the clipboard if nothing is selected, and the result goes to the clipboard.
Inside the terminal they always use the clipboard, because Ctrl+C there would send SIGINT. `clipx` also works in the shell: `pbpaste | clipx jwt`.

Hotstrings (just type them):
- `;ts` `;date` `;iso` `;utc` `;ep` (timestamps)
- `;uuid`
- `;cb` (code block)
- `;inc` (incident update), `;upd` (status line in UTC), `;pm` (postmortem skeleton)
- `;lgtm` `;mfg` `;br`

> Hotkeys don't reach windows running as Administrator unless the script runs elevated too.
