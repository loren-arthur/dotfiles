-- Loren's Neovim config
-- Active config path: ~/.config/nvim/init.lua

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    dir = vim.fn.expand("~/repo/pim"),
    name = "pim",
    lazy = false,
    config = function()
      require("pim").setup({
        pi_cmd = { "pi", "--mode", "rpc" },
        pane = { width = 80 },
        session = { on_open = "select" },
      })
    end,
  },

  -- Fuzzy finding / vim.ui.select replacement for model + session selectors
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local fzf = require("fzf-lua")
      fzf.setup({})
      fzf.register_ui_select()

      vim.keymap.set("n", "<leader>f", fzf.files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>b", fzf.buffers, { desc = "Buffers" })
      vim.keymap.set("n", "<leader>g", fzf.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>l", fzf.blines, { desc = "Buffer lines" })
      vim.keymap.set("n", "<leader>h", fzf.oldfiles, { desc = "File history" })
    end,
  },

  -- Native Neovim Git integration
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "-" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "+" },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          map("n", "]c", gs.next_hunk, "Next git hunk")
          map("n", "[c", gs.prev_hunk, "Previous git hunk")

          map("n", "<leader>Gp", gs.preview_hunk, "Git preview hunk")
          map("n", "<leader>Gr", gs.reset_hunk, "Git reset hunk")
          map("v", "<leader>Gr", function()
            gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, "Git reset selected hunk")
          map("n", "<leader>Gb", gs.blame_line, "Git blame line")
          map("n", "<leader>Gd", gs.diffthis, "Git diff this file")
        end,
      })
    end,
  },
  -- Treesitter (syntax-aware parsing; required by render-markdown)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "markdown", "markdown_inline", "lua", "vim", "vimdoc",
          "bash", "json", "yaml", "python",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- In-editor markdown rendering
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown" },
    opts = {
      heading = { sign = false },
      code = { sign = false, width = "block" },
      checkbox = {
        unchecked = { icon = "　　" },
        checked = { icon = "　　" },
      },
    },
    keys = {
      { "<leader>m", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle markdown render" },
    },
  },

  -- TODO/FIXME/etc. highlighting and navigation
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    keys = {
      { "<leader>st", "<cmd>TodoFzfLua<CR>", desc = "Search TODOs" },
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous TODO" },
    },
    opts = {
      -- Highlight keywords even outside code comments (e.g. #TODO in docs)
      highlight = {
        comments_only = false,
        pattern = [[(KEYWORDS)]],
      },
      search = {
        pattern = [[\b(KEYWORDS)\b]],
      },
    },
  },

  -- File tree explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file tree" },
      { "<leader>E", "<cmd>Neotree reveal<CR>", desc = "Reveal file in tree" },
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        filesystem = {
          follow_current_file = { enabled = true },
          use_libuv_file_watcher = true,
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
          },
        },
        window = {
          width = 32,
        },
      })
    end,
  },
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>GD", "<cmd>DiffviewOpen<CR>", desc = "Git diff view" },
      { "<leader>GC", "<cmd>DiffviewClose<CR>", desc = "Close git diff view" },
      { "<leader>GH", "<cmd>DiffviewFileHistory %<CR>", desc = "Git file history" },
    },
  },
}, {
  checker = { enabled = false },
  change_detection = { notify = false },
})

-- Basic editor defaults
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.background = "light"

-- Let the terminal theme provide the main background color.
-- This keeps Neovim from painting over Solarized Light / terminal palette backgrounds.
local function use_terminal_background()
  vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "LineNr", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "NONE" })
end

use_terminal_background()

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = use_terminal_background,
})

vim.opt.mouse = "a"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.hidden = true
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.scrolloff = 8
vim.opt.undofile = true

-- Indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Useful basics
-- Markdown: toggle a checkbox on the current line ([ ] <-> [x])
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(ev)
    vim.keymap.set("n", "<leader>x", function()
      local line = vim.api.nvim_get_current_line()
      if line:match("%[ %]") then
        line = line:gsub("%[ %]", "[x]", 1)
      elseif line:match("%[[xX]%]") then
        line = line:gsub("%[[xX]%]", "[ ]", 1)
      end
      vim.api.nvim_set_current_line(line)
    end, { buffer = ev.buf, desc = "Toggle markdown checkbox" })
  end,
})

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Write file" })
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit window" })

-- Clipboard: use the real system clipboard for all yank/paste.
-- Locally (macOS) this uses pbcopy/pbpaste, which Neovim auto-detects.
-- Over SSH (no local clipboard) fall back to OSC52, like vim-oscyank.
vim.opt.clipboard = "unnamedplus"
if vim.env.SSH_TTY and vim.env.SSH_TTY ~= "" then
  vim.g.clipboard = "osc52"
end

-- pim orchestrator
local function pim_agent_board_orchestrator()
  local work_root = vim.fn.expand("~/docs/work")
  local board_path = work_root .. "/agent-board/board.md"
  local prompt = table.concat({
    "You are Loren's pim-backed agent-board orchestrator.",
    "Treat ~/docs/work as the shared workspace.",
    "Start by reading @agent-board/board.md, @agent-board/sessions.json, @agent-board/events.jsonl, @agent-board/alerts.md, and relevant prompt/handoff/task files as needed.",
    "The human and agents both use these files as source of truth.",
    "Help Loren navigate, edit, summarize, and coordinate the board.",
    "Do not assume hidden state; prefer files and buffers.",
  }, " ")

  vim.cmd.chdir(vim.fn.fnameescape(work_root))
  vim.cmd.edit(vim.fn.fnameescape(board_path))

  local pim = require("pim")
  pim.setup({
    pi_cmd = { "pi", "--mode", "rpc", "--name", "orchestrator: agent board" },
    pane = { width = 80 },
  })
  pim.open()
  vim.schedule(function()
    pim.send(prompt)
  end)
end

vim.api.nvim_create_user_command("PimOrchestrator", pim_agent_board_orchestrator, {
  desc = "Open the agent-board file and start pim as Loren's orchestrator",
})

-- pim shortcuts
vim.keymap.set("n", "<leader>pO", pim_agent_board_orchestrator, { desc = "pim: agent-board orchestrator" })
vim.keymap.set("n", "<leader>po", "<cmd>PimOpen<CR>", { desc = "pim: open conversation" })
vim.keymap.set("n", "<leader>pt", "<cmd>PimToggle<CR>", { desc = "pim: toggle conversation" })
vim.keymap.set("n", "<leader>ps", "<cmd>PimSend<CR>", { desc = "pim: send prompt" })
vim.keymap.set("v", "<leader>ps", ":PimSendSelection ", { desc = "pim: send selection" })
vim.keymap.set("n", "<leader>pa", "<cmd>PimAbort<CR>", { desc = "pim: abort" })
vim.keymap.set("n", "<leader>ph", "<cmd>PimTranscript<CR>", { desc = "pim: open transcript" })
