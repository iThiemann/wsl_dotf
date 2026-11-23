# ==============================================================================
# ~/.config/tmux/which-key.tmux — which-key style menu
#   Opened with  prefix Space  or  Alt-Space.  Press the letter shown to run an
#   entry, Esc/q to close. Groups (…) open a sub-menu. Edit freely — every entry is
#   "Label" key { tmux commands }, "" is a separator.
# ==============================================================================
display-menu -T "#[align=centre fg=#7aa2f7] which-key " -x C -y C \
  "Sessions…"            s { display-menu -T "#[align=centre fg=#bb9af7] sessions " -x C -y C \
      "Session manager (sessionx)" o { run-shell -b "~/.config/tmux/plugins/tmux-sessionx/scripts/sessionx.sh" } \
      "Choose tree"                s { choose-tree -Zs } \
      "New session"                n { command-prompt -p "new session:" { new-session -s "%%" } } \
      "Rename session"             r { command-prompt -I "#S" { rename-session "%%" } } \
      "Last session"               l { switch-client -l } \
      "" \
      "Save now (resurrect)"       S { run-shell "~/.config/tmux/plugins/tmux-resurrect/scripts/save.sh" } \
      "Restore last save"          R { run-shell "~/.config/tmux/plugins/tmux-resurrect/scripts/restore.sh" } \
      "" \
      "Detach"                     d { detach-client } \
      "Kill session"               X { confirm-before -p "kill session #S? (y/n)" kill-session } \
  } \
  "Windows…"             w { display-menu -T "#[align=centre fg=#bb9af7] windows " -x C -y C \
      "New window"                 c { new-window -c "#{pane_current_path}" } \
      "Choose window"              w { choose-tree -Zw } \
      "Rename window"              r { command-prompt -I "#W" { rename-window "%%" } } \
      "Last window"                l { last-window } \
      "Move left"                  < { swap-window -d -t -1 } \
      "Move right"                 > { swap-window -d -t +1 } \
      "Next layout"                Space { next-layout } \
      "" \
      "Kill window"                X { confirm-before -p "kill window #W? (y/n)" kill-window } \
  } \
  "Panes…"               p { display-menu -T "#[align=centre fg=#bb9af7] panes " -x C -y C \
      "Split side by side"         | { split-window -h -c "#{pane_current_path}" } \
      "Split top/bottom"           - { split-window -v -c "#{pane_current_path}" } \
      "Zoom toggle"                z { resize-pane -Z } \
      "Show pane numbers"          q { display-panes } \
      "Break to new window"        ! { break-pane } \
      "Synchronise panes"          S { setw synchronize-panes } \
      "IDE layout"                 i { split-window -v -l 30% -c "#{pane_current_path}" ; split-window -h -l 66% -c "#{pane_current_path}" ; split-window -h -l 50% -c "#{pane_current_path}" } \
      "" \
      "Kill pane"                  x { kill-pane } \
  } \
  "Tools…"               t { display-menu -T "#[align=centre fg=#bb9af7] tools " -x C -y C \
      "Popup shell"                t { display-popup -E -w 80% -h 80% -d "#{pane_current_path}" } \
      "lazygit"                    g { display-popup -E -w 90% -h 90% -d "#{pane_current_path}" lazygit } \
      "btop / htop"                h { display-popup -E -w 90% -h 90% "command -v btop >/dev/null && btop || htop" } \
      "Clipboard history"          y { display-popup -E -w 85% -h 85% -T " clipboard " "$HOME/.local/bin/clip" } \
      "All shortcuts (keys)"       k { display-popup -E -w 90% -h 90% -T " keys " "bash -ic keys" } \
      "Open URL from pane"         u { run-shell -b "~/.config/tmux/plugins/tmux-fzf-url/fzf-url.sh" } \
      "tmux-fzf (manage anything)" f { run-shell -b "~/.config/tmux/plugins/tmux-fzf/main.sh" } \
  } \
  "Plugins…"             P { display-menu -T "#[align=centre fg=#bb9af7] plugins (TPM) " -x C -y C \
      "Install"                    I { run-shell "~/.config/tmux/plugins/tpm/bindings/install_plugins" } \
      "Update"                     U { run-shell "~/.config/tmux/plugins/tpm/bindings/update_plugins" } \
      "Clean unused"               C { run-shell "~/.config/tmux/plugins/tpm/bindings/clean_plugins" } \
  } \
  "" \
  "Copy mode"            Enter { copy-mode } \
  "Command prompt"       : { command-prompt } \
  "Search all bindings"  ? { display-popup -E -w 85% -h 85% -T " key bindings " "$HOME/.local/bin/tmux-keys" } \
  "Reload config"        r { source-file ~/.config/tmux/tmux.conf ; display "tmux.conf reloaded" }
