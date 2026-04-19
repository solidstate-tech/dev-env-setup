# dev-env-setup

Cross-platform (macOS + Ubuntu) bootstrap for a developer workstation. Make-driven, idempotent, dotfiles managed via GNU stow.

## Quick start

```sh
mkdir -p ~/github.com/solidstate-tech
cd ~/github.com/solidstate-tech
git clone git@github.com:solidstate-tech/dev-env-setup.git
cd dev-env-setup
make all
```

Re-run `make all` after pulling updates — every target is idempotent.

## What it installs

- **CLI:** git, gh, stow, mise (language version manager), ripgrep, fd, fzf, lazygit, tree-sitter, bat, eza, jq, yq, htop, tmux, neovim, watchman, shellcheck, shfmt
- **Languages (via mise):** Node LTS, Ruby 3.3, Java temurin-17, Python 3.12; plus Bun and Rust standalone
- **Mac apps (via Homebrew cask):** OrbStack, Ghostty, Android Studio, Chrome, Firefox, Arc; Xcode via App Store
- **Dotfiles (via stow):** zsh, git, tmux, ssh, mise, ghostty, nvim
- **Editor:** Neovim + LazyVim with full LSP / formatter / DAP / treesitter setup

## Documentation

- [`docs/new-machine.md`](docs/new-machine.md) — day-1 runbook
- [`docs/secrets.md`](docs/secrets.md) — `~/.secrets.local` schema
- [`mobile/README.md`](mobile/README.md) — React Native (iOS + Android) toolchain
- [`docs/superpowers/specs/2026-04-19-dev-env-setup-design.md`](docs/superpowers/specs/2026-04-19-dev-env-setup-design.md) — design rationale
- [`docs/superpowers/plans/2026-04-19-dev-env-setup.md`](docs/superpowers/plans/2026-04-19-dev-env-setup.md) — implementation plan

## Make targets

Run `make help` for the full list. The most useful ones:

| Target | What it does |
|---|---|
| `make all` | Bootstrap everything |
| `make stow-dotfiles` | (Re-)symlink all dotfiles |
| `make stow-dry-run` | Preview what stow would do |
| `make doctor` | Verify the environment |
| `make lint` / `make fmt` | Lint/format shell scripts |
