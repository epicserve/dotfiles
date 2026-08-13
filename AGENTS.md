# AGENTS.md

Personal dotfiles for macOS, WSL/Ubuntu, and Omarchy (Arch Linux). Platform setup
scripts plus symlinked configs. `CLAUDE.md` imports this file so Claude Code,
Codex, and Grok share one set of instructions.

## Setup

```bash
./setup_macos.sh        # macOS
./setup_wsl_ubuntu.sh   # WSL/Ubuntu
./setup_omarchy.sh      # Omarchy/Arch
```

Scripts are interactive. Git setup asks for name, personal/work emails, a work
project parent path, and a 1Password SSH key for commit signing.

Omarchy post-setup (monitors, PyCharm, Zen, 1Password) lives in `docs/omarchy.md`.
Do not duplicate those steps here.

## Layout

- Root `setup_*.sh` files source shared scripts under `scripts/`.
- `config/` is the source of truth. Runtime copies are symlinks into `~/.config/`,
  not copies. Edit files in this repo.
- Zsh uses `$ZDOTDIR=$HOME/.config/zsh` (set in `~/.zshenv`). Edit
  `config/zsh/`, not `~/.zshrc`.

### Shared scripts

| Script | Role |
| --- | --- |
| `base_setup.sh` | Cross-platform tools (uv, AWS CLI, fzf, Sentry CLI) |
| `base_linux_setup.sh` | Linux tools from upstream GitHub releases (aws-vault, Just, AppPack) |
| `setup_git.sh` | Interactive Git + 1Password SSH signing |
| `setup_zsh.sh` / `setup_zsh_theme.sh` | Oh My Zsh, zoxide, Powerlevel10k, config symlinks |
| `setup_brew.sh` / `setup_macos_settings.sh` | macOS only |
| `setup_chatgpt.sh` | Official ChatGPT desktop: verify OpenAI's signed RPM repo, repackage for pacman |
| `setup_stripe_cli.sh` | Official Stripe CLI binary (not the AUR) |
| `setup_obs.sh` / `backup_obs.sh` | Restore / backup OBS scenes and profiles |

### Config

- `zsh/` — `.zshrc`, `.p10k.zsh`, per-OS override scripts
- `git/` — base config plus `include` / `includeIf` local and work overlays
- `aliases/` — sourced by zsh/bash
- `hypr/` — Hyprland overrides; `omarchy_hyprland_overrides.conf` sources the `_*.conf` partials
- `omarchy/` — theme (`digital-nature`) and bashrc additions
- `ghostty/`, `waybar/`, `pipewire/`, `vscode/`, `udev/`, `obs/`, `claude/`
- `chatgpt/openai-linux-repository.asc` — pinned OpenAI Linux repo public key

## Patterns

**Symlink, don't copy.** Point `~/.config/<app>` at `~/.dotfiles/config/<app>`.

**Append only if missing.** Use `grep -qFx` before adding a line to an existing
file such as `~/.config/hypr/hyprland.conf`.

**Git identity.** 1Password SSH for auth and commit signing. Personal vs work
email is selected with Git `includeIf` on directory path (see
`config/git/config_local`). Do not hard-code emails in scripts.

**Official installers vs AUR.** Prefer AUR/`yay` for ordinary packages. ChatGPT
desktop and Stripe CLI install from the vendor's signed artifacts because AUR
wrappers are a supply-chain risk. Do not replace those scripts with
`yay -S chatgpt-desktop-bin` or `yay -S stripe-cli`.

**ChatGPT updates.** `scripts/setup_chatgpt.sh` is idempotent (`--check` reports
without installing). The app must be quit before an install. The package name is
`chatgpt-bin`; that name collides with an unrelated AUR CLI, so do not let an
AUR helper "update" it.

## Omarchy / Hyprland

Setup *sources* custom files from this repo into Omarchy's
`~/.config/hypr/hyprland.conf`. It does not replace Omarchy's config.

- Edit `config/hypr/_*.conf` and keep them sourced from
  `omarchy_hyprland_overrides.conf`.
- `~/.config/hypr/envs.conf` is **not** loaded by Omarchy's Hyprland config.
  Environment overrides go in `config/hypr/_envs.conf`.
- Never edit `~/.local/share/omarchy/` — `omarchy update` overwrites it.
- Prefer `omarchy pkg add` / `omarchy` CLI for packages and desktop actions.
- Multi-monitor workspaces and waybar are applied only when
  `hyprctl monitors -j` reports more than one display.
- Setup removes Omarchy's ChatGPT webapp and installs the native desktop app.

After Hyprland edits, validate with `hyprctl reload` and `hyprctl configerrors`.
Waybar does not auto-reload; use `omarchy restart waybar`.
