# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

**Salchipapa.Dots** is a dotfiles repository for a Linux development environment. It contains configuration files for shell, terminal multiplexer, terminal emulator, editor, and CLI tools — plus an interactive installer (`install.sh`) and a set of SSH/Git multi-account management scripts.

All config directories under `Salchipapa*/` are meant to be symlinked into `~/.config/` or `~` by `install.sh`. There are no build steps, tests, or package managers for the dotfiles themselves.

## Running the installer

```bash
chmod +x install.sh
sudo ./install.sh
```

The installer is interactive. It:
1. Prompts for shell choice (Fish or Zsh), multiplexer (Zellij or Tmux), and terminal emulator (Alacritty or Wezterm).
2. Installs Homebrew, system packages, and core tools via `brew`.
3. Creates symlinks from this repo into `~/.config/`.
4. Syncs Neovim plugins: `nvim --headless '+Lazy! sync' +qa`

To install just CLIs (Gemini, Angular) and re-sync Neovim plugins, choose **"Install CLIs + Lazy sync"** from the menu.

## SalchipapaGit — SSH multi-account scripts

These are standalone bash scripts in `SalchipapaGit/`. They must be run directly (not via the installer):

| Script | Purpose |
|---|---|
| `setup-git-users` | First-time setup: creates `~/.gitconfig`, `~/.ssh/config`, and SSH keys for one main account + optional extras |
| `add-git-user` | Adds an additional GitHub account after initial setup |
| `user-delete` | Removes an SSH account (key, gitconfig, SSH config entry) |
| `clone-repo` | Clones a repo using a selected SSH identity (replaces `github.com` with the correct `gh-<key>` host alias) |

The SSH host alias convention is `gh-<keyname>` (e.g. `gh-personal`, `gh-work`). Per-account git config files are `~/.gitconfig-<keyname>`, activated via `[includeIf "gitdir:~/<dir>/"]` blocks in `~/.gitconfig`.

## Neovim configuration

Entry point: `SalchipapaNvim/nvim/init.lua` → loads `config.nodejs` then `config.lazy` (LazyVim).

- `lua/config/` — core configuration (keymaps, options, autocmds, lazy bootstrap, Node.js path setup)
- `lua/plugins/` — per-plugin LazyVim specs (AI tools: copilot, avante, gemini, code-companion, claude-code; editor tools: fzf-lua, oil, obsidian, nvim-dap, blink, dial, etc.)

The `lua/config/nodejs.lua` module resolves the Node.js binary path (via nvm) before plugins load.

Sync plugins headlessly: `nvim --headless '+Lazy! sync' +qa`

## Fish shell configuration

`SalchipapaFish/fish/config.fish` is the main entry point. Key behaviors:
- Auto-starts Zellij if not already inside a Zellij session.
- Initializes starship, zoxide, atuin, fzf, and carapace completions.
- Enables vi key bindings.
- `obs` alias: syncs the Obsidian vault at `~/.config/obsidian` to GitHub.

Fish plugins are managed by Fisher (`fish_plugins` file).

## Theme

All configs use the **Solarized Osaka** color palette. The installer scripts share a common ANSI color block — when adding new scripts, follow the same pattern from any existing `SalchipapaGit/` script.

## WSL notes

The environment runs on WSL2. Clipboard in Neovim requires `win32yank` installed on the Windows side and available in the Windows PATH.
