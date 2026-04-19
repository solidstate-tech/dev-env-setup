#!/usr/bin/env bash
# Prompt once for git name + email and write ~/.gitconfig.local.
set -euo pipefail

target="$HOME/.gitconfig.local"
if [ -f "$target" ]; then
  echo "$target already exists; leaving it alone."
  exit 0
fi

read -rp "Git user.name: " name
read -rp "Git user.email: " email

cat >"$target" <<EOF
[user]
  name = $name
  email = $email
EOF

echo "Wrote $target."
