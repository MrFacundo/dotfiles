#git
alias gcl='git clone'
alias ga='git add .'
alias gc='git commit -m'
alias gcb='git checkout -b'
alias gst='git status'
alias pull='git pull'
alias push='git push'
alias pullb='git pull origin "$(git_current_branch)"'
alias pushb='git push origin "$(git_current_branch)"'

#other
alias repo='(LC_ALL=en_US.UTF-8 firefox "https://github.com/MrFacundo?tab=repositories" > /dev/null 2>&1 &) & disown'
alias pngtojpg='magick mogrify  -format jpg -background white -alpha remove -alpha off *.png'
alias c='code'
alias l='eza -1 --icons=always'
alias ls='eza -la'
alias cd="zoxide"
alias cat="bat"
alias ccss='sudo chown -R $(whoami) "$(which code)" && sudo chown -R $(whoami) /opt/visual-studio-code'
alias krestart='killall plasmashell && kstart plasmashell'
alias p="python"
