#!/usr/bin/env sh

set +x

# Set zsh as your shell if it's not set
if [ "${SHELL##*/}" != "zsh" ]; then
  chsh -s /bin/zsh;
fi

if [ ! -d ~/.oh-my-zsh ]; then
  echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  mkdir -p ~/.oh-my-zsh/custom/completions
  just --completions zsh > ~/.oh-my-zsh/custom/completions/_just
fi

# Install powerlevel10k theme for Oh My Zsh
. "$HOME/.dotfiles/scripts/setup_zsh_theme.sh"

# Add ZDOTDIR to $HOME/.config/zsh
if [ ! -f ~/.zshenv ]; then
  touch ~/.zshenv
fi
grep -qxF "export ZDOTDIR=\$HOME/.config/zsh" ~/.zshenv || echo 'export ZDOTDIR=$HOME/.config/zsh' >> ~/.zshenv
# Publish a forwarded SSH agent for herdr shells (see config/zsh/ssh_agent.zsh)
ssh_agent_line='[ -f "$ZDOTDIR/ssh_agent.zsh" ] && . "$ZDOTDIR/ssh_agent.zsh"'
grep -qxF "$ssh_agent_line" ~/.zshenv || echo "$ssh_agent_line" >> ~/.zshenv

ln -sf ~/.dotfiles/config/zsh ~/.config/

if [ -f ~/.gitconfig ] || [ -L ~/.gitconfig ]; then
  mv ~/.gitconfig ~/.gitconfig.backup
  echo "Backed up existing ~/.gitconfig to ~/.gitconfig.backup"
fi
if [ -f ~/.gitignore ] || [ -L ~/.gitignore ]; then
  mv ~/.gitignore ~/.gitignore.backup
  echo "Backed up existing ~/.gitignore to ~/.gitignore.backup"
fi
if [ -d ~/.config/git ] && [ ! -L ~/.config/git ]; then
  mv ~/.config/git ~/.config/git.backup
  echo "Backed up existing ~/.config/git to ~/.config/git.backup"
fi

ln -sf ~/.dotfiles/config/aliases ~/.config/

# Herdr TUI binary, from the official installer, which drops a release binary
# on PATH.
if ! command -v herdr >/dev/null 2>&1; then
  echo "Installing herdr..."
  curl -fsSL https://herdr.dev/install.sh | sh
fi

# Herdr desktop app (herdr-app) and its herdr-core/hc server, separate from the
# TUI and sharing no sessions with it. Official installer, not the AUR: the app
# updates itself and the core in ~/.local, which a /usr/bin package would block.
# Install once only, since re-running the installer reinstalls the app. Skipped
# on WSL, which has no desktop to run it in.
if ! grep -qiE "(Microsoft|WSL)" /proc/version 2>/dev/null &&
  ! command -v herdr-app >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/herdr-app" ]; then
  echo "Installing the Herdr app..."
  curl -fsSL https://releases.herdr.dev/app/install.sh | sh
fi

# Herdr config: link only config.toml. ~/.config/herdr also holds sockets, logs,
# and session state that must stay out of the repo.
mkdir -p "$HOME/.config/herdr"
herdr_cfg="$HOME/.config/herdr/config.toml"
if [ -f "$herdr_cfg" ] && [ ! -L "$herdr_cfg" ]; then
  mv "$herdr_cfg" "$herdr_cfg.pre-dotfiles.bak"
  echo "Backed up existing ~/.config/herdr/config.toml to config.toml.pre-dotfiles.bak"
fi
ln -snf "$HOME/.dotfiles/config/herdr/config.toml" "$herdr_cfg"

# Herdr app config: link only keys, settings, the theme, and our own layout and
# mod. The app rewrites the rest of ~/.config/herdr-app (guide, shipped mods and
# layouts, state) on every start. It writes settings.json through the symlink
# (zoom, Settings), but misses edits made to the repo copies until restarted or
# re-linked here. The pears-links mod is linked file by file because the app
# writes jsconfig.json and gpui-kit.d.ts into each mod folder; those stay out of
# the repo. main-pears is a clone of the shipped main layout with that mod beside
# the status bar; pick it with Ctrl+Shift+L.
for herdr_app_file in keys.json settings.json themes/tokyo-night.json \
  layouts/main-pears.json mods/pears-links/main.js mods/pears-links/mod.json; do
  herdr_app_cfg="$HOME/.config/herdr-app/$herdr_app_file"
  mkdir -p "$(dirname "$herdr_app_cfg")"
  if [ -f "$herdr_app_cfg" ] && [ ! -L "$herdr_app_cfg" ]; then
    mv "$herdr_app_cfg" "$herdr_app_cfg.pre-dotfiles.bak"
    echo "Backed up existing ~/.config/herdr-app/$herdr_app_file to $herdr_app_file.pre-dotfiles.bak"
  fi
  ln -snf "$HOME/.dotfiles/config/herdr-app/$herdr_app_file" "$herdr_app_cfg"
done

. "$HOME/.dotfiles/scripts/setup_git.sh"
