#!/usr/bin/env bash
set -euo pipefail

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh already installed."
  exit 0
fi

# RUNZSH=no  — do not launch a zsh subshell after install.
# CHSH=no    — do not call chsh (avoids interactive prompt in containers).
# KEEP_ZSHRC=yes — do not clobber our stow-managed ~/.zshrc.
RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
