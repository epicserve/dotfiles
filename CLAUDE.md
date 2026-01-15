# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for macOS, WSL/Ubuntu, and Omarchy (Arch Linux). Uses shell scripts and symlinks to manage configurations across platforms.

## Setup Commands

```bash
# macOS
./setup_macos.sh

# WSL/Ubuntu
./setup_wsl_ubuntu.sh

# Omarchy/Arch Linux
./setup_omarchy.sh
```

The setup scripts are interactive and will prompt for Git configuration details (name, emails, SSH key from 1Password).

## Architecture

**Entry Points:** Platform-specific setup scripts at root level (`setup_*.sh`) that source shared scripts.

**Shared Scripts (`scripts/`):**
- `base_setup.sh` - Universal tools (uv, AWS CLI, fzf)
- `base_linux_setup.sh` - Linux-specific tools (aws-vault, Just, AppPack)
- `setup_git.sh` - Interactive Git configuration with 1Password SSH integration
- `setup_zsh.sh` - Oh My Zsh, zoxide, zsh config symlinks
- `setup_zsh_theme.sh` - Powerlevel10k theme
- `setup_brew.sh` - Homebrew packages (macOS only)
- `setup_macos_settings.sh` - macOS system preferences

**Configuration Files (`config/`):**
- `zsh/` - Shell configuration (.zshrc, .p10k.zsh) - symlinked via $ZDOTDIR
- `git/` - Git config with base + local/work overrides using include directives
- `aliases/` - Shell aliases sourced by .zshrc/.bashrc
- `hypr/` - Hyprland window manager overrides (input, bindings, workspaces)
- `omarchy/` - Omarchy theme files and bashrc additions
- `ghostty/` - Ghostty terminal configuration
- `waybar/` - Status bar config including multi-monitor support
- `pipewire/` - Audio configuration

## Key Patterns

**Symlink-based:** Configs are symlinked from `~/.dotfiles/config/` to `~/.config/`, not copied.

**Conditional appending:** Scripts check with `grep -qFx` before appending to existing configs (like `~/.config/hypr/hyprland.conf`).

**Git configuration:** Uses 1Password for SSH keys and commit signing. Work vs personal configs are separated via Git's includeIf directive based on directory paths.

**Multi-monitor detection:** Omarchy setup detects monitor count via `hyprctl monitors -j` and applies appropriate workspace/waybar configs.

## Omarchy-Specific Notes

Omarchy setup adds source directives to the main Hyprland config (`~/.config/hypr/hyprland.conf`) rather than replacing it. Custom configs in `config/hypr/` are included via `source = ~/.dotfiles/config/hypr/...` lines.

See `docs/omarchy.md` for manual post-setup steps (monitor configuration, PyCharm setup, Zen Browser settings).