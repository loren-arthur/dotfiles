" Loren's Vim Configuration
" Generated with baseline settings

" ============================================================================
" Vim-Plug Plugin Manager
" ============================================================================
" Install vim-plug if not already installed
" Run: curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"
" After installing plugins, run :PlugInstall

" Disable polyglot's TypeScript handling to avoid conflict with coc-tsserver
let g:polyglot_disabled = ['typescript', 'typescriptreact']

call plug#begin('~/.vim/plugged')

" File navigation and fuzzy finding
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Git integration
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'

" GitHub PR review
Plug 'ashot/vim-pr-comments'

" OSC 52 clipboard support (works over SSH)
Plug 'ojroques/vim-oscyank'

" Status line
Plug 'itchyny/lightline.vim'

" Code intelligence and LSP
" Disabled - Claude Code does the heavy lifting now!
" Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Editing enhancements
Plug 'tpope/vim-commentary'        " Toggle comments with gcc
Plug 'tpope/vim-surround'          " Change/delete/add surroundings
Plug 'tpope/vim-repeat'            " Make . work with plugin actions
Plug 'jiangmiao/auto-pairs'        " Auto-insert closing brackets/quotes

" Syntax highlighting
Plug 'sheerun/vim-polyglot'

" Personal wiki
Plug 'vimwiki/vimwiki'

" Color scheme
" Plug 'altercation/vim-colors-solarized'

call plug#end()

" Auto-install plugins on first launch
if empty(glob('~/.vim/plugged'))
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" ============================================================================
" Display Settings
" ============================================================================
syntax on                      " Enable syntax highlighting
set number                     " Show line numbers
set relativenumber             " Show relative line numbers for easier navigation
set cursorline                 " Highlight the current line

" ============================================================================
" Indentation Settings
" ============================================================================
set expandtab                  " Convert tabs to spaces
set tabstop=4                  " Tab width is 4 spaces
set shiftwidth=4               " Indent width is 4 spaces
set softtabstop=4              " Backspace removes 4 spaces

" ============================================================================
" Auto-Indentation
" ============================================================================
set autoindent                 " Copy indent from current line when starting new line
set smartindent                " Smart autoindenting for C-like languages

" ============================================================================
" Search Settings
" ============================================================================
set hlsearch                   " Highlight all search matches
set incsearch                  " Show matches as you type
set ignorecase                 " Case-insensitive search
set smartcase                  " Case-sensitive if search contains uppercase

" ============================================================================
" UI Enhancements
" ============================================================================
set laststatus=2               " Always show status line
set ruler                      " Show line and column number in status line
set wildmenu                   " Visual autocomplete for command menu
set wildmode=longest:full,full " Command completion behavior
set showcmd                    " Show incomplete commands in bottom right

" ============================================================================
" File Handling
" ============================================================================
set nobackup                   " Don't create backup files
set noswapfile                 " Don't create swap files

" ============================================================================
" Auto-reload Files
" ============================================================================
set autoread                   " Automatically reload files changed outside vim
" Trigger autoread when changing buffers or gaining focus (works with tmux focus-events)
autocmd FocusGained,BufEnter * checktime

" Auto-detect paste via bracketed paste (no manual :set paste needed)
if &term =~ 'xterm\|tmux\|screen'
  let &t_BE = "\e[?2004h"
  let &t_BD = "\e[?2004l"
  exec "set t_PS=\e[200~ t_PE=\e[201~"
endif

" ============================================================================
" Persistent Undo
" ============================================================================
set undofile                   " Enable persistent undo
set undodir=~/.vim/undo        " Store undo files in this directory
" Create undo directory if it doesn't exist
if !isdirectory(expand('~/.vim/undo'))
    call mkdir(expand('~/.vim/undo'), 'p')
endif

" ============================================================================
" Clipboard Integration
" ============================================================================
" Don't use system clipboard in normal mode (only visual mode)
" set clipboard=unnamed

" ============================================================================
" Editing Behavior
" ============================================================================
set backspace=indent,eol,start " Allow backspace over everything in insert mode
set showmatch                  " Briefly highlight matching brackets
set hidden                     " Allow switching buffers without saving

" ============================================================================
" Key Mappings
" ============================================================================
" Set Space as leader key
let mapleader = " "

" Quick save with leader+w
nnoremap <leader>w :w<CR>

" Quick quit with leader+q
nnoremap <leader>q :q<CR>

" Clear search highlighting with leader+/
nnoremap <leader>/ :nohlsearch<CR>

" ============================================================================
" Color Scheme
" ============================================================================
" Using terminal colorscheme - no vim colorscheme set

