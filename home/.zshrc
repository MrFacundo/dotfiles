# Fix for something. Expands to nothing a pattern that matches nothing.
setopt null_glob

# ---- Key bindings----
bindkey '^Z' undo

# ---- Oh My Zsh configuration ----
export ZSH="$HOME/.oh-my-zsh"

# ---- Oh My Zsh plugins ----
plugins=(
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
    you-should-use
)

source $ZSH/oh-my-zsh.sh

# ---- Language environment ----
# export LANG=en_US.UTF-8

# ---- Compilation flags ----
# export ARCHFLAGS="-arch x86_64"

# ---- Custom PATH additions ----
export PATH="$HOME/.rvm/gems/ruby-3.4.1/bin:$HOME/.rvm/bin:$PATH"
export PATH="$PATH:$HOME/.spicetify"
export PATH="$PATH:$HOME/.local/share/gem/ruby/3.0.0/bin"
export PATH="$PATH:$HOME/.gem/bin"
export PATH="$PATH:$HOME/.gem/ruby/3.3.0/bin"
export PATH="$PATH:/usr/bin/code"
export PATH="$PATH:/home/facu/.local/bin"

# ---- NVM (Node Version Manager) ----
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ---- RVM (Ruby Version Manager) ----
export GEM_PATH="$GEM_HOME"
export PATH="$PATH:$GEM_HOME/bin"

# ---- QT Platform Theme ----
export QT_QPA_PLATFORMTHEME=qt5ct

# ---- FZF configuration ----
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}


# --- List directory contents on cd ---

chpwd() {
  l
}

# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"

# ---- Editor configuration ----
export EDITOR="nvim"
export VISUAL="nvim"
export MOZ_ENABLE_WAYLAND=1


# ---- Starship prompt configuration ----
eval "$(starship init zsh)"

