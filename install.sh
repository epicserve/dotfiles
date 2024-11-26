#!/usr/bin/env bash

# Install Homebrew
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
uv run --with ansible ansible-playbook playbook.yml -c local
sudo dscl . -create /Users/$USER UserShell /opt/homebrew/bin/zsh
chsh -s /opt/homebrew/bin/zsh && . ~/.zshrc