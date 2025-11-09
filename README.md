## Clean Arch - KDE system setup: 

### Automated setup:

Just run:
```sh
./scripts/setup-dotfiles.sh
```
### Manual setup:

#### Pacman packages:
```sh
sudo pacman -S 7zip bat bc bluez bluez-utils chromium clang cmake cmatrix cowsay docker docker-compose eza fastfetch fd ffmpeg fzf git github-cli gwenview htop jq kcolorchooser kdeconnect ksystemlog ktorrent less libreoffice-fresh man-db man-pages musescore ncdu neovim npm okular poppler qt5-tools ripgrep spectacle starship stow syncthing tree unrar unzip variety vlc yazi zoxide zsh
```

#### Yay:
```sh
cd
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
```
#### AUR packages:
```sh
yay -S koi visual-studio-code-bin stremio slack-desktop spotify ventoy kwin-effects-forceblur kwin-effect-rounded-corners-git kwin-scripts-krohnkite-git webapp-manager
```

## Config setup: 

### Github setup

If GitHub CLI is installed, set it up:

```sh
gh auth login
```

Else, generate SSH keys:

```sh
ssh-keygen -t ed25519 -C "<EMAIL>"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```
And add manually the key to the Github account.


### Clone this repository: (using SSH)

```sh
git clone git@github.com:MrFacundo/dotfiles.git
cd dotfiles
```

### OhMyZsh: 
Run `ohMyZsh/ohMyZshInstall.sh` to install oh-my-zsh, along with plugins.

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
- **Autostart apps**: Koi settings.
- **Breeze**: No title bar in windows.
- **Fastfetch**: Config.
- **Dolphin**: Custom actions.
- **Git**: Email, name, editor.
- **Konsole**: Color schemes, Leaf Light and Leaf Dark profiles.
- **Variety**: Wallpaper changer.
- **Koi**: Dynamic theming.
- **KWin Rules**: Window transparency for some app windows.
- **KWrite**: Various settings.
- **OhMyZsh**: Aliases, theme and functions.
- **Okular**: Panel, page layout.
- **Plasma**: General settings, colors, window decorations, shortcuts, etc.
- **Spicetify**: Config and themes files.
- **VSCode**: Custom CSS
- **Yazi**: Config.
- **Zsh**: Theme, plugins, OhMyZsh, fzf.

### VSCode: 
  
*Custom CSS extension:*
  
Have the Custom CSS and JS Loader extension installed. Make sure the following is set in  `settings.json`:

```json
"vscode_custom_css.imports": [
	"file:///home/<USERNAME>/.config/vscode/.config/vscode/style.css"
],
```

Adjust the permissions for VSCode:

```sh
  ccss
```

Leaf Theme:

```sh
git clone https://github.com/LynithDev/leaf-vscode
```
- In VSCode, select `Install Extension From Location`
- Locate the theme and click install.

### Other:

**Spicetify**:
```sh
curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
sudo chmod 777 /opt/spotify -R
spicetify backup apply
spicetify config current_theme Leaf

```

### Dynamic theming script:

The scripts at `./themeTogglingScripts` should be loaded in `Koi` by config file.
Themed apps:
- Konsole
- KWrite
- Variety
- Spotify
