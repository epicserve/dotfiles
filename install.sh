#!/usr/bin/env bash

if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$PATH:$HOME/.local/bin"
fi
uv run --with ansible ansible-playbook playbook.yml
sudo dscl . -create /Users/$USER UserShell /opt/homebrew/bin/zsh
chsh -s /opt/homebrew/bin/zsh && . ~/.zshrc