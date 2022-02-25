#!bash

# this takes a multi-line string on the cmd line and merges my default
# starship config plus the contents of that string, with the string
# taking precedence, writes the results to a temp file, and sets
# STARSHIP_CONFIG to the temp file. Use it in .envrc thus:
#   extra-starship '
#     [nodejs]
#     somevariable = "fish"
#   '

extra-starship() {
    export STARSHIP_CONFIG=$(mktemp)
    toml-merge ~/.config/starship.toml <(echo "$1"|sed 's/^[[:space:]]*//') >$STARSHIP_CONFIG
}
