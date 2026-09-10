# SSH agent for shell tools (ssh-add etc.). ssh itself picks a forwarded laptop
# agent via the Match rule in ~/.ssh/config, and git signs through
# config/git/ssh-sign; both call config/git/forwarded-agent at run time, so the
# choice is never frozen into a shell's environment.
export SSH_AUTH_SOCK=~/.1password/agent.sock
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=gpg.ssh.program \
       GIT_CONFIG_VALUE_0="$HOME/.config/git/ssh-sign"
unset GIT_SSH_COMMAND

# AWS-Vault Settings
export AWS_VAULT_BACKEND=secret-service

# Default browser
export BROWSER="zen-browser"
