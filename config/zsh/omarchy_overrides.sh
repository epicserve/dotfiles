# SSH agent: prefer one forwarded from a remote session (published at
# ~/.ssh/agent.sock by ssh_agent.zsh) while it answers, else local 1Password.
# ssh-add exits 2 only when it cannot reach the agent.
if [ -S "$HOME/.ssh/agent.sock" ] \
   && { SSH_AUTH_SOCK="$HOME/.ssh/agent.sock" ssh-add -l >/dev/null 2>&1; [ $? -ne 2 ]; }; then
  export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
  # op-ssh-sign needs the local 1Password app; sign through the forwarded agent.
  export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=gpg.ssh.program GIT_CONFIG_VALUE_0=ssh-keygen
  # ~/.ssh/config pins IdentityAgent to 1Password, which beats SSH_AUTH_SOCK, so
  # point git's ssh at the forwarded agent explicitly (push/fetch/clone).
  export GIT_SSH_COMMAND="ssh -o IdentityAgent=$HOME/.ssh/agent.sock"
else
  export SSH_AUTH_SOCK=~/.1password/agent.sock
  unset GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0 GIT_SSH_COMMAND
fi

# AWS-Vault Settings
export AWS_VAULT_BACKEND=secret-service

# Default browser
export BROWSER="zen-browser"
