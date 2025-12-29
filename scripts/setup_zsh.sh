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
  just --completions zsh > ~/.oh-my-zsh/custom/completions/just.zsh
fi

# Install Spaceship theme for Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" ]; then
  git clone https://github.com/denysdovhan/spaceship-prompt $HOME/.oh-my-zsh/custom/themes/spaceship-prompt
fi
if [ ! -L "$HOME/.oh-my-zsh/themes/epicserve.zsh-theme" ]; then
  ln -s $HOME/.dotfiles/config/oh_my_zsh/epicserve.zsh-theme $HOME/.oh-my-zsh/themes/epicserve.zsh-theme
fi

# install zoxide
if ! command -v zoxide >/dev/null 2>&1; then
  echo "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# Add ZDOTDIR to $HOME/.config/zsh
if [ ! -f ~/.zshenv ]; then
  touch ~/.zshenv
fi
grep -qxF "export ZDOTDIR=\$HOME/.config/zsh" ~/.zshenv || echo 'export ZDOTDIR=$HOME/.config/zsh' >> ~/.zshenv

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

ln -sf ~/.dotfiles/config/git ~/.config/
ln -sf ~/.dotfiles/config/aliases ~/.config/
