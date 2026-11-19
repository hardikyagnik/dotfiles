#!/usr/bin/env bash
# Copies the latest Defy keyboard layer JSON from ~/.config/Defy to hardware/defy/backup.json

set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/ui.sh
source "$DOTFILES_ROOT/scripts/lib/ui.sh"

DEFY_NEURON_ID="${DEFY_NEURON_ID:-1f0eaf1b9e6e23b0}"
DEFY_CONFIG_DIR="$HOME/.config/Defy/$DEFY_NEURON_ID"
DEST="$DOTFILES_ROOT/hardware/defy/backup.json"

log_section "Backing up Defy keyboard layers"

if [[ ! -d "$DEFY_CONFIG_DIR" ]]; then
  log_err "Defy config dir not found: $DEFY_CONFIG_DIR"
  exit 1
fi

# Latest file by name (timestamp is YYYYMMDDHHMMSS at start of filename)
latest="$(find "$DEFY_CONFIG_DIR" -maxdepth 1 -name '*-Defy.json' -type f 2>/dev/null | sort -r | head -n1)"

if [[ -z "$latest" ]]; then
  log_err "No *-Defy.json files in $DEFY_CONFIG_DIR"
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
cp "$latest" "$DEST"
log_ok "Copied $(basename "$latest") -> hardware/defy/backup.json"
