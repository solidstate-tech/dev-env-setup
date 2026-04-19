#!/usr/bin/env bash
set -euo pipefail

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh already installed."
  exit 0
fi

# RUNZSH=no prevents the installer from launching a zsh subshell.
# KEEP_ZSHRC=yes prevents it from clobbering our stow-managed ~/.zshrc.
RUNZSH=no KEEP_ZSHRC=yes sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
