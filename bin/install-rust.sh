#!/usr/bin/env bash
set -euo pipefail

if command -v rustc >/dev/null 2>&1; then
  echo "rust already installed: $(rustc --version)"
  exit 0
fi

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
