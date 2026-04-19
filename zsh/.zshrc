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
alias ls='eza'
alias ll='eza -l'
alias la='eza -la'
alias cat='bat --paging=never'
alias dps='docker ps'
alias dlogs='docker logs -f'

# Local overrides (never committed)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Secrets (never committed)
[ -f ~/.secrets.local ] && source ~/.secrets.local
