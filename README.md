# Clean Arch - KDE system setup: 

## Automated setup:

Just clone this repo and run:
```sh
./scripts/install.sh
```

## Manual setup:

### Yay:
```sh
cd
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
```

### Pacman packages:
```sh
yay -S 7zip bat bc bluez bluez-utils chromium clang cmake cmatrix cowsay docker docker-compose eza fastfetch fd ffmpeg fzf git github-cli gwenview htop jq kcolorchooser kdeconnect ksystemlog ktorrent less libreoffice-fresh man-db man-pages musescore ncdu neovim npm okular poppler qt5-tools ripgrep spectacle starship stow syncthing tree unrar unzip variety vlc yazi zoxide zsh
```

### AUR packages:
```sh
yay -S koi visual-studio-code-bin stremio slack-desktop spotify ventoy kwin-effects-forceblur kwin-effect-rounded-corners-git kwin-scripts-krohnkite-git webapp-manager
```

### Github setup

```sh
gh auth login
```

In case manual setup is needed:

```sh
ssh-keygen -t ed25519 -C "<EMAIL>"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```
Add manually the key to the Github account.


### Clone this repository:

```sh
git clone git@github.com:MrFacundo/dotfiles.git
cd dotfiles
```

### OhMyZsh: 
Run `scripts/ohMyZshInstall.sh`

### Lazyvim:

```sh
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

### Run from inside dotfiles directory
  	
```sh
stow -t $HOME home
```

**Stowed configs:**
- **Autostart apps**: Koi, Variety.
- **Breeze**: No title bar in windows.
- **Fastfetch**: Config.
- **Dolphin**: Custom actions.
- **Git**: Email, name, editor.
- **Konsole**: Color schemes, Leaf Light and Leaf Dark profiles.
- **Variety**: Wallpaper changer.
- **KDE** Plasma: Autostart, color schemes, global theme, key bindings, window rules 
- **Koi**: Dynamic theming.
- **KWin Rules**: Window transparency for some app windows.
- **KWrite**: Various settings.
- **OhMyZsh**: Aliases, theme and functions.
- **Okular**: Panel, page layout.
- **Plasma**: General settings, colors, window decorations, shortcuts, etc.
- **Spicetify**: Config and themes files.
- **Starship**: prompt config.
- **VSCode**: Custom CSS
- **Yazi**: Config.
- **Zsh**: Path additions, environment, prompt, plugins, fzf.

## For both automated and manual installations:

### VSCode:
  
Adjust permissions for the Custom Css extension:

```sh
  ccss
```

### Spicetify:
```sh
sudo chmod 777 /opt/spotify -R
curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
spicetify backup apply
cp -r spicetify/* ~/.config/spicetify 
spicetify config current_theme Leaf

```

