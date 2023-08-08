"""""""""""""""""""""""""""""""""
"" 按键映射
"""""""""""""""""""""""""""""""""
imap jj <ESC>

"""""""""""""""""""""""""""""""""
"" 实用
"""""""""""""""""""""""""""""""""
set nocompatible " 关闭兼容模式

set mouse=a "启用鼠标

set clipboard=unnamed,unnamedplus  " 全局使用系统剪切板

"set ts=4                " 设置tab键长度为四个空格
"set expandtab           " 设置tab键替换为四个空格键

""""""""""""""""""""""""""""""""""
"" 外观
""""""""""""""""""""""""""""""""""
" 行号
set nu
set relativenumber

" 开启 语法高亮
syntax on
" 查找结果 高亮显示
set hlsearch
" 配色方案
"colorscheme desert
" 背景透明
hi Normal ctermfg=252 ctermbg=none
