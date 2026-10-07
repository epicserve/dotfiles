# SSH agent for shell tools (ssh-add etc.). ssh itself picks a forwarded laptop
# agent via the Match rule in ~/.ssh/config; git signs through
# config/git/ssh-sign and connects through config/git/ssh-command, which fall
# back to the local 1Password app when the forwarded agent won't sign. All of
# them call config/git/forwarded-agent at run time, so the choice is never
# frozen into a shell's environment.
export SSH_AUTH_SOCK=~/.1password/agent.sock
export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=gpg.ssh.program \
       GIT_CONFIG_VALUE_0="$HOME/.config/git/ssh-sign" \
       GIT_CONFIG_KEY_1=core.sshCommand \
       GIT_CONFIG_VALUE_1="$HOME/.config/git/ssh-command"
unset GIT_SSH_COMMAND

# AWS-Vault Settings
export AWS_VAULT_BACKEND=secret-service

# Default browser
export BROWSER="zen-browser"
