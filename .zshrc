# =============================================================================
# Z Shell Configuration (.zshrc)
# =============================================================================

# -----------------------------------------------------------------------------
# Environment Setup
# -----------------------------------------------------------------------------
# Initialize Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
# Initialize mise (development tool version manager)
eval "$($HOME/.local/bin/mise activate zsh)"
# Initialize Starship prompt
eval "$($HOME/.local/share/mise/shims/starship init zsh)"
# Add Go binaries to PATH
export PATH=$PATH:$(go env GOPATH)/bin
# Load custom completions
source ~/completions.zsh
# Don't add commands that start with a space to history
export HISTCONTROL=ignorespace

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
# Editor
alias v="nvim"
# Docker tools
alias dive='docker run -ti --rm -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive'
# Modern replacements
alias ls='eza'
alias cat='bat'
# Git shortcuts
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias gloga='git log --oneline --decorate --graph --all'

# -----------------------------------------------------------------------------
# Git Functions
# -----------------------------------------------------------------------------
# Get current branch name
function git_current_branch() {
  local ref
  ref=$(command git symbolic-ref --quiet HEAD 2>/dev/null)
  local ret=$?
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return # Not in a git repo
    ref=$(command git rev-parse --short HEAD 2>/dev/null) || return
  fi
  echo ${ref#refs/heads/}
}

# Reset dev branch to origin
function grhd() {
  if [[ $(git branch --show-current) == "dev" ]]; then
    git reset --hard origin/dev
  else
    echo "Not on dev branch"
  fi
}

# Detect main branch (main, trunk, master, etc.)
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

# Detect development branch
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

# Delete all branches merged in current HEAD, including squashed commits
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

# Delete all fully merged branches (excluding main/develop)
function gbda() {
  git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch --delete 2>/dev/null
}

# -----------------------------------------------------------------------------
# Development Tool Overrides
# -----------------------------------------------------------------------------
# Enhanced Go test function with gotestsum if available
function go() {
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
