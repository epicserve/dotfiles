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

# Set the SSH_AUTH_SOCK to the 1Password agent socket
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"