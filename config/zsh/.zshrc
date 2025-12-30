# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set Shell Language
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Theme repository: https://github.com/romkatv/powerlevel10k
if [ "$TERMINAL_EMULATOR" != "JetBrains-JediTerm" ]; then
  ZSH_THEME="powerlevel10k/powerlevel10k"
else
  # Until the p10k can look good in PyCharm/Intellij use a different theme
  ZSH_THEME="eastwood"
fi
export ZSH_THEME

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  aws
  docker
  docker-compose
  git
  git-extras
  heroku
  npm
  uv
)

source $ZSH/oh-my-zsh.sh

# DOCKER SETTINGS
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1

export XDG_CONFIG_HOME=~/.config

# Import Base Aliases
. $HOME/.config/aliases/base_aliases.sh

# UV installed tools
. $HOME/.local/bin/env

# Initialize Zoxide
eval "$(zoxide init zsh)"

# Load OS-specific overrides
if [[ "$OSTYPE" == darwin* ]]; then
  . $HOME/.config/zsh/macos_overrides.sh
elif [[ "$OSTYPE" == linux* ]]; then
  . $HOME/.config/zsh/wsl_ubuntu_overrides.sh
fi


