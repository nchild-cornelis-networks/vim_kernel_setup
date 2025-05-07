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

exit 1
echo "Building tags and cscope"
pushd $KERN
# add COMPILED_SOURCE=1 if running on a built kernel to avoid bloat
make  -j  `nproc` cscope
ctags -L cscope.files
popd

