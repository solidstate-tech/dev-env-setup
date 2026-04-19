#!/usr/bin/env bash
# tests/smoke-ubuntu.sh — run `make all-no-mobile` inside a fresh ubuntu:22.04 container.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
img="dev-env-setup-smoke:ubuntu22"

docker build -t "$img" -f "$repo_root/tests/Dockerfile.ubuntu" "$repo_root/tests"

docker run --rm -t \
  -v "$repo_root:/home/dev/dev-env-setup:ro" \
  -w /home/dev \
  "$img" \
  bash -c '
    set -euo pipefail
    cp -a dev-env-setup repo
    cd repo
    # Pre-seed .gitconfig.local so setup-git.sh does not prompt for input.
    cat > "$HOME/.gitconfig.local" <<EOF
[user]
  name = smoke
  email = smoke@local
EOF
    make all-no-mobile
    make doctor
    # Idempotency check: second run should not error and should be quick
    make all-no-mobile
  '
