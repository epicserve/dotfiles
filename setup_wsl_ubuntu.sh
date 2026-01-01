#!/usr/bin/sh
set -e

. $HOME/.dotfiles/scripts/clone_dotfiles.sh

# Ensure en_US.UTF-8 locale is generated and set before anything else
if ! locale -a | grep -q "en_US.utf8"; then
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
  . /etc/default/locale
fi

if ! grep -q "deb \[signed-by=/etc/apt/keyrings/gierens.gpg\] http://deb.gierens.de stable main" /etc/apt/sources.list.d/gierens.list 2>/dev/null; then
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
fi

# install apps
sudo apt update && sudo apt install -y zsh git pass eza

. $HOME/.dotfiles/scripts/base_setup.sh
. $HOME/.dotfiles/scripts/base_linux_setup.sh
. $HOME/.dotfiles/scripts/setup_zsh.sh
