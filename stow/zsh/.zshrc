# XDG config base
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
ZSH_CONFIG_DIR="$XDG_CONFIG_HOME/zsh"

# Core modules
for _zsh_mod in env aliases tools; do
  [[ -r "$ZSH_CONFIG_DIR/${_zsh_mod}.zsh" ]] && source "$ZSH_CONFIG_DIR/${_zsh_mod}.zsh"
done
unset _zsh_mod

# Drop-in module snippets (e.g. from future stow packages like agents, ssh, network)
if [[ -d "$ZSH_CONFIG_DIR/conf.d" ]]; then
  for _zsh_conf in "$ZSH_CONFIG_DIR/conf.d"/*.zsh(N); do
    [[ -r "$_zsh_conf" ]] && source "$_zsh_conf"
  done
  unset _zsh_conf
fi

# Machine-local overrides & secrets (kept outside git)
[[ -r "$ZSH_CONFIG_DIR/local.zsh" ]] && source "$ZSH_CONFIG_DIR/local.zsh"
[[ -r "$ZSH_CONFIG_DIR/secrets.zsh" ]] && source "$ZSH_CONFIG_DIR/secrets.zsh"
