# Dev Environment Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure `solidstate-tech/dev-env-setup` into a cross-platform (macOS + Ubuntu), Make-driven, idempotent bootstrap with stow-managed dotfiles, mise for language versions, OrbStack for Docker on Mac, full React Native toolchain, and Neovim/LazyVim as the sole editor.

**Architecture:** A single repo cloned to `~/github.com/solidstate-tech/dev-env-setup`. `make all` orchestrates idempotent targets. Dotfiles live in stow packages (one folder per area: `zsh/`, `nvim/`, `git/`, etc.). A thin `bin/pkg` shim selects `brew` vs `apt`. Language runtimes managed by `mise`. Secrets sourced from `~/.secrets.local` (outside repo).

**Tech Stack:** GNU Make, GNU stow, Homebrew (Mac), apt (Ubuntu), `mise`, OrbStack, Neovim + LazyVim, Bash, ShellCheck, shfmt, Docker (for smoke testing the Linux path).

**Spec:** [`docs/superpowers/specs/2026-04-19-dev-env-setup-design.md`](../specs/2026-04-19-dev-env-setup-design.md)

**Notes:**
- Implementation runs on the existing Ubuntu machine (`/home/u1-e590/github.com/solidstate-tech/dev-env-setup`). The Mac path is validated by the structure of the targets and the smoke-tested Linux path.
- The current Ubuntu user setup MUST NOT be clobbered. Validation of `make all` end-to-end happens inside an `ubuntu:22.04` Docker container, never against `$HOME`.
- The repo's old branch is `master`. Don't rename to `main` mid-plan; rename in the final task as a deliberate cutover.
- Every shell script ships with `set -euo pipefail` and passes `shellcheck` and `shfmt -d`.

---

## File Structure

After completion, the repo looks like:

```
dev-env-setup/
├── README.md                              # Quick start
├── Makefile                               # Orchestrator
├── .editorconfig
├── .shellcheckrc
├── bin/
│   ├── pkg                                # Cross-platform install wrapper
│   ├── bootstrap                          # First-run prerequisites
│   ├── install-mise.sh
│   ├── install-bun.sh
│   ├── install-rust.sh
│   ├── install-fonts.sh
│   ├── install-lazygit.sh
│   ├── install-tree-sitter.sh
│   ├── install-fd.sh
│   ├── setup-git.sh
│   ├── setup-android-sdk.sh
│   └── doctor.sh
├── packages/
│   ├── Brewfile                           # Mac packages
│   └── Aptfile                            # Ubuntu packages
├── mise/.config/mise/config.toml
├── zsh/.zshrc
├── zsh/.zprofile
├── git/.gitconfig
├── git/.gitignore_global
├── tmux/.tmux.conf
├── ghostty/.config/ghostty/config
├── ssh/.ssh/config
├── nvim/.config/nvim/init.lua
├── nvim/.config/nvim/lazy-lock.json
├── nvim/.config/nvim/lazyvim.json
├── nvim/.config/nvim/stylua.toml
├── nvim/.config/nvim/.neoconf.json
├── nvim/.config/nvim/lua/config/lazy.lua
├── nvim/.config/nvim/lua/config/keymaps.lua
├── nvim/.config/nvim/lua/plugins/treesitter.lua
├── nvim/.config/nvim/lua/plugins/lsp.lua
├── nvim/.config/nvim/lua/plugins/format.lua
├── nvim/.config/nvim/lua/plugins/dap.lua
├── nvim/.config/nvim/lua/plugins/extras.lua
├── nvim/.config/nvim/lua/plugins/markdown-preview.lua
├── mobile/README.md
├── templates/secrets.local.template
├── docs/
│   ├── new-machine.md
│   ├── secrets.md
│   ├── superpowers/
│   │   ├── specs/2026-04-19-dev-env-setup-design.md   (already exists)
│   │   └── plans/2026-04-19-dev-env-setup.md          (this file)
└── tests/
    └── smoke-ubuntu.sh                    # Container-based end-to-end test
```

**Files removed from existing repo (in Task 21):** `Brewfile` (root), `.zshrc` (root), `.tmux.conf` (root), `.vimrc`, `iterm-profile.json`, `vs-code.json`, `vs_code_extensions_list.txt`.

---

## Task 1: Lint/format scaffolding & old-file inventory

**Files:**
- Create: `.editorconfig`, `.shellcheckrc`, `.gitignore`
- Verify: existing `Brewfile`, `.zshrc`, `.tmux.conf`, `.vimrc`, `iterm-profile.json`, `vs-code.json`, `vs_code_extensions_list.txt`, `README.md` still present (will be removed in Task 21)

- [ ] **Step 1: Confirm starting state**

```bash
cd ~/github.com/solidstate-tech/dev-env-setup
git status                    # expect clean
git branch --show-current     # expect master
ls -1                         # expect: Brewfile .tmux.conf .vimrc .zshrc README.md iterm-profile.json vs-code.json vs_code_extensions_list.txt + docs/
```

- [ ] **Step 2: Create `.editorconfig`**

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2

[Makefile]
indent_style = tab

[*.{sh,bash}]
indent_style = space
indent_size = 2

[*.lua]
indent_size = 2
```

- [ ] **Step 3: Create `.shellcheckrc`**

```
# Use POSIX-extended severity. Allow `source` of files we know exist at runtime.
disable=SC1090,SC1091
```

- [ ] **Step 4: Create `.gitignore`**

```
.DS_Store
*.swp
.idea/
.vscode/
.claude/
node_modules/
```

- [ ] **Step 5: Verify shellcheck and shfmt are available locally**

```bash
command -v shellcheck shfmt
```
Expected: both resolve. If shellcheck missing: `sudo apt-get install -y shellcheck`. If shfmt missing: download from https://github.com/mvdan/sh/releases or `cargo install shfmt`.

- [ ] **Step 6: Commit**

```bash
git add .editorconfig .shellcheckrc .gitignore
git commit -m "chore: add editorconfig, shellcheckrc, gitignore"
```

---

## Task 2: `bin/pkg` cross-platform install wrapper

**Files:**
- Create: `bin/pkg`

- [ ] **Step 1: Write `bin/pkg`**

```bash
#!/usr/bin/env bash
# pkg — install OS packages with the right native package manager.
# Usage: bin/pkg <package> [<package> ...]
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "usage: $(basename "$0") <package> [<package> ...]" >&2
  exit 64
