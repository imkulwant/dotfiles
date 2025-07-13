#!/bin/bash
set -euo pipefail

echo ""
echo "Starting full system setup..."

# 1. Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add Homebrew to PATH for current session
  eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || \
  eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null
else
  echo "Homebrew is already installed."
fi

# 2. Install chezmoi if not present
if ! command -v chezmoi >/dev/null 2>&1; then
  echo "Installing chezmoi..."
  brew install chezmoi
else
  echo "chezmoi is already installed."
fi

# 3. Initialize chezmoi with your dotfiles repo and apply
if [ ! -d "$HOME/.local/share/chezmoi/.git" ]; then
  echo "Initializing chezmoi with your dotfiles repository..."
  chezmoi init --apply git@github.com:imkulwant/dotfiles.git
else
  echo "chezmoi already initialized."
  echo "You can reinitialize with: chezmoi init --apply git@github.com:imkulwant/dotfiles.git"
fi

brew bundle install --file ~/Brewfile

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo ""
echo "Setup complete!"
