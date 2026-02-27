#!/usr/bin/env bash

printf "${BBLUE}Running brew bundle${NC}"
brew bundle --file=$DOTFILES_ROOT/install/Brewfile
brew bundle --file=$DOTFILES_ROOT/install/Caskfile
