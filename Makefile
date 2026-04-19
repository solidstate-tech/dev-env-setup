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
	@# OpenSSH requires strict perms on ~/.ssh and ~/.ssh/config; stow symlinks don't carry mode.
	@chmod 0700 $(HOME)/.ssh 2>/dev/null || true
	@chmod 0600 $(HOME)/.ssh/config 2>/dev/null || true

.PHONY: unstow-dotfiles
unstow-dotfiles: ## Remove all stow-managed symlinks.
	stow -D -t $(HOME) -d $(REPO) $(STOW_PACKAGES)

.PHONY: stow-dry-run
stow-dry-run: ## Show what stow-dotfiles would do without doing it.
	stow -n -v -t $(HOME) -d $(REPO) $(STOW_PACKAGES)

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

.PHONY: install-neovim
install-neovim: ## Install Neovim >= 0.9 (Linux upstream release; brew on Mac).
	bin/install-neovim.sh

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
all: install-pkg-mgr install-stow install-packages stow-dotfiles install-omz install-mise install-bun install-rust install-fonts install-cli-extras install-neovim setup-git seed-secrets nvim-bootstrap doctor ## Bootstrap everything (idempotent).
ifeq ($(UNAME_S),Darwin)
	@$(MAKE) mobile-bootstrap
endif
	@echo "✓ Done. Open a new terminal."

.PHONY: all-no-mobile
all-no-mobile: install-pkg-mgr install-stow install-packages stow-dotfiles install-omz install-mise install-bun install-rust install-fonts install-cli-extras install-neovim setup-git seed-secrets nvim-bootstrap doctor ## Bootstrap without mobile toolchain (CI / containers).
	@echo "✓ Done."

# ---- Tests ----

.PHONY: smoke
smoke: ## Run the Linux smoke test in a Docker container.
	tests/smoke-ubuntu.sh
