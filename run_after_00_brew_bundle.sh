#!/usr/bin/env bash
# Install Homebrew packages from the Brewfile managed by chezmoi

# Path to the Brewfile in your home directory
BREWFILE="$HOME/Brewfile"

if command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew packages from $BREWFILE"
  brew bundle install --file="$BREWFILE"
else
  echo "Homebrew is not installed. Skipping brew bundle."
fi