fi

case "$(uname -s)" in
  Darwin)
    if ! command -v brew >/dev/null 2>&1; then
      echo "pkg: Homebrew not installed; run 'make install-pkg-mgr' first" >&2
      exit 1
    fi
    brew install "$@"
    ;;
  Linux)
    sudo apt-get update -qq
    sudo apt-get install -y "$@"
    ;;
  *)
    echo "pkg: unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac
```

- [ ] **Step 2: Make it executable and lint-clean**

```bash
chmod +x bin/pkg
shellcheck bin/pkg && shfmt -d -i 2 bin/pkg
```
Expected: no output (success).

- [ ] **Step 3: Smoke-test the help path (no install)**

```bash
bin/pkg
```
Expected: prints `usage: pkg <package> [<package> ...]` to stderr, exit 64.

- [ ] **Step 4: Commit**

```bash
git add bin/pkg
git commit -m "feat: add bin/pkg cross-platform install wrapper"
```

---

## Task 3: `Makefile` skeleton with `lint`, `fmt`, `help` targets

**Files:**
- Create: `Makefile`

- [ ] **Step 1: Write `Makefile`** (skeleton — install/stow targets land in Tasks 16–19)

```makefile
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

REPO := $(shell pwd)
UNAME_S := $(shell uname -s)

SHELL_SCRIPTS := $(shell find bin tests -type f \( -name '*.sh' -o ! -name '*.*' \) 2>/dev/null)

.PHONY: help
help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: lint
lint: ## Run shellcheck on all shell scripts.
	@if [ -n "$(SHELL_SCRIPTS)" ]; then shellcheck $(SHELL_SCRIPTS); else echo "no scripts yet"; fi

.PHONY: fmt
fmt: ## Format all shell scripts with shfmt.
	@if [ -n "$(SHELL_SCRIPTS)" ]; then shfmt -w -i 2 $(SHELL_SCRIPTS); fi

.PHONY: fmt-check
fmt-check: ## Verify shell scripts are formatted.
	@if [ -n "$(SHELL_SCRIPTS)" ]; then shfmt -d -i 2 $(SHELL_SCRIPTS); fi
```

- [ ] **Step 2: Smoke-test help and lint**

```bash
make help
make lint
make fmt-check
```
Expected: `make help` lists 4 targets; `make lint` reports `bin/pkg` clean; `make fmt-check` exits 0.

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "feat: add Makefile skeleton with help/lint/fmt targets"
```

---

## Task 4: `packages/Brewfile`

**Files:**
- Create: `packages/Brewfile`

- [ ] **Step 1: Write `packages/Brewfile`**

```ruby
# packages/Brewfile — Mac packages installed via `brew bundle`.
# Casks and `mas` lines are Mac-only; ignored by the Linux path.

# Taps
tap "homebrew/bundle"

# CLI
brew "git"
brew "gh"
brew "stow"
brew "mise"
brew "ripgrep"
brew "fd"
brew "fzf"
brew "lazygit"
brew "tree-sitter"
brew "bat"
brew "eza"
brew "jq"
brew "yq"
brew "htop"
brew "tmux"
brew "watchman"
brew "neovim"
brew "shellcheck"
brew "shfmt"
brew "tig"
brew "mas"

# Fonts
cask "font-jetbrains-mono-nerd-font"

# GUI / Casks
cask "orbstack"
cask "ghostty"
cask "android-studio"
cask "google-chrome"
cask "firefox"
cask "arc"

# App Store
mas "Xcode", id: 497799835
```

- [ ] **Step 2: Quick syntax sanity-check**

```bash
ruby -c packages/Brewfile
```
Expected: `Syntax OK`.

- [ ] **Step 3: Commit**

```bash
git add packages/Brewfile
git commit -m "feat: add packages/Brewfile (Mac packages)"
```

---

## Task 5: `packages/Aptfile`

**Files:**
- Create: `packages/Aptfile`

- [ ] **Step 1: Write `packages/Aptfile`** (newline-separated, comments allowed)

```
# packages/Aptfile — Ubuntu packages installed via apt-get.
# Note: tools that lag badly in Ubuntu LTS (mise, lazygit, tree-sitter, fd)
# are installed by bin/install-*.sh from upstream releases instead.

build-essential
curl
git
gh
stow
zsh
ripgrep
fzf
bat
jq
htop
tmux
neovim
shellcheck
unzip
zip
ca-certificates
libssl-dev
libreadline-dev
zlib1g-dev
libffi-dev
libyaml-dev
pkg-config
xclip
tig
docker.io
docker-compose-plugin
```

- [ ] **Step 2: Verify the file is readable line-by-line**

```bash
grep -vE '^\s*(#|$)' packages/Aptfile | wc -l
```
Expected: a positive integer (~25).

- [ ] **Step 3: Commit**

```bash
git add packages/Aptfile
git commit -m "feat: add packages/Aptfile (Ubuntu packages)"
```

---

## Task 6: `zsh/` stow package

**Files:**
- Create: `zsh/.zshrc`, `zsh/.zprofile`

- [ ] **Step 1: Create directory**

```bash
mkdir -p zsh
```

- [ ] **Step 2: Write `zsh/.zshrc`** (modernized, secret-free, project-alias-free)

