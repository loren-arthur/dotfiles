#!/usr/bin/env bash
# Remote Workspace Setup Script
# Configures OSC 52, mosh, and other tools for remote development

set -e

echo "=========================================="
echo "Remote Workspace Setup"
echo "=========================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${BLUE}[✓]${NC} $1"
}

# Get the directory where this script lives (the dotfiles directory)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "Dotfiles directory: $DOTFILES_DIR"
echo

# ============================================================================
# Test OSC 52 Support
# ============================================================================
info "Testing OSC 52 clipboard support..."
echo
echo "This tests remote copy/paste functionality with your terminal."
echo
echo "Supported terminals: iTerm2, WezTerm, Alacritty, VS Code terminal"
warn "Note: If running tmux locally, OSC 52 won't work unless configured"
echo
read -p "Press Enter to test clipboard..."
echo

# Generate a random test string
TEST_UUID="osc52-test-$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo $RANDOM-$RANDOM-$RANDOM)"

echo "Test string: $TEST_UUID"
echo
info "Copying to clipboard via OSC 52..."

# Copy test string to clipboard via OSC 52
printf "\033]52;c;$(printf "%s" "$TEST_UUID" | base64)\a"

echo
read -p "Paste from clipboard (Cmd+V / Ctrl+Shift+V): " PASTED_VALUE
echo

if [[ "$PASTED_VALUE" == "$TEST_UUID" ]]; then
    success "OSC 52 working!"
elif [[ -z "$PASTED_VALUE" ]]; then
    warn "Clipboard test failed - no value pasted"
    echo
    echo "Troubleshooting:"
    echo "  • iTerm2: Enable Preferences → General → Selection → 'Applications in terminal may access clipboard'"
    echo "  • Alacritty: Add 'osc52' to features in config"
    echo "  • Terminal.app: Not supported - use iTerm2 instead"
    echo
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Setup cancelled."
        exit 1
    fi
else
    warn "Clipboard test failed - value mismatch"
    echo "  Expected: $TEST_UUID"
    echo "  Got:      $PASTED_VALUE"
    echo
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Setup cancelled."
        exit 1
    fi
fi

echo

# ============================================================================
# Configure UTF-8 Locale
# ============================================================================
if command -v apt-get &> /dev/null; then
    info "Configuring UTF-8 locale..."
    sudo apt-get update -qq
    sudo apt-get install -y locales

    sudo locale-gen en_US.UTF-8
    sudo update-locale LANG=en_US.UTF-8

    # Add locale settings to .zshrc if not already present
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "export LANG=en_US.UTF-8" "$HOME/.zshrc" 2>/dev/null; then
            info "Adding locale settings to ~/.zshrc"
            cat >> "$HOME/.zshrc" << 'EOF'

# Locale settings
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
EOF
            success "Locale settings added to ~/.zshrc"
        fi
    fi

    success "UTF-8 locale configured"
fi

# Add hostname to prompt for remote workspaces
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "POWERLEVEL9K_CONTEXT_" "$HOME/.zshrc" 2>/dev/null; then
        info "Configuring prompt to show hostname..."
        cat >> "$HOME/.zshrc" << 'EOF'

# Show hostname in prompt for remote workspaces
POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND='yellow'
# Always show context (user@host) in remote workspaces
typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION='%n@%m'
EOF
        success "Prompt configured to show hostname"
    fi
fi

echo

# ============================================================================
# Optional: Install Eternal Terminal
# ============================================================================
info "Eternal Terminal provides persistent remote connections with full OSC 52 clipboard support."
info "It auto-reconnects on network changes and survives SSH disconnects."
echo
read -p "Install Eternal Terminal? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v apt-get &> /dev/null; then
        info "Adding Eternal Terminal PPA..."
        sudo apt-get update -qq
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository -y ppa:jgmath2000/et
        sudo apt-get update -qq

        info "Installing Eternal Terminal..."
        sudo apt-get install -y et
        success "Eternal Terminal installed"

    elif command -v brew &> /dev/null; then
        if ! command -v et &> /dev/null; then
            info "Installing Eternal Terminal..."
            brew install eternalterminal
            success "Eternal Terminal installed"
        else
            info "Eternal Terminal already installed"
        fi
    else
        warn "No package manager found, cannot install Eternal Terminal"
    fi
