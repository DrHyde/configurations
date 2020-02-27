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
    if [ "$#" == "0" ]; then
        install
    elif [ "$#" == "1" ]; then
        if [ "$1" == "--look-for-updates" ]; then
            look_for_updates
        else
            wtf
        fi
    else
        wtf
    fi
}

function install {
    install_symlink $HOME/.bash_completion       $CHECKOUT_DIR/bash/dot-bash_completion
    install_symlink $HOME/.bash_completion.d $CHECKOUT_DIR/bash/dot-bash_completion.d
    install_symlink $HOME/.vim   $CHECKOUT_DIR/vim/dot-vim
    install_symlink $HOME/.vimrc $CHECKOUT_DIR/vim/dot-vimrc

    grep bash_completion ~/.profile >/dev/null 2>&1 || echo '. $HOME/.bash_completion'  >> ~/.profile
    grep EDITOR          ~/.profile >/dev/null 2>&1 || echo 'export EDITOR=`which vim`' >> ~/.profile

    grep -- --look-for-updates ~/.profile >/dev/null 2>&1 || \
        echo "$CHECKOUT_DIR/install.sh --look-for-updates" >> ~/.profile
}

function wtf {
    echo WTF!?!?!
}

function look_for_updates {
    echo
    echo Looking for updates \(Not yet implemented\)
    echo
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
