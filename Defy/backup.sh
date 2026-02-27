#!/usr/bin/env bash
# Copies the latest Defy keyboard layer JSON from ~/.config/Defy to this repo as backup.json

set -e
source "$DOTFILES_ROOT/utils/colors"

if [[ -z "${DOTFILES_ROOT:-}" ]]; then
  echo "${CROSSMARK} ${HRED}DOTFILES_ROOT is not set. Source your shell config or run from the repo root.${NC}" >&2
  exit 1
fi

DEFY_CONFIG_DIR="$HOME/.config/Defy/1f0eaf1b9e6e23b0"
DEST="$DOTFILES_ROOT/Defy/backup.json"

printf "${BBLUE}Backing up Defy keyboard layers${NC}\n"

if [[ ! -d "$DEFY_CONFIG_DIR" ]]; then
  printf "${CROSSMARK} ${HRED}Defy config dir not found: %s${NC}\n" "$DEFY_CONFIG_DIR" >&2
  exit 1
fi

# Latest file by name (timestamp is YYYYMMDDHHMMSS at start of filename)
latest=$(find "$DEFY_CONFIG_DIR" -maxdepth 1 -name '*-Defy.json' -type f 2>/dev/null | sort -r | head -n1)

if [[ -z "$latest" ]]; then
  printf "${CROSSMARK} ${HRED}No *-Defy.json files in %s${NC}\n" "$DEFY_CONFIG_DIR" >&2
  exit 1
fi

cp "$latest" "$DEST"
printf "${CHECKMARK} ${HGREEN}Copied %s → Defy/backup.json${NC}\n" "$(basename "$latest")"
