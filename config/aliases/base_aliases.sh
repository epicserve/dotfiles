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
alias gb='git branch'
unalias gco 2>/dev/null
function gco() {
  if [[ $# -eq 0 ]]; then
    local result branch
    result=$( (echo "Create new branch...";
      { git branch --sort=-committerdate | sed 's/^[* ]*//' | sed $'s/$/\t(local)/';
        git branch -r --sort=-committerdate | grep -v 'HEAD' | sed 's/^[[:space:]]*//' | sed 's|^origin/||' | sed $'s/$/\t(remote)/'; } |
      awk -F'\t' '!seen[$1]++') |
      fzf --height=50% --reverse \
          --delimiter='\t' \
          --header="Select branch or create new" \
          --preview="b={1}; [[ \$b != 'Create new branch...' ]] && git log --oneline --graph --color=always \$b 2>/dev/null || echo 'Will prompt for new branch name'")
    if [[ "$result" == "Create new branch..." ]]; then
      read -rp "New branch name: " branch_name
      if [[ -n "$branch_name" ]]; then
        git checkout -b "$branch_name"
      fi
    elif [[ -n "$result" ]]; then
      branch=$(echo "$result" | cut -f1)
      git checkout "$branch"
    fi
  else
    git checkout "$@"
  fi
}
alias gd='git diff'
alias gdl='git log --pretty=oneline --abbrev-commit --since="6am" | perl -wpe "s/^([^\s]+)/-/g" | tail -r'
alias gf='git fetch'
alias gl='git pull'
alias glr='gl -r'
alias gp='git push'
alias grb='git rebase --rebase-merges=rebase-cousins'
alias gst='git status'
alias gsw="git commit -m 'Save index' && git stash push -u -q && git reset --soft HEAD^" # Git Stash Working - only stash unstaged changes


##
## Docker
##

# Docker Clean Containers - Removes all stopped containers
alias dcc='docker rm $(docker ps -a -q -f status=exited)'

# Docker Clean Images - Remove the <none> images
alias dci='docker rmi $(docker images -a | grep "^<none>" | awk '\''{if (NR!=1) {print $3}}'\'')'

# Docker kill all running containers
alias dka='docker kill $(docker ps | awk '\''{if (NR!=1) {print $1}}'\'')'

# Run ddc process with --rm
alias dc='docker compose'
alias dcdn='docker compose down -t 0 --remove-orphans'
alias dce='docker compose exec'
alias dcl='docker compose logs -f'
alias dcr='docker compose run'
alias dcrr='docker compose run --rm'
alias dcup='docker compose up'
alias dcb='docker compose build'


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

##
## Dotfiles
##
alias udf=~/.dotfiles/scripts/clone_dotfiles.sh