```sh
# ~/.zshrc — managed by dev-env-setup (stow zsh).

# Path to oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(git docker gh)

[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# mise (language version manager)
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Editor
export EDITOR='nvim'
export VISUAL='nvim'

# Aliases
alias vim='nvim'
alias vi='nvim'
alias gs='tig status'
alias ls='eza'           # falls through to ls if eza absent
alias ll='eza -l'
alias la='eza -la'
alias cat='bat --paging=never'
alias dps='docker ps'
alias dlogs='docker logs -f'

# Local overrides (never committed)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Secrets (never committed)
[ -f ~/.secrets.local ] && source ~/.secrets.local
```

- [ ] **Step 3: Write `zsh/.zprofile`** (login-shell PATH and toolchain init)

```sh
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
```

- [ ] **Step 4: Commit**

```bash
git add zsh/.zshrc zsh/.zprofile
git commit -m "feat(zsh): add stow package with modernized .zshrc and .zprofile"
```

---

## Task 7: `git/` stow package

**Files:**
- Create: `git/.gitconfig`, `git/.gitignore_global`

- [ ] **Step 1: Create directory**

```bash
mkdir -p git
```

- [ ] **Step 2: Write `git/.gitconfig`**

```ini
# ~/.gitconfig — managed by dev-env-setup (stow git).

[include]
  path = ~/.gitconfig.local

[init]
  defaultBranch = main

[pull]
  rebase = true

[rebase]
  autoStash = true
  autoSquash = true

[push]
  default = current
  autoSetupRemote = true

[core]
  excludesfile = ~/.gitignore_global
  editor = nvim

[diff]
  algorithm = histogram
  colorMoved = default

[merge]
  conflictstyle = zdiff3

[alias]
  st = status
  co = checkout
  br = branch
  ci = commit
  lg = log --graph --pretty=format:'%C(yellow)%h%Creset -%C(red)%d%Creset %s %C(green)(%cr) %C(blue)<%an>%Creset' --abbrev-commit
  unstage = reset HEAD --
  amend = commit --amend --no-edit
```

- [ ] **Step 3: Write `git/.gitignore_global`**

```
.DS_Store
*.swp
*.swo
.idea/
.vscode/
.claude/
.envrc
.direnv/
node_modules/
```

- [ ] **Step 4: Commit**

```bash
git add git/.gitconfig git/.gitignore_global
git commit -m "feat(git): add stow package with .gitconfig and global ignore"
```

---

## Task 8: `tmux/` stow package

**Files:**
- Create: `tmux/.tmux.conf`

- [ ] **Step 1: Read the existing `.tmux.conf` from the repo root**

```bash
cat .tmux.conf
```

- [ ] **Step 2: Write `tmux/.tmux.conf`** — preserves the user's existing keybindings if any; otherwise the sensible defaults below

```tmux
# ~/.tmux.conf — managed by dev-env-setup (stow tmux).

set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"

set -g mouse on
set -g history-limit 50000
set -g escape-time 0
set -g focus-events on

# 1-indexed windows/panes (more keyboard-friendly)
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# vi mode
setw -g mode-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel

# Reload config
bind r source-file ~/.tmux.conf \; display "tmux.conf reloaded"

# Split panes with intuitive bindings
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Smarter pane switching with vim-tmux-navigator (works with the nvim plugin)
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"

# Status bar
set -g status-interval 5
set -g status-style "bg=default,fg=white"
set -g status-left "[#S] "
set -g status-right "%Y-%m-%d %H:%M "
```

- [ ] **Step 3: Commit**

```bash
mkdir -p tmux
git add tmux/.tmux.conf
git commit -m "feat(tmux): add stow package with refreshed tmux.conf"
```

---

## Task 9: `ssh/` stow package (host config only, no keys)

**Files:**
- Create: `ssh/.ssh/config`

- [ ] **Step 1: Create directory and write `ssh/.ssh/config`**

```bash
mkdir -p ssh/.ssh
```

```ssh-config
# ~/.ssh/config — managed by dev-env-setup (stow ssh).
# Keys live separately and are NOT in this repo.

Host *
  AddKeysToAgent yes
  UseKeychain yes        # Mac-only; harmless on Linux (ignored with warning)
  ServerAliveInterval 60
  ServerAliveCountMax 3
  HashKnownHosts yes

Host github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
```

- [ ] **Step 2: Commit**

```bash
git add ssh/.ssh/config
git commit -m "feat(ssh): add stow package with host config (no keys)"
```

---

## Task 10: `mise/` stow package

**Files:**
- Create: `mise/.config/mise/config.toml`

- [ ] **Step 1: Create directory and write the mise config**

```bash
mkdir -p mise/.config/mise
```

```toml
# ~/.config/mise/config.toml — managed by dev-env-setup (stow mise).

[tools]
node   = "lts"
ruby   = "3.3"
java   = "temurin-17"
python = "3.12"

[settings]
experimental = true
```

- [ ] **Step 2: Commit**

```bash
git add mise/.config/mise/config.toml
git commit -m "feat(mise): add stow package with global tool versions"
```

---

## Task 11: `ghostty/` stow package

**Files:**
- Create: `ghostty/.config/ghostty/config`

- [ ] **Step 1: Create directory and write the ghostty config**

```bash
mkdir -p ghostty/.config/ghostty
```

```ini
# ~/.config/ghostty/config — managed by dev-env-setup (stow ghostty).

font-family = "JetBrainsMono Nerd Font"
font-size = 14

theme = "Tokyo Night"

cursor-style = block
cursor-style-blink = false

window-padding-x = 8
window-padding-y = 8

mouse-hide-while-typing = true
copy-on-select = clipboard

confirm-close-surface = false
```

- [ ] **Step 2: Commit**

```bash
git add ghostty/.config/ghostty/config
git commit -m "feat(ghostty): add stow package with terminal config"
```

---

