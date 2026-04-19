#!/usr/bin/env bash
set -euo pipefail

# Minimum version required by LazyVim.
MIN_MAJOR=0
MIN_MINOR=9

_nvim_version_ok() {
  local ver
  ver="$(nvim --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' | head -1)"
  [ -z "$ver" ] && return 1
  local major minor
  major="$(echo "$ver" | cut -d. -f1)"
  minor="$(echo "$ver" | cut -d. -f2)"
  [ "$major" -gt "$MIN_MAJOR" ] || { [ "$major" -eq "$MIN_MAJOR" ] && [ "$minor" -ge "$MIN_MINOR" ]; }
}

if command -v nvim >/dev/null 2>&1 && _nvim_version_ok; then
  echo "neovim already installed and new enough: $(nvim --version | head -1)"
  exit 0
fi

case "$(uname -s)" in
Darwin) brew install neovim ;;
Linux)
  arch="$(uname -m)"
  case "$arch" in
  x86_64) suffix=linux-x86_64 ;;
  aarch64 | arm64) suffix=linux-arm64 ;;
  *)
    echo "unsupported arch: $arch" >&2
    exit 1
    ;;
  esac
  # Pin to a known-good release. Bump after smoke-test validation.
  version="0.11.2"
  tarball="nvim-${suffix}.tar.gz"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/$tarball" \
    "https://github.com/neovim/neovim/releases/download/v${version}/${tarball}"
  rm -rf "$HOME/.local/nvim"
  mkdir -p "$HOME/.local/nvim"
  tar -xf "$tmp/$tarball" -C "$HOME/.local/nvim" --strip-components=1
  mkdir -p "$HOME/.local/bin"
  ln -sf "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmp"
  echo "neovim v${version} installed to \$HOME/.local/nvim; symlinked at \$HOME/.local/bin/nvim"
  ;;
esac
