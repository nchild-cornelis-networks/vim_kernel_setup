#!/bin/bash

# ideally this can be rerun several times to continually regenerate
# ctags/cscope without trying to reinstalls deps
# following https://stackoverflow.com/questions/33676829/vim-configuration-for-linux-kernel-development

if [ $# -lt 1 ]; then
	echo "USAGE: $0 <path_to_kernel>"
	exit 1
fi
KERN=$1

# ensure Vim 8 or more
vim_ver=`rpm -qa |grep vim | grep -oP "vim-\K\d+"`
if [ $vim_ver -lt 8 ]; then
	echo "Need Vim version larger than 8 (found $vim_ver)";
	exit 1
fi

# get package manager
if command -v zypper; then
	pm=zypper
else
	pm=dnf
fi

# install deps
if ( ! rpm -qa | grep -q cscope ) || ( ! rpm -qa | grep -q ctags ); then
	sudo $pm install cscope ctags
fi

# get colors
if ! grep -q TERM= ~/.bashrc ; then
	echo 'export TERM="xterm-256color"' >> ~/.bashrc
fi
if [ ! -f ~/.vimrc ] || ! grep -q t_Co ~/.vimrc ; then 
	echo "set t_Co=256" >> ~/.vimrc
fi

# use absolute paths in cscope
if ! grep -q csre ~/.vimrc ; then 
	echo "set csre" >> ~/vimrc
fi

if ! grep -q t_SI ~/.vimrc ; then
	cat >> ~/.vimrc << EOF
  " use an orange cursor in insert mode
  let &t_SI = "\<Esc>]12;orange\x7"
  " use a red cursor otherwise
  let &t_EI = "\<Esc>]12;red\x7"
  silent !echo -ne "\033]12;red\007"
  " reset cursor when vim exits
  autocmd VimLeave * silent !echo -ne "\033]112\007"
  " use \003]12;gray\007 for gnome-terminal
EOF
fi

# install https://github.com/joe-skb7/cscope-maps
vim_folder=~/.vim/pack/kern
if [ ! -d $vim_folder ]; then
	mkdir -p $vim_folder/start/
	pushd $vim_folder/start/
	echo cloning https://github.com/joe-skb7/cscope-maps.git
	git clone https://github.com/joe-skb7/cscope-maps.git
	popd
fi

# kernel 80 char col limit and trailing spaces
#if [ ! -f ~/.vimrc ] || ! grep -q colorcolumn=81 ~/.vimrc ; then
#cat >> ~/.vimrc<< EOF
#        "80 characters line
#        set colorcolumn=81
#        "execute "set colorcolumn=" . join(range(81,335), ',')
#"       highlight ColorColumn ctermbg=Black ctermfg=DarkRed'
#EOF
	
#fi

# kernel syntax plugin
if [ ! -d ~/.vim/plugin ] || [ ! -f ~/.vim/plugin/linuxsty.vim ]; then
	mkdir -p ~/.vim/plugin
	pushd ~/.vim/plugin/
	curl -o linuxsty.vim  https://www.vim.org/scripts/download_script.php?src_id=23732
	popd
fi

# https://github.com/preservim/nerdtree , see dir tree structure
if [ ! -d $vim_folder/start/nerdtree ]; then
	pushd $vim_folder/start
	git clone git@github.com:preservim/nerdtree.git
	echo "nmap <F5> :NERDTreeToggle<CR>" >> ~/.vimrc
	popd
fi
# https://github.com/preservim/tagbar# , see ctags in file
if [ ! -d $vim_folder/start/tagbar ]; then
        pushd $vim_folder/start
        git clone git@github.com:preservim/tagbar.git
        popd
	echo "nmap <F6> :TagbarToggle<CR>" >> ~/.vimrc
fi

# https://github.com/vim-airline/vim-airline# , better bottom line
if [ ! -d $vim_folder/start/vim-airline ]; then
        pushd $vim_folder/start
        git clone git@github.com:vim-airline/vim-airline.git
        popd
fi

# color theme https://github.com/morhetz/gruvbox
if [ ! -d $vim_folder/start/gruvbox ]; then
	pushd $vim_folder/start
	git clone git@github.com:morhetz/gruvbox.git
	popd
	echo "colorscheme gruvbox" >> ~/.vimrc
	echo "set number" >> ~/.vimrc # sliding line numbers in here
	echo "set bg=dark" >> ~/.vimrc 
fi

# https://github.com/tpope/vim-fugitive , git commands in vim
if [ ! -d $vim_folder/start/vim-fugitive ]; then
	pushd $vim_folder/start
	git clone https://github.com/tpope/vim-fugitive.git
	vim -u NONE -c "helptags fugitive/doc" -c q
	popd
fi
 
# this thing works pretty bad with the kernel tbh, may remove this
# YouCompleteMe Code completion https://github.com/ycm-core/YouCompleteMe?tab=readme-ov-file#linux-64-bit
if [ ! -d $vim_folder/start/YouCompleteMe ] && [ $vim_ver -gt 8 ]; then
	sudo $pm install cmake gcc-c++ make python3-devel
	pushd $vim_folder/start/
	git clone git@github.com:ycm-core/YouCompleteMe.git
	cd YouCompleteMe
	git submodule update --init --recursive
	python3 install.py --clangd-completer
	popd
		
fi
exit 1
echo "Building tags and cscope"
pushd $KERN
# add COMPILED_SOURCE=1 if running on a built kernel to avoid bloat
make  -j  `nproc` cscope
ctags -L cscope.files
popd

