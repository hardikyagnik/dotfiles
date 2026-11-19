# Dotfiles manager
if [[ -n "${DOTFILES_ROOT:-}" && -x "$DOTFILES_ROOT/install.sh" ]]; then
  alias dot='"$DOTFILES_ROOT/install.sh"'
fi

# File listing (guarded so minimal/remote machines don't break if eza isn't installed)
if command -v eza >/dev/null 2>&1; then
  alias ls="eza"
  alias la="eza -a --icons --group-directories-last"
  alias ll="eza -al --icons --group-directories-last --git"
else
  alias la="ls -A"
  alias ll="ls -alh"
fi
