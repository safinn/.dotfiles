eval "$($HOME/.local/bin/mise activate zsh)"
eval "$($HOME/.local/share/mise/shims/starship init zsh)"
eval "$(rbenv init - zsh)"

export PATH=$PATH:$(go env GOPATH)/bin

source ~/completions.zsh

alias v="nvim"
alias dive='docker run -ti --rm -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive'
alias ls='eza'
alias cat='bat'

alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias gloga='git log --oneline --decorate --graph --all'

function git_current_branch() {
  local ref
  ref=$(command git symbolic-ref --quiet HEAD 2>/dev/null)
  local ret=$?
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return
    ref=$(command git rev-parse --short HEAD 2>/dev/null) || return
  fi
  echo ${ref#refs/heads/}
}

function grhd() {
  if [[ $(git branch --show-current) == "dev" ]]; then
    git reset --hard origin/dev
  else
    echo "Not on dev branch"
  fi
}

# Check if main exists and use instead of master
function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,master}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return 0
    fi
  done

  # If no main branch was found, fall back to master but return error
  echo master
  return 1
}

# Check for develop and similarly named branches
function git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in dev devel develop development; do
    if command git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return 0
    fi
  done

  echo develop
  return 1
}

# Copied and modified from James Roeder (jmaroeder) under MIT License
# https://github.com/jmaroeder/plugin-git/blob/216723ef4f9e8dde399661c39c80bdf73f4076c4/functions/gbda.fish
# Delete all branches merged in current HEAD, including squashed
function gbds() {
  local default_branch=$(git_main_branch)
  ((!$?)) || default_branch=$(git_develop_branch)

  git for-each-ref refs/heads/ "--format=%(refname:short)" |
    while read branch; do
      local merge_base=$(git merge-base $default_branch $branch)
      if [[ $(git cherry $default_branch $(git commit-tree $(git rev-parse $branch\^{tree}) -p $merge_base -m _)) = -* ]]; then
        git branch -D $branch
      fi
    done
}

function gbda() {
  git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch --delete 2>/dev/null
}

# Function to use gotestsum for 'go test' commands and regular go command for everything else
go() {
  if [[ $1 == "test" ]]; then
    shift
    if command -v gotestsum >/dev/null 2>&1; then
      command gotestsum --format-hide-empty-pkg -f dots -- "$@"
    else
      command go test "$@"
    fi
  else
    command go "$@"
  fi
}
