#!/usr/bin/sh

set -e

# Ensure en_US.UTF-8 locale is generated and set before anything else
if ! locale -a | grep -q "en_US.utf8"; then
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
  . /etc/default/locale
fi

# install apps
sudo apt update && sudo apt upgrade
sudo apt install zsh git pass

. scripts/base_setup.sh
. scripts/base_linux_setup.sh

# Set zsh as your shell if it's not set
if [ "$SHELL" != "/bin/zsh" ]; then
  chsh -s /bin/zsh;
fi

if [ ! -d ~/.oh-my-zsh ]; then
  echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  mkdir -p ~/.oh-my-zsh/custom/completions
  just --completions zsh > ~/.oh-my-zsh/custom/completions/just.zsh
fi

# install zoxide
if ! command -v zoxide >/dev/null 2>&1; then
  echo "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# Add ZDOTDIR to $HOME/.config/zsh
grep -qxF "export ZDOTDIR=\$HOME/.config/zsh" ~/.zshenv || echo 'export ZDOTDIR=$HOME/.config/zsh' >> ~/.zshenv

ln -sf ~/.dotfiles/config/zsh ~/.config/
ln -sf ~/.dotfiles/config/git ~/.config/
ln -sf ~/.config/config_wsl_ubuntu ~/.config/git/config_local
ln -sf ~/.dotfiles/config/aliases ~/.config/
