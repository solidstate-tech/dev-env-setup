# New Machine Runbook

Follow these steps on a fresh Mac or Ubuntu machine.

## 1. Prerequisites

- A working internet connection.
- An Apple ID signed into the App Store (Mac, for Xcode).

## 2. Bootstrap

```sh
mkdir -p ~/github.com/solidstate-tech
cd ~/github.com/solidstate-tech
git clone git@github.com:solidstate-tech/dev-env-setup.git
cd dev-env-setup
make all
```

`make all` is idempotent — re-run after pulling repo updates.

## 3. Mac-specific manual steps

These can't be fully automated:

1. Open the App Store, sign in.
2. `mas install 497799835` (or open Xcode in App Store directly).
3. Launch Xcode once. Accept the license. Let it install additional components.
4. `xcodebuild -runFirstLaunch` after Xcode is up, to install simulator runtime.
5. Open Android Studio once to verify SDK install. Use the AVD manager (or `avdmanager create avd ...`) to create at least one virtual device.

## 4. Secrets

`make seed-secrets` writes a starter `~/.secrets.local`. Edit it with your actual API keys (or restore from your prior machine — see [secrets.md](secrets.md)).

## 5. SSH keys

Restore your SSH keys to `~/.ssh/` from backup, or generate new ones:
```sh
ssh-keygen -t ed25519 -C "you@example.com"
# Add ~/.ssh/id_ed25519.pub to your GitHub account
```

## 6. Set zsh as default shell

```sh
chsh -s "$(command -v zsh)"
```
Log out and back in for this to take effect.

## 7. Verify

```sh
make doctor
```

All checks should pass. Open a new terminal so the shell picks up `~/.zprofile`.