## Task 12: `nvim/` stow package — base port

**Files:**
- Create: `nvim/.config/nvim/init.lua`, `nvim/.config/nvim/lazy-lock.json`, `nvim/.config/nvim/lazyvim.json`, `nvim/.config/nvim/stylua.toml`, `nvim/.config/nvim/.neoconf.json`, `nvim/.config/nvim/lua/config/lazy.lua`, `nvim/.config/nvim/lua/config/keymaps.lua`, `nvim/.config/nvim/lua/plugins/treesitter.lua`, `nvim/.config/nvim/lua/plugins/markdown-preview.lua`

- [ ] **Step 1: Mirror the existing `~/.config/nvim/` into the repo**

```bash
mkdir -p nvim/.config/nvim
rsync -a --exclude='.git' --exclude='lazy-lock.json' --exclude='spell' --exclude='LICENSE' --exclude='README.md' ~/.config/nvim/ nvim/.config/nvim/
# Bring lazy-lock.json over too — pinning plugin commits is a feature
cp ~/.config/nvim/lazy-lock.json nvim/.config/nvim/lazy-lock.json
ls nvim/.config/nvim/
```
Expected: includes `init.lua`, `lazy-lock.json`, `lazyvim.json`, `stylua.toml`, `.neoconf.json`, `lua/`.

- [ ] **Step 2: Verify the LazyVim config files are intact**

```bash
test -f nvim/.config/nvim/lua/config/lazy.lua
test -f nvim/.config/nvim/lua/config/keymaps.lua || true   # may not exist yet — created in step 3
test -f nvim/.config/nvim/lua/plugins/treesitter.lua
test -f nvim/.config/nvim/lua/plugins/markdown-preview.lua
```

- [ ] **Step 3: If `lua/config/keymaps.lua` doesn't exist, create an empty one**

```bash
mkdir -p nvim/.config/nvim/lua/config
[ -f nvim/.config/nvim/lua/config/keymaps.lua ] || cat > nvim/.config/nvim/lua/config/keymaps.lua <<'EOF'
-- Personal keymaps — kept minimal initially; grown as muscle memory dictates.
-- LazyVim defaults are still in effect.
EOF
```

- [ ] **Step 4: Commit**

```bash
git add nvim/.config/nvim
git commit -m "feat(nvim): import existing LazyVim config as stow package"
```

---

## Task 13: `nvim/` — LSP, formatters, treesitter expansion, language extras, DAP, extra plugins

**Files:**
- Create: `nvim/.config/nvim/lua/plugins/lsp.lua`
- Create: `nvim/.config/nvim/lua/plugins/format.lua`
- Create: `nvim/.config/nvim/lua/plugins/dap.lua`
- Create: `nvim/.config/nvim/lua/plugins/extras.lua`
- Modify: `nvim/.config/nvim/lua/plugins/treesitter.lua`
- Modify: `nvim/.config/nvim/lua/config/lazy.lua` (enable LazyVim language extras)

- [ ] **Step 1: Write `lua/plugins/lsp.lua`**

```lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {},
        eslint = {},
        bashls = {},
        jsonls = {},
        yamlls = {},
        taplo = {},
        marksman = {},
        dockerls = {},
        docker_compose_language_service = {},
        ruby_lsp = {},
        kotlin_language_server = {},
        sourcekit = {},   -- iOS Swift; binary installed by Xcode, not Mason
        gopls = {},
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "vtsls",
        "eslint-lsp",
        "bash-language-server",
        "json-lsp",
        "yaml-language-server",
        "taplo",
        "marksman",
        "dockerfile-language-server",
        "docker-compose-language-service",
        "ruby-lsp",
        "kotlin-language-server",
        "gopls",
      })
    end,
  },
}
```

- [ ] **Step 2: Write `lua/plugins/format.lua`**

```lua
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "biome", "prettierd", stop_after_first = true },
        typescript = { "biome", "prettierd", stop_after_first = true },
        javascriptreact = { "biome", "prettierd", stop_after_first = true },
        typescriptreact = { "biome", "prettierd", stop_after_first = true },
        json = { "biome", "prettierd", stop_after_first = true },
        jsonc = { "biome", "prettierd", stop_after_first = true },
        yaml = { "prettierd" },
        markdown = { "prettierd" },
        lua = { "stylua" },
        ruby = { "rubocop" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        kotlin = { "ktlint" },
        swift = { "swiftformat" },
      },
      format_on_save = function(bufnr)
        if vim.b[bufnr].disable_autoformat or vim.g.disable_autoformat then
          return
        end
        return { timeout_ms = 1500, lsp_format = "fallback" }
      end,
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "biome",
        "prettierd",
        "stylua",
        "rubocop",
        "shfmt",
        "shellcheck",
        "ktlint",
      })
    end,
  },
}
```

- [ ] **Step 3: Replace `lua/plugins/treesitter.lua`** (extend the parser list)

```lua
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "tsx",
        "typescript",
        "javascript",
        "kotlin",
        "swift",
        "ruby",
        "markdown",
        "markdown_inline",
        "regex",
        "lua",
        "bash",
        "json",
        "yaml",
        "toml",
        "html",
        "css",
        "scss",
        "dockerfile",
        "embedded_template",
        "slim",
      })
    end,
  },
}
```

- [ ] **Step 4: Write `lua/plugins/dap.lua`**

```lua
return {
  -- LazyVim's DAP extras (loaded via lazy.lua) bring core; this file pins JS adapter.
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
    },
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "js-debug-adapter" })
    end,
  },
}
```

- [ ] **Step 5: Write `lua/plugins/extras.lua`** (oil, spectre, tmux-navigator)

```lua
return {
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
    },
    opts = {
      view_options = { show_hidden = true },
    },
  },
  {
    "nvim-pack/nvim-spectre",
    cmd = "Spectre",
    keys = {
      { "<leader>sR", function() require("spectre").open() end, desc = "Spectre (project find/replace)" },
    },
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
}
```

