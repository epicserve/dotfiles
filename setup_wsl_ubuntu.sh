#!/usr/bin/sh
set -e

. $HOME/.dotfiles/scripts/clone_dotfiles.sh

# Ensure en_US.UTF-8 locale is generated and set before anything else
if ! locale -a | grep -q "en_US.utf8"; then
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
  . /etc/default/locale
fi

# install apps
sudo apt update && sudo apt install -y zsh git pass

. $HOME/.dotfiles/scripts/base_setup.sh
. $HOME/.dotfiles/scripts/base_linux_setup.sh
. $HOME/.dotfiles/scripts/setup_zsh.sh

