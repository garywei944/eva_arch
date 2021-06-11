" General
set nocompatible
syntax on
set showmode
set showcmd
set mouse=a
set encoding=utf-8
set t_Co=256
filetype plugin indent on

" Indent
set autoindent
set tabstop=4
set shiftwidth=4
set noexpandtab
set softtabstop=4

" Appearance
set number
set relativenumber
set textwidth=80
set nowrap
set linebreak
set wrapmargin=2
set scrolloff=5
set sidescrolloff=15
set laststatus=2
set ruler
set colorcolumn=80
set cursorline

" Search
set showmatch
set hlsearch
set incsearch
set ignorecase
set smartcase

" Edit
set spell spelllang=en_us
set nobackup
set noswapfile
set undofile
set backupdir=~/.vim/.backup//
set directory=~/.vim/.swp//
set undodir=~/.vim/.undo//
set autochdir
set noerrorbells
set visualbell
set history=1000
set autoread
set listchars=tab:»■,trail:■
set list
set wildmenu
set wildmode=longest:list,full

" Theme
set termguicolors
color tender
highlight Normal guibg=#000001
highlight Visual guibg=#323232
highlight StatusLine guibg=#444444 guifg=#b3deef
highlight StatusLineTerm guibg=#444444 guifg=#b3deef
highlight StatusLineTermNC guibg=#444444 guifg=#999999

" Keymap
nnoremap <silent> <leader>e :NERDTreeToggle<cr>
nnoremap <silent> <leader>f :NERDTreeFind<cr>
nnoremap <silent> <c-p> :call fzf#Open()<cr>
nnoremap <silent> <c-u> :Mru<cr>
