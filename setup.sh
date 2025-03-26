#!/bin/bash
# =============================================================================
# Automated Mac Setup Script
# =============================================================================
# This script automates the setup of a new macOS system with development tools,
# applications, and preferred system settings.
# =============================================================================

# Exit on error
set -e

echo "===== Starting Mac Setup ====="

# -----------------------------------------------------------------------------
# Install Homebrew (must be installed before using brew commands)
# -----------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for this session
  if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "Homebrew already installed. Updating..."
  brew update
fi

# -----------------------------------------------------------------------------
# Create development directories
# -----------------------------------------------------------------------------
echo "Setting up development directories..."
mkdir -p ~/Documents/dev/repos

# Clone ZSH completions
if [ ! -d ~/Documents/dev/repos/zsh-completions ]; then
  echo "Cloning zsh-completions..."
  git clone https://github.com/zsh-users/zsh-completions ~/Documents/dev/repos/zsh-completions
fi

# -----------------------------------------------------------------------------
# Set up dotfiles
# -----------------------------------------------------------------------------
echo "Setting up dotfiles..."
cd ~
if [ ! -d ~/.dotfiles ]; then
  # Try SSH first, fall back to HTTPS if it fails
  if ! git clone git@github.com:safinn/.dotfiles.git 2>/dev/null; then
    echo "SSH clone failed, trying HTTPS instead..."
    git clone https://github.com/safinn/.dotfiles.git
  fi
fi

if [ -d ~/.dotfiles ]; then
  cd ~/.dotfiles
  if command -v stow >/dev/null 2>&1; then
    echo "Linking dotfiles with stow..."
    stow .
  else
    echo "Installing stow..."
    brew install stow
    stow .
  fi
  cd ~
else
  echo "⚠️  Dotfiles installation failed. Check your network connection and Git access."
fi

# -----------------------------------------------------------------------------
# Install Homebrew packages from Brewfile
# -----------------------------------------------------------------------------
echo "Installing packages from Brewfile..."
if [ -f ~/.dotfiles/Brewfile ]; then
  brew analytics off
  brew bundle --file=~/.dotfiles/Brewfile
else
  echo "⚠️  Brewfile not found in ~/.dotfiles directory."
fi

# -----------------------------------------------------------------------------
# Install mise (development tool version manager)
# -----------------------------------------------------------------------------
if ! command -v mise >/dev/null 2>&1; then
  echo "Installing mise version manager..."
  curl -sSL https://mise.run | sh

  # Add mise to current shell session
  export PATH="$HOME/.local/bin:$PATH"
fi

# Install tools defined in .mise.toml
if command -v mise >/dev/null 2>&1; then
  echo "Installing development tools with mise..."
  mise install
fi

# -----------------------------------------------------------------------------
# Configure macOS system preferences
# -----------------------------------------------------------------------------
echo "Setting macOS preferences..."

# Keyboard settings
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Mouse and trackpad
defaults write -g com.apple.swipescrolldirection -bool false

# Dock settings
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0

# General UI/UX
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Menu bar
defaults write com.apple.menuextra.clock IsAnalog -bool false
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM HH:mm"

# Finder settings
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Spotlight preferences
defaults write com.apple.spotlight orderedItems -array \
  '{"enabled" = 1;"name" = "APPLICATIONS";}' \
  '{"enabled" = 1;"name" = "MENU_CONVERSION";}' \
  '{"enabled" = 1;"name" = "MENU_DEFINITION";}' \
  '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
  '{"enabled" = 1;"name" = "DIRECTORIES";}' \
  '{"enabled" = 1;"name" = "DOCUMENTS";}' \
  '{"enabled" = 1;"name" = "PDF";}' \
  '{"enabled" = 0;"name" = "FONTS";}' \
  '{"enabled" = 0;"name" = "MESSAGES";}' \
  '{"enabled" = 0;"name" = "CONTACT";}' \
  '{"enabled" = 0;"name" = "EVENT_TODO";}' \
  '{"enabled" = 0;"name" = "IMAGES";}' \
  '{"enabled" = 0;"name" = "BOOKMARKS";}' \
  '{"enabled" = 0;"name" = "MUSIC";}' \
  '{"enabled" = 0;"name" = "MOVIES";}' \
  '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
  '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
  '{"enabled" = 0;"name" = "SOURCE";}' \
  '{"enabled" = 0;"name" = "MENU_OTHER";}' \
  '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
  '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
  '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

# Show Library folder
chflags nohidden ~/Library

# Restart system UI processes to apply changes
killall Dock Finder SystemUIServer 2>/dev/null || true

# -----------------------------------------------------------------------------
# Set up shell environment
# -----------------------------------------------------------------------------
# Start SSH agent
echo "Starting SSH agent..."
eval "$(ssh-agent -s)" 2>/dev/null

# Rebuild ZSH completion index
echo "Updating ZSH completions..."
rm -f ~/.zcompdump
if type compinit >/dev/null 2>&1; then
  compinit
else
  echo "ZSH completions will be available in new terminal sessions"
fi

# -----------------------------------------------------------------------------
# Finish up
# -----------------------------------------------------------------------------
echo "✅ Mac setup complete! Logout/restart to take effect."
