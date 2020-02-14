#!/bin/bash

# bash/dot-bash_completion   > ~/.bash_completion
# bash/dot-bash_completion.d > ~/.bash_completion.d
# vim/dot-vim                > ~/.vim
# vim/dot-vimrc              > ~/.vimrc

CHECKOUT_DIR=$(dirname $(pwd)/$0)

red='\e[1;31m'   # bold red
yellow='\e[0;33m'
green='\e[1;32m'
blue='\e[1;34m'
NC='\e[0m'       # no colour

function main {
    install_symlink $HOME/.bash_completion       $CHECKOUT_DIR/bash/dot-bash_completion
    install_symlink $HOME/.bash_completion.d $CHECKOUT_DIR/bash/dot-bash_completion.d
    install_symlink $HOME/.vim   $CHECKOUT_DIR/vim/dot-vim
    install_symlink $HOME/.vimrc $CHECKOUT_DIR/vim/dot-vimrc
}

function install_symlink {
    LINK=$1
    FILE=$2
    (
        test -L $LINK && (
            printf "$red$LINK is already a symlink, leaving it alone$NC\n"
        )
    ) || (
        printf "${green}Create symlink from $LINK to $FILE$NC\n"
        ln -s $FILE $LINK
    )
}

main "$@"
