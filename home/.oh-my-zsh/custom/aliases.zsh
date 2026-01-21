# git
alias g='git'
alias gcl='git clone'
alias ga='git add .'
alias gc='git commit -m'
alias gcb='git checkout -b'
alias glo="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
alias grs='git restore'
alias gs='git status --short --branch'
alias gpl='git pull'
alias gps='git push'
alias gco='git checkout'
alias gfe='git fetch'
alias lg='lazygit'
alias ghr='(LC_ALL=en_US.UTF-8 firefox "https://github.com/MrFacundo?tab=repositories" > /dev/null 2>&1 &) & disown'

# other
alias pngtojpg='magick mogrify  -format jpg -background white -alpha remove -alpha off *.png'
alias c='code'
alias l='eza -1 --icons=always --group-directories-first'
alias ls='eza -la --no-user --group-directories-first'
alias lt='eza -F -T --level=3 --color=always --icons=always --group-directories-first'
alias cd="z"
alias ccss='sudo chown -R $(whoami) "$(which code)" && sudo chown -R $(whoami) /opt/visual-studio-code'
alias krestart='killall plasmashell 2>/dev/null; kstart plasmashell'
alias p="python"
alias pacman="sudo pacman"
alias apt='sudo apt'
alias v="nvim"
if command -v bat &>/dev/null; then
  alias cat='bat --wrap auto -n -P'
elif command -v batcat &>/dev/null; then
  alias cat='batcat --wrap auto -n -P'
fi
alias dot='cd ~/dotfiles/ && gs'
alias dev='npm run dev'
alias wttr='curl wttr.in/Lisbon'
alias src='source ~/.zshrc'
alias ytl='nohup konsole --layout /home/facu/dotfiles/home/.config/konsole/layout.json >/dev/null 2>&1 & disown && exit'
alias glow='glow -p'

# suffix
alias -s md="glow"
