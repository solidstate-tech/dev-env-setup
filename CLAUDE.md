# Project Context

## About this project

`dev-env-setup` is the user's personal cross-platform (macOS + Ubuntu) developer-workstation bootstrap. Goal: a fresh machine becomes a fully working dev environment via `make all`, idempotent, no manual fiddling beyond a few unavoidable App Store / Xcode steps on Mac.

The project is mid-rewrite. The repo currently holds the old flat-layout files (`Brewfile`, `iterm-profile.json`, `vs-code.json`, `vs_code_extensions_list.txt`, plus old root `.zshrc` / `.tmux.conf` / `.vimrc` not yet visible because the cwd hasn't been listed since they were tracked). The rewrite is fully designed and planned; implementation is the active work.

## Source of truth — read these first, in order

1. `docs/superpowers/specs/2026-04-19-dev-env-setup-design.md` — the validated design. Architecture decisions, what's in / out of scope, dotfiles inventory, nvim build-out, secrets strategy. Treat as authoritative for *what* we're building.
2. `docs/superpowers/plans/2026-04-19-dev-env-setup.md` — the 23-task implementation plan. Each task is bite-sized with full code blocks, tests, and commit message. Treat as authoritative for *how* we're building it.
3. This file — operating guidance for working in this repo.

If anything in this CLAUDE.md contradicts the spec or the plan, trust those. Update this file to match.

## Architectural choices (for context — see spec for rationale)

- **Cross-platform** Mac + Ubuntu, both first-class. `bin/pkg` shim resolves to `brew` or `apt`. Casks/`mas` lines in Brewfile are Mac-only (the Linux path doesn't read Brewfile).
- **Make-driven**, every step is a `.PHONY` target, idempotent and re-runnable.
- **Stow** for dotfiles. One folder per area (`zsh/`, `nvim/`, `git/`, …); contents mirror `$HOME`. `make stow-dotfiles` symlinks them.
- **mise** is the single language version manager (Node, Ruby, Java, Python). Bun and Rust stay on their own canonical installers.
- **Secrets** live in `~/.secrets.local` outside the repo, sourced by `.zshrc`. Never commit secrets here.
- **Editor**: Neovim + LazyVim only. No VS Code / Cursor / Antigravity carry-over from the user's prior setup.
- **Docker on Mac**: OrbStack (cask). Linux: `docker.io` from apt.

## How to work in this repo

- **Use the plan.** When implementing, follow the task order in `docs/superpowers/plans/2026-04-19-dev-env-setup.md`. Mark each step's checkbox done as you finish it.
- **TDD-style discipline where it applies.** For shell scripts: `shellcheck` and `shfmt -d` must pass. `make lint` and `make fmt-check` are the gate.
- **Idempotency is non-negotiable.** Every install script and Make target must be safe to run twice. The smoke test (Task 22) runs `make all-no-mobile` twice in a row to catch regressions.
- **Frequent atomic commits.** One commit per task (some tasks have multiple commits). Use the commit messages in the plan verbatim or close to it.

## Critical safety rules — do NOT do these

- **NEVER run `make all` (or any composite install target) against the user's `$HOME`.** It would clobber existing dotfiles, install unwanted things, and reorder PATH. The smoke test runs everything inside a fresh `ubuntu:22.04` container — that's the only place `make all-no-mobile` should execute end-to-end during implementation.
- **NEVER run `bin/install-omz.sh` against the user's home.** It would install oh-my-zsh on top of an existing one and may overwrite `~/.zshrc` if `KEEP_ZSHRC=yes` ever gets dropped.
- **NEVER run `make stow-dotfiles` on the user's home machine.** Existing `.zshrc`, `.tmux.conf`, `.gitconfig`, `~/.config/nvim/` are real files and stow will refuse to clobber non-symlinks (which is good) — but the failure surface is messy. The user's machine is for *developing* this repo, not for *running* it.
- Validation against real `$HOME` happens **only** when the new MacBook arrives, not during implementation.

## Cross-platform reminders

- Anything that calls `brew` must be guarded by `ifeq ($(UNAME_S),Darwin)` (Make) or `case "$(uname -s)" in Darwin) ... ;; esac` (shell).
- Bash features are fine — every shell script declares `#!/usr/bin/env bash` and the Makefile sets `SHELL := /usr/bin/env bash`.
- macOS BSD coreutils differ from Linux GNU coreutils (`sed -i`, `readlink -f`, etc.). Prefer portable invocations or guard.
- Ubuntu 22.04 is the Linux baseline. glibc is 2.35 — many "latest" prebuilt binaries (tree-sitter, npm-installed CLIs) require newer glibc and will fail. The `bin/install-tree-sitter.sh` script pins to v0.25.10 for this reason.

## User context

- The user is on Ubuntu 22.04 today; a new MacBook arrives soon. The dev-env-setup is being polished now so the MacBook bootstrap is one command.
- Current Linux machine has: zsh + oh-my-zsh, tmux, nvim w/ LazyVim, Android SDK + JDK 17, Node via nvm, bun, rbenv, cargo, Docker, gh CLI. Most of this gets formalized into the new setup; some (rbenv, nvm) gets replaced by mise.
- The user does heavy React Native dev — bare workflow, both iOS and Android. iOS is new (this is the user's first Mac for development).
- Personal use, not commercial — so OrbStack's free tier is fine.

## Active work

The implementation plan is being executed via the `superpowers:subagent-driven-development` skill. Each plan task gets its own subagent dispatch; review happens between tasks. If you're a subagent reading this: your task is in the plan file — find your task ID, do exactly the steps listed, commit as instructed, then report back. Do not freelance beyond the task.

## Useful commands once the rewrite is in place

```sh
make help               # List all targets
make lint               # shellcheck all scripts
make fmt                # shfmt -w all scripts
make fmt-check          # shfmt -d (no writes — fails if formatting is off)
make stow-dry-run       # Preview what stow-dotfiles would do
make smoke              # Container-based end-to-end test (10–15 min)
make doctor             # Verify the environment (after `make all` on a real machine)
```

## Documentation

- `README.md` — quick-start (rewritten in plan Task 20)
- `docs/new-machine.md` — day-1 runbook (created in plan Task 19)
- `docs/secrets.md` — `~/.secrets.local` schema (created in plan Task 19)
- `mobile/README.md` — React Native iOS + Android guide (created in plan Task 19)
- `docs/superpowers/specs/` — design specs
- `docs/superpowers/plans/` — implementation plans