" ============================================================================
" CoC Inlay Hint Colors - DISABLED
" ============================================================================
" " Make inlay hints look like inserted annotations with subtle background
" " Using blue to match comment color with very light gray background
" highlight CocInlayHint ctermfg=blue ctermbg=254 guifg=Blue guibg=#e4e4e4

" ============================================================================
" FZF Configuration
" ============================================================================
" FZF keybindings
nnoremap <leader>f :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <leader>l :Lines<CR>
nnoremap <leader>h :History<CR>

" FZF layout
let g:fzf_layout = { 'down': '40%' }

" ============================================================================
" Lightline Configuration
" ============================================================================
" Custom lightline colors with softer palette
let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}

" Normal mode - green matching tmux with light gray background
let s:p.normal.left = [ [ '#000000', '#00ff00', 0, 10 ], [ '#808080', '#e4e4e4', 244, 254 ] ]
let s:p.normal.middle = [ [ '#808080', '#e4e4e4', 244, 254 ] ]
let s:p.normal.right = [ [ '#000000', '#00ff00', 0, 10 ], [ '#808080', '#e4e4e4', 244, 254 ] ]

" Insert mode - softer blue
let s:p.insert.left = [ [ '#000000', '#00ffff', 0, 14 ], [ '#808080', '#e4e4e4', 244, 254 ] ]
let s:p.insert.right = [ [ '#000000', '#00ffff', 0, 14 ], [ '#808080', '#e4e4e4', 244, 254 ] ]

" Visual mode - softer yellow
let s:p.visual.left = [ [ '#000000', '#ffff00', 0, 11 ], [ '#808080', '#e4e4e4', 244, 254 ] ]
let s:p.visual.right = [ [ '#000000', '#ffff00', 0, 11 ], [ '#808080', '#e4e4e4', 244, 254 ] ]

" Replace mode - red
let s:p.replace.left = [ [ '#ffffff', '#ff0000', 15, 9 ], [ '#808080', '#e4e4e4', 244, 254 ] ]
let s:p.replace.right = [ [ '#ffffff', '#ff0000', 15, 9 ], [ '#808080', '#e4e4e4', 244, 254 ] ]

" Inactive windows
let s:p.inactive.left = [ [ '#808080', '#e4e4e4', 244, 254 ], [ '#808080', '#e4e4e4', 244, 254 ] ]
let s:p.inactive.middle = [ [ '#808080', '#e4e4e4', 244, 254 ] ]
let s:p.inactive.right = [ [ '#808080', '#e4e4e4', 244, 254 ], [ '#808080', '#e4e4e4', 244, 254 ] ]

let g:lightline = {
      \ 'colorscheme': 'custom',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'readonly', 'filename', 'modified' ] ],
      \   'right': [ [ 'lineinfo' ],
      \              [ 'percent' ],
      \              [ 'fileformat', 'fileencoding', 'filetype' ] ]
      \ },
      \ }

" Register custom colorscheme
let g:lightline#colorscheme#custom#palette = s:p

" ============================================================================
" Vim-Signify Configuration
" ============================================================================
" Update signs faster (but not too fast to avoid tsserver overload)
set updatetime=300

" Sign column symbols
let g:signify_sign_add               = '+'
let g:signify_sign_delete            = '-'
let g:signify_sign_delete_first_line = '‾'
let g:signify_sign_change            = '~'

