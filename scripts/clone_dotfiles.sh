#!/usr/bin/sh

if [ ! -d ~/.dotfiles ]; then
  git clone https://github.com/epicserve/dotfiles.git ~/.dotfiles
else
  cd ~/.dotfiles
  git stash
  git pull --rebase
  git stash pop
fi