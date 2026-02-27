#!/usr/bin/env bash

set -e 
source $DOTFILES_ROOT/utils/link
source $DOTFILES_ROOT/utils/colors

for dir in "$DOTFILES_ROOT"/*; do

  # Skip following dirs
  basename=$(basename "$dir")
  case "$basename" in
    utils|.git|setup)
      continue
      ;;
  esac

  # Run all the setup.sh scripts  
  if [ -d "$dir" ]; then
    setup_script="$dir/setup.sh"
    if [ -f "$setup_script" ]; then
      # echo "⚙️ Setting up $basename"
      printf "⚙️${BBLUE} Setting up $basename${NC}"
      source "$setup_script"
      printf ""
    fi
  fi
done