else
    info "Skipped Eternal Terminal installation. Use SSH for remote connections."
fi

echo

# ============================================================================
# Configure Tmux for OSC 52
# ============================================================================
info "Configuring tmux for OSC 52..."

# Create a local tmux config extension (not tracked in git)
TMUX_LOCAL="$HOME/.tmux.local.conf"

# Check if OSC 52 is already configured
if [ -f "$TMUX_LOCAL" ] && grep -q "set -s set-clipboard on" "$TMUX_LOCAL" 2>/dev/null; then
    info "Tmux OSC 52 already configured"
else
    info "Adding OSC 52 support to local tmux config..."

    # Create local config file with OSC 52 support
    cat > "$TMUX_LOCAL" << 'EOF'
# ============================================================================
# Remote Clipboard Support (OSC 52)
# ============================================================================
# Enable OSC 52 passthrough to copy to local machine clipboard
set -s set-clipboard on

# Override copy-pipe-and-cancel to use OSC 52
# This sends the copied text to your local machine's clipboard
unbind -T copy-mode-vi y
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "yank-osc52"
EOF

    success "Tmux OSC 52 config created at ~/.tmux.local.conf"
    info "The dotfiles .tmux.conf automatically sources this file"
fi

echo

# ============================================================================
# Create yank-osc52 Helper Script
# ============================================================================
info "Creating yank-osc52 helper script..."

mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/yank-osc52" << 'EOF'
#!/usr/bin/env bash
# Helper script to copy to clipboard via OSC 52
# Works through SSH and nested tmux sessions

# Read input from stdin
input=$(cat)

# Encode to base64
encoded=$(printf "%s" "$input" | base64 | tr -d '\n')

# Send OSC 52 escape sequence
# This works even through tmux/SSH by wrapping in DCS
if [ -n "$TMUX" ]; then
    # Inside tmux, use DCS passthrough
    printf "\ePtmux;\e\e]52;c;%s\a\e\\" "$encoded" > /dev/tty
else
    # Direct to terminal
    printf "\e]52;c;%s\a" "$encoded" > /dev/tty
fi

# Also try local clipboard as fallback (ignore errors from xclip in SSH)
if command -v pbcopy &> /dev/null; then
    printf "%s" "$input" | pbcopy 2>/dev/null || true
elif command -v xclip &> /dev/null && [ -n "$DISPLAY" ]; then
    printf "%s" "$input" | xclip -selection clipboard 2>/dev/null || true
fi
EOF

chmod +x "$HOME/.local/bin/yank-osc52"
success "Created yank-osc52 helper at ~/.local/bin/yank-osc52"

echo

# ============================================================================
# Ensure ~/.local/bin is in PATH
# ============================================================================
info "Ensuring ~/.local/bin is in PATH..."

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    warn "~/.local/bin is not in PATH"

    # Check if we should add it to .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$HOME/.zshrc" 2>/dev/null; then
            info "Adding ~/.local/bin to PATH in ~/.zshrc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
            success "Updated ~/.zshrc"
        fi
    fi

    echo "Run: export PATH=\"\$HOME/.local/bin:\$PATH\""
else
    success "~/.local/bin is already in PATH"
fi

echo

# ============================================================================
# Completion
# ============================================================================
echo
success "=========================================="
success "Remote Workspace Setup Complete!"
success "=========================================="
echo
info "Connecting to remote workspace:"
echo "  • With Eternal Terminal: et user@host"
echo "  • With SSH: ssh user@host"
echo "  • Then start tmux: tmux new -A -s main"
echo
info "How to use remote clipboard (OSC 52):"
echo "  • Tmux: Press Ctrl-g [ for copy mode, select with 'v', yank with 'y'"
echo "  • Vim: Enter visual mode (v/V/Ctrl-v), select text, press 'y'"
echo "  • Text is copied to your LOCAL clipboard"
echo "  • Paste on your Mac with Cmd+V"
echo
info "Session persistence:"
echo "  • Eternal Terminal automatically reconnects on network changes"
echo "  • Tmux sessions survive all disconnects"
echo "  • If disconnected, reconnect and run: tmux attach"
echo
info "Note: Restart tmux for OSC 52 changes to take effect:"
echo "  tmux kill-server && tmux"
echo

