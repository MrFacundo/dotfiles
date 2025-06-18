mkcd(){ NAME=$1; mkdir -p "$NAME"; cd "$NAME"; }

listapps() {
  {
    echo "Flatpak installed apps:"
    flatpak list

    echo -e "\nPacman installed packages:"
    pacman -Qe

    echo -e "\nYay (AUR) installed packages:"
    yay -Qm

  } > installed_apps.txt
}

extract () {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1     ;;
      *.tar.gz)    tar xzf $1     ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       unrar e $1     ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xf $1      ;;
      *.tbz2)      tar xjf $1     ;;
      *.tgz)       tar xzf $1     ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
      echo "'$1' is not a valid file"
    fi
}

ghb() {
  if [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1; then
    xdg-open $(git remote get-url origin | sed -e's/:/\//' -e's/git@/https:\/\//' -e's/.git$//')
  else
    echo "Not a git repository"
  fi
}

xlsx2csv() {
  for file in "$@"; do
    outfile="${file%.xlsx}.txt"
    libreoffice --headless \
      --convert-to "csv:Text - txt - csv (StarCalc):9,34,9" "$file" \
      --outdir "$(dirname "$file")" >/dev/null 2>&1
    mv "${file%.xlsx}.csv" "$outfile"
  done
}


y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"z
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}