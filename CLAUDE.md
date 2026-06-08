# CLAUDE.md — dotfiles
Personal dotfiles for a Linux (Ubuntu) development environment, managed via Oh My Zsh and bootstrapped with `bootstrap.sh`.
## Repo Structure
- `de.zshrc` — the main zshrc; copied to `~/.zshrc` by bootstrap
- `bootstrap.sh` — idempotent setup script, run with `./bootstrap.sh`
- `Brewfile` — Homebrew packages
- `plugins/` — custom Oh My Zsh plugins, each in their own subdirectory
- `configs/` — config files copied to their target locations by bootstrap
