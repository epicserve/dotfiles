#!/usr/bin/env sh

# Mac specific paths
export PATH="/opt/homebrew/bin:$PATH"

# Add macOS specific plugins
plugins=("${plugins[@]}" brew)

eval "$(brew shellenv)"

# This makes it so ZSH will use the default Homebrew directory for completions scripts
fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)

# Set default editor
export EDITOR='pycharm'

# Pycharm
export PATH="$PATH:/Applications/PyCharm.app/Contents/MacOS"

