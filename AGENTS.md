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
| `base_setup.sh` | Install mise, symlink `config/mise/`, `mise install` (uv, aws-cli, fzf, gh, node, …) |
| `setup_git.sh` | Interactive Git + 1Password SSH signing |
| `setup_zsh.sh` / `setup_zsh_theme.sh` | Oh My Zsh, Powerlevel10k, config symlinks |
| `setup_brew.sh` / `setup_macos_settings.sh` | macOS only |
| `setup_chatgpt.sh` | Official ChatGPT desktop: verify OpenAI's signed RPM repo, repackage for pacman |
| `setup_stripe_cli.sh` | Purge AUR `stripe-cli` if present (binary comes from mise) |
| `setup_obs.sh` / `backup_obs.sh` | Restore / backup OBS scenes and profiles |

### Config

- `zsh/` — `.zshrc`, `.p10k.zsh`, per-OS override scripts
- `git/` — base config plus `include` / `includeIf` local and work overlays
- `aliases/` — sourced by zsh/bash
- `hypr/` — Hyprland Lua overrides (`bindings.lua`, `input.lua`, `looknfeel.lua`,
  `monitors.lua`, `autostart.lua`), symlinked to `~/.config/hypr/*.lua`
- `omarchy/` — theme (`digital-nature`, `colors.toml` format), `shell.json`
  (quickshell bar layout), and bashrc additions
- `mise/` — global `config.toml` (tools + versions), symlinked to `~/.config/mise`
- `ghostty/`, `pipewire/`, `vscode/`, `udev/`, `obs/`, `claude/`
- `chatgpt/openai-linux-repository.asc` — pinned OpenAI Linux repo public key

## Patterns

**Idempotent setup.** Every setup script, and every block within one, must be
safe to re-run on an already-configured machine. Guard installs with a state
check (`command -v`, `pacman -Q`) rather than relying on `--needed` alone, so
re-runs skip the network entirely. Check before changing state (`grep -qFx`
before appending, `getcap` before `setcap`, `[ -L ]` before replacing a file
with a symlink) and use `ln -snf` so symlinks converge. A re-run should make
no changes and trigger no avoidable sudo prompts.

**Symlink, don't copy.** Point `~/.config/<app>` at `~/.dotfiles/config/<app>`.

**Append only if missing.** Use `grep -qFx` before adding a line to an existing
file such as `~/.bashrc`.

**Git identity.** 1Password SSH for auth and commit signing. Personal vs work
email is selected with Git `includeIf` on directory path (see
`config/git/config_local`). Do not hard-code emails in scripts.

**Official installers vs AUR.** Prefer AUR/`yay` for ordinary packages. ChatGPT
desktop installs from the vendor's signed artifacts because AUR wrappers are a
supply-chain risk. Do not replace that script with `yay -S chatgpt-desktop-bin`.
Stripe CLI is installed by mise (`aqua:stripe/stripe-cli`); never `yay -S stripe-cli`.

**ChatGPT updates.** `scripts/setup_chatgpt.sh` is idempotent (`--check` reports
without installing). The app must be quit before an install. The package name is
`chatgpt-bin`; that name collides with an unrelated AUR CLI, so do not let an
AUR helper "update" it.

## Omarchy / Hyprland (Quattro / v4+)

Omarchy v4 configures Hyprland in Lua (hyprlang `.conf` is dead; Hyprland 0.57
removes it). Omarchy owns `~/.config/hypr/hyprland.lua`, which requires the five
user override files; setup replaces those with symlinks into this repo:
`bindings.lua`, `input.lua`, `looknfeel.lua`, `monitors.lua`, `autostart.lua`.
Edit them in `config/hypr/`. Env vars go in `monitors.lua` (or any of the five) via
`hl.env(...)`.

- Omarchy itself lives in `/usr/share/omarchy` (pacman-owned; `~/.local/share/omarchy`
  is a symlink to it). Never edit it.
- The bar, launcher, menus, notifications, OSD, and lock screen are one quickshell
  process (`omarchy-shell`), configured by `config/omarchy/shell.json` (symlinked to
  `~/.config/omarchy/shell.json`). Restart it with `omarchy-restart-shell`. Waybar,
  walker, mako, swayosd, hyprlock, and hypridle no longer exist.
- Do **not** run `omarchy refresh hyprland` or `omarchy refresh shell` casually:
  they `cp -f` defaults *through* the symlinks and dirty this repo. Recover with
  `git -C ~/.dotfiles checkout -- config/hypr config/omarchy/shell.json && ./setup_omarchy.sh`.
- Omarchy wrappers (`omarchy-mise-install`, `mise use -g`) write
  `~/.config/mise/config.toml` through the symlink and will dirty this repo the
  same way. Recover with `git -C ~/.dotfiles checkout -- config/mise`.
- Theme: `config/omarchy/themes/digital-nature/` in v4 format — `colors.toml` plus
  `backgrounds/`, `icons.theme`, `neovim.lua`, `vscode.json`. Terminal/btop/hyprland/
  shell theming is generated from `colors.toml` into `~/.local/state/omarchy/current/theme/`.
  Apply with `omarchy-theme-set digital-nature`.
- Binding API: `o.bind` / `hl.unbind` / `hl.dsp.*`. References:
  `/usr/share/hypr/stubs/hl.meta.lua` and `/usr/share/omarchy/default/hypr/`.
- Prefer `omarchy pkg add` / `omarchy` CLI for packages and desktop actions.
- Setup removes Omarchy's ChatGPT webapp and installs the native desktop app.

After Hyprland edits, validate with `hyprctl reload` and `hyprctl configerrors`.
