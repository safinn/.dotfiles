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

source "$HOME/.zshrc"

echo "Set preferred mac settings"
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write -g com.apple.swipescrolldirection -bool false
# Set dock to autohide
defaults write com.apple.dock "autohide" -bool "true" && killall Dock
# Show hidden files in finder
defaults write com.apple.finder "AppleShowAllFiles" -bool "true" && killall Finder
