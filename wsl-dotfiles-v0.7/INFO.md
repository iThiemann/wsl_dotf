Everything is in the updated wsl-dotfiles.tar.gz. I tested the git part against real repos on git 2.43, the same version Ubuntu 24.04 ships. The rbw, helmfile and Windows Terminal changes are written but haven’t been run.

Multiple git servers, accounts and credentials

Git chooses settings in two ways:

Identity (name, email, SSH key, signing) is picked by where the repo is or where its remote points.
Credentials are picked by the URL being accessed, so they also apply to git clone.

These rules go into ~/.gitconfig.local, which stays out of the repo. Your shared ~/.gitconfig doesn’t change.

ini
# ~/.gitconfig.local
[includeIf "gitdir:~/work/"]                                        # repo location
	path = ~/.config/git/identities/work
[includeIf "hasconfig:remote.*.url:https://gitlab.company.com/**"]  # remote URL (git ≥ 2.36)
	path = ~/.config/git/identities/work
[credential "https://gitlab.company.com"]                           # credentials per URL
	helper =                      # empty line = forget the default helper
	helper = rbw                  # or the Windows Credential Manager, or a 1-hour cache
	username = mmustermann
[credential "https://github.com"]
	useHttpPath = true            # two accounts on one host: ask per repo path, not per host

The identity file holds user.email, the SSH key (core.sshCommand = ssh -i ~/.ssh/id_work …) and SSH commit signing.

You don’t have to write these by hand. git-identity add work --email … --dir ~/work/ --url gitlab.company.com --ssh-key ~/.ssh/id_work --sign --cred rbw creates the identity file and all the rules. git-identity check, run inside a repo, shows which email, key and credential helper apply there and which file each comes from.

The first git clone happens before any identity file applies, so for it use an SSH host alias; the template is in ssh_config.example.

rbw (Bitwarden CLI)

The oh-my-zsh rbw plugin is enabled. rbw itself is installed with apt, as its page says: sudo apt install rbw. 
github.com
For WSL terminals, the installer sets the password prompt to the text-mode pinentry-curses. You still need to set your email with rbw config set email you@example.com. The installer reminds you, and shows the setting for the EU vault.
Passwords stay out of the clipboard history. The plugin’s own rbwpw copies passwords the normal way, so my clipboard recorder (Hyper+Q / clip) would have saved them. I replaced it: rbwpw and rbwf (an fzf picker) mark the copied password as private, so neither the history nor Windows’ Win+V keeps it. It clears after 20 seconds.
Git tokens from the vault: the new git-credential-rbw helper is what helper = rbw above uses.
SSH keys from the vault: optional with RBW_SSH_AGENT=1. rbw has a built-in agent: after rbw unlock, point SSH_AUTH_SOCK at $XDG_RUNTIME_DIR/rbw/ssh-agent-socket. 
github.com
YubiKey: rbw supports Email, Authenticator App, and Yubico OTP security keys (so YubiKeys work only via Yubico OTP); WebAuthn/passkeys and Duo don’t work. 
github.com
Both links are in the README, together with the Yubico test article.

Helm zsh completion

This was already covered: the oh-my-zsh helm plugin generates and caches exactly what the docs describe, source <(helm completion zsh). I added a fallback that loads it directly if the plugin is ever removed. bash already had cached helm completion. 
helm.sh

helm_ls for helmfiles

I added this, but not by pasting the snippet. It uses the old pre-0.11 lspconfig.helm_ls.setup form, and root_patterns isn’t a real lspconfig option (the current one is root_markers). The same settings are now in the LazyVim config:

filetypes = { "helm", "helmfile" }, with Chart.yaml or helmfile.yaml marking the project root.
A new helmfile filetype for helmfile*.yaml, helmfile.d/*.yaml and *.yaml.gotmpl. Without it, helm_ls never starts on those files.
The test now covers two helmfile samples.
<leader>if / <leader>iF run helmfile lint / diff on the current file.
The nvim guide doc is updated to match.

Windows Terminal session restore

Both settings were already in place: “Open windows from a previous session” (firstWindowPreference: persistedWindowLayout) and “Launch on machine startup” (startOnUserLogin).

Your summary of the limitations matches the setup. The Windows README now has a restored / not restored table with your link, and what fills each gap:

Running programs: the tmux profile, which brings back sessions, panes and nvim.
SSH re-authentication: key-based login through ssh-agent or rbw’s agent, so restored SSH tabs log in on their own.

Links I couldn’t open

Three of your links didn’t load here, so for them I went by your summary and what I already knew:

the oh-my-zsh rbw page (GitHub blocks automated access)
the Windows Terminal blog post (the site returned an error)
the Yubico article (it loaded without its text)
