# Dev Environment Setup — Design

**Date:** 2026-04-19
**Status:** Approved (pending implementation plan)
**Owner:** sds@solidstate.my
**Repo:** `solidstate-tech/dev-env-setup` (branch `master`)

## Summary

Rewrite the existing `dev-env-setup` repo into a cross-platform (macOS + Ubuntu), Make-driven, idempotent bootstrap for a developer workstation, optimized for React Native development (iOS + Android), Docker-based local services (via OrbStack), and a fully built-out Neovim/LazyVim setup as the sole editor.

The trigger: a new MacBook arrives, and the current Ubuntu machine's setup needs to be made portable. The old repo (README + Brewfile + flat dotfiles) is too thin and has rotted (Ubuntu-only Snap instructions, references to dropped tools).

## Goals

- One-command bootstrap (`make all`) on a fresh Mac or Ubuntu machine.
- Cross-platform first-class — both OSes treated equally, behind a thin `bin/pkg` shim.
- Dotfiles managed via GNU `stow` (symlinks, no drift).
- Single language-version manager: `mise`.
- Secrets never committed: `~/.secrets.local` sourced from `.zshrc`.
- React Native dev (iOS + Android, bare workflow) supported on Mac.
- Neovim + LazyVim is the sole editor — no VS Code / Cursor / Antigravity carry-over.
- Repo is idempotent: every Make target is safe to re-run after `git pull`.

## Non-goals

- Full macOS system-defaults configuration (key repeat, Finder hidden files, etc.). Reserved for a possible follow-up `bin/macos-defaults.sh`.
- Per-project tool versions — those live in each project's `.tool-versions` (auto-honored by `mise`).
- Expo / EAS tooling — global install skipped; add per-project if needed later.
- Cloud editors / remote dev environments.
- macOS app sync (e.g., 1Password, Slack settings) — out of scope.
- Migration of in-repo plaintext secrets out of the existing `dev-env-setup` repo's history. The new `.zshrc` will not contain secrets going forward; rewriting historical commits is not in scope here.

## Architectural decisions

| Concern | Choice | Rationale |
|---|---|---|
| Install style | Modular `Makefile` + Brewfile + thin install scripts | Discoverable, debuggable, re-runnable; no new tool to learn. |
| OS scope | Cross-platform first-class (Mac + Ubuntu) | User regularly works on both; abstracted package layer prevents rot. |
| Dotfile manager | GNU `stow` | Cross-platform, zero drift (symlinks), no DSL, repo layout self-documents. |
| Secrets | `~/.secrets.local` sourced from `.zshrc` | Simple, fully local, no extra tools, safe for public repo. |
| Version manager | `mise` (formerly `rtx`) | Replaces `nvm` + `rbenv` + JDK installer + Python installer in one tool. Per-project pinning via `.tool-versions`. |
| Docker runtime (Mac) | OrbStack | Faster file I/O, lower RAM, lower friction than Docker Desktop. Personal use → free. |
| Mobile dev tier | Bare React Native, full native tooling | Matches existing `scooped/mobile`; iOS work needs Xcode anyway. |
| Editor | Neovim + LazyVim only | Drops Cursor/VS Code/Antigravity. Smaller dotfiles surface, single config to maintain. |
| Terminal (Mac) | Ghostty | Fast, native, modern. |
| Browsers | Chrome + Firefox + Arc (cask) | Daily-driver + testing + opinionated dev browser. |

## Repo layout

```
dev-env-setup/
├── README.md                    # Quick start: clone, run `make all`
├── Makefile                     # Orchestrator
├── bin/
│   ├── pkg                      # Cross-platform install wrapper (brew/apt)
│   └── bootstrap                # First-run: prerequisites only (Xcode CLT, Homebrew or apt refresh)
├── packages/
│   ├── Brewfile                 # Mac packages (brew + cask + mas)
│   └── Aptfile                  # Ubuntu packages (apt)
├── mise/
│   └── .config/mise/config.toml # Global tool versions
├── zsh/
│   ├── .zshrc
│   └── .zprofile
├── git/
│   ├── .gitconfig
│   └── .gitignore_global
├── tmux/
│   └── .tmux.conf
├── ghostty/
│   └── .config/ghostty/config
├── nvim/
│   └── .config/nvim/            # Full LazyVim build-out
├── ssh/
│   └── .ssh/config              # Host config only — no keys
├── mobile/
│   └── README.md                # iOS/Android one-time bootstrap notes
├── docs/
│   ├── new-machine.md           # Day-1 runbook
│   └── secrets.md               # ~/.secrets.local schema
└── templates/
    └── secrets.local.template
```

