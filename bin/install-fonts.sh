#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
Darwin)
  if brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
    echo "JetBrainsMono Nerd Font already installed (cask)."
    exit 0
  fi
  brew install --cask font-jetbrains-mono-nerd-font
  ;;
Linux)
  fonts_dir="$HOME/.local/share/fonts"
  mkdir -p "$fonts_dir"
  if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    echo "JetBrainsMono Nerd Font already installed."
    exit 0
  fi
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/JetBrainsMono.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  unzip -q "$tmp/JetBrainsMono.zip" -d "$fonts_dir/JetBrainsMono"
  fc-cache -f "$fonts_dir"
  rm -rf "$tmp"
  ;;
esac