- [ ] **Step 6: Update `lua/config/lazy.lua` to enable LazyVim language extras**

Read existing file first:
```bash
cat nvim/.config/nvim/lua/config/lazy.lua
```

Then ensure the `spec` table includes the language extras alongside `LazyVim`. If the file looks like:
```lua
require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
  ...
})
```

Modify the `spec` block to add language extras between `LazyVim/LazyVim` and `{ import = "plugins" }`:
```lua
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.tailwind" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.docker" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.yaml" },
    { import = "lazyvim.plugins.extras.lang.ruby" },
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "plugins" },
```

- [ ] **Step 7: Commit**

```bash
git add nvim/.config/nvim/lua
git commit -m "feat(nvim): expand LazyVim with LSPs, formatters, DAP, language extras, and extra plugins"
```

---

## Task 14: Install scripts for upstream-curl tools

**Files:**
- Create: `bin/install-mise.sh`, `bin/install-bun.sh`, `bin/install-rust.sh`, `bin/install-fonts.sh`, `bin/install-lazygit.sh`, `bin/install-tree-sitter.sh`, `bin/install-fd.sh`

All scripts: `set -euo pipefail`, idempotent (skip if already installed), shellcheck-clean.

- [ ] **Step 1: `bin/install-mise.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

if command -v mise >/dev/null 2>&1; then
  echo "mise already installed: $(mise --version)"
  exit 0
fi

curl -fsSL https://mise.run | sh
echo "mise installed. Add 'eval \"\$(mise activate zsh)\"' to your shell rc (already done in zsh/.zshrc)."
```

- [ ] **Step 2: `bin/install-bun.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

if command -v bun >/dev/null 2>&1; then
  echo "bun already installed: $(bun --version)"
  exit 0
fi

curl -fsSL https://bun.sh/install | bash
```

- [ ] **Step 3: `bin/install-rust.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

if command -v rustc >/dev/null 2>&1; then
  echo "rust already installed: $(rustc --version)"
  exit 0
fi

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
```

- [ ] **Step 4: `bin/install-fonts.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
  Darwin)
    if brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
      echo "JetBrainsMono Nerd Font already installed (cask)."
      exit 0
    fi
    brew install --cask font-jetbrains-mono-nerd-font
    ;;
  Linux)
    fonts_dir="$HOME/.local/share/fonts"
    mkdir -p "$fonts_dir"
    if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
      echo "JetBrainsMono Nerd Font already installed."
      exit 0
    fi
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/JetBrainsMono.zip" \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -q "$tmp/JetBrainsMono.zip" -d "$fonts_dir/JetBrainsMono"
    fc-cache -f "$fonts_dir"
    rm -rf "$tmp"
    ;;
esac
```

- [ ] **Step 5: `bin/install-lazygit.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

if command -v lazygit >/dev/null 2>&1; then
  echo "lazygit already installed: $(lazygit --version | head -1)"
  exit 0
fi

case "$(uname -s)" in
  Darwin) brew install lazygit ;;
  Linux)
    arch="$(uname -m)"
    case "$arch" in
      x86_64) suffix=Linux_x86_64 ;;
      aarch64|arm64) suffix=Linux_arm64 ;;
      *) echo "unsupported arch: $arch" >&2; exit 1 ;;
    esac
    version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
      | grep -Po '"tag_name": "v\K[^"]*')"
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/lazygit.tar.gz" \
      "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_${suffix}.tar.gz"
    tar -xf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
    install -m 0755 "$tmp/lazygit" "$HOME/.local/bin/lazygit"
    rm -rf "$tmp"
    ;;
esac
```

- [ ] **Step 6: `bin/install-tree-sitter.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

if command -v tree-sitter >/dev/null 2>&1; then
  echo "tree-sitter already installed: $(tree-sitter --version)"
  exit 0
fi

case "$(uname -s)" in
  Darwin) brew install tree-sitter ;;
  Linux)
    arch="$(uname -m)"
    case "$arch" in
      x86_64) suffix=linux-x64 ;;
      aarch64|arm64) suffix=linux-arm64 ;;
      *) echo "unsupported arch: $arch" >&2; exit 1 ;;
    esac
    # Pin: v0.25.10 builds against glibc 2.35 (Ubuntu 22.04). Bump after testing.
    version="0.25.10"
    mkdir -p "$HOME/.local/bin"
    curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/tree-sitter-${suffix}.gz" \
      | gunzip > "$HOME/.local/bin/tree-sitter"
    chmod +x "$HOME/.local/bin/tree-sitter"
    ;;
esac
```

- [ ] **Step 7: `bin/install-fd.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

if command -v fd >/dev/null 2>&1 && fd --version | awk '{print $2}' | awk -F. '{exit !($1>8 || ($1==8 && $2>=4))}'; then
  echo "fd already installed and recent enough: $(fd --version)"
  exit 0
fi

case "$(uname -s)" in
  Darwin) brew install fd ;;
  Linux)
    if ! command -v cargo >/dev/null 2>&1; then
      echo "cargo required to build fd; run bin/install-rust.sh first" >&2
      exit 1
    fi
    cargo install fd-find
    ;;
esac
```

- [ ] **Step 8: `bin/install-omz.sh`** — install oh-my-zsh framework non-interactively

```bash
#!/usr/bin/env bash
set -euo pipefail

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh already installed."
  exit 0
fi

# RUNZSH=no prevents the installer from launching a zsh subshell.
# KEEP_ZSHRC=yes prevents it from clobbering our stow-managed ~/.zshrc.
RUNZSH=no KEEP_ZSHRC=yes sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

- [ ] **Step 9: Make all executable, lint, format-check**

```bash
chmod +x bin/install-*.sh
make lint
make fmt-check
```
Expected: all pass.

- [ ] **Step 10: Commit**

```bash
git add bin/install-mise.sh bin/install-bun.sh bin/install-rust.sh bin/install-fonts.sh \
        bin/install-lazygit.sh bin/install-tree-sitter.sh bin/install-fd.sh bin/install-omz.sh
