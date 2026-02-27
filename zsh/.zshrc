## PATHS
export DOTFILES_ROOT="$(dirname "$(dirname "$(realpath ${(%):-%N})")")"
ZSH_DIR=$DOTFILES_ROOT/zsh

## Variables
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx
export EZA_COLORS='di=36:ln=31:bold:so=37:pi=33:bold:ex=35:bd=37:cd=37:su=37:sg=37:tw=32:ow=32'

## Starship Prompt
eval "$(starship init zsh)"

export STARSHIP_CONFIG=$ZSH_DIR/starship.toml

# History Config
setopt SHARE_HISTORY         # Share history across all open terminals
setopt HIST_IGNORE_ALL_DUPS  # Delete old recorded entry if new entry is a duplicate
setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks
setopt HIST_FCNTL_LOCK       # Use modern system locking for better performance/reliability

SAVEHIST=10000  # Saved to Disk (default 1000)
HISTSIZE=10000  # Saved to RAM (default 2000)

## Load Aliases
source $ZSH_DIR/.aliases

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
