# Starship prompt (reads ~/.config/starship.toml natively)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# FZF key bindings and fuzzy completion
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)

  export FZF_CTRL_R_OPTS="--layout=reverse --height '60%' --border --margin '0,2,0'"
  if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--layout=reverse --height '80%' --border --preview 'bat --color=always --style=numbers --line-range=:500 {} || cat {}'"
  else
    export FZF_CTRL_T_OPTS="--layout=reverse --height '80%' --border --preview 'cat {}'"
  fi
fi
