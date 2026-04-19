#!/usr/bin/env bash
# Verify the dev environment is in working order.
set -euo pipefail

ok=0
fail=0
check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf "  ✓ %s\n" "$label"
    ok=$((ok + 1))
  else
    printf "  ✗ %s\n" "$label"
    fail=$((fail + 1))
  fi
}

echo "== Tools on PATH =="
for cmd in git gh stow mise nvim tmux lazygit fzf fd ripgrep tree-sitter bat jq; do
  check "$cmd" command -v "$cmd"
done

if [ "$(uname -s)" = "Darwin" ]; then
  echo "== Mac-only =="
  for cmd in brew watchman; do
    check "$cmd" command -v "$cmd"
  done
fi

echo "== mise tools =="
check "node lts" bash -c 'mise which node >/dev/null'
check "ruby 3.3" bash -c 'mise which ruby >/dev/null'
check "java 17" bash -c 'mise which java >/dev/null'
check "python 3.12" bash -c 'mise which python >/dev/null'

echo "== Dotfiles symlinks =="
for f in ~/.zshrc ~/.zprofile ~/.gitconfig ~/.tmux.conf ~/.config/nvim ~/.config/mise/config.toml; do
  check "$f symlinked" test -L "$f"
done

echo
echo "$ok ok, $fail failed"
[ "$fail" -eq 0 ]
