#!/usr/bin/sh

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

# Add ZDOTDIR to $HOME/.config/zsh
grep -qxF "export ZDOTDIR=\$HOME/.config/zsh" ~/.zshenv || echo 'export ZDOTDIR=$HOME/.config/zsh' >> ~/.zshenv

ln -sf ~/.dotfiles/config/zsh ~/.config/
ln -sf ~/.dotfiles/config/git/config_wsl_ubuntu ~/.dotfiles/config/git/config_local