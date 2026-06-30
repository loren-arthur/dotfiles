# dotfiles

Personal config, symlinked into place via `install.sh`.

## Install

```sh
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` is idempotent and backs up any existing non-symlink target
(e.g. `~/.config/nvim` -> `~/.config/nvim.backup.<timestamp>`).

## What's here

| Path | Symlinked to |
|------|--------------|
| `nvim/` | `~/.config/nvim` |

## Neovim

- Plugin manager: [lazy.nvim](https://github.com/folke/lazy.nvim) (bootstraps itself on first launch).
- `lazy-lock.json` pins exact plugin versions for reproducible installs.
- Highlights: `fzf-lua`, `neo-tree`, `gitsigns` + `diffview`,
  `render-markdown` + `nvim-treesitter`, `todo-comments`, OSC52/system clipboard.

### Machine-specific notes

`nvim/init.lua` references a couple of local paths that won't exist on a
fresh machine — adjust or remove if you're not me:

- `~/repo/pim` — local plugin loaded via `dir = ...`.
- `pi` CLI and `~/docs/work` — used by the `Pim*` orchestrator helpers.

### Requirements

- Neovim 0.10+ (developed on 0.11).
- A C compiler (for treesitter parser builds) and `git`.
- `ripgrep` and `fd` recommended for `fzf-lua`.
- A Nerd Font for `nvim-web-devicons` glyphs.