Each top-level folder under `zsh/`, `git/`, `tmux/`, `nvim/`, `ssh/`, `mise/`, `ghostty/` is a stow "package" — its contents mirror the layout under `$HOME`.

## Bootstrap flow

`make all` executes in order. Each step is its own target — re-runnable individually.

1. `preflight` — assert OS (Darwin/Linux), arch (arm64/x86_64), git + curl present.
2. `install-pkg-mgr` — Mac: install Xcode CLT (`xcode-select --install` if absent), then Homebrew. Linux: `sudo apt-get update`.
3. `install-stow` — needed before any dotfile linking.
4. `install-packages` — `brew bundle --file packages/Brewfile` (Mac) or `xargs -a packages/Aptfile sudo apt-get install -y` (Linux).
5. `stow-dotfiles` — `cd $REPO && stow -t $HOME zsh git tmux nvim ssh mise ghostty`.
6. `install-mise` — `curl https://mise.run | sh`, then `mise install` (reads global `~/.config/mise/config.toml`).
7. `install-bun` — `curl -fsSL https://bun.sh/install | bash`.
8. `install-rust` — `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y`.
9. `install-fonts` — install JetBrains Mono Nerd Font (Mac via cask `font-jetbrains-mono-nerd-font`; Linux via downloading release zip into `~/.local/share/fonts` and `fc-cache -f`).
10. `setup-git` — if `~/.gitconfig.local` missing, prompt for name + email and write it. `.gitconfig` includes it.
11. `seed-secrets` — if `~/.secrets.local` missing, copy `templates/secrets.local.template` and instruct user to fill in.
12. `mobile-bootstrap` (Mac only) — `brew install watchman`, `gem install cocoapods` (against mise's Ruby), then non-interactive `sdkmanager --install ...` for Android SDK components after Android Studio is present.
13. `nvim-bootstrap` — `nvim --headless "+Lazy! sync" +qa` to install plugins on first run.
14. `doctor` — verify: tools on PATH, `mise current` resolves, `nvim --headless "+checkhealth" +qa` flags only known-acceptable warnings.

### Manual one-time steps (documented in `docs/new-machine.md`)

- **Xcode**: `mas install 497799835` requires App Store login. After install, launch Xcode once, accept the license, install additional components (modal pops up).
- **iOS Simulator runtimes**: `xcodebuild -runFirstLaunch` after Xcode is up; extra simulator versions via Xcode → Settings → Components.
- **At least one AVD** must be created via Android Studio's AVD manager or `avdmanager` (a creation script is provided in `mobile/README.md`).
- **iOS code signing** (Apple Developer account, team ID, provisioning, optional fastlane match) — per-project, checklist in `mobile/README.md`.
- **macOS system defaults**, **SSH keys**, **GPG keys** — out of scope for the bootstrap script; add manually or from a backup.

## Cross-platform package abstraction

`bin/pkg` is a thin shell shim:
```sh
#!/usr/bin/env bash
case "$(uname -s)" in
  Darwin) brew install "$@" ;;
  Linux)  sudo apt-get install -y "$@" ;;
esac
```

**Manifests are declarative**:

`packages/Brewfile` — explicit `brew`, `cask`, and `mas` lines. Mac-only; not consumed by the Linux path.

`packages/Aptfile` — newline-separated package names, fed to `apt-get install -y` via `xargs`.

**Tools installed via upstream `curl|sh` rather than apt** (because Ubuntu LTS lags badly):
- `mise`
- `OrbStack` (Mac only)
- `lazygit`
- `tree-sitter` CLI (download from GitHub releases — Ubuntu 22.04 ships glibc 2.35; pin to a version that matches)
- `fd` (cargo install — Ubuntu's `fd-find` is too old for snacks.nvim's explorer)
- Bun, Rust (canonical installers)

This is captured in dedicated `bin/install-*.sh` scripts called from the relevant Make targets, so the choice is auditable.

## Mobile dev toolchain (Mac)

**Automated:**
- `watchman` (brew)
- CocoaPods (gem install against mise's Ruby — brew's cocoapods regularly breaks)
- `android-studio` (cask) — brings SDK Manager + AVD GUI
- Android SDK components via `sdkmanager --install "platform-tools" "platforms;android-34" "build-tools;34.0.0" "emulator" "system-images;android-34;google_apis;arm64-v8a"`
- JDK 17 (`temurin-17` via mise) — Adoptium build, RN Android standard
- Node LTS (mise)
- Ruby 3.3.x (mise) — used by CocoaPods
- Android env vars in `.zshrc`: `ANDROID_HOME=$HOME/Library/Android/sdk` (Mac) or `$HOME/Android/Sdk` (Linux); PATH adds `$ANDROID_HOME/{emulator,platform-tools,cmdline-tools/latest/bin}`

**Manual (in `mobile/README.md`):**
- Xcode install + first-launch + license + components
- iOS Simulator runtimes (post-Xcode)
- AVD creation (script provided)
- iOS code signing
- Apple Developer account / team ID setup

**Per-project, not in this repo:**
- RN version, JDK target, Node version (each project's `.tool-versions` + `package.json`)
- Expo CLI / EAS CLI (per-project devDependency)
- `react-native-cli` global install — explicitly skipped; use `npx react-native` per-project

## Dotfiles inventory

### `zsh/`
- `.zshrc` — oh-my-zsh load, theme `robbyrussell`, plugins `git mise docker gh`, aliases. Sources `~/.secrets.local` and `~/.zshrc.local` if present.
- `.zprofile` — login-shell PATH: Homebrew shellenv, `mise activate`, cargo env, bun, Android SDK exports.
- **Surviving aliases**: docker shortcuts (`dps`, `dlogs`), `gs="tig status"`, `vim`/`vi` → `nvim`.
- **Dropped aliases** (move them to the relevant project repos' Makefiles):
  - `rs="bundle exec rails s"` (no current Rails project)
  - `kd-up`, `kd-down`, `kd-logs`, `kd-migrate` (kitchen-dashboard-specific)
  - `scrapper-up`, `scrapper-down`, `scrapper-logs`, `scrapper-migrate` (lenovo-scrapper-specific)
  - `dev-tools-up`, `dev-tools-down` (kitchen-dashboard-container-specific)
- **Plaintext secrets removed** from `.zshrc`; `DEEPSEEK_API_KEY`, `OPENAI_API_KEY`, `OPENROUTER_API_KEY`, `DEEPSEEK_USE_LOCAL` move into `~/.secrets.local`.
- **Per-project npm prefix PATH hack removed** — replaced by mise managing Node properly.

### `git/`
- `.gitconfig` — name/email pulled from `[include] path = ~/.gitconfig.local`. Aliases (`lg`, `st`), `pull.rebase = true`, `init.defaultBranch = main`, `core.excludesfile = ~/.gitignore_global`.
- `.gitignore_global` — `.DS_Store`, `*.swp`, `.idea/`, `.vscode/`, `.claude/`.

### `tmux/`
- `.tmux.conf` — current ~50-line config, plus mouse on, 256color, vi-mode copy. TPM bootstrap deferred unless a need surfaces.

### `ghostty/`
- `.config/ghostty/config` — font (JetBrains Mono Nerd Font), theme, basic keybindings.

### `nvim/`
- `.config/nvim/` — full LazyVim build-out (next section).

### `ssh/`
- `.ssh/config` — Host blocks for github.com, dev servers. **No keys.** Keys are restored manually from a backup or generated fresh per machine.

### `mise/`
- `.config/mise/config.toml` — global tool versions: `node = "lts"`, `ruby = "3.3"`, `java = "temurin-17"`, `python = "3.12"`.

### Not stowed (deliberate)
- macOS app preferences for Cursor / VS Code / Antigravity — nvim-only setup.
- iTerm profile — replaced by Ghostty.
- Brew completions, oh-my-zsh itself — installed by bootstrap, not stowed.

## Nvim build-out

Lives at `nvim/.config/nvim/lua/` in the repo, stowed into `~/.config/nvim/`.

### LSP (Mason auto-install via LazyVim) — `lua/plugins/lsp.lua`
- `vtsls` (TypeScript/JavaScript)
- `eslint`
- `lua_ls`
- `bashls`
- `jsonls`, `yamlls`, `taplo`
- `marksman`
- `dockerls`, `docker_compose_language_service`
- `ruby-lsp`
- `kotlin_language_server` (RN Android)
- `sourcekit-lsp` (RN iOS — installed by Xcode, not Mason)
- `gopls`

### Formatters / linters — `lua/plugins/format.lua`
- `prettierd` (default JS/TS/JSON/YAML/Markdown)
- `biome` (preferred where a project's `biome.json` exists)
- `stylua` (Lua)
- `rubocop` (Ruby)
- `shfmt` + `shellcheck`
- `ktlint` (Kotlin)
- `swiftformat` (Swift)
- Format-on-save default-on; per-buffer opt-out via `vim.b.disable_autoformat`.

### Treesitter — extend existing `treesitter.lua`
Add: `tsx`, `typescript`, `javascript`, `kotlin`, `swift`, `ruby`, `markdown`, `markdown_inline`, `regex`, `lua`, `bash`, `json`, `yaml`, `toml`, `html`, `css`.

### LazyVim language extras — `lua/config/lazy.lua`
Enable: `lang.typescript`, `lang.tailwind`, `lang.markdown`, `lang.docker`, `lang.json`, `lang.yaml`, `lang.ruby`. (Git tooling — gitsigns, lazygit integration — is in LazyVim defaults; no extra needed.)

### Debugging
`nvim-dap` + LazyVim DAP extras for TypeScript/Node via `js-debug-adapter`. Native iOS/Android debugging stays in Xcode/Android Studio.

### Plugins beyond LazyVim defaults
- `markdown-preview.nvim` (already added)
- `oil.nvim` (file explorer in a buffer)
- `nvim-spectre` (project-wide find-and-replace)
- `vim-tmux-navigator` (`Ctrl+h/j/k/l` across tmux + nvim splits)

### Explicitly skipped
- AI completion (Copilot / Codeium / Supermaven / claude.nvim) — none installed by default.
- Custom colorscheme — LazyVim default `tokyonight` stands.
- Custom statusline — LazyVim default `lualine` stands.

### Keymaps
`lua/config/keymaps.lua` for personal leader-key habits — kept minimal initially, grown as muscle memory dictates.

## Secrets

`~/.secrets.local` is a gitignored file outside the repo, sourced by `.zshrc` if present:
```sh
[ -f ~/.secrets.local ] && source ~/.secrets.local
```

`templates/secrets.local.template` ships a skeleton:
```sh
# AI provider API keys
export DEEPSEEK_API_KEY=""
export OPENAI_API_KEY=""
export OPENROUTER_API_KEY=""

# Tunables
export DEEPSEEK_USE_LOCAL=false
```

Restoring on a new machine: copy `~/.secrets.local` from the prior machine via secure channel (1Password note, encrypted backup). Documented in `docs/secrets.md`.

## Migration from old repo

Existing repo state (branch `master`, commits up to `8b8ae75c`):
- `Brewfile`, `.zshrc`, `.tmux.conf`, `.vimrc`, `iterm-profile.json`, `vs-code.json`, `vs_code_extensions_list.txt`, `README.md`.

Implementation plan handles:
1. Restructure into stow packages.
2. Refresh `Brewfile` against current toolchain.
3. Drop `.vimrc` (replaced by `nvim/`).
4. Drop `iterm-profile.json` (Ghostty replaces).
5. Drop `vs-code.json` and `vs_code_extensions_list.txt` (nvim-only).
6. New `Aptfile`, `Makefile`, `bin/`, `mise/`, `git/`, `ghostty/`, `nvim/`, `ssh/`, `mobile/`, `docs/`, `templates/`.
7. README rewritten as quick-start.
8. Default branch rename `master` → `main` (deferred to implementation plan).

History is preserved (no rewrites). The new structure lands as a series of commits on `master` (or a feature branch merged back).

## Acceptance criteria

- `git clone … && cd dev-env-setup && make all` on a fresh Mac produces a working dev environment with: Homebrew, all CLI tools, mise + global runtimes, OrbStack, Ghostty, Android Studio, watchman, nvim with all plugins installed, dotfiles symlinked, `~/.secrets.local` template seeded.
- Same command on a fresh Ubuntu machine produces the equivalent (no Xcode/iOS, no OrbStack — Docker via apt instead, no Android Studio cask — snap install with manual step).
- `make doctor` passes (no ❌ for any tool listed in this spec; ⚠️ acceptable only for documented optional features).
- `nvim` opens cleanly with no errors; `:Lazy` shows all plugins installed; `:checkhealth` errors only on optional providers (Python/Ruby/Perl hosts) and image-protocol terminals.
- `make all` is idempotent — second run does nothing destructive, no prompts, exits 0.
- Brand-new repo can be cloned to `~/github.com/solidstate-tech/dev-env-setup` on the new MacBook and bootstrap to a working state in under 60 minutes (most time = Xcode download + simulator runtimes).

## Open questions for implementation

- Default branch rename (`master` → `main`) — confirm timing (before or after the restructure commit series).
- Which exact LazyVim release / version to pin against, or float at HEAD.
- Whether to add `bin/macos-defaults.sh` in the same PR or defer.
- AVD creation script: which device profile + system image to default to.
