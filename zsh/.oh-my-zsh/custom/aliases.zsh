#42

alias francinette=/home/facu/francinette/tester.sh
alias paco=/home/facu/francinette/tester.sh
alias grade='bash -c "$(curl https://grademe.fr)"'
alias mr='make restart'
alias c="flatpak run com.visualstudio.code" 

#git
alias gcl='git clone'
alias ga='git add .'
alias gco='git commit -m'
alias pull='git pull origin main'
alias pull2='git pull origin master'
alias push='git push origin main'
alias push2='git push origin master'
alias gpo='git push origin'
alias ggr='git config --get remote.origin.url'
alias ghb='gh browse'

#other
alias ip="curl ipinfo.io/ip"
alias speedtest="wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip"
alias update='\
  sudo apt update && \
  sudo apt -y full-upgrade && \
  sudo apt -y autoremove && '
alias repo='xdg-open "https://github.com/MrFacundo?tab=repositories" &'
