#!/usr/bin/sh

export SSH_AUTH_SOCK=~/.1password/agent.sock

. ~/.config/aliases/base_aliases.sh

# AWS-Vault Settings
export AWS_VAULT_BACKEND=secret-service
export BROWSER="zen-browser"
