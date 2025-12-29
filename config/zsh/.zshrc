# Set Shell Language
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# Theme repository: https://github.com/denysdovhan/spaceship-prompt
export ZSH_THEME="spaceship"
export SPACESHIP_PACKAGE_SHOW=false
export SPACESHIP_NODE_SHOW=false

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