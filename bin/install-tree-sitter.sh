#!/usr/bin/env bash
set -euo pipefail

if command -v tree-sitter >/dev/null 2>&1; then
  echo "tree-sitter already installed: $(tree-sitter --version)"
  exit 0
fi

case "$(uname -s)" in
Darwin) brew install tree-sitter ;;
Linux)
  arch="$(uname -m)"
  case "$arch" in
  x86_64) suffix=linux-x64 ;;
  aarch64 | arm64) suffix=linux-arm64 ;;
  *)
    echo "unsupported arch: $arch" >&2
    exit 1
    ;;
  esac
  # Pin: v0.25.10 builds against glibc 2.35 (Ubuntu 22.04). Bump after testing.
  version="0.25.10"
  mkdir -p "$HOME/.local/bin"
  curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/tree-sitter-${suffix}.gz" |
    gunzip >"$HOME/.local/bin/tree-sitter"
  chmod +x "$HOME/.local/bin/tree-sitter"
  ;;
esac
