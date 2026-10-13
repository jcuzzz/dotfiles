" ~/.vimrc - lightweight editor settings, no plugins, no network.
"
" Used by:
"   * Vim (any build), e.g. where Neovim is not installed
"   * the lightweight server Neovim (nvim-lite/.config/nvim/init.lua
"     sources this file), so both editors behave the same
" The workstation Neovim IDE (nvim package) does not read this file.
"
" Safe on vim-tiny / vi: everything that needs +eval sits inside `if 1`,
" which builds without it skip (:help no-eval-feature).
"
" Per-machine additions: ~/.vimrc.local (untracked), sourced at the end.

set nocompatible
set backspace=indent,eol,start
set ruler showcmd
set incsearch hlsearch

if 1
  " ── Basics ────────────────────────────────────────────────────────────
  if has('syntax') && !exists('g:syntax_on')
    syntax enable
  endif
  filetype plugin indent on

  let mapleader = ' '
  let maplocalleader = '\'

  set encoding=utf-8
  set hidden                        " switch buffers without saving first
  set number relativenumber
  set scrolloff=8 sidescrolloff=8
  set nowrap
  set splitright splitbelow
  set ignorecase smartcase          " case-insensitive unless a capital is typed
  set wildmenu wildmode=longest:full,full
  set laststatus=2
  silent! set signcolumn=yes        " Vim 8.1+
  set updatetime=250
  set timeoutlen=400 ttimeoutlen=10 " no lag after <Esc>, also inside tmux
  set confirm                       " ask to save rather than refusing to :q
  set mouse=a
  set autoread
  set noswapfile nobackup
  " ASCII-only, so it renders without a Nerd Font or even a UTF-8 locale
  set list listchars=tab:>\ ,trail:-,nbsp:+
  set shortmess+=I

  " Undo survives closing the file. Neovim keeps its own undodir.
  if has('persistent_undo') && !has('nvim')
    let s:undo = expand('~/.local/state/vim/undo')
    if !isdirectory(s:undo) && exists('*mkdir')
      silent! call mkdir(s:undo, 'p', 0700)
    endif
    let &undodir = s:undo
    set undofile
  endif

  " Colours: Neovim 0.10+ has a good default scheme; elsewhere use habamax
  " (bundled with Vim 9 / Neovim 0.8+) if present, else the terminal default.
  if !has('nvim-0.10')
    set background=dark
    silent! colorscheme habamax
  endif

  " ── Indentation ───────────────────────────────────────────────────────
  " 4 spaces by default; 2 for languages that settled on it; real tabs for
  " Go and Makefiles. Matches the workstation Neovim config.
  set expandtab tabstop=4 shiftwidth=4 softtabstop=4
  set autoindent smartindent
  augroup dotfiles_indent
    autocmd!
    autocmd FileType lua,javascript,typescript,json,jsonc,yaml,html,css,markdown,sql,terraform,hcl
          \ setlocal tabstop=2 shiftwidth=2 softtabstop=2
    autocmd FileType go,make setlocal noexpandtab tabstop=4 shiftwidth=4 softtabstop=0
    " dbt models are SQL with Jinja; treat them as SQL
    autocmd BufRead,BufNewFile */models/*.sql,*/macros/*.sql,*/tests/*.sql setlocal filetype=sql
    autocmd BufRead,BufNewFile *.toml if &filetype ==# '' | setlocal filetype=toml | endif
    autocmd BufRead,BufNewFile .envrc setlocal filetype=sh
  augroup END

  augroup dotfiles_misc
    autocmd!
    " Reopen a file at the last cursor position
    autocmd BufReadPost * if &filetype !~# 'commit\|rebase' && line("'\"") > 0 && line("'\"") <= line('$') | exe 'normal! g`"' | endif
    " Strip trailing whitespace on save, except where it is meaningful
    autocmd BufWritePre * if index(['markdown', 'diff'], &filetype) < 0 | let s:v = winsaveview() | keeppatterns %s/\s\+$//e | call winrestview(s:v) | endif
    autocmd VimResized * wincmd =
  augroup END

  " ── Keymaps (same keys as the workstation config) ─────────────────────
  if has('nvim')
    nnoremap <silent> <Esc> <Cmd>nohlsearch<CR>
  else
    " Mapping a lone <Esc> in Vim breaks arrow keys in some terminals
    nnoremap <silent> <Esc><Esc> :nohlsearch<CR>
  endif
  nnoremap <silent> <leader>w :write<CR>
  nnoremap <silent> <leader>q :quit<CR>
  nnoremap <silent> <leader>Q :qall<CR>
  nnoremap <silent> <leader>- :split<CR>
  nnoremap <silent> <leader>\| :vsplit<CR>
  nnoremap <silent> <S-h> :bprevious<CR>
  nnoremap <silent> <S-l> :bnext<CR>
  nnoremap <silent> <leader>bd :bdelete<CR>
  nnoremap <leader>e :Explore<CR>
  nnoremap <leader>ff :find<Space>
  nnoremap <leader>fb :ls<CR>:buffer<Space>
  nnoremap <C-d> <C-d>zz
  nnoremap <C-u> <C-u>zz
  nnoremap n nzzzv
  nnoremap N Nzzzv
  vnoremap < <gv
  vnoremap > >gv
  xnoremap <leader>p "_dP
  " :find searches below the current directory
  set path+=**
  set wildignore+=*/.git/*,*/node_modules/*,*/__pycache__/*,*/.venv/*,*/target/*

  " ── Ctrl-h/j/k/l: move between splits, and on into tmux panes ─────────
  " Plugin-free version of vim-tmux-navigator: try to move inside the
  " editor; at the edge, ask tmux to move instead. Pairs with the is_vim
  " bindings in ~/.config/tmux/tmux.conf. If the real plugin is installed
  " its mappings take over (checked after plugins load).
  function! s:Navigate(dir) abort
    let l:win = winnr()
    execute 'wincmd ' . a:dir
    if winnr() == l:win && !empty($TMUX)
      let l:pane = {'h': 'L', 'j': 'D', 'k': 'U', 'l': 'R'}[a:dir]
      silent call system('tmux select-pane -' . l:pane)
    endif
  endfunction
  function! s:MapNavigation() abort
    if exists(':TmuxNavigateLeft') == 2
      return
    endif
    for l:d in ['h', 'j', 'k', 'l']
      execute 'nnoremap <silent> <C-' . l:d . '> :call <SID>Navigate("' . l:d . '")<CR>'
    endfor
  endfunction
  augroup dotfiles_nav
    autocmd!
    autocmd VimEnter * call s:MapNavigation()
  augroup END

  " ── Status line (no plugins, no icons) ────────────────────────────────
  set statusline=\ %f%m%r%h%w\ %=%y\ %{&fileencoding?&fileencoding:&encoding}\ %l:%c\ %p%%

  " ── Machine-local overrides ───────────────────────────────────────────
  if filereadable(expand('~/.vimrc.local'))
    execute 'source ' . fnameescape(expand('~/.vimrc.local'))
  endif
endif
