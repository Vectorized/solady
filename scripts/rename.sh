#!/usr/bin/env bash

# Make sed command compatible in both Mac and Linux environments
# Reference: https://stackoverflow.com/a/38595160/8696958
sedi () {
    sed --version >/dev/null 2>&1 && sed -i -- "$@" || sed -i "" "$@"
}

# Read the new repo name
echo Enter your new repo name:
read repo

# Rename instances of "femplate" to the new repo name in README.md
sedi 's/femplate/'${repo}'/g' 'README.md'
sedi 's/.'${repo}'..https:\/\/github.com\/abigger87\/'${repo}'./[femplate](https:\/\/github.com\/abigger87\/femplate)/g' 'README.md'
