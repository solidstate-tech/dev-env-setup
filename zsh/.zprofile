# ~/.zprofile — managed by dev-env-setup (stow zsh).

# Homebrew (Mac)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# User-local bin
export PATH="$HOME/.local/bin:$PATH"

# Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Android SDK (Mac vs Linux paths differ)
if [ "$(uname -s)" = "Darwin" ]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
else
  export ANDROID_HOME="$HOME/Android/Sdk"
fi
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"

# Java (mise manages it; this exports JAVA_HOME from the active mise install)
if command -v mise >/dev/null 2>&1; then
  java_dir="$(mise where java 2>/dev/null || true)"
  [ -n "$java_dir" ] && export JAVA_HOME="$java_dir"
fi
