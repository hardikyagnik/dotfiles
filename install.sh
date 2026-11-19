#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$DOTFILES_ROOT/stow"
BREW_DIR="$DOTFILES_ROOT/brew"
PROFILES_DIR="$DOTFILES_ROOT/profiles"

# shellcheck source=scripts/lib/ui.sh
source "$DOTFILES_ROOT/scripts/lib/ui.sh"

# Defaults
OS="$(uname -s)"
PROFILE=""
STOW_ONLY=false
BREW_ONLY=false
UNSTOW=false
DRY_RUN=false
CUSTOM_PACKAGES=()
CUSTOM_BUNDLES=()
BACKUP_TS="$(date +%Y%m%d%H%M%S)"

usage() {
  cat <<EOF
Usage: ./install.sh [options]

Options:
  --profile <name>          Profile to apply (default: 'mac' on macOS, 'cloud' on Linux)
  --package(s) <p1,p2>      Stow only these packages (skips Brew unless --bundle(s) is also given)
  --bundle(s) <b1,b2>       Install only these Brew bundles (skips Stow unless --package(s) is also given)
  --stow-only               Run only the Stow phase for the active profile
  --brew-only               Run only the Brew phase for the active profile
  --unstow                  Remove symlinks for selected Stow packages
  -n, --dry-run             Preview actions without modifying the system
  --list-profiles           List available profiles and exit
  -h, --help                Show this help message

Examples:
  ./install.sh                              # Full setup for default OS profile (Brew + Stow)
  ./install.sh --profile mac-secondary      # Full setup for secondary Intel MacBook
  ./install.sh --bundle core                # Run only brew/Brewfile.core
  ./install.sh --package zsh                # Restow only stow/zsh
  ./install.sh --unstow --package starship  # Unlink only starship
  ./install.sh --dry-run                    # Preview changes safely
EOF
}

