; ==============================================================================
; devops.ahk — AutoHotkey v2 automation for a DevOps / Ops / SRE workstation
;
;   CapsLock is the "Hyper" key:  tap = Esc (great for nvim)  ·  hold = layer below
;   Shift+CapsLock toggles the real Caps Lock.
;
;   Caps + H  (or Caps + F1)   searchable list of EVERY shortcut (which-key style)
;   Caps + F5 reload  ·  Caps + F4 edit  ·  Caps + Esc pause/resume all hotkeys
;
;   Personal tweaks go into devops.local.ahk (same folder, never overwritten):
;     Cfg.Browser := ["ahk_exe chrome.exe", "chrome.exe", "Chrome"]
;     Cfg.TicketUrl := "https://mycompany.atlassian.net/browse/"
;
;   Clipboard transforms (JSON, base64, JWT, YAML, URL, epoch …) run `clipx` in WSL.
;   Note: hotkeys don't reach windows running as Administrator unless this script is elevated.
; ==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook True
InstallKeybdHook()
SetTitleMatchMode 2
A_MaxHotkeysPerInterval := 200
A_MenuMaskKey := "vkE8"

; ---------------------------------------------------------------- configuration ----
LOCALAPPDATA := EnvGet("LOCALAPPDATA")

; app launchers: [window to look for, what to run if it isn't open, label]
; search / ticket URLs get the selection (or clipboard) appended URL-encoded
; TicketUrl: ABC-123 → TicketUrl . "ABC-123"  ·  TmuxProfile: WT profile for Win+Shift+Enter
; WslDistro: distro that has `clipx` (empty = default distro)
; Clip*: clipboard history (text only) in %USERPROFILE%\.cliphist\history.jsonl — shared with WSL `clip`
global Cfg := {
  Terminal: ["ahk_exe WindowsTerminal.exe", "wt.exe", "Windows Terminal"],
  Browser:  ["ahk_exe msedge.exe", "msedge.exe", "Edge"],
  Code:     ["ahk_exe Code.exe", LOCALAPPDATA "\Programs\Microsoft VS Code\Code.exe", "VS Code"],
  Explorer: ["ahk_class CabinetWClass", "explorer.exe", "Explorer"],
  Slack:    ["ahk_exe slack.exe", LOCALAPPDATA "\slack\slack.exe", "Slack"],
  Teams:    ["ahk_exe ms-teams.exe", "shell:AppsFolder\MSTeams_8wekyb3d8bbwe!MSTeams", "Teams"],
  Outlook:  ["ahk_exe olk.exe", "shell:AppsFolder\Microsoft.OutlookForWindows_8wekyb3d8bbwe!Microsoft.OutlookforWindows", "Outlook"],
  Notes:    ["ahk_exe Obsidian.exe", LOCALAPPDATA "\Programs\Obsidian\Obsidian.exe", "Obsidian"],
  SearchUrl:   "https://www.google.com/search?q=",
  GitHubUrl:   "https://github.com/search?type=code&q=",
  TicketUrl:   "https://your-company.atlassian.net/browse/",
  TmuxProfile: "{6a3e2f41-8c1d-4b7e-9f20-3d5a1c7e0b13}",
  WslDistro:   "",
  ClipMaxEntries: 5000,
  ClipMaxChars:   200000,
  ClipIgnoreApps: ["KeePassXC.exe", "KeePass.exe", "1Password.exe", "Bitwarden.exe", "LastPass.exe", "Dashlane.exe"]
}

global HelpRows := []

#Include *i %A_ScriptDir%\devops.local.ahk

; ================================================================ CapsLock = Hyper ====
SetCapsLockState "AlwaysOff"
CapsLock::Send "{Esc}"                         ; tap alone → Esc
+CapsLock:: SetCapsLockState(GetKeyState("CapsLock", "T") ? "AlwaysOff" : "AlwaysOn")
Help("CapsLock (tap)", "Esc")
Help("Shift + CapsLock", "real Caps Lock on/off")

; register "CapsLock & <key>" with a description for the help window
Caps(key, desc, fn) {
  Hotkey("CapsLock & " key, fn)
  Help("Caps + " StrUpper(key), desc)
}
Help(keys, desc) => HelpRows.Push([keys, desc])
Shifted() => GetKeyState("Shift", "P")

; --------------------------------------------------------------------- apps ---------
Help("", "──────── apps: open, or switch to it (press again = next window of that app)")
Caps("t", "Terminal",            (*) => RunOrRaise(Cfg.Terminal))
Caps("b", "Browser",             (*) => RunOrRaise(Cfg.Browser))
Caps("c", "VS Code",             (*) => RunOrRaise(Cfg.Code))
Caps("e", "Explorer",            (*) => RunOrRaise(Cfg.Explorer))
Caps("s", "Slack",               (*) => RunOrRaise(Cfg.Slack))
Caps("a", "Teams",               (*) => RunOrRaise(Cfg.Teams))
Caps("o", "Outlook",             (*) => RunOrRaise(Cfg.Outlook))
Caps("n", "Notes (Obsidian)",    (*) => RunOrRaise(Cfg.Notes))
Caps("Space", "Command Palette (PowerToys)", (*) => Send("#!{Space}"))

#Enter:: Run("wt.exe -w new")
#+Enter:: Run('wt.exe -w 0 nt -p "' Cfg.TmuxProfile '"')
Help("Win + Enter", "new Windows Terminal window")
Help("Win + Shift + Enter", "new tmux tab (sessions restored by tmux-continuum)")

; ------------------------------------------------------------------- windows ---------
Help("", "──────── windows  (zones: FancyZones Win+←/→ · layouts Win+Ctrl+Alt+1…6)")
Caps("f", "maximize / restore active window", (*) => ToggleMax())
Caps("x", "minimize active window",           (*) => WinMinimize("A"))
Caps("p", "pin on top (PowerToys Always On Top)", (*) => Send("#^t"))
Caps("Tab", "move active window to next monitor", (*) => Send("#+{Right}"))

; ------------------------------------------------------------ clipboard / text ---------
Help("", "──────── text  (works on the selection, else the clipboard → result goes to the clipboard)")
Caps("v", "paste as plain text",                  (*) => PastePlain())
Caps("j", "JSON pretty  ·  +Shift: compact",      (*) => ClipX(Shifted() ? "json-compact" : "json"))
Caps("y", "YAML → JSON  ·  +Shift: JSON → YAML",  (*) => ClipX(Shifted() ? "json2yaml" : "yaml2json"))
Caps("d", "base64 decode  ·  +Shift: encode (k8s secrets)", (*) => ClipX(Shifted() ? "b64e" : "b64d"))
Caps("w", "decode JWT (header + payload, exp as UTC)", (*) => ClipX("jwt"))
Caps("u", "URL decode  ·  +Shift: encode",        (*) => ClipX(Shifted() ? "urle" : "urld"))
Caps("z", "epoch ↔ ISO-8601 UTC",                 (*) => ClipX("epoch"))
Caps("l", "lowercase  ·  +Shift: UPPERCASE",      (*) => ClipX(Shifted() ? "upper" : "lower"))
Caps("r", "sort lines + remove duplicates",       (*) => ClipX("uniq"))

; --------------------------------------------------------------- search / open --------
Help("", "──────── search / open  (selection, else clipboard)")
Caps("g", "Google  ·  +Shift: GitHub code search", (*) => WebSearch(Shifted() ? Cfg.GitHubUrl : Cfg.SearchUrl))
Caps("k", "open ticket (ABC-123) in Jira",         (*) => OpenTicket())
Caps("Enter", "open selection: URL, path, ticket, else search", (*) => OpenSmart())

; ------------------------------------------------------------ clipboard history -------
Help("", "──────── clipboard history  (everything copied as text, also from WSL; WSL: clip)")
Caps("q", "clipboard history: type to filter, Enter pastes, Shift+Enter copies  ·  +Shift: pause/resume recording",
  (*) => Shifted() ? ClipTogglePause() : ClipHistoryGui())

; -------------------------------------------------------------------- script ---------
Help("", "──────── this script")
Caps("h", "show this help", ShowHelp)
Caps("F1", "show this help", ShowHelp)
Caps("F2", "all cheat sheets: bash, zsh, tmux, nvim, atuin, fzf, k9s, git, Windows … (WSL: keys --export)", ShowSheets)
Caps("F5", "reload script", (*) => Reload())
Caps("F4", "edit script", (*) => Edit())
#SuspendExempt
CapsLock & Esc:: {
  Suspend -1
  Notify(A_IsSuspended ? "AutoHotkey: hotkeys OFF" : "AutoHotkey: hotkeys ON")
}
#SuspendExempt False
Help("Caps + Esc", "pause / resume all hotkeys")

; ================================================================== hotstrings ========
; fire as soon as the trigger is typed. The ";" prefix keeps them from firing by accident.
Help("", "──────── hotstrings  (just type them)")
HS(";ts",   "timestamp  2026-11-16 04:56:00",        (*) => SendText(FormatTime(, "yyyy-MM-dd HH:mm:ss")))
HS(";date", "date  2026-11-16",                       (*) => SendText(FormatTime(, "yyyy-MM-dd")))
HS(";iso",  "ISO-8601 local  2026-11-16T04:56:00+01:00", (*) => SendText(IsoLocal()))
HS(";utc",  "ISO-8601 UTC  2026-11-16T03:56:00Z",     (*) => SendText(FormatTime(A_NowUTC, "yyyy-MM-dd'T'HH:mm:ss") "Z"))
HS(";ep",   "unix epoch seconds",                     (*) => SendText(DateDiff(A_NowUTC, "19700101000000", "Seconds")))
HS(";uuid", "random UUID v4",                         (*) => SendText(NewUuid()))
HS(";cb",   "markdown code block",                    (*) => (SendText("``````" "`n`n" "``````"), Send("{Up}")))
HS(";inc",  "incident update template (Slack/Teams)", (*) => SendText(IncidentTemplate()))
HS(";upd",  "status update line with UTC time",       (*) => SendText("[" FormatTime(A_NowUTC, "HH:mm") " UTC] Update: "))
HS(";pm",   "postmortem skeleton (markdown)",         (*) => SendText(PostmortemTemplate()))
HS(";lgtm", "LGTM 👍",                                (*) => SendText("LGTM 👍"))
HS(";mfg",  "Mit freundlichen Grüßen",                (*) => SendText("Mit freundlichen Grüßen`n"))
HS(";br",   "Best regards",                           (*) => SendText("Best regards`n"))

HS(trigger, desc, fn) {
  Hotstring(":*:" trigger, fn)          ; * = fires as soon as the trigger is typed
  Help(trigger, desc)
}

; ================================================================== functions =========
RunOrRaise(app) {
  winTitle := app[1], target := app[2], label := app[3]
  if WinExist(winTitle) {
    if WinActive(winTitle)
      WinActivateBottom(winTitle)          ; already in front → cycle to its next window
    else
      WinActivate(winTitle)
    return
  }
  try Run(target)
  catch
    Notify("Could not start " label " (" target ") — adjust Cfg in devops.local.ahk")
}

ToggleMax() {
  if WinGetMinMax("A") = 1
    WinRestore("A")
  else
    WinMaximize("A")
}

PastePlain() {
  text := A_Clipboard
  if text = ""
    return Notify("Clipboard is empty")
  A_Clipboard := text                     ; re-setting drops formatting (HTML/RTF)
  Send "^v"
}

; selected text — without Ctrl+C in terminals (would send SIGINT; copyOnSelect copies there)
GetSelection() {
  if WinActive("ahk_exe WindowsTerminal.exe") || WinActive("ahk_exe mintty.exe")
    return ""
  saved := ClipboardAll()
  A_Clipboard := ""
  Send "^c"
  text := ClipWait(0.3) ? A_Clipboard : ""
  A_Clipboard := saved
  return text
}

SelectionOrClipboard() {
  sel := GetSelection()
  return sel != "" ? sel : A_Clipboard
}

; run `clipx <op>` in WSL on the selection/clipboard, put the result into the clipboard
ClipX(op) {
  text := SelectionOrClipboard()
  if text = ""
    return Notify("Nothing selected and clipboard is empty")
  inF := A_Temp "\clipx_in.txt", outF := A_Temp "\clipx_out.txt", errF := A_Temp "\clipx_err.txt"
  for f in [inF, outF, errF]
    try FileDelete(f)
  FileAppend(text, inF, "UTF-8-RAW")
  q(s) => "'" s "'"
  distro := Cfg.WslDistro != "" ? "-d " Cfg.WslDistro " " : ""
  cmd := Format('wsl.exe {1}-e bash -lc "clipx {2} {3} {4} 2>$(wslpath -u {5})"', distro, op, q(inF), q(outF), q(errF))
  code := RunWait(cmd, , "Hide")
  if code != 0 {
    err := FileExist(errF) ? Trim(FileRead(errF, "UTF-8")) : ""
    return Notify("clipx " op " failed" (err != "" ? ":`n" SubStr(err, 1, 300) : ""), 5000)
  }
  result := RTrim(FileRead(outF, "UTF-8"), "`r`n")
  A_Clipboard := result
  Notify("✓ " op " → clipboard (Ctrl+V)`n" SubStr(result, 1, 400), 4000)
}

UriEncode(s) {
  out := ""
  buf := Buffer(StrPut(s, "UTF-8"))
  StrPut(s, buf, "UTF-8")
  loop buf.Size - 1 {
    b := NumGet(buf, A_Index - 1, "UChar")
    if (b >= 0x30 && b <= 0x39) || (b >= 0x41 && b <= 0x5A) || (b >= 0x61 && b <= 0x7A)
      || b = 0x2D || b = 0x2E || b = 0x5F || b = 0x7E
      out .= Chr(b)
    else
      out .= Format("%{:02X}", b)
  }
  return out
}

WebSearch(baseUrl) {
  q := Trim(SelectionOrClipboard())
  if q = "" {
    ib := InputBox("Search for:", "Search")
    if ib.Result != "OK" || ib.Value = ""
      return
    q := ib.Value
  }
  Run(baseUrl UriEncode(SubStr(q, 1, 500)))
}

OpenTicket() {
  t := SelectionOrClipboard()
  if RegExMatch(t, "\b[A-Z][A-Z0-9]+-\d+\b", &m)
    Run(Cfg.TicketUrl m[0])
  else
    Notify("No ticket key (ABC-123) in selection/clipboard")
}

OpenSmart() {
  t := Trim(SelectionOrClipboard(), " `t`r`n`"'")
  if t = ""
    return Notify("Nothing selected")
  if RegExMatch(t, "i)^(https?|ftp)://\S+$")
    return Run(t)
  if RegExMatch(t, "i)^www\.\S+$")
    return Run("https://" t)
  if FileExist(t)
    return Run(t)
  if RegExMatch(t, "^[A-Z][A-Z0-9]+-\d+$")
    return Run(Cfg.TicketUrl t)
  Run(Cfg.SearchUrl UriEncode(t))
}

IsoLocal() {
  off := DateDiff(A_Now, A_NowUTC, "Minutes")
  sign := off < 0 ? "-" : "+", off := Abs(off)
  return FormatTime(, "yyyy-MM-dd'T'HH:mm:ss") sign Format("{:02}:{:02}", off // 60, Mod(off, 60))
}

NewUuid() {
  guid := Buffer(16)
  DllCall("ole32\CoCreateGuid", "Ptr", guid)
  str := Buffer(80)
  DllCall("ole32\StringFromGUID2", "Ptr", guid, "Ptr", str, "Int", 40)
  return StrLower(SubStr(StrGet(str), 2, 36))
}

IncidentTemplate() {
  return "🚨 *INCIDENT* — <short title>`n"
    . "*Status:* Investigating  (Investigating · Identified · Monitoring · Resolved)`n"
    . "*Severity:* SEV-?`n"
    . "*Impact:* <who/what is affected>`n"
    . "*Started:* " FormatTime(A_NowUTC, "yyyy-MM-dd HH:mm") " UTC`n"
    . "*Incident commander:* <name>`n"
    . "*Next update:* in 30 min`n"
}

PostmortemTemplate() {
  return "# Postmortem: <title>`n`n"
    . "**Date:** " FormatTime(, "yyyy-MM-dd") "  **Severity:** SEV-?  **Authors:** `n`n"
    . "## Summary`n`n## Impact`n`n## Timeline (UTC)`n| Time | Event |`n|---|---|`n`n"
    . "## Root cause`n`n## Detection`n`n## Resolution`n`n"
    . "## What went well / what didn't`n`n## Action items`n| Action | Owner | Ticket | Due |`n|---|---|---|---|`n"
}

Notify(msg, ms := 2500) {
  ToolTip(msg)
  SetTimer(() => ToolTip(), -ms)
}

; ------------------------------------------------------------- help window ----------
global HelpGui := ""

ShowHelp(*) {
  global HelpGui
  if HelpGui {                       ; second press closes it
    HelpGui.Destroy(), HelpGui := ""
    return
  }
  HelpGui := Gui("+AlwaysOnTop -MinimizeBox +ToolWindow", "AutoHotkey · all shortcuts")
  HelpGui.BackColor := "1A1B26"
  HelpGui.SetFont("s10 cC0CAF5", "Segoe UI")
  HelpGui.AddText(, "Type to filter · Esc closes")
  filter := HelpGui.AddEdit("w760 Background24283B cC0CAF5")
  lv := HelpGui.AddListView("w760 r30 -Multi Background1A1B26 cC0CAF5", ["Keys", "Action"])
  fill(*) {
    lv.Delete()
    needle := filter.Value
    for row in HelpRows
      if needle = "" || InStr(row[1] " " row[2], needle)
        lv.Add(, row*)
    lv.ModifyCol(1, 210), lv.ModifyCol(2, 530)
  }
  fill()
  filter.OnEvent("Change", fill)
  close(*) {
    global HelpGui
    HelpGui.Destroy(), HelpGui := ""
  }
  HelpGui.OnEvent("Escape", close)
  HelpGui.OnEvent("Close", close)
  HelpGui.Show()
  filter.Focus()
}

; ================================================================ clipboard history ====
; Every text copy (Windows apps AND WSL, which shares this clipboard) is appended as one
; JSON line to %USERPROFILE%\.cliphist\history.jsonl. Skipped: copies from password
; managers (they flag the clipboard as private, or are listed in Cfg.ClipIgnoreApps),
; consecutive duplicates, and texts over Cfg.ClipMaxChars. Plain text on disk — keep
; secrets in a password manager.
global ClipDir := EnvGet("USERPROFILE") "\.cliphist"
global ClipFile := ClipDir "\history.jsonl"
global ClipPaused := false
global ClipLast := ""
global ClipGui := ""
DirCreate(ClipDir)
ClipPrune()
OnClipboardChange(ClipSave)

ClipSave(dataType) {
  global ClipLast
  if ClipPaused || dataType != 1          ; 1 = text
    return
  if ClipExcluded()
    return
  text := A_Clipboard
  if text = "" || text == ClipLast || StrLen(text) > Cfg.ClipMaxChars
    return
  ClipLast := text
  app := ""
  try app := WinGetProcessName("A")
  line := '{"ts":"' FormatTime(A_NowUTC, "yyyy-MM-dd'T'HH:mm:ss") 'Z","app":"' JsonEsc(app) '","text":"' JsonEsc(text) '"}' "`n"
  try FileAppend(line, ClipFile, "UTF-8-RAW")
}

; password managers mark their clipboard data as "don't monitor / don't keep in history"
ClipExcluded() {
  static formats := [
    DllCall("RegisterClipboardFormat", "Str", "ExcludeClipboardContentFromMonitorProcessing", "UInt"),
    DllCall("RegisterClipboardFormat", "Str", "CanIncludeInClipboardHistory", "UInt"),
    DllCall("RegisterClipboardFormat", "Str", "Clipboard Viewer Ignore", "UInt")
  ]
  for fmt in formats {
    if DllCall("IsClipboardFormatAvailable", "UInt", fmt)
      return true
  }
  app := ""
  try app := WinGetProcessName("A")
  for exe in Cfg.ClipIgnoreApps {
    if app = exe
      return true
  }
  return false
}

ClipTogglePause() {
  global ClipPaused
  ClipPaused := !ClipPaused
  Notify(ClipPaused ? "Clipboard history: recording PAUSED" : "Clipboard history: recording ON")
}

ClipPrune() {
  if !FileExist(ClipFile)
    return
  lines := StrSplit(RTrim(FileRead(ClipFile, "UTF-8"), "`n"), "`n")
  keepN := Cfg.ClipMaxEntries
  if lines.Length <= keepN
    return
  keep := ""
  loop keepN
    keep .= lines[lines.Length - keepN + A_Index] "`n"
  FileDelete(ClipFile)
  FileAppend(keep, ClipFile, "UTF-8-RAW")
}

ClipLoad() {
  items := []
  if !FileExist(ClipFile)
    return items
  for line in StrSplit(FileRead(ClipFile, "UTF-8"), "`n", "`r") {
    if RegExMatch(line, '^\{"ts":"([^"]*)","app":"((?:[^"\\]++|\\.)*+)","text":"((?:[^"\\]++|\\.)*+)"\}', &m)
      items.Push({ ts: m[1], app: JsonUnesc(m[2]), text: JsonUnesc(m[3]) })
  }
  return items
}

JsonEsc(s) {
  s := StrReplace(s, "\", "\\")
  s := StrReplace(s, '"', '\"')
  s := StrReplace(s, "`r", "\r")
  s := StrReplace(s, "`n", "\n")
  s := StrReplace(s, "`t", "\t")
  return RegExReplace(s, "[\x00-\x1F]", "")
}

JsonUnesc(s) {
  s := StrReplace(s, "\\", Chr(1))
  s := StrReplace(s, "\n", "`n")
  s := StrReplace(s, "\r", "`r")
  s := StrReplace(s, "\t", "`t")
  s := StrReplace(s, '\"', '"')
  s := StrReplace(s, "\/", "/")
  return StrReplace(s, Chr(1), "\")
}

ClipHistoryGui() {
  global ClipGui
  if ClipGui {                                   ; Caps+Q again closes it
    ClipGui.Destroy(), ClipGui := ""
    return
  }
  target := WinExist("A")
  items := ClipLoad()
  g := Gui("+AlwaysOnTop -MinimizeBox", "Clipboard history · Enter paste · Shift+Enter copy · Tab → list · Esc close")
  ClipGui := g
  g.BackColor := "1A1B26"
  g.SetFont("s10 cC0CAF5", "Segoe UI")
  filter := g.AddEdit("w920 Background24283B cC0CAF5")
  lv := g.AddListView("w920 r24 -Multi Background1A1B26 cC0CAF5", ["Time (UTC)", "App", "Text"])
  shown := []
  fill(*) {
    lv.Opt("-Redraw")
    lv.Delete()
    shown.Length := 0
    needle := filter.Value
    i := items.Length
    while i >= 1 && shown.Length < 2000 {
      it := items[i]
      if needle = "" || InStr(it.text, needle) || InStr(it.app, needle) {
        lv.Add(, StrReplace(SubStr(it.ts, 1, 16), "T", " "), it.app, SubStr(RegExReplace(it.text, "\s+", " "), 1, 200))
        shown.Push(it)
      }
      i--
    }
    lv.ModifyCol(1, 130), lv.ModifyCol(2, 130), lv.ModifyCol(3, 640)
    if shown.Length
      lv.Modify(1, "Select Focus")
    lv.Opt("+Redraw")
  }
  pick(paste) {
    global ClipLast, ClipGui
    row := lv.GetNext(0, "F")
    if !row
      row := 1
    if row > shown.Length
      return
    text := shown[row].text
    ClipLast := text                              ; don't record our own re-copy
    A_Clipboard := text
    g.Destroy(), ClipGui := ""
    if paste && target {
      WinActivate(target)
      if WinWaitActive(target, , 1)
        Send("^v")
    }
  }
  close(*) {
    global ClipGui
    g.Destroy(), ClipGui := ""
  }
  filter.OnEvent("Change", fill)
  lv.OnEvent("DoubleClick", (*) => pick(true))
  g.AddButton("Default x0 y0 w0 h0", "OK").OnEvent("Click", (*) => pick(!GetKeyState("Shift", "P")))
  g.OnEvent("Escape", close)
  g.OnEvent("Close", close)
  fill()
  g.Show()
  filter.Focus()
}

; ================================================================ cheat sheets (Caps+F2) =
; Shows %USERPROFILE%\.keys\*.tsv — written by `keys --export` in WSL (bash, zsh, tmux,
; nvim, atuin, fzf, k9s, lazygit, git, Windows Terminal, Windows …) + this script's keys.
global SheetsGui := ""

ShowSheets(*) {
  global SheetsGui
  if SheetsGui {
    SheetsGui.Destroy(), SheetsGui := ""
    return
  }
  sheets := Map(), names := []
  names.Push("autohotkey (this script)"), sheets["autohotkey (this script)"] := HelpRows
  loop files EnvGet("USERPROFILE") "\.keys\*.tsv" {
    rows := [], title := A_LoopFileName
    for i, line in StrSplit(FileRead(A_LoopFileFullPath, "UTF-8"), "`n", "`r") {
      if i = 1 && SubStr(line, 1, 2) = "# " {
        title := SubStr(line, 3)
        continue
      }
      parts := StrSplit(line, "`t")
      if parts.Length >= 2
        rows.Push([parts[1], parts[2]])
    }
    if !sheets.Has(title)
      names.Push(title)
    sheets[title] := rows
  }
  if names.Length = 1
    Notify("Only this script's keys found — run  keys --export  in WSL once", 5000)

  g := Gui("+AlwaysOnTop -MinimizeBox", "Cheat sheets · pick a sheet, or type to search ALL sheets · Esc closes")
  SheetsGui := g
  g.BackColor := "1A1B26"
  g.SetFont("s10 cC0CAF5", "Segoe UI")
  dd := g.AddDropDownList("w300 Choose1 R20", names)
  filter := g.AddEdit("x+10 w500 Background24283B cC0CAF5")
  lv := g.AddListView("xm w810 r30 -Multi Background1A1B26 cC0CAF5", ["Keys", "Action"])
  fill(*) {
    lv.Opt("-Redraw")
    lv.Delete()
    needle := filter.Value, sel := dd.Text
    for name in names {
      if needle = "" && name != sel
        continue
      for r in sheets[name] {
        if needle = "" || InStr(r[1] " " r[2] " " name, needle)
          lv.Add(, r[1], (needle != "" ? "[" name "]  " : "") r[2])
      }
    }
    lv.ModifyCol(1, 240), lv.ModifyCol(2, 550)
    lv.Opt("+Redraw")
  }
  close(*) {
    global SheetsGui
    g.Destroy(), SheetsGui := ""
  }
  dd.OnEvent("Change", fill)
  filter.OnEvent("Change", fill)
  g.OnEvent("Escape", close)
  g.OnEvent("Close", close)
  fill()
  g.Show()
  filter.Focus()
}
