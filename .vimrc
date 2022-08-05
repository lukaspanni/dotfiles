syntax on
set ruler
set number
set numberwidth=3

let mapleader = ','

call plug#begin('~/.local/share/nvim/site/plugged')
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ryanoasis/vim-devicons'
Plug 'vwxyutarooo/nerdtree-devicons-syntax'
Plug 'sainnhe/gruvbox-material'

call plug#end()

nnoremap <leader>n :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif


colorscheme gruvbox-material

set guifont=CaskaydiaCove\ NerdFont:h12
