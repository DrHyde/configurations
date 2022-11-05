#!/usr/bin/env bash

CHECKOUT_DIR="$( cd "$(dirname "$0")"; pwd -P)"

red='\e[1;31m'   # bold red
yellow='\e[0;33m'
green='\e[1;32m'
blue='\e[1;34m'
NC='\e[0m'       # no colour

TIMEOUT=$(which timeout)
if [ "$(uname)" == "OpenBSD" ]; then
    TIMEOUT=gtimeout
elif [ "$(uname)" == "AIX" ]; then
    TIMEOUT=notimeout
fi

function main {
    if [ "$#" == "0" ]; then
        install
    elif [ "$#" == "1" ]; then
        if [ "$1" == "--look-for-updates" ]; then
            look_for_updates
        elif [ "$1" == "--updateall" ]; then
            for repo in shellscripts perlscripts configurations; do
                ./install.sh --update $repo
            done
            vim -c 'let g:gitsessions_auto_create_sessions=0' -c ':PluginInstall' -c 'qall'
            vim -c 'let g:gitsessions_auto_create_sessions=0' -c ':PluginUpdate' -c 'qall'
        else
            wtf
        fi
    elif [ "$#" == "2" ]; then
        if [ "$1" == "--update" ]; then
            (
                cd $CHECKOUT_DIR/../$2
                git pull
                if [ "$2" == "configurations" ]; then
                    ./install.sh
                    if [ -f "local-post-install.sh" ]; then
                        ./local-post-install.sh
                    fi
                fi
            )
        else
            wtf
        fi
    else
        wtf
    fi
}

