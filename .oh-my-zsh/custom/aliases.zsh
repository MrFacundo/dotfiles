#42
alias francinette=/home/facu/francinette/tester.sh
alias paco=/home/facu/francinette/tester.sh
alias grade='bash -c "$(curl https://grademe.fr)"'
alias web='cd /home/facu/Code/42/webserv && clear && make && ./webserv test_files/configs/test2.conf'
alias webf='cd /home/facu/Code/42/webserv && clear && make && ./webserv test_files/configs/test2.conf & disown && firefox --new-window "http://localhost:4242"'
alias trb='cd /home/facu/Code/42/transcendence; docker-compose up --build'
alias tr='cd /home/facu/Code/42/transcendence; docker-compose up'

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
alias abe="docker exec -it transcendence_back bash"
alias cat="bat"
