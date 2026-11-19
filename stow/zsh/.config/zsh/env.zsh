# Dotfiles repo root (derived from stowed ~/.zshrc -> <repo>/stow/zsh/.zshrc)
if [[ -z "${DOTFILES_ROOT:-}" && -L "$HOME/.zshrc" ]]; then
  _dotfiles_candidate="${${:-$HOME/.zshrc}:A:h:h:h}"
  [[ -f "$_dotfiles_candidate/install.sh" ]] && export DOTFILES_ROOT="$_dotfiles_candidate"
  unset _dotfiles_candidate
fi

# Colors
export LSCOLORS="gxBxhxDxfxhxhxhxhxcxcx"
export EZA_COLORS="di=36:ln=31:bold:so=37:pi=33:bold:ex=35:bd=37:cd=37:su=37:sg=37:tw=32:ow=32"

# History
setopt SHARE_HISTORY         # Share history across all open terminals
setopt HIST_IGNORE_ALL_DUPS  # Delete old recorded entry if new entry is a duplicate
setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks
setopt HIST_FCNTL_LOCK       # Use modern system locking for better performance/reliability

SAVEHIST=10000               # Saved to disk (default 1000)
HISTSIZE=10000               # Saved to RAM (default 2000)