list_profiles() {
  log_section "Available profiles"
  local file name desc
  for file in "$PROFILES_DIR"/*.sh; do
    [[ -f "$file" ]] || continue
    name="$(basename "$file" .sh)"
    desc="$(
      PROFILE_DESC=""
      # shellcheck disable=SC1090
      source "$file"
      printf '%s' "${PROFILE_DESC:-}"
    )"
    printf "  ${BCYAN}%-16s${NC} %s\n" "$name" "$desc"
  done
}

print_banner() {
  printf "${HGREEN}"
  cat <<'EOF'

   _______    ______  .___________. _______  __   __       _______     _______.
  |       \  /  __  \ |           ||   ____||  | |  |     |   ____|   /       |
  |  .--.  ||  |  |  |`---|  |----`|  |__   |  | |  |     |  |__     |   (----`
  |  |  |  ||  |  |  |    |  |     |   __|  |  | |  |     |   __|     \   \
  |  '--'  ||  `--'  |    |  |     |  |     |  | |  `----.|  |____.----)   |
  |_______/  \______/     |__|     |__|     |__| |_______||_______|_______/

--.__.--.__.--.__.--.__.--.__.--.__.--.__.--.__.--.__.--.__.--.__.--.__.--.__.--
EOF
  printf "${NC}\n"
}

load_brew_env() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$candidate" ]]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done
  return 1
}

ensure_xcode_clt() {
  [[ "$OS" == "Darwin" ]] || return 0
  log_section "Checking Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then
    log_ok "Xcode Command Line Tools already installed"
    return 0
  fi
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would install Xcode Command Line Tools (xcode-select --install)"
    return 0
  fi
  log_info "Xcode Command Line Tools not found. Launching installer..."
  xcode-select --install
}

ensure_homebrew() {
  log_section "Checking Homebrew"
  if load_brew_env; then
    log_ok "Homebrew available at $(command -v brew)"
    return 0
  fi

  if [[ "${BREW_OPTIONAL:-false}" == true ]]; then
    log_warn "Homebrew not installed (optional for profile '$PROFILE'); skipping Brew bundles"
    return 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would install Homebrew"
    return 1
  fi

  log_info "Homebrew not found. Installing..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew_env
  log_ok "Homebrew installed"
}

run_brew_bundles() {
  if [[ ${#BREW_BUNDLES[@]} -eq 0 ]]; then
    log_info "No Brew bundles configured for profile '$PROFILE'"
    return 0
  fi

  if ! ensure_homebrew; then
    if [[ "$DRY_RUN" == true ]]; then
      local b
      for b in "${BREW_BUNDLES[@]}"; do
        log_info "[dry-run] Would run: brew bundle --file=$BREW_DIR/Brewfile.$b"
      done
    fi
    return 0
  fi

  log_section "Installing Homebrew bundles"
  local bundle brewfile
  for bundle in "${BREW_BUNDLES[@]}"; do
    brewfile="$BREW_DIR/Brewfile.$bundle"
    if [[ ! -f "$brewfile" ]]; then
      log_err "Brewfile not found: $brewfile"
      exit 1
    fi
    if [[ "$DRY_RUN" == true ]]; then
      log_info "[dry-run] Would run: brew bundle --file=$brewfile"
    else
      log_info "Running Brewfile.$bundle"
      brew bundle --file="$brewfile"
      log_ok "Applied Brewfile.$bundle"
    fi
  done
}

is_ignored_stow_entry() {
  local base="$1"
  case "$base" in
    .DS_Store|README|README.md|.stow-local-ignore|secrets.*|*.local|*.local.*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Back up conflicting real files or clear stale symlinks from older dotfiles layouts
prepare_stow_targets() {
  local pkg="$1"
  local pkg_dir="$STOW_DIR/$pkg"
  local src rel base target link_dest

  while IFS= read -r -d '' src; do
    base="$(basename "$src")"
    if is_ignored_stow_entry "$base"; then
      continue
    fi

    rel="${src#"$pkg_dir"/}"
    target="$HOME/$rel"

    if [[ -L "$target" ]]; then
      # Already points to this exact Stow file
      if [[ "$target" -ef "$src" ]]; then
        continue
      fi

      link_dest="$(readlink "$target")"
      case "$link_dest" in
        "$DOTFILES_ROOT"/*)
          if [[ "$DRY_RUN" == true ]]; then
            log_info "[dry-run] Would remove stale dotfiles symlink: $target -> $link_dest"
          else
            log_warn "Removing stale dotfiles symlink: $target -> $link_dest"
            rm "$target"
          fi
          ;;
        *)
          if [[ "$DRY_RUN" == true ]]; then
            log_info "[dry-run] Would back up existing symlink: $target -> ${target}.backup.${BACKUP_TS}"
          else
            log_warn "Backing up existing symlink: $target -> ${target}.backup.${BACKUP_TS}"
            mv "$target" "${target}.backup.${BACKUP_TS}"
          fi
          ;;
      esac
    elif [[ -e "$target" ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        log_info "[dry-run] Would back up existing file: $target -> ${target}.backup.${BACKUP_TS}"
      else
        log_warn "Backing up existing file: $target -> ${target}.backup.${BACKUP_TS}"
        mv "$target" "${target}.backup.${BACKUP_TS}"
      fi
    fi
  done < <(find "$pkg_dir" \( -type f -o -type l \) -print0)
}

run_stow() {
  if [[ ${#STOW_PACKAGES[@]} -eq 0 ]]; then
    log_info "No Stow packages selected"
    return 0
  fi

  # Ensure brew PATH is loaded if stow was installed via Homebrew
  load_brew_env || true

  local action_label="Stowing"
  local stow_mode="--restow"
  if [[ "$UNSTOW" == true ]]; then
    action_label="Unstowing"
    stow_mode="--delete"
  fi

  log_section "$action_label packages (${STOW_PACKAGES[*]})"

  local has_stow=true
  if ! command -v stow >/dev/null 2>&1; then
    has_stow=false
    if [[ "$DRY_RUN" == false ]]; then
      log_err "GNU Stow not found. Install it first (e.g. 'brew install stow' or 'sudo apt install stow')."
      exit 1
    fi
    log_warn "GNU Stow not found in PATH; showing planned commands only"
  fi

  local stow_args=(
    --dir="$STOW_DIR"
    --target="$HOME"
    --no-folding
    "$stow_mode"
    '--ignore=\.DS_Store$'
    '--ignore=^README(\.md)?$'
    '--ignore=\.local(\..+)?$'
    '--ignore=^secrets\.'
  )

  if [[ "$DRY_RUN" == true ]]; then
    stow_args+=(--simulate --verbose=1)
  fi

  local pkg
  for pkg in "${STOW_PACKAGES[@]}"; do
    if [[ ! -d "$STOW_DIR/$pkg" ]]; then
      log_err "Stow package not found: $STOW_DIR/$pkg"
      exit 1
    fi

    if [[ "$UNSTOW" == false ]]; then
      prepare_stow_targets "$pkg"
    fi

    if [[ "$has_stow" == false ]]; then
      log_info "[dry-run] Would run: stow ${stow_args[*]} $pkg"
      continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
      log_info "[dry-run] Simulating stow for package '$pkg'"
      stow "${stow_args[@]}" "$pkg" || \
        log_warn "[dry-run] Stow reported conflicts for '$pkg' (expected if existing files or stale symlinks above haven't been backed up/removed yet)"
    else
      stow "${stow_args[@]}" "$pkg"
      log_ok "$action_label $pkg"
    fi
  done
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || { log_err "--profile requires a value"; exit 1; }
      PROFILE="$2"
      shift 2
      ;;
    --package|--packages)
      [[ $# -ge 2 ]] || { log_err "$1 requires a comma-separated list"; exit 1; }
      IFS=',' read -r -a CUSTOM_PACKAGES <<< "$2"
      shift 2
      ;;
    --bundle|--bundles)
      [[ $# -ge 2 ]] || { log_err "$1 requires a comma-separated list"; exit 1; }
      IFS=',' read -r -a CUSTOM_BUNDLES <<< "$2"
      shift 2
      ;;
    --stow-only)
      STOW_ONLY=true
      shift
      ;;
    --brew-only)
      BREW_ONLY=true
      shift
      ;;
    --unstow)
      UNSTOW=true
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    --list-profiles)
      list_profiles
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ "$STOW_ONLY" == true && "$BREW_ONLY" == true ]]; then
  log_err "Cannot combine --stow-only and --brew-only"
  exit 1
fi
if [[ "$STOW_ONLY" == true && ${#CUSTOM_BUNDLES[@]} -gt 0 ]]; then
  log_err "Cannot combine --stow-only with --bundle(s)"
  exit 1
fi
if [[ "$BREW_ONLY" == true && ${#CUSTOM_PACKAGES[@]} -gt 0 ]]; then
  log_err "Cannot combine --brew-only with --package(s)"
  exit 1
fi

# Decide which independent phases to run
RUN_BREW=true
RUN_STOW=true
if [[ "$UNSTOW" == true ]]; then
  RUN_BREW=false
elif [[ "$STOW_ONLY" == true ]]; then
  RUN_BREW=false
elif [[ "$BREW_ONLY" == true ]]; then
  RUN_STOW=false
elif [[ ${#CUSTOM_PACKAGES[@]} -gt 0 && ${#CUSTOM_BUNDLES[@]} -eq 0 ]]; then
  RUN_BREW=false
elif [[ ${#CUSTOM_BUNDLES[@]} -gt 0 && ${#CUSTOM_PACKAGES[@]} -eq 0 ]]; then
  RUN_STOW=false
fi

# Resolve default profile by OS
if [[ -z "$PROFILE" ]]; then
  case "$OS" in
    Darwin) PROFILE="mac" ;;
    Linux)  PROFILE="cloud" ;;
    *)      PROFILE="cloud" ;;
  esac
fi

PROFILE_FILE="$PROFILES_DIR/$PROFILE.sh"
if [[ ! -f "$PROFILE_FILE" ]]; then
  log_err "Profile not found: $PROFILE ($PROFILE_FILE)"
  list_profiles
  exit 1
fi

STOW_PACKAGES=()
BREW_BUNDLES=()
BREW_OPTIONAL=false
# shellcheck disable=SC1090
source "$PROFILE_FILE"

if [[ ${#CUSTOM_PACKAGES[@]} -gt 0 ]]; then
  STOW_PACKAGES=("${CUSTOM_PACKAGES[@]}")
fi
if [[ ${#CUSTOM_BUNDLES[@]} -gt 0 ]]; then
  BREW_BUNDLES=("${CUSTOM_BUNDLES[@]}")
fi

print_banner
log_title "Setting up dotfiles..."
log_info "DOTFILES_ROOT: $DOTFILES_ROOT"
if [[ "$DRY_RUN" == true ]]; then
  log_info "OS: $OS | Profile: $PROFILE (dry-run)"
else
  log_info "OS: $OS | Profile: $PROFILE"
fi

if [[ "$UNSTOW" == true ]]; then
  run_stow
  log_ok "Unstow completed!"
  exit 0
fi

if [[ "$RUN_BREW" == true ]]; then
  ensure_xcode_clt
  run_brew_bundles
fi

if [[ "$RUN_STOW" == true ]]; then
  run_stow
fi

printf "\n"
log_ok "Dotfiles setup completed!"