function install {
    install_symlink $HOME/.bash_completion       $CHECKOUT_DIR/bash/dot-bash_completion
    install_symlink $HOME/.bash_completion.d     $CHECKOUT_DIR/bash/dot-bash_completion.d
    install_symlink $HOME/.bash_functions        $CHECKOUT_DIR/bash/dot-bash_functions
    install_symlink $HOME/.bash_functions.d      $CHECKOUT_DIR/bash/dot-bash_functions.d
    install_symlink $HOME/.cpandistprefs         $CHECKOUT_DIR/cpandistprefs
    install_symlink $HOME/.parallel              $CHECKOUT_DIR/dot-parallel
    install_symlink $HOME/.perldb                $CHECKOUT_DIR/dot-perldb
    install_symlink $HOME/.treerc                $CHECKOUT_DIR/dot-treerc
    install_symlink $HOME/.screenrc              $CHECKOUT_DIR/dot-screenrc
    install_symlink $HOME/.vim                   $CHECKOUT_DIR/vim/dot-vim
    install_symlink $HOME/.vimrc                 $CHECKOUT_DIR/vim/dot-vimrc
    install_symlink $HOME/.vimrc-basic           $CHECKOUT_DIR/vim/dot-vimrc-basic

    check_vim_plugins

    mkdir $HOME/bin 2>/dev/null
    install_symlink $HOME/bin/lls                $CHECKOUT_DIR/../perlscripts/lls
    install_symlink $HOME/bin/as_check           $CHECKOUT_DIR/../perlscripts/as_check
    install_symlink $HOME/bin/charnames          $CHECKOUT_DIR/../perlscripts/charnames
    install_symlink $HOME/bin/gh-get-issues      $CHECKOUT_DIR/../perlscripts/gh-get-issues
    install_symlink $HOME/bin/git-rmbranch       $CHECKOUT_DIR/../shellscripts/git-rmbranch
    install_symlink $HOME/bin/ffaddsubs          $CHECKOUT_DIR/../shellscripts/ffaddsubs
    install_symlink $HOME/bin/ffverify           $CHECKOUT_DIR/../shellscripts/ffverify
    install_symlink $HOME/bin/fps                $CHECKOUT_DIR/../shellscripts/fps
    install_symlink $HOME/bin/rotator            $CHECKOUT_DIR/../perlscripts/rotator
    install_symlink $HOME/bin/shtimeout          $CHECKOUT_DIR/../shellscripts/shtimeout
    install_symlink $HOME/bin/50-2-25            $CHECKOUT_DIR/../shellscripts/50-2-25
    install_symlink $HOME/bin/bytemark.command   $CHECKOUT_DIR/../shellscripts/bytemark.command
    install_symlink $HOME/bin/duckpond.command   $CHECKOUT_DIR/../shellscripts/duckpond.command
    install_symlink $HOME/bin/get-operavision.sh $CHECKOUT_DIR/../shellscripts/get-operavision.sh
    install_symlink $HOME/bin/get_iplayer_hi.sh  $CHECKOUT_DIR/../shellscripts/get_iplayer_hi.sh
    install_symlink $HOME/bin/git-rmbranch       $CHECKOUT_DIR/../shellscripts/git-rmbranch
    install_symlink $HOME/bin/perlbrew-cron.sh   $CHECKOUT_DIR/../shellscripts/perlbrew-cron.sh
    install_symlink $HOME/bin/phone_notify.pl    $CHECKOUT_DIR/../perlscripts/phone_notify.pl
    install_symlink $HOME/bin/sleep-screen       $CHECKOUT_DIR/../shellscripts/mac-sleep-screen
    install_symlink $HOME/bin/mirror             $CHECKOUT_DIR/../perlscripts/mirror/mirror.pl
    install_symlink $HOME/bin/releasemodule      $CHECKOUT_DIR/../shellscripts/releasemodule

    if [ "$(whoami)" == "dcantrell" ]; then
        # need a slightly different config at work
        cat $CHECKOUT_DIR/dot-gitconfig | sed 's/david@cantrell.org.uk/david.cantrell@broadbean.com/' > $HOME/.gitconfig
    else
        install_symlink $HOME/.gitconfig         $CHECKOUT_DIR/dot-gitconfig
    fi

    which img2sixel >/dev/null 2>&1 && \
        install_symlink $HOME/bin/imgcat         $(which img2sixel)

    which hardlink >/dev/null 2>&1 && (
        if [[ "$(uname)" == "Darwin" ]]; then
            if [ "$(uname -p)" == "i386" ]; then
                install_hardlink /usr/local/share/man/man1/hardlink.1 /usr/local/opt/util-linux/share/man/man1/hardlink.1
            else
                printf "  ${red}ARGH I DON'T KNOW HOW TO LINK$NC\n"
            fi
        fi
    )

    mkdir $HOME/.get_iplayer 2>/dev/null
    install_symlink $HOME/.get_iplayer/options   $CHECKOUT_DIR/get_iplayer/options

    (
        cd "$CHECKOUT_DIR/dot-config"
        [ ! -d "$HOME/.config" ] && mkdir "$HOME/.config"
        for file in $(find . -type f); do
            filename=$(basename $file)
            dirname=$(dirname $(echo $file|sed 's/^..//'))
            [ ! -d "$HOME/.config/$dirname" ] && mkdir -p "$HOME/.config/$dirname"
            if [[ "$filename" == "starship.toml" || "$dirname" == *direnv* ]]; then
                # need to copy this so we don't wake up the disk on every prompt
                copy_if_not_equal $CHECKOUT_DIR/dot-config/$dirname/$filename $HOME/.config/$dirname/$filename
            else
                install_symlink $HOME/.config/$dirname/$filename $CHECKOUT_DIR/dot-config/$dirname/$filename
            fi
            if [[ "$dirname" == "bat/syntaxes" ]]; then
                echo -n "Rebuilding bat cache ... "
                bat cache --build > /dev/null
                echo OK
            fi
        done
    )

    if [[ "$(uname)" == "Darwin" ]]; then
        mkdir $HOME/Library/KeyBindings 2>/dev/null || true
        copy_if_not_equal $CHECKOUT_DIR/karabiner/DefaultKeyBinding.dict $HOME/Library/KeyBindings/DefaultKeyBinding.dict
    fi

    grep perlbrew              ~/.profile >/dev/null 2>&1 || add 'source ~/perl5/perlbrew/etc/bashrc'
    grep bash_completion       ~/.profile >/dev/null 2>&1 || add '. $HOME/.bash_completion'
    grep bash_functions        ~/.profile >/dev/null 2>&1 || add '. $HOME/.bash_functions'
    grep EDITOR                ~/.profile >/dev/null 2>&1 || add 'export EDITOR=`which vim 2>/dev/null || which vi`'
    grep SHELLCHECK_OPTS       ~/.profile >/dev/null 2>&1 || add 'export SHELLCHECK_OPTS=-C'
    grep LESS                  ~/.profile >/dev/null 2>&1 || add 'export LESS=-FRX'
    grep PS1                   ~/.profile >/dev/null 2>&1 || add "export PS1='\\h:\\w \$ '"
    grep FZF_DEFAULT_OPTS      ~/.profile >/dev/null 2>&1 || add_after fzf "export FZF_DEFAULT_OPTS=--no-mouse"
    grep 'shopt -s checkhash'  ~/.profile >/dev/null 2>&1 || add "shopt -s checkhash"

    grep PROMPT_COMMAND        ~/.profile >/dev/null 2>&1 || echo set PROMPT_COMMAND in .profile
    # this must be before direnv, starship etc
    # export PROMPT_COMMAND='echo -ne "\033]0;${HOSTNAME}: $(realpath .)\007"'

    grep QUOTING_STYLE         ~/.profile >/dev/null 2>&1 || add 'export QUOTING_STYLE=literal'
    grep -- --look-for-updates ~/.profile >/dev/null 2>&1 || add "$CHECKOUT_DIR/install.sh --look-for-updates"

    local perlbrew_line=$(grep -n perlbrew ~/.profile |sed 's/:.*//')
    local bash_functions_line=$(grep -n bash_functions ~/.profile |sed 's/:.*//')
    if [ $perlbrew_line -gt $bash_functions_line ]; then
        printf "${red}perlbrew should be loaded before my bash_functions$NC\n"
    fi
    wait
}

