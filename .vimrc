" Enable syntax highlighting
syntax on

" Show line numbers
set number

" Enable relative line numbers (optional)
" set relativenumber

" Enable auto-indentation and smart indentation
set autoindent
set smartindent

" Tab and indentation settings
set tabstop=4       " Number of spaces that a <Tab> counts for
set shiftwidth=4    " Size of an indentation
set expandtab       " Convert tabs to spaces

" Enable mouse support (optional)
set mouse=a

" Highlight the current line (optional)
set cursorline

" Set encoding (optional)
set encoding=utf-8


" Initialize plugin system
call plug#begin('~/.vim/plugged')

" File Explorer
Plug 'preservim/nerdtree'

" Code Completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Syntax Checking and Linting
Plug 'dense-analysis/ale'

call plug#end()

" NERDTree settings
" Start NERDTree, unless a file or session is specified, eg. vim -S session_file.vim.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') && v:this_session == '' | NERDTree | endif
