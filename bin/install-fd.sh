#!/usr/bin/env bash
set -euo pipefail

if command -v fd >/dev/null 2>&1 && fd --version | awk '{print $2}' | awk -F. '{exit !($1>8 || ($1==8 && $2>=4))}'; then
  echo "fd already installed and recent enough: $(fd --version)"
  exit 0
fi

case "$(uname -s)" in
Darwin) brew install fd ;;
Linux)
  if ! command -v cargo >/dev/null 2>&1; then
    echo "cargo required to build fd; run bin/install-rust.sh first" >&2
    exit 1
  fi
  cargo install fd-find
  ;;
esac
