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
