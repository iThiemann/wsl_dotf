; ==============================================================================
; devops.local.ahk — your personal settings for devops.ahk (never overwritten by setup)
;   Loaded right after the defaults, so anything here wins. Hyper+F5 (hold CapsLock + F5) reloads.
; ==============================================================================

; --- apps: [window to look for, what to start, label] ---------------------------------
; Cfg.Browser := ["ahk_exe chrome.exe", "chrome.exe", "Chrome"]
; Cfg.Browser := ["ahk_exe firefox.exe", "firefox.exe", "Firefox"]
; Cfg.Browser := ["ahk_exe Arc.exe", "shell:AppsFolder\TheBrowserCompany.Arc_ttt1ap7aakyb4!Arc", "Arc"]
; Cfg.Notes   := ["ahk_exe Notion.exe", EnvGet("LOCALAPPDATA") "\Programs\Notion\Notion.exe", "Notion"]
; Cfg.Outlook := ["ahk_exe OUTLOOK.EXE", "outlook.exe", "Outlook (classic)"]

; --- URLs ------------------------------------------------------------------------------
; Cfg.TicketUrl := "https://mycompany.atlassian.net/browse/"
; Cfg.SearchUrl := "https://duckduckgo.com/?q="

; --- WSL distro with clipx (empty = default) ------------------------------------------
; Cfg.WslDistro := "Ubuntu-24.04"

; --- your own hotkeys / hotstrings ---------------------------------------------------------
; ^+!#1:: Run("https://grafana.mycompany.com")      ; Hyper+1 (^+!# = Ctrl+Shift+Alt+Win)
; Help("Hyper + 1", "Grafana")
; Hyper("i", "…", (*) => …)   ; same, with help entry — use a free key (Hyper+H lists the taken ones)
; HS(";oncall", "on-call handover note", (*) => SendText("Handover " FormatTime(, "yyyy-MM-dd") ":`n- open incidents:`n- watch:`n"))