function add {
    local add="$1"

    echo "$add" >> ~/.profile
    printf "${green}Added $add to end of .profile${NC}\n"
}

function add_after {
    local lookfor="$1"
    local add="$2"

    cp $HOME/.profile "$HOME/.profile-$lookfor-backup"
    awk "{ print } /$lookfor/ { print \"$add\" }" < ~/.profile > ~/.$$ && \
      mv ~/.$$ ~/.profile && \
      printf "${green}Added $add to .profile after $lookfor$NC\n" &&
      printf "  backup at ~/.profile-$lookfor-backup\n"
}

function wtf {
    printf "${red}WTF!?!?!$NC\n"
}

function notimeout {
    shift
    "$@"
}

function is_repo_up_to_date {
    local repo=$1; shift
    local branch=$1; shift
    local timeout_text=$1; shift
    local out_of_date_text=$1; shift
    local try_text=$1; shift

    cd $repo
    $TIMEOUT 5 git fetch -q origin
    if [ "$?" != "0" ]; then
        echo
        printf "${red}${timeout_text}$NC\n"
        echo
    elif [ "$(git log -1 --pretty=format:%H origin/$BRANCH)" != "$(git log -1 --pretty=format:%H)" ]; then
        echo
        printf "${red}${out_of_date_text}$NC\n"
        printf "  Try:\n    ${green}${try_text}$NC\n"
        echo
    fi
}

function check_vim_plugins {
    (
        cd $HOME/.vim/bundle
        # if we can't find Vundle then we need to pull down the submodule
        if [ ! -e Vundle.vim/autoload ]; then
            git submodule init
            git pull --recurse-submodules
        fi

        for i in $(grep ^Plugin ../../dot-vimrc |awk '{print $2}'|sed "s/^.*\///;s/'.*//"); do
            local DIR=$i
            if [ "$i" == "vim-misc" ]; then
                DIR=xolox-vim-misc
            fi
            if [ ! -e "$DIR" ]; then
                printf "${red}Your $i vim plugin is missing.$NC\n"
                printf "  Try:\n    ${green}vim -c 'let g:gitsessions_auto_create_sessions=0' -c ':PluginInstall' -c 'qall'$NC\n"
            fi

        done

        # now check if any installed modules need updating
        for i in *; do
            (
                if [ "$i" != "Vundle.vim" ]; then
                    local BRANCH=master
                    if [ "$i" == "vim-perl" ]; then
                        BRANCH=dev
                    fi

                    is_repo_up_to_date $i $BRANCH \
                        "Timed out trying to check if vim plugin $i is up to date" \
                        "Your $i vim plugin is out of date" \
                        "vim -c 'let g:gitsessions_auto_create_sessions=0' -c ':PluginUpdate $i' -c 'qall'"
                fi
            ) &
            if [ "$(uname)" == "SunOS" ]; then
                sleep 1
            fi
        done

        wait
    )
}