git commit -m "feat(bin): add install scripts for mise, bun, rust, fonts, lazygit, tree-sitter, fd, oh-my-zsh"
```

---

## Task 15: Setup helper scripts (`bin/setup-git.sh`, `bin/setup-android-sdk.sh`, `bin/doctor.sh`, `bin/bootstrap`)

**Files:**
- Create: `bin/setup-git.sh`, `bin/setup-android-sdk.sh`, `bin/doctor.sh`, `bin/bootstrap`

- [ ] **Step 1: `bin/setup-git.sh`**

```bash
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

cat > "$target" <<EOF
[user]
  name = $name
  email = $email
EOF

echo "Wrote $target."
```

- [ ] **Step 2: `bin/setup-android-sdk.sh`**

```bash
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
```

- [ ] **Step 3: `bin/doctor.sh`**

```bash
#!/usr/bin/env bash
# Verify the dev environment is in working order.
set -euo pipefail

ok=0
fail=0
check() {
  local label="$1"; shift
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
check "node lts"   bash -c 'mise which node >/dev/null'
check "ruby 3.3"   bash -c 'mise which ruby >/dev/null'
check "java 17"    bash -c 'mise which java >/dev/null'
check "python 3.12" bash -c 'mise which python >/dev/null'

echo "== Dotfiles symlinks =="
for f in ~/.zshrc ~/.zprofile ~/.gitconfig ~/.tmux.conf ~/.config/nvim ~/.config/mise/config.toml; do
  check "$f symlinked" test -L "$f"
done

echo
echo "$ok ok, $fail failed"
[ "$fail" -eq 0 ]
```

- [ ] **Step 4: `bin/bootstrap`** — first-run prerequisites only (Xcode CLT or apt refresh + git/curl)

```bash
#!/usr/bin/env bash
# bin/bootstrap — first-run prerequisites for `make all`.
set -euo pipefail

case "$(uname -s)" in
  Darwin)
    if ! xcode-select -p >/dev/null 2>&1; then
      echo "Installing Xcode Command Line Tools..."
      xcode-select --install
      echo "Re-run 'make all' once the CLT installer finishes."
      exit 0
    fi
    if ! command -v brew >/dev/null 2>&1; then
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    ;;
  Linux)
    sudo apt-get update -qq
    sudo apt-get install -y curl git ca-certificates
    ;;
esac
```

- [ ] **Step 5: Make all executable, lint, format-check**

```bash
chmod +x bin/setup-git.sh bin/setup-android-sdk.sh bin/doctor.sh bin/bootstrap
make lint
make fmt-check
```
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add bin/setup-git.sh bin/setup-android-sdk.sh bin/doctor.sh bin/bootstrap
git commit -m "feat(bin): add bootstrap, setup-git, setup-android-sdk, doctor scripts"
```

---

## Task 16: Makefile — package + stow targets

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Append package + stow targets to `Makefile`**

```makefile
# ---- Package management ----

.PHONY: install-pkg-mgr
install-pkg-mgr: ## Install Homebrew (Mac) or refresh apt cache (Linux).
	bin/bootstrap

.PHONY: install-stow
install-stow: ## Install GNU stow (prerequisite for stow-dotfiles).
ifeq ($(UNAME_S),Darwin)
	@command -v stow >/dev/null || brew install stow
else
	@command -v stow >/dev/null || sudo apt-get install -y stow
endif

.PHONY: install-packages
install-packages: ## Install OS packages from Brewfile (Mac) or Aptfile (Linux).
ifeq ($(UNAME_S),Darwin)
	brew bundle --file=packages/Brewfile
else
	xargs -a <(grep -vE '^\s*(#|$$)' packages/Aptfile) sudo apt-get install -y
endif

# ---- Dotfiles ----

STOW_PACKAGES := zsh git tmux ssh mise ghostty nvim

.PHONY: stow-dotfiles
stow-dotfiles: ## Symlink all stow packages into $HOME.
	@mkdir -p $(HOME)/.config $(HOME)/.local/bin
	stow -t $(HOME) -d $(REPO) $(STOW_PACKAGES)

.PHONY: unstow-dotfiles
unstow-dotfiles: ## Remove all stow-managed symlinks.
	stow -D -t $(HOME) -d $(REPO) $(STOW_PACKAGES)

.PHONY: stow-dry-run
stow-dry-run: ## Show what stow-dotfiles would do without doing it.
	stow -n -v -t $(HOME) -d $(REPO) $(STOW_PACKAGES)
```

- [ ] **Step 2: Sanity-check the new targets are listed**

```bash
make help
```
Expected: `install-pkg-mgr`, `install-stow`, `install-packages`, `stow-dotfiles`, `unstow-dotfiles`, `stow-dry-run` all appear.

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "feat(make): add install-pkg-mgr, install-stow, install-packages, stow targets"
```

---

## Task 17: Makefile — language tools, fonts, git/secrets seeding

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Append language-tool targets**

```makefile
# ---- Language toolchain ----

.PHONY: install-mise
install-mise: ## Install mise and the global tool set from mise/config.toml.
	bin/install-mise.sh
	@bash -c 'export PATH="$$HOME/.local/bin:$$PATH"; mise install || true'

.PHONY: install-bun
install-bun: ## Install bun.
	bin/install-bun.sh

.PHONY: install-rust
install-rust: ## Install rustup + stable toolchain.
	bin/install-rust.sh

.PHONY: install-fonts
install-fonts: ## Install JetBrains Mono Nerd Font.
	bin/install-fonts.sh

