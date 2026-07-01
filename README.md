# Dotfiles

Personal development environment I sync across my Unix machines: **neovim, tmux, and zsh**, plus my [pi](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/) coding-agent tooling.

> Editor note: I moved from Vim/CoC to **Neovim + [pim](https://github.com/loren-arthur/pim)**. The old `.vimrc`, `coc-settings.json`, and shell-based `agent-workflow/` scripts have been removed in favor of the neovim config and the `pi-agent-board` package.

## Install

```sh
git clone --recurse-submodules https://github.com/loren-arthur/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Already cloned without submodules? Run `git submodule update --init --recursive`.

`install.sh` installs dependencies (Linux `apt` / macOS `brew`), sets up
Oh-My-Zsh + Powerlevel10k + zsh plugins, and symlinks configs. Symlinking is
idempotent and backs up any existing non-symlink target to
`<target>.backup.<timestamp>`.

## What's here

| Path | Symlinked to |
|------|--------------|
| `nvim/` | `~/.config/nvim` |
| `.tmux.conf` | `~/.tmux.conf` |
| `.p10k.zsh` | `~/.p10k.zsh` |
| `.zshrc` | *sourced* by a generated `~/.zshrc` |
| `pi-agent-board/` | `~/repo/pi-agent-board` |

Submodules:

| Submodule | Upstream |
|-----------|----------|
| `vendor/pim` | `git@github.com:loren-arthur/pim.git` (Neovim pi adapter) |

Also: `setup-remote.sh` — optional helper for remote machines (OSC 52 test,
mosh / Eternal Terminal, tmux tips).

> No machine-specific or secret files are tracked here. In particular
> `~/.pi/agent/settings.json`, `models.json`, and `auth.json` are **not**
> versioned — create them per machine (see [pi setup](#pi-coding-agent)).

## Neovim

- Plugin manager: [lazy.nvim](https://github.com/folke/lazy.nvim) (bootstraps on first launch).
- `nvim/lazy-lock.json` pins exact plugin versions for reproducible installs.
- Highlights: `fzf-lua`, `neo-tree`, `gitsigns` + `diffview`,
  `render-markdown` + `nvim-treesitter`, `todo-comments`, native system
  clipboard (OSC 52 over SSH), and `pim` (loaded from `vendor/pim`).

## Tmux

- Prefix `Ctrl-g`; vi keybindings and copy-mode; yank to system clipboard.
- Easy splits, minimal status bar.

## Zsh

- Powerlevel10k theme, `zsh-autosuggestions`, `zsh-syntax-highlighting`, vi-mode.
- `install.sh` generates a `~/.zshrc` that **sources** this repo's `.zshrc`, so
  machine-local additions can be appended to `~/.zshrc` without touching the repo.

## pi (coding agent)

**No pi config is versioned here** — `settings.json`, `models.json`, and
`auth.json` are all machine-local (secrets, machine paths, or auto-generated
data). Set pi up per machine:

1. **Install pi** and sign in so `~/.pi/agent/auth.json` is populated.
2. **Create `~/.pi/agent/settings.json`.** Paths resolve relative to
   `~/.pi/agent`; `~` and absolute paths work. Minimal portable example:

   ```json
   {
     "packages": ["~/dotfiles/pi-agent-board"],
     "theme": "light"
   }
   ```

   The `pi-agent-board` package lives in this repo and is symlinked to
   `~/repo/pi-agent-board` by `install.sh`, so that path is portable.
3. **Add machine-specific packages/models locally**, not in this repo (e.g.
   work-only packages). `refresh-models`-style packages generate
   `~/.pi/agent/models.json`; run them after setup rather than copying models.
4. Optionally set `defaultProvider` / `defaultModel` for your environment.

### Machine-specific notes

Personal paths, all with escape hatches:

- `pim` is vendored at `vendor/pim`; `nvim/init.lua` loads it from
  `~/dotfiles/vendor/pim` (`PIM_PLUGIN_PATH` overrides the board extension's path).
- `~/docs/work` is the work/notes root used by the `Pim*` orchestrator and the
  agent-board skills (`AGENT_BOARD_ROOT` overrides it).

## Requirements

- Neovim 0.10+ (developed on 0.11); a C compiler for treesitter parsers; `git`.
- `ripgrep` + `fd` for `fzf-lua`; a Nerd Font for devicons.
