#!/usr/bin/env bash
# Symlink dotfiles into place. Safe to re-run (idempotent).
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    local backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
    echo "Backing up existing $dst -> $backup"
    mv "$dst" "$backup"
  fi
  ln -s "$src" "$dst"
  echo "Linked $dst -> $src"
}

link "$DOTFILES/nvim" "$HOME/.config/nvim"
link "$DOTFILES/pi/agent/settings.json" "$HOME/.pi/agent/settings.json"
# pi-agent-board lives inside this repo; keep the old ~/repo path working too.
link "$DOTFILES/pi-agent-board" "$HOME/repo/pi-agent-board"

echo "Done. Open nvim; lazy.nvim will bootstrap and install plugins."
