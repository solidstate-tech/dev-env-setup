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
