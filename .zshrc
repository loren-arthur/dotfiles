# ----------------------------------------------------------------------------
# Core Settings
# ----------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE APPEND_HISTORY INC_APPEND_HISTORY
setopt COMPLETE_IN_WORD CORRECT
unsetopt SHARE_HISTORY

bindkey -v
export KEYTIMEOUT=1

# ----------------------------------------------------------------------------
# Environment Variables (from bashrc)
# ----------------------------------------------------------------------------
# Homebrew
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CASK_OPTS=--require-sha
export HOMEBREW_DIR=/opt/homebrew
export HOMEBREW_BIN=/opt/homebrew/bin
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Go
export GOPATH="$HOME/go"
export GO111MODULE=auto
export GOPRIVATE=

# AWS
export AWS_VAULT_KEYCHAIN_NAME=login
export AWS_SESSION_TTL=24h
export AWS_ASSUME_ROLE_TTL=1h

# Helm
export HELM_DRIVER=configmap


# ----------------------------------------------------------------------------
# PATH Setup
# ----------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$GOPATH/bin:/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

# ----------------------------------------------------------------------------
# Pure Prompt (async, minimal, git-aware)
# ----------------------------------------------------------------------------
fpath+=(/opt/homebrew/share/zsh/site-functions)
autoload -U promptinit; promptinit
prompt pure

# ----------------------------------------------------------------------------
# Vi Mode Enhancements
# ----------------------------------------------------------------------------
# Change cursor shape for different vi modes
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    echo -ne '\e[2 q'  # Block cursor
  else
    echo -ne '\e[6 q'  # Beam cursor
  fi
}
zle -N zle-keymap-select
echo -ne '\e[6 q'  # Start with beam cursor

# ----------------------------------------------------------------------------
# History Search
# ----------------------------------------------------------------------------
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search    # Up arrow
bindkey "^[[B" down-line-or-beginning-search  # Down arrow
bindkey "^R" history-incremental-search-backward  # Ctrl+R
bindkey "^P" up-line-or-beginning-search      # Ctrl+P (vi style)
bindkey "^N" down-line-or-beginning-search    # Ctrl+N (vi style)

# ----------------------------------------------------------------------------
# Completions (cached)
# ----------------------------------------------------------------------------
autoload -Uz compinit
[[ -n ~/.zcompdump(#qN.mh+24) ]] && compinit || compinit -C

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
export LS_COLORS='di=01;34'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Git completions
autoload -Uz _git_dd 2>/dev/null

# ----------------------------------------------------------------------------
# Plugins
# ----------------------------------------------------------------------------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

[[ -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

[[ -f "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ----------------------------------------------------------------------------
# Lazy Loaders (only init when first used)
# ----------------------------------------------------------------------------
pyenv() {
  unfunction pyenv
  eval "$(command pyenv init -)"
  pyenv "$@"
}

rbenv() {
  unfunction rbenv
  eval "$(command rbenv init -)"
  rbenv "$@"
}

# Direnv hook (fast enough to run on startup)
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# ----------------------------------------------------------------------------
# Aliases
# ----------------------------------------------------------------------------
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias v='vim'
alias python='python3'
alias pip='pip3'


# ----------------------------------------------------------------------------
# Gitsign (lazy - only loads key when you first use git)
# ----------------------------------------------------------------------------
_lazy_gitsign() {
  if command -v dd-gitsign &>/dev/null; then
    eval "$(dd-gitsign load-key)"
  fi
}
# Hook into first git command
git() {
  unfunction git
  _lazy_gitsign
  command git "$@"
}

# ----------------------------------------------------------------------------
# Local config
# ----------------------------------------------------------------------------
[[ -f "$HOME/.zshrc_aliases" ]] && source "$HOME/.zshrc_aliases"
