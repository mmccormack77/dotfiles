# BBR Terminal Setup: Adopting Joel's Dotfiles

A step-by-step guide for BBR engineers to adopt Joel Micalizzi's dotfiles repo for a friendlier terminal experience on a Coder workspace, without breaking the existing environment.

## Context

Joel's upstream `bootstrap.sh` does a lot: it installs Homebrew, Snowflake CLI, Azure CLI, Terraform, pyenv, fnm, and overwrites the entire `~/.claude/` configuration. Running it as-is on a BBR-managed Coder workspace is aggressive and would clobber the Claude Code config governed by BBR org policies.

This guide adopts **only the shell niceties** (zsh + Oh My Zsh + Starship prompt + fzf + git config + the `de` plugin) by forking the repo, customizing it, and symlinking just the pieces needed. The rest of Joel's repo stays in your fork as reference.

**Scope (what this guide installs):**
- zsh as the interactive shell
- Oh My Zsh framework with a curated plugin list
- Starship prompt
- fzf (Ctrl-R fuzzy history search)
- Customized git config and global gitignore
- Joel's `de` custom plugin

**Out of scope (intentionally skipped):**
- Homebrew on Linux
- Snowflake CLI, Azure CLI, Terraform, pyenv, fnm, Kona
- `chsh` (Coder workspaces have no Linux password; we use a bashrc handoff instead)

## Critical files

Files you'll read or edit during execution:

- `~/dotfiles/de.zshrc` (edit before symlinking), main zsh config
- `~/dotfiles/configs/.gitconfig` (edit before symlinking), git identity
- `~/dotfiles/configs/starship.toml` (use as-is), prompt config
- `~/dotfiles/configs/.gitignore_global` (use as-is)
- `~/dotfiles/plugins/de/de.plugin.zsh` (optional edit), Joel's custom plugin, one hardcoded email inside `de_git_work_log`

Files this guide deliberately **DOES NOT TOUCH:**

- `~/.claude/` (Claude Code config, BBR-governed)
- `~/.config/Code/User/settings.json` (code-server settings)
- `~/.snowflake/`, `~/.azure/` (out of scope)
- `~/.bashrc` (left intact as fallback)

---

## Guide

### Step 0a. Pre-flight verification

In your current bash terminal, confirm prerequisites:

```bash
zsh --version                              # expect 5.8.x or higher
git --version
curl --version | head -1
echo "default shell: $(getent passwd $USER | cut -d: -f7)"
df -h ~ | tail -1                          # confirm at least a few hundred MB free
```

If any of these fail, stop and investigate before continuing.

### Step 0b. Decide on your git identity (no action yet)

Just pick the values you'll use later, no commands here. You'll write them into the config file in Step 4a.

- **Name:** your full name as it appears in BBR systems (Outlook, Teams, etc.)
- **Email:** your BBR email (`<firstinitial+lastname>@bbrpartners.com`)

### Step 0c. Nerd Font (one-time local setup on Windows, recommended)

A "Nerd Font" is a programming font with extra glyph icons (folder, git branch, lock, etc.). Joel's Starship prompt config uses these icons. Without one, you'll see small boxes or question marks where the icons should be.

You're using the VS Code desktop app on Windows connected to a Coder workspace, so the terminal font is rendered locally by VS Code on your Windows machine. Install the font there:

1. Download **MesloLG Nerd Font** (Joel's recommendation): https://github.com/ryanoasis/nerd-fonts/releases/latest, look for `Meslo.zip`
2. Extract the zip file
3. Open Windows Settings, go to **Personalization > Fonts**
4. Drag and drop the `.ttf` files into the Fonts pane (or click "Browse and install fonts" at the top) to install each font face
5. In VS Code, open Settings (Ctrl+,), click the `{}` icon (top right) to open `settings.json`, and add both:

```json
"terminal.integrated.fontFamily": "MesloLGS Nerd Font, monospace",
"editor.fontFamily": "MesloLGS Nerd Font, Consolas, 'Courier New', monospace"
```

> **Why both keys?** `terminal.integrated.fontFamily` is what makes Starship's icons render in the terminal panel, this is the one that matters for the prompt. `editor.fontFamily` controls the code editor font. Setting both keeps everything consistent.

> **Why "MesloLGS" with an S?** Nerd Fonts package the Meslo family as `MesloLGS NF` / `MesloLGM NF` / `MesloLGL NF` (S/M/L = small, medium, large line spacing). `MesloLGS Nerd Font` is the most common variant.

If you'd rather skip this and use a plain prompt, see "Fallback: No Nerd Font" at the bottom of this guide.

### Step 1. Backup everything we might touch

One-shot safety net:

```bash
BACKUP_DIR="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -a "$HOME/.bashrc"  "$BACKUP_DIR/.bashrc.orig"  2>/dev/null || true
cp -a "$HOME/.profile" "$BACKUP_DIR/.profile.orig" 2>/dev/null || true
tar -czf "$BACKUP_DIR/dot-claude-snapshot.tgz" -C "$HOME" .claude
getent passwd "$USER" > "$BACKUP_DIR/passwd.line"
echo "Backup at: $BACKUP_DIR"
ls -la "$BACKUP_DIR"
```

The `~/.claude/` tar is a defensive snapshot only; this guide does not touch that directory. Note `$BACKUP_DIR` for the rollback step.

### Step 2. Fork Joel's repo in the GitHub browser UI

1. Open https://github.com/jcmicalizzi/dotfiles in your browser
2. Click **Fork** (top right) and accept the defaults; the fork lands at `https://github.com/<your-github-username>/dotfiles`
3. Note your GitHub username for the next step

> **Visibility:** the fork is public, which is normal and what Joel intended ("you can fork this repo"). GitHub does not notify Joel when anyone forks; he'd only see your fork if he specifically opens his repo's "Forks" tab. Public forks of a public repo don't expose anything that wasn't already public. (GitHub blocks converting a public fork to private; if privacy ever matters later, use a private mirror repo instead of a fork.)

### Step 3. Clone your fork to `~/dotfiles`

Replace `<your-github-username>` with your GitHub username from Step 2:

```bash
git clone https://github.com/<your-github-username>/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
git remote add upstream https://github.com/jcmicalizzi/dotfiles.git
git remote -v                              # should show origin (yours) + upstream (Joel's)
```

> **How forks and `upstream` actually work:** Your fork is an independent copy. Edits you make stay in your fork only; Joel cannot see them. Joel's future changes do NOT auto-sync into your fork, your fork is frozen at the moment you forked it. The `upstream` remote is only a named bookmark pointing at Joel's repo; it does nothing on its own. To pull Joel's later updates you would have to explicitly run `git fetch upstream && git merge upstream/main` (or click "Sync fork" in the GitHub web UI), at which point you can review and accept or reject the changes. If you never want Joel's updates, just don't run that command, your fork will stay exactly as you left it.

### Step 4. Customize Joel-specific files (do this before symlinking)

Work on a branch in your fork so the originals stay accessible:

```bash
cd "$HOME/dotfiles"
git checkout -b <your-name>-customizations
```

**4a. Edit `~/dotfiles/configs/.gitconfig`**, replace Joel's identity:

```ini
[user]
    name = <YOUR FULL NAME>
    email = <your-bbr-email>
[core]
    excludesfile = ~/.gitignore_global
[init]
    defaultBranch = main
[pull]
    rebase = false
```

**4b. Edit `~/dotfiles/de.zshrc`**, three surgical changes:

1. Remove the linuxbrew PATH line (we have no Homebrew):
   ```
   export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
   ```
   Delete this line.

2. Add two PATH lines so Starship and fzf resolve:
   ```
   export PATH="$HOME/.local/bin:$PATH"
   export PATH="$HOME/.fzf/bin:$PATH"
   ```
   The first is for Starship (installed to `~/.local/bin` in Step 5b). The second is for fzf (installed to `~/.fzf/bin` in Step 5c). Without the fzf PATH line, the `source <(fzf --zsh)` call later in this file will emit `command not found: fzf` on every shell startup.

3. Replace the plugins line. Find:
   ```
   plugins=(git python uv vscode kona de docker docker-compose terraform azure custom_azure claude_code)
   ```
   Replace with:
   ```
   plugins=(git python vscode de docker docker-compose)
   ```
   (Dropping `uv`, `kona`, `terraform`, `azure`, `custom_azure`, `claude_code` because their backing tools/plugins aren't installed.)

4. Update the `GIT_COMMIT_AUTHOR` line:
   ```
   export GIT_COMMIT_AUTHOR="<YOUR FULL NAME> <<your-bbr-email>>"
   ```

**4c. Optional**, `~/dotfiles/plugins/de/de.plugin.zsh` contains a `de_git_work_log` function hardcoded with Joel's email. If you want to use that function, change `jmicalizzi@bbrpartners.com` to your own BBR email inside it. Otherwise skip.

**4d. Commit your customizations:**

```bash
cd "$HOME/dotfiles"
git add -A
git -c user.email=<your-bbr-email> \
    -c user.name="<YOUR FULL NAME>" \
    commit -m "Customize identity and trim plugins for BBR dev box"
```

**4e. Set up GitHub auth for your personal fork, then push:**

The Coder workspace auto-injects a GitHub token scoped to the `bbrpartners` org (that's how pushes to BBR-org repos work without prompting). That injected token has no write access to your personal account, so pushing to `<your-github-username>/dotfiles` returns 403. The fix is to pre-load a personal Personal Access Token (PAT) into git's credential store, which takes precedence over Coder's helper.

**Create a fine-grained PAT scoped only to your `dotfiles` repo:**

1. In your browser, go to https://github.com/settings/personal-access-tokens/new (the **fine-grained** UI, note the URL says "personal-access-tokens", not "tokens")
2. **Token name:** `BBR coder dev box - dotfiles`
3. **Resource owner:** yourself (your personal GitHub username). If you have access to organizations like `bbrpartners`, do NOT pick one of those, this PAT is for your personal account only.
4. **Expiration:** **Custom, set to 1 year from today** (maximum allowed for fine-grained tokens). GitHub will email you ~7 days before it expires.
5. **Repository access:** select **"Only select repositories"** and pick your dotfiles fork. Don't leave this blank, and don't pick "Public Repositories (read-only)" or "All repositories."
6. **Permissions > Repository permissions > Contents:**
   - **This is the most common trap.** The dropdown defaults to **"No access"**. You MUST change it to **"Read and write"**, not "Read-only" (push will 403), not "No access" (push will 403).
   - Click the **Contents** row, then select **Access: Read and write** from the dropdown.
   - Leave every other permission row as "No access". You don't need Metadata (auto-granted), Pull requests, Issues, Workflows, or anything else for this use case.
7. Before clicking Generate, scroll back up and verify the summary at the top of the page shows:
   - Repository access: `1 repository selected` (your dotfiles fork)
   - Repository permissions: `1 permission`, Contents: Read and write
8. Click **Generate token** at the bottom of the page
9. **Copy the token immediately**, GitHub shows it exactly once. It's ~93 characters and starts with `github_pat_`. Treat it like a password.

> **If the push later returns `Permission to <your-github-username>/dotfiles.git denied to <your-github-username>`:** the PAT authenticated correctly but lacks write permission. Go to https://github.com/settings/personal-access-tokens, click your token, find **Permissions > Contents**, and change it to **Read and write**. Save. Retry the push (no need to regenerate or update `~/.git-credentials`, the token value is unchanged, only its permissions).

**Load the PAT into git's credential store, then push:**

```bash
# Tell git to use the on-disk credential store helper.
git config --global credential.helper store

# Make sure the file is created with safe permissions even if it didn't exist before.
umask 077
touch "$HOME/.git-credentials"
chmod 600 "$HOME/.git-credentials"
```

Now write the PAT into the credentials file. **Use VS Code, not shell `printf`**: shell substitution is fragile and you can easily end up with an empty file or a literal `<PAT>` placeholder.

1. In VS Code, open `~/.git-credentials` (Ctrl+P, type the path, Enter)
2. Paste exactly this single line, replacing `YOUR_PAT_HERE` with the token you copied:
   ```
   https://<your-github-username>:YOUR_PAT_HERE@github.com
   ```
   - No quotes around it
   - No leading or trailing spaces
   - No newline before the line; one trailing newline at the end is fine
3. Save (Ctrl+S)
4. Verify in the terminal:
   ```bash
   ls -la ~/.git-credentials                                              # size > 0, mode -rw-------
   sed 's|://\([^:]*\):[^@]*@|://\1:REDACTED@|' ~/.git-credentials        # prints: https://<your-github-username>:REDACTED@github.com
   ```

Now push:

```bash
cd ~/dotfiles
git push -u origin <your-name>-customizations
```

If you see `Branch '<your-name>-customizations' set up to track 'origin/<your-name>-customizations'` and no 403, you're done. Future pushes from this repo will use these credentials silently.

> **Troubleshooting matrix:**
>
> | Error | Cause | Fix |
> |---|---|---|
> | `Invalid username or token. Password authentication is not supported.` | `~/.git-credentials` is empty or missing the token | Re-do the VS Code edit; verify with the `sed` command above |
> | `Permission to <your-github-username>/dotfiles.git denied to <your-github-username>.` | PAT exists but `Contents` permission is not "Read and write" | Edit the PAT's Contents permission on GitHub; no need to regenerate |
> | `repository 'https://...' not found` | Repo doesn't exist or PAT resource owner is wrong | Verify the fork exists at `github.com/<your-github-username>/dotfiles`; check PAT resource owner is your personal account |
>
> **In ~1 year when the PAT expires:** GitHub will email you. Generate a new PAT (same steps), open `~/.git-credentials` in VS Code, replace the old token portion with the new one, save.
>
> **If the workspace is ever destroyed and rebuilt:** your customized commits live safely on GitHub. In the new workspace, re-clone the fork (Step 3), re-create `~/.git-credentials` via the same VS Code paste, and you're back. The PAT itself is in your GitHub account and survives workspace destruction.

### Step 5. Install the lean tooling (no sudo, no Homebrew)

**5a. Oh My Zsh** (zsh framework):

```bash
ls ~/.oh-my-zsh 2>/dev/null && echo "already exists, skip" || \
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

`RUNZSH=no` keeps you in bash at the end of install; `CHSH=no` suppresses the mid-install "change your default shell to zsh?" prompt (we defer that to Step 9 after testing); `KEEP_ZSHRC=yes` prevents the installer from writing its own `~/.zshrc` (we provide ours via symlink in Step 7).

> **If the installer prompts "Do you want to change your default shell to zsh? [Y/n]" anyway** (e.g., you forgot `CHSH=no`): type **`n`** and press Enter. The default shell change happens intentionally in Step 9, after verifying the config works in Step 8.

**5b. Starship** (prompt):

```bash
mkdir -p "$HOME/.local/bin"
curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
"$HOME/.local/bin/starship" --version
```

**5c. fzf** (fuzzy finder, Ctrl-R history search):

```bash
git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
"$HOME/.fzf/install" --key-bindings --completion --no-update-rc
```

`--no-update-rc` is important: it tells fzf NOT to edit your shell rc files (our zshrc handles fzf integration via `source <(fzf --zsh)`).

### Step 6. Copy the `de` custom plugin (only)

```bash
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
cp -r "$HOME/dotfiles/plugins/de" "$HOME/.oh-my-zsh/custom/plugins/de"
ls "$HOME/.oh-my-zsh/custom/plugins/"      # should list just "de" (plus an example dir from OMZ)
```

Skip Joel's `claude_code`, `custom_azure`, and `kona` plugins.

### Step 7. Symlink the dotfiles into `$HOME`

Symlinks (not copies) mean future repo edits propagate automatically and `git pull upstream main` can deliver Joel's updates.

```bash
# Defensive: if anything pre-exists that isn't a symlink, back it up.
for f in .zshrc .gitconfig .gitignore_global; do
  if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
    echo "Backing up existing $HOME/$f"
    mv "$HOME/$f" "$BACKUP_DIR/${f}.pre-symlink"
  fi
done

ln -sf "$HOME/dotfiles/de.zshrc"                  "$HOME/.zshrc"
ln -sf "$HOME/dotfiles/configs/.gitconfig"        "$HOME/.gitconfig"
ln -sf "$HOME/dotfiles/configs/.gitignore_global" "$HOME/.gitignore_global"
mkdir -p "$HOME/.config"
ln -sf "$HOME/dotfiles/configs/starship.toml"     "$HOME/.config/starship.toml"

ls -la "$HOME/.zshrc" "$HOME/.gitconfig" "$HOME/.gitignore_global" "$HOME/.config/starship.toml"
```

### Step 8. Test in a subshell BEFORE changing default shell

Critical safety step. Launch zsh inside your bash terminal:

```bash
zsh -l
```

Inside zsh, run these checks:

```zsh
echo "We are in: $0"                       # should be -zsh
which starship                              # ~/.local/bin/starship
git config --get user.email                 # your BBR email
alias gst                                   # should show: gst='git status'
type de_load_dotenv                         # should say: ...is a shell function
exit                                        # drops you back to bash
```

**What to look for:**
- Starship prompt renders with colored sections (if you see boxes for icons, the Nerd Font isn't installed yet, see Step 0c or use the no-Nerd-Font fallback at the bottom)
- No red error messages on startup
- Aliases like `gst`, `gco`, `glog` work

**If you see "plugin not found" errors:** something didn't get trimmed in Step 4b. Re-edit `~/dotfiles/de.zshrc`, remove the offending plugin, and re-test.

### Step 9. Make zsh your default shell (bashrc handoff, no password needed)

> **Why not `chsh`?** On a Coder workspace the `coder` Linux account has no usable password (`passwd -S` reports status `L` for locked, you log in via Coder web/SSO, never via a Linux password). `chsh` would prompt for that password, you'd have nothing valid to enter, and PAM would reject. So this guide uses a different approach that needs no privilege.

Only after Step 8 looks good. Add a small handoff block to the end of `~/.bashrc` so that every new bash session silently hands off to zsh.

> **Note:** the block below is a **shell command** to run in your terminal. The `cat >> ... <<'EOF' ... EOF` syntax tells bash to append the lines between the EOF markers to `~/.bashrc`. Do NOT paste this entire block into the `.bashrc` file in an editor, only run it in the terminal once.

```bash
cat >> "$HOME/.bashrc" <<'EOF'

# Hand off interactive bash sessions to zsh (added by dotfiles setup)
if [ -z "$ZSH_VERSION" ] && [ -x /usr/bin/zsh ] && [[ $- == *i* ]]; then
    exec /usr/bin/zsh -l
fi
EOF
```

**What the block does, line by line:**
- `-z "$ZSH_VERSION"`, only proceed if NOT already in zsh (prevents an infinite handoff loop)
- `-x /usr/bin/zsh`, only proceed if zsh is actually installed and executable
- `[[ $- == *i* ]]`, only proceed for *interactive* shells (so scripts that source `~/.bashrc` aren't affected)
- `exec /usr/bin/zsh -l`, replace the bash process with a login zsh; no nested shell, no stacked processes

**Verify it was appended correctly:**

```bash
tail -6 "$HOME/.bashrc"     # should show the block you just added
```

**Test:** close the current terminal in VS Code and open a brand-new one. It should drop you directly into zsh with the Starship prompt, no manual `zsh -l` needed.

> **Quirks worth knowing:**
> - `echo $SHELL` will still report `/bin/bash` (the OS-level default). Cosmetic only, you ARE in zsh, just look at the prompt and run `echo $0` (it'll show `-zsh`).
> - Subshells started via `bash -c "..."` will run bash, not zsh. Almost never matters in practice; matters only if a script you write assumes zsh syntax.
> - This block only activates for INTERACTIVE bash. Scripts that `source ~/.bashrc` (rare, but they exist) won't get hijacked.

### Step 10. Verification

In a brand-new terminal:

```bash
echo "$0"                                   # -zsh
which starship                              # ~/.local/bin/starship
git config --global user.name               # your name
git config --global user.email              # your BBR email
alias gst gco glog                          # all should expand
# Press Ctrl-R: should show fzf-styled history search
```

Checklist:
- [ ] Prompt is colored with directory and (in repos) git branch info
- [ ] `gst` works as a shortcut for `git status`
- [ ] `Ctrl-R` opens fzf history search
- [ ] Commits attribute to you with your BBR email
- [ ] `~/.claude/` directory still has all its original files

---

## Rollback (if you want to undo everything)

```bash
# Restore the original .bashrc (this also removes the zsh handoff block).
cp -a "$BACKUP_DIR/.bashrc.orig" "$HOME/.bashrc"

# Remove symlinks.
rm -f "$HOME/.zshrc" "$HOME/.gitconfig" "$HOME/.gitignore_global" "$HOME/.config/starship.toml"

# Optional: remove installed tools.
rm -rf "$HOME/.oh-my-zsh" "$HOME/.fzf"
rm -f  "$HOME/.local/bin/starship" "$HOME/.fzf.zsh" "$HOME/.fzf.bash"

# Optional: remove the dotfiles repo.
rm -rf "$HOME/dotfiles"
```

Open a fresh terminal. You're back to where you started. `~/.claude/` is untouched throughout.

---

## Fallback: No Nerd Font

If after Step 8 the prompt shows boxes/missing icons and you'd rather not install a Nerd Font, swap to a plain Starship preset:

```bash
"$HOME/.local/bin/starship" preset plain-text-symbols > "$HOME/dotfiles/configs/starship.toml"
cd "$HOME/dotfiles" && git add configs/starship.toml && \
  git -c user.email=<your-bbr-email> -c user.name="<YOUR FULL NAME>" \
    commit -m "Use plain-text Starship preset (no Nerd Font required)"
```

Open a new terminal, icons are replaced with ASCII characters.

---

## Final verification

Open a fresh terminal and confirm all of:
- `echo $0` shows `-zsh`
- Prompt is styled (Starship)
- `git config --get user.email` returns your BBR email
- `gst`, `gco`, `glog` aliases work
- `Ctrl-R` opens fzf history search
- `ls ~/.claude/` still shows your existing Claude Code config (unchanged)