function look_for_updates {
    cd $CHECKOUT_DIR

    for repo in configurations shellscripts perlscripts; do
        (
            cd $CHECKOUT_DIR/..
            [ ! -d "$repo" ] && git clone git@github.com:DrHyde/$repo.git

            local BRANCH=master

            is_repo_up_to_date $repo $BRANCH \
                "Timed out trying to talk to github to see if your $repo repo is up to date" \
                "Your $repo repo isn\'t the same as Github." \
                "$CHECKOUT_DIR/install.sh --update $repo"
        ) &
    done
    check_vim_plugins &

    wait

    for wanted in rg tldr tree img2sixel hyperfine hardlink fzf ctags ngrok karabiner ; do
        if [[ "$wanted" == "ngrok" && "$(uname)" =~ ^(SunOS|OpenBSD)$ ]]; then
            true
        elif [[ "$wanted" == "karabiner" ]]; then
            if [[ "$(uname)" == "Darwin" ]]; then
                ps auxww|grep -v grep|grep -qi karabiner || \
                printf "${red}Install Karabiner: brew install --cask karabiner-elements$NC\n"
            fi
        elif [[ "$(which $wanted 2>/dev/null)" == "" || "$(which $wanted 2>/dev/null)" == "no $wanted in"* ]]; then
            if [[ "$wanted" == "img2sixel" && "$(uname)" == "Darwin" ]]; then
                printf "${red}Install libsixel:\n  brew install libsixel$NC\n"
            elif [[ "$wanted" == "hardlink" && "$(uname)" == "Darwin" ]]; then
                printf "${red}Install util-linux then link the 'hardlink' binary and manpage:\n"
                printf "  brew install util-linux\n"
                printf "  ${CHECKOUT_DIR}/install.sh\n"
                if [ "$(uname -p)" == "i386" ]; then
                    printf "  (cd /usr/local; ln -s ../opt/util-linux/bin/hardlink bin/hardlink)"
                else
                    printf "  ARGH I DON'T KNOW HOW TO LINK"
                fi
                printf "$NC\n"
                printf "  yes, that's util-linux, on a Mac"
            else
                printf "${red}Install '$wanted'$NC\n"
            fi
        elif [ "$wanted" == "fzf" ]; then
            grep fzf $HOME/.profile >/dev/null 2>&1 || \
              printf "${red}Install fzf keybindings in .profile (probably run /usr/local/opt/fzf/install)$NC\n"
        fi
    done
    echo

    if [ "$(grep HOME/.bashrc $HOME/.profile)" == "" ]; then
        printf "${red}.profile needs to source .bashrc thus: $NC\n"
        cat << 'SOURCE_BASHRC_SNIPPET'
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
SOURCE_BASHRC_SNIPPET
        echo
    fi

    if [ "$(grep bash_functions $HOME/.profile)" == "" ]; then
        printf "${red}.profile needs to source bash functions, run install.sh$NC\n";
    fi
    if [ $( $SHELL -c 'echo $BASH_VERSINFO' ) -lt 5 ]; then
        printf "${red}Consider upgrading to bash 5$NC\n"
    fi
}

function install_symlink {
    LINK=$1
    FILE=$2
    (
        test -L $LINK
    ) || (
        test -e $LINK && (
            printf "$red$LINK already exists but isn't a symlink, leaving it alone$NC\n"
        )
    ) || (
        printf "${green}Create symlink from $LINK to $FILE$NC\n"
        ln -s $FILE $LINK
    )
}

function install_hardlink {
    NEW=$1
    SOURCE=$2

    source_inode=$(stat -f %i "$SOURCE" 2>/dev/null)
    new_inode=$(stat -f %i "$NEW" 2>/dev/null)
    if [[ "$new_inode" == "" ]]; then
        printf "${green}Create hard link from $SOURCE to $NEW$NC\n"
        ln "$SOURCE" "$NEW"
    elif [[ "$new_inode" != "$source_inode" ]]; then
        printf "${green}Delete incorrect $NEW$NC\n"
        rm "$NEW"
        printf "${green}Create hard link from $SOURCE to $NEW$NC\n"
        ln "$SOURCE" "$NEW"
    fi
}

function copy_if_not_equal {
    SOURCE=$1
    TARGET=$2
    if [[ "$(cksum $SOURCE|awk '{print $1}')" == "$((cksum $TARGET|awk '{print $1}') 2>/dev/null)" ]]; then
        true
    else
        printf "${red}Updating $TARGET\n  from $SOURCE$NC\n"
        cp $SOURCE $TARGET
    fi
}

if [ "$UID" != "0" ]; then
    main "$@"
fi
