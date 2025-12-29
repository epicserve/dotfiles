#!/usr/bin/env sh

set +x

. $HOME/.dotfiles/scripts/base_setup.sh
. $HOME/.dotfiles/scripts/base_linux_setup.sh
. $HOME/.dotfiles/scripts/setup_zsh.sh
. $HOME/.dotfiles/scripts/setup_macos_settings.sh
ln -sf ~/.config/git/config_macos ~/.config/git/config_local

# Install Spaceship theme for Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" ]; then
  git clone https://github.com/denysdovhan/spaceship-prompt $HOME/.oh-my-zsh/custom/themes/spaceship-prompt
fi
if [ ! -L "$HOME/.oh-my-zsh/themes/epicserve.zsh-theme" ]; then
  ln -s $HOME/.dotfiles/config/oh_my_zsh/epicserve.zsh-theme $HOME/.oh-my-zsh/themes/epicserve.zsh-theme
fi

# Install Powerline fonts
if ! ls ~/Library/Fonts/*Powerline*.otf ~/Library/Fonts/*Powerline*.ttf 1> /dev/null 2>&1; then
  git clone https://github.com/powerline/fonts.git --depth=1 /tmp/fonts
  cd /tmp/fonts
  ./install.sh
  rm -rf /tmp/fonts
  cd ~/.dotfiles
fi

. $HOME/.dotfiles/scripts/setup_brew.sh
