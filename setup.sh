echo "Installing xcode-stuff"
xcode-select --install

# Create directory if it doesn't exist
mkdir -p ~/Documents/dev/repos
if [ ! -d ~/Documents/dev/repos/zsh-completions ]; then
  echo "Cloning zsh-completions into ~/Documents/dev/repos..."
  git clone https://github.com/zsh-users/zsh-completions ~/Documents/dev/repos/zsh-completions
fi

# Install Homebrew if not already installed
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not detected. Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew is already installed."
  echo "Updating Homebrew..."
  brew update
fi

echo "Installing Brewfile packages..."
brew bundle --file=./Brewfile

echo "Copying dotfiles from Github"
cd ~
git clone git@github.com:safinn/.dotfiles.git
cd .dotfiles
echo "Running stow to link dotfiles..."
stow .

# Install mise if not already installed
if ! command -v mise >/dev/null 2>&1; then
  echo "mise not detected. Installing mise..."
  curl https://mise.run | sh
else
  echo "mise is already installed."
fi

# Install all mise tools
if command -v mise >/dev/null 2>&1; then
  echo "Installing mise tools..."
  mise install
else
  echo "mise not found to install tools."
fi

echo "Set preferred mac settings"
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write -g com.apple.swipescrolldirection -bool false
# Set dock to autohide
defaults write com.apple.dock "autohide" -bool "true" && killall Dock
# Save to disk by default, instead of iCloud
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
# Enable dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain AppleAccentColor -string "-1"
defaults write NSGlobalDomain AppleHighlightColor -string \
  "0.847059 0.847059 0.862745 Graphite"
# Set menu bar clock format
defaults write com.apple.menuextra.clock IsAnalog -bool false
defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d h:mm a"
# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true
# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true
# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Show hidden files in finder
defaults write com.apple.finder "AppleShowAllFiles" -bool "true" && killall Finder
# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# View files as list
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0

# Set spotlight indexing order
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

# rebuild zcompdump for autocompletions
rm -f ~/.zcompdump
compinit
# Set up SSH agent
eval $(ssh-agent -s)
# source .zshrc
source "$HOME/.zshrc"
