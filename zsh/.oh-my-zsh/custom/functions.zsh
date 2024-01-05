treels() {
    ls -R | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'
}

mkcd(){ NAME=$1; mkdir -p "$NAME"; cd "$NAME"; }

rcommit() { git commit -m "$(w3m whatthecommit.com | head -n 1)"}

listapps() {
  {
    echo "Flatpak installed apps:"
    flatpak list

    echo -e "\nSnap installed apps:"
    snap list

    echo -e "\nAPT installed apps:"
    apt list --installed

    echo -e "\nInstalled Gnome extensions:"
    gnome-extensions list
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