" ============================================================================
" CoC.nvim Configuration - DISABLED (Claude Code does this now!)
" ============================================================================
" " CoC extensions to auto-install
" " Note: Python uses ty (Astral's LSP) configured via coc-settings.json
" let g:coc_global_extensions = [
"   \ 'coc-json',
"   \ 'coc-tsserver',
"   \ 'coc-eslint',
"   \ 'coc-prettier',
"   \ ]
"
" " Use tab for trigger completion and navigate to next complete item
" inoremap <silent><expr> <TAB>
"       \ coc#pum#visible() ? coc#pum#next(1) :
"       \ CheckBackspace() ? "\<Tab>" :
"       \ coc#refresh()
" inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
"
" " Make <CR> to accept selected completion item
" inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
"                               \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
"
" function! CheckBackspace() abort
"   let col = col('.') - 1
"   return !col || getline('.')[col - 1]  =~# '\s'
" endfunction
"
" " Use <C-n> to trigger completion (your preferred key)
" inoremap <silent><expr> <c-n> coc#refresh()
"
" " GoTo code navigation
" nmap <silent> gd <Plug>(coc-definition)
" nmap <silent> gy <Plug>(coc-type-definition)
" nmap <silent> gi <Plug>(coc-implementation)
" nmap <silent> gr <Plug>(coc-references)
"
" " Use K to show documentation in preview window
" nnoremap <silent> K :call ShowDocumentation()<CR>
"
" function! ShowDocumentation()
"   if CocAction('hasProvider', 'hover')
"     call CocActionAsync('doHover')
"   else
"     call feedkeys('K', 'in')
"   endif
" endfunction
"
" " Highlight symbol under cursor on CursorHold (skip TypeScript due to JSX confusion)
" autocmd CursorHold * silent if index(['typescript', 'typescriptreact'], &filetype) < 0 && CocHasProvider('documentHighlight') | call CocActionAsync('highlight') | endif
"
" " Rename symbol
" nmap <leader>rn <Plug>(coc-rename)
"
" " Format selected code
" xmap <leader>cf  <Plug>(coc-format-selected)
" nmap <leader>cf  <Plug>(coc-format-selected)
"
" " Symbol search
" nnoremap <silent> <leader>s :CocList symbols<CR>
" nnoremap <silent> <leader>o :CocList outline<CR>
"
" " Code actions (quick fixes, refactorings, etc.)
" nmap <leader>a <Plug>(coc-codeaction-cursor)
" xmap <leader>a <Plug>(coc-codeaction-selected)
"
" " Navigate diagnostics
" nmap <silent> [g <Plug>(coc-diagnostic-prev)
" nmap <silent> ]g <Plug>(coc-diagnostic-next)
"
" " Show all CoC commands
" nnoremap <silent> <leader>c :CocList commands<CR>
"
" " Show diagnostic error messages
" nnoremap <silent> <leader>d :CocDiagnostics<CR>
"
" " Customize virtual text colors for diagnostics
" highlight CocErrorVirtualText ctermfg=Black ctermbg=Red guifg=#ff5555
" highlight CocWarningVirtualText ctermfg=Black ctermbg=Yellow guifg=#ffff00
" highlight CocInfoVirtualText ctermfg=Black ctermbg=Blue guifg=#5555ff
" highlight CocHintVirtualText ctermfg=Black ctermbg=Cyan guifg=#55ffff

" In visual mode, y yanks to system clipboard (+ register)
vnoremap y "+y

" ============================================================================
" Vimwiki Configuration
" ============================================================================
let g:vimwiki_list = [{'path': '~/vimwiki/',
                      \ 'syntax': 'markdown',
                      \ 'ext': '.md'}]

" ============================================================================
" Diff & Split Colors (light background friendly)
" ============================================================================
highlight DiffAdd    ctermbg=194 ctermfg=Black guibg=#d7ffd7 guifg=Black  " light green
highlight DiffChange ctermbg=254 ctermfg=Black guibg=#e4e4e4 guifg=Black  " light gray
highlight DiffDelete ctermbg=224 ctermfg=Black guibg=#ffd7d7 guifg=Black  " light pink
highlight DiffText   ctermbg=229 ctermfg=Black guibg=#ffffd7 guifg=Black  " light yellow
highlight Folded     ctermbg=254 ctermfg=Black guibg=#e4e4e4 guifg=Black  " folded lines
highlight FoldColumn ctermbg=255 ctermfg=Black guibg=#eeeeee guifg=Black  " fold column
highlight VertSplit  ctermbg=255 ctermfg=240  guibg=#eeeeee guifg=#585858  " window divider
highlight StatusLine ctermbg=254 ctermfg=Black guibg=#e4e4e4 guifg=Black  " active status
highlight StatusLineNC ctermbg=255 ctermfg=244 guibg=#eeeeee guifg=#808080 " inactive status

" ============================================================================
" Agent Workflow Plugin
" ============================================================================
set runtimepath+=/Users/loren.arthur/repo/agent-workflow/vim

" Side-by-side diff of current file against target (not in plugin)
function! AppriseSideBySide()
  let l:target = trim(system('git config --get appraise.target'))
  if empty(l:target)
    let l:target = 'main'
  endif
  let l:file = expand('%')

  diffthis
  vnew
  setlocal buftype=nofile bufhidden=wipe
  silent file [target]
  execute 'silent r !git show ' . shellescape(l:target . ':' . l:file)
  normal ggdd
  setlocal nomodifiable
  diffthis
  wincmd p
  echo l:file . " vs " . l:target
endfunction

function! AppriseSideBySideOff()
  diffoff!
  only
endfunction

nnoremap <leader>rs :call AppriseSideBySide()<CR>
nnoremap <leader>ro :call AppriseSideBySideOff()<CR>
