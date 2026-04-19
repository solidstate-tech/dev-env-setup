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
