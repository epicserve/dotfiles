##
## Basic Shell
##
alias ll="ls -l"
alias la="ls -la"

if command -v eza &> /dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

##
## Print Column
##
alias c1="awk '{print \$1}'"
alias c2="awk '{print \$2}'"
alias c3="awk '{print \$3}'"
alias c4="awk '{print \$4}'"
alias c5="awk '{print \$5}'"
alias c6="awk '{print \$6}'"
alias c7="awk '{print \$7}'"
alias c8="awk '{print \$8}'"
alias c9="awk '{print \$9}'"


##
## Git
##
alias gd='git diff'
alias gdl='git log --pretty=oneline --abbrev-commit --since="6am" | perl -wpe "s/^([^\s]+)/-/g" | tail -r'
alias grb='git rebase --rebase-merges=rebase-cousins'
# Git Stash Working - only stash unstaged changes
alias gsw="git commit -m 'Save index' && git stash push -u -q && git reset --soft HEAD^"
alias gl='git pull'
alias glr='gl -r'


##
## Docker
##

# Docker Clean Containers - Removes all stopped containers
alias dcc='docker rm $(docker ps -a -q -f status=exited)'

# Docker Clean Images - Remove the <none> images
alias dci='docker rmi $(docker images -a | grep "^<none>" | awk '\''{if (NR!=1) {print $3}}'\'')'

# Docker kill all running containers
alias dka='docker kill $(docker ps | awk '\''{if (NR!=1) {print $1}}'\'')'

# Run docker compose process with --rm
alias dcl='docker compose logs -f'
alias dcr='docker compose run'
alias dcrr='docker compose run --rm'
alias dcdn='docker compose down -t 0'


##
## Django
##
alias d='dce web ./manage.py'
alias dt='d test'
alias dtf='dt --failfast'
alias dmm='d makemigrations'
alias dm='d migrate'
alias ds='d shell'
alias uav='just update_aws_vars'

##
## aws-vault
##
alias av=aws-vault
alias ava='aws-vault add'
alias avlt='aws-vault list'
alias avrt='aws-vault rotate'
alias ave='aws-vault exec'
alias avrm='aws-vault remove'
alias avl='aws-vault login'


##
## Terraform
##
function tf {
  local tf_args=("${@:1}")
  aws-vault exec admin -- chamber exec terraform -- terraform "${tf_args[@]}"
}


##
## AppPack
##
alias ap=apppack