.PHONY: install-cli-extras
install-cli-extras: ## Install lazygit, tree-sitter, fresh fd (upstream releases).
	bin/install-lazygit.sh
	bin/install-tree-sitter.sh
	bin/install-fd.sh

.PHONY: install-omz
install-omz: ## Install oh-my-zsh framework (non-interactive, won't touch our .zshrc).
	bin/install-omz.sh

# ---- Configuration seeding ----

.PHONY: setup-git
setup-git: ## Prompt for git user.name and user.email if ~/.gitconfig.local missing.
	bin/setup-git.sh

.PHONY: seed-secrets
seed-secrets: ## Seed ~/.secrets.local from template if missing.
	@if [ ! -f $(HOME)/.secrets.local ]; then \
	  cp templates/secrets.local.template $(HOME)/.secrets.local; \
	  chmod 600 $(HOME)/.secrets.local; \
	  echo "Wrote $(HOME)/.secrets.local — fill in your API keys."; \
	else \
	  echo "$(HOME)/.secrets.local already exists; leaving it alone."; \
	fi
```

- [ ] **Step 2: Confirm targets list**

```bash
make help
```
Expected: includes the new targets above.

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "feat(make): add language toolchain, font, git, and secrets-seeding targets"
```

---

## Task 18: Makefile — mobile, nvim, doctor, all

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Append the remaining targets**

```makefile
# ---- Mobile (Mac only) ----

.PHONY: mobile-bootstrap
mobile-bootstrap: ## Mac-only: install watchman, cocoapods (gem), Android SDK components.
ifeq ($(UNAME_S),Darwin)
	brew install watchman
	@bash -c 'export PATH="$$HOME/.local/bin:$$PATH"; eval "$$(mise activate bash)"; gem install cocoapods --no-document'
	bin/setup-android-sdk.sh
else
	@echo "mobile-bootstrap is Mac-only; skipping on Linux."
endif

# ---- nvim ----

.PHONY: nvim-bootstrap
nvim-bootstrap: ## Headless plugin sync for Neovim.
	nvim --headless "+Lazy! sync" +qa

# ---- Doctor + composite ----

.PHONY: doctor
doctor: ## Verify the environment.
	bin/doctor.sh

.PHONY: all
all: install-pkg-mgr install-stow install-packages install-omz stow-dotfiles install-mise install-bun install-rust install-fonts install-cli-extras setup-git seed-secrets nvim-bootstrap doctor ## Bootstrap everything (idempotent).
ifeq ($(UNAME_S),Darwin)
	@$(MAKE) mobile-bootstrap
endif
	@echo "✓ Done. Open a new terminal."

.PHONY: all-no-mobile
all-no-mobile: install-pkg-mgr install-stow install-packages install-omz stow-dotfiles install-mise install-bun install-rust install-fonts install-cli-extras setup-git seed-secrets nvim-bootstrap doctor ## Bootstrap without mobile toolchain (CI / containers).
	@echo "✓ Done."
```

- [ ] **Step 2: Confirm full target list and `make help` is readable**

```bash
make help
```
Expected: ~20 targets total, all readable on a single screen.

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "feat(make): add mobile, nvim, doctor, and composite all targets"
```

---

## Task 19: Templates and docs

**Files:**
- Create: `templates/secrets.local.template`
- Create: `docs/secrets.md`
- Create: `docs/new-machine.md`
- Create: `mobile/README.md`

- [ ] **Step 1: `templates/secrets.local.template`**

```bash
mkdir -p templates
```

```sh
# ~/.secrets.local — sourced by ~/.zshrc. Never commit this file.

# AI provider API keys
export DEEPSEEK_API_KEY=""
export OPENAI_API_KEY=""
export OPENROUTER_API_KEY=""

# Tunables
export DEEPSEEK_USE_LOCAL=false

# Add anything else that should NOT be in version control:
# export GH_TOKEN=""
# export ANTHROPIC_API_KEY=""
```

- [ ] **Step 2: `docs/secrets.md`**

```markdown
# Secrets

`~/.secrets.local` is a gitignored file outside this repo, sourced by `~/.zshrc`:

```sh
[ -f ~/.secrets.local ] && source ~/.secrets.local
```

## Restoring on a new machine

1. `make seed-secrets` writes a starter `~/.secrets.local` from `templates/secrets.local.template`.
2. Copy values from the prior machine's `~/.secrets.local` via a secure channel (1Password note, encrypted backup).
3. `chmod 600 ~/.secrets.local` (already done by `make seed-secrets` and the template).

## Adding a new secret

1. `export FOO=...` line in your local `~/.secrets.local`.
2. If the secret should be *expected* on every machine, add a `export FOO=""` line to `templates/secrets.local.template` and commit.
3. Open a new shell to verify it's in your environment: `echo "$FOO"`.

## What does NOT belong here

- SSH keys (in `~/.ssh/`, restored from backup).
- GPG keys (in `~/.gnupg/`, restored from backup).
- API keys checked into other tools' configs (those tools manage their own).
```

- [ ] **Step 3: `docs/new-machine.md`** — the day-1 runbook

```markdown
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
```

- [ ] **Step 4: `mobile/README.md`** — RN-specific manual steps

```markdown
# Mobile development

## iOS (Mac only)

### One-time

1. App Store: install Xcode (`mas install 497799835`). ~15 GB.
2. Launch Xcode → accept license → let it install components.
3. `xcodebuild -runFirstLaunch` (installs the default iOS Simulator runtime).
4. Optional: install extra simulator versions via Xcode → Settings → Components.
5. Code signing:
   - Sign into your Apple Developer account in Xcode → Settings → Accounts.
   - Note your Team ID (Xcode → Settings → Accounts → Manage Certificates).
   - Per-project: configure signing in `ios/<App>.xcworkspace` or via `fastlane match`.

### Per-project

