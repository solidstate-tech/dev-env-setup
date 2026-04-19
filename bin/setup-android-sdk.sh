#!/usr/bin/env bash
# Install Android SDK components non-interactively.
# Assumes Android Studio (Mac cask) or snap (Linux) is already installed.
set -euo pipefail

if [ "$(uname -s)" = "Darwin" ]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
else
  export ANDROID_HOME="$HOME/Android/Sdk"
fi

sdkmanager_bin="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

if [ ! -x "$sdkmanager_bin" ]; then
  echo "sdkmanager not found at $sdkmanager_bin" >&2
  echo "Install Android Studio first (Mac: 'brew install --cask android-studio'; Linux: 'sudo snap install android-studio --classic'), then launch it once to install cmdline-tools." >&2
  exit 1
fi

# Accept all licenses non-interactively
yes | "$sdkmanager_bin" --licenses >/dev/null

"$sdkmanager_bin" --install \
  "platform-tools" \
  "platforms;android-34" \
  "build-tools;34.0.0" \
  "emulator" \
  "system-images;android-34;google_apis;arm64-v8a"

echo "Android SDK components installed."
