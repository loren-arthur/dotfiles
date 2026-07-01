#!/usr/bin/env bash
# Dotfiles installation script
# Installs dependencies and symlinks configs for neovim, zsh, and tmux.

set -e

echo "=================================="
echo "Dotfiles Installation Script"
echo "=================================="
echo

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info "Using dotfiles directory: $DOTFILES_DIR"
echo

# Ensure submodules (vendor/pim) are present
if [ -f "$DOTFILES_DIR/.gitmodules" ]; then
    info "Initializing git submodules..."
    git -C "$DOTFILES_DIR" submodule update --init --recursive
fi
echo

# ============================================================================
# Detect OS
# ============================================================================
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"; info "Detected: Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"; info "Detected: macOS"
else
    OS="unknown"; warn "Unknown OS: $OSTYPE"
fi
echo

# ============================================================================
# Core dependencies
# ============================================================================
if [ "$OS" = "linux" ]; then
    info "Installing core dependencies via apt..."
    sudo apt-get update -qq
    sudo apt-get install -y \
        neovim tmux git curl wget build-essential \
        zsh fzf ripgrep fd-find gh software-properties-common
elif [ "$OS" = "macos" ]; then
    if ! command -v brew >/dev/null 2>&1; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    info "Installing core dependencies via brew..."
    brew install neovim tmux node fzf ripgrep fd gh uv
fi
echo

# ============================================================================
# Oh-My-Zsh + Powerlevel10k + plugins
# ============================================================================
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    # Oh-My-Zsh writes a default .zshrc; remove so our sourcing setup wins.
    [ -f "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
    [ -f "$HOME/.zshrc.pre-oh-my-zsh" ] && mv "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi
echo

# ============================================================================
# Symlinks
# ============================================================================
# link SRC DST — idempotent; backs up existing non-symlink targets.
link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ]; then
        rm "$dst"
    elif [ -e "$dst" ]; then
        local backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
        warn "Backing up existing $dst -> $backup"
        mv "$dst" "$backup"
    fi
    ln -s "$src" "$dst"
    info "Linked $dst -> $src"
}

info "Symlinking home dotfiles..."
link "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link "$DOTFILES_DIR/.p10k.zsh"  "$HOME/.p10k.zsh"

info "Symlinking neovim + pi configs..."
link "$DOTFILES_DIR/nvim"           "$HOME/.config/nvim"
# pi-agent-board lives in this repo; keep the old ~/repo path working too.
link "$DOTFILES_DIR/pi-agent-board" "$HOME/repo/pi-agent-board"

# .zshrc: create a real file that sources the repo version, so machine-local
# scripts can append to ~/.zshrc without touching the repo.
info "Setting up .zshrc..."
if [ ! -f "$HOME/.zshrc" ]; then
    cat > "$HOME/.zshrc" <<EOF
# Source base zsh configuration from dotfiles
if [ -f "$DOTFILES_DIR/.zshrc" ]; then
    source "$DOTFILES_DIR/.zshrc"
fi
EOF
    info "Created ~/.zshrc that sources the dotfiles version"
elif ! grep -q "source.*$DOTFILES_DIR/.zshrc" "$HOME/.zshrc" 2>/dev/null; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
    { printf '# Source base zsh configuration from dotfiles\nif [ -f "%s/.zshrc" ]; then\n    source "%s/.zshrc"\nfi\n\n' "$DOTFILES_DIR" "$DOTFILES_DIR"; cat "$HOME/.zshrc.backup"; } > "$HOME/.zshrc"
    info "Updated ~/.zshrc to source dotfiles (backup: ~/.zshrc.backup)"
else
    info "~/.zshrc already sources dotfiles, skipping"
fi
echo

# ============================================================================
# Python tooling (optional but handy)
# ============================================================================
if command -v uv >/dev/null 2>&1; then
    info "Installing Python tools via uv (ty, ruff)..."
    export PATH="$HOME/.local/bin:$PATH"
    uv tool install ty@latest || true
    uv tool install ruff || true
fi
echo

# ============================================================================
# Default shell
# ============================================================================
if [ "$SHELL" != "$(command -v zsh)" ]; then
    info "Setting zsh as default shell..."
    grep -q "$(command -v zsh)" /etc/shells 2>/dev/null || echo "$(command -v zsh)" | sudo tee -a /etc/shells >/dev/null
    sudo chsh -s "$(command -v zsh)" "$USER" 2>/dev/null || warn "Could not change shell; run: chsh -s \$(command -v zsh)"
fi
echo

success "Installation complete!"
echo
info "Next steps:"
echo "  1. Start zsh (or re-login)."
echo "  2. Open nvim — lazy.nvim bootstraps and installs plugins."
echo "  3. Configure pi per machine — see README (pi setup)."