```sh
cd <rn-project>
mise install              # honors project's .tool-versions
bun install               # or npm/yarn/pnpm
cd ios && pod install
cd ..
npx react-native run-ios
```

## Android (Mac + Linux)

### One-time

1. `make mobile-bootstrap` (Mac) — installs watchman, cocoapods, Android SDK components. Linux: `sudo snap install android-studio --classic` then run `bin/setup-android-sdk.sh`.
2. Launch Android Studio once. Confirm SDK Manager shows `platform-tools`, `platforms;android-34`, `build-tools;34.0.0`, `emulator`.
3. Create at least one AVD:
   ```sh
   avdmanager create avd \
     --name pixel_7_api_34 \
     --package "system-images;android-34;google_apis;arm64-v8a" \
     --device "pixel_7"
   ```

### Per-project

```sh
cd <rn-project>
mise install
bun install
npx react-native run-android
```
```

- [ ] **Step 5: Commit**

```bash
git add templates/secrets.local.template docs/secrets.md docs/new-machine.md mobile/README.md
git commit -m "docs: add secrets, new-machine runbook, mobile guide, and secrets template"
```

---

## Task 20: README.md rewrite

**Files:**
- Modify: `README.md` (full rewrite)

- [ ] **Step 1: Replace `README.md` with a quick-start**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README as quick-start"
```

---

## Task 21: Remove old root-level files

**Files:**
- Delete: `Brewfile` (root), `.zshrc` (root), `.tmux.conf` (root), `.vimrc`, `iterm-profile.json`, `vs-code.json`, `vs_code_extensions_list.txt`

- [ ] **Step 1: Verify no in-progress changes reference these files**

```bash
git status
git ls-files | grep -E '^(Brewfile|\.zshrc|\.tmux\.conf|\.vimrc|iterm-profile\.json|vs-code\.json|vs_code_extensions_list\.txt)$'
```
Expected: 7 files listed.

- [ ] **Step 2: Remove**

```bash
git rm Brewfile .zshrc .tmux.conf .vimrc iterm-profile.json vs-code.json vs_code_extensions_list.txt
```

- [ ] **Step 3: Commit**

```bash
git commit -m "chore: remove old flat-layout files (replaced by stow packages)"
```

---

## Task 22: Container-based smoke test

**Files:**
- Create: `tests/smoke-ubuntu.sh`, `tests/Dockerfile.ubuntu`

- [ ] **Step 1: Write `tests/Dockerfile.ubuntu`**

```bash
mkdir -p tests
```

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo curl ca-certificates git build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user with passwordless sudo (mirrors a fresh dev machine).
RUN useradd -m -s /bin/bash dev && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev

USER dev
WORKDIR /home/dev
ENV HOME=/home/dev
ENV PATH="/home/dev/.local/bin:/home/dev/.cargo/bin:${PATH}"
```

- [ ] **Step 2: Write `tests/smoke-ubuntu.sh`**

```bash
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
    make all-no-mobile
    make doctor
    # Idempotency check: second run should not error and should be quick
    make all-no-mobile
  '
```

- [ ] **Step 3: Make executable, lint, format-check**

```bash
chmod +x tests/smoke-ubuntu.sh
make lint
make fmt-check
```

- [ ] **Step 4: Append `smoke` target to `Makefile`**

```makefile
# ---- Tests ----

.PHONY: smoke
smoke: ## Run the Linux smoke test in a Docker container.
	tests/smoke-ubuntu.sh
```

- [ ] **Step 5: Run the smoke test**

```bash
make smoke
```
Expected: container builds, `make all-no-mobile` completes, `make doctor` reports 0 failures, second `make all-no-mobile` is fast and exits 0.

- [ ] **Step 6: Commit**

```bash
git add tests/Dockerfile.ubuntu tests/smoke-ubuntu.sh Makefile
git commit -m "test: add container-based ubuntu smoke test for full bootstrap path"
```

---

## Task 23: Final cleanup — default branch rename and push

**Files:** none

- [ ] **Step 1: Final lint sweep**

```bash
make lint
make fmt-check
```
Expected: both exit 0.

- [ ] **Step 2: Verify git history is sensible**

```bash
git log --oneline -25
```
Expected: ~22 new commits on top of the original repo state, each focused on one task.

- [ ] **Step 3: Push current `master` branch**

```bash
git push origin master
```

- [ ] **Step 4: Rename default branch `master` → `main` and push**

```bash
git branch -m master main
git push -u origin main
```

- [ ] **Step 5: Update GitHub default branch via `gh`**

```bash
gh repo edit solidstate-tech/dev-env-setup --default-branch main
git push origin --delete master
```
Note: confirm first via `gh repo view solidstate-tech/dev-env-setup` that no PRs target `master`.

- [ ] **Step 6: Verify**

```bash
gh repo view solidstate-tech/dev-env-setup --json defaultBranchRef
```
Expected: `defaultBranchRef.name == "main"`.

---

## Acceptance criteria recap

- [ ] `make help` lists ~20 documented targets.
- [ ] `make lint` and `make fmt-check` pass.
- [ ] `make smoke` succeeds (container-based end-to-end).
- [ ] All stow packages exist and `make stow-dry-run` shows expected operations with no conflicts.
- [ ] `~/.zshrc` (in repo) contains no plaintext secrets.
- [ ] `nvim/.config/nvim/lua/plugins/{lsp,format,dap,extras,treesitter,markdown-preview}.lua` all present.
- [ ] Old root files (`Brewfile`, `.zshrc`, `.tmux.conf`, `.vimrc`, `iterm-profile.json`, `vs-code.json`, `vs_code_extensions_list.txt`) removed.
- [ ] Default branch is `main`.
- [ ] Repo cloned to a fresh Mac and `make all` produces a working env in <60 minutes (this validation happens when the new MacBook arrives — not part of the implementation plan).
