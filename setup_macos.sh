#!/usr/bin/env sh

set +x

. $HOME/.dotfiles/scripts/base_setup.sh
. $HOME/.dotfiles/scripts/base_linux_setup.sh
. $HOME/.dotfiles/scripts/setup_zsh.sh
. $HOME/.dotfiles/scripts/setup_macos_settings.sh
ln -sf ~/.config/git/config_macos ~/.config/git/config_local

# Install Powerline fonts
if ! ls ~/Library/Fonts/*Powerline*.otf ~/Library/Fonts/*Powerline*.ttf 1> /dev/null 2>&1; then
  git clone https://github.com/powerline/fonts.git --depth=1 /tmp/fonts
  cd /tmp/fonts
  ./install.sh
  rm -rf /tmp/fonts
  cd ~/.dotfiles
fi

. $HOME/.dotfiles/scripts/setup_brew.sh
