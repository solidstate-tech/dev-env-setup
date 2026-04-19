#!/usr/bin/env bash
set -euo pipefail

if command -v mise >/dev/null 2>&1; then
  echo "mise already installed: $(mise --version)"
  exit 0
fi

curl -fsSL https://mise.run | sh
echo "mise installed. Add 'eval \"\$(mise activate zsh)\"' to your shell rc (already done in zsh/.zshrc)."
