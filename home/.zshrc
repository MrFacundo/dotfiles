# ---- Powerlevel10k instant prompt ----
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---- Oh My Zsh configuration ----
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# ---- Oh My Zsh plugins ----
# git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
# git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $ZSH_CUSTOM/plugins/you-should-use
plugins=(
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
    you-should-use
)

source $ZSH/oh-my-zsh.sh

# ---- User configuration ----

# ---- Language environment ----
# export LANG=en_US.UTF-8

# ---- Preferred editor for local and remote sessions ----
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# ---- Compilation flags ----
# export ARCHFLAGS="-arch x86_64"

# ---- Powerlevel10k prompt configuration ----
# git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ---- Custom PATH additions ----
export PATH="/home/facu/.rvm/gems/ruby-3.4.1/bin:$HOME/.rvm/bin:$PATH"
export PATH="$PATH:/home/facu/.spicetify"
export PATH="$PATH:$HOME/.local/share/gem/ruby/3.0.0/bin"
export PATH="$PATH:/home/facu/.gem/bin"
export PATH="$PATH:/home/facu/.gem/ruby/3.3.0/bin"
export PATH="$PATH:/usr/bin/code"

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

# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"

# ---- Editor configuration ----
export EDITOR="code --wait"
export VISUAL="vim"
export MOZ_ENABLE_WAYLAND=1
