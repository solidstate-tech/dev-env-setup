#!/usr/bin/env bash
set -euo pipefail

if command -v lazygit >/dev/null 2>&1; then
  echo "lazygit already installed: $(lazygit --version | head -1)"
  exit 0
fi

case "$(uname -s)" in
Darwin) brew install lazygit ;;
Linux)
  arch="$(uname -m)"
  case "$arch" in
  x86_64) suffix=Linux_x86_64 ;;
  aarch64 | arm64) suffix=Linux_arm64 ;;
  *)
    echo "unsupported arch: $arch" >&2
    exit 1
    ;;
  esac
  version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest |
    grep -Po '"tag_name": "v\K[^"]*')"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/lazygit.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_${suffix}.tar.gz"
  tar -xf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  install -m 0755 "$tmp/lazygit" "$HOME/.local/bin/lazygit"
  rm -rf "$tmp"
  ;;
esac
