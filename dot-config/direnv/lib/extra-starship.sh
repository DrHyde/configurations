#!bash

# this takes a filename on the cmd line and merges my default
# starship config plus the contents of that file, with the file
# taking precedence, writes the results to a temp file, and sets
# STARSHIP_CONFIG to the temp file. Use it in .envrc thus:
#   extra-starship <(cat <<- EOF
#     [nodejs]
#     disabled="foish"
#   EOF)
# and NB that it's PICKY about whitespace

extra-starship() {
    export STARSHIP_CONFIG=$(mktemp)
    toml-merge ~/.config/starship.toml $1 >$STARSHIP_CONFIG
}
