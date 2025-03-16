#42
alias grade='bash -c "$(curl https://grademe.fr)"'
alias trb='cd /home/facu/Code/42/transcendence; docker-compose up --build'
alias tr='cd /home/facu/Code/42/transcendence; docker-compose up'
alias trl='qdbus org.kde.KWin /KWin nextDesktop && nohup chromium --new-window http://localhost:8080 &disown && sleep 1 && nohup firefox --new-window http://localhost:8080 & disown'
alias abe="docker exec -it transcendence_back bash"

#git
alias gcl='git clone'
alias ga='git add .'
alias gc='git commit -m'
alias gcb='git checkout -b'
alias pull='git pull origin main'
alias push='git push origin main'
alias pullb='git pull origin "$(git_current_branch)"'
alias pushb='git push origin "$(git_current_branch)"'

#other
alias repo='(LC_ALL=en_US.UTF-8 firefox "https://github.com/MrFacundo?tab=repositories" > /dev/null 2>&1 &) & disown'
alias rg='ranger'
alias pngtojpg='magick mogrify  -format jpg -background white -alpha remove -alpha off *.png'
alias c='code'
alias fzfc='code $(fzf --preview "less {}")'
alias l='eza -1 --icons=always'
alias ls='eza -la'
alias cd="z"
alias cat="bat"
alias kp="~/Rice/konsole/auto.sh && (sleep 1 && konsole) & disown && exit"