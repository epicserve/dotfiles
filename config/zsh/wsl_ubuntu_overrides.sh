# Settings needed for aws-vault to work
export AWS_VAULT_BACKEND=pass
export GPG_TTY="$( tty )"
export BROWSER="/mnt/c/Windows/System32/cmd.exe /c start"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion