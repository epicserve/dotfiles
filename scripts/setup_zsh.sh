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

# Herdr binary. Omarchy gets it from the AUR (setup_omarchy.sh); elsewhere use
# the official installer, which drops a release binary on PATH.
if ! command -v herdr >/dev/null 2>&1; then
  echo "Installing herdr..."
  curl -fsSL https://herdr.dev/install.sh | sh
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

. "$HOME/.dotfiles/scripts/setup_git.sh"
