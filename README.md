## Clean Arch - KDE system setup: 

#### Pacman packages:
```sh
sudo pacman -S 7zip bat bc bluez bluez-utils chromium clang cmake cmatrix cowsay docker docker-compose dysks eza fastfetch fd ffmpeg fzf git gnu-netcat gwenview htop jq kcolorchooser kdeconnect ksystemlog ktorrent less libreoffice-fresh man-db man-pages musescore ncdu npm okular poppler qt5-tools ripgrep spectacle stow syncthing tree unrar unzip vim vlc yazi zoxide zsh
```

#### Yay:
```sh
cd
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
```
#### AUR packages:
```sh
yay -S koi visual-studio-code-bin stremio slack-desktop spotify ventoy kwin-effects-forceblur kwin-effect-rounded-corners-git
```

#### Github SSH key:

```sh
ssh-keygen -t ed25519 -C "<EMAIL>"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
clip < ~/.ssh/id_ed25519.pub
```
Add the key to the Github account.

## Dotfiles setup: 

### Clone this repository: (using SSH)

```sh
git clone git@github.com:MrFacundo/dotfiles.git
cd dotfiles
```

### OhMyZsh: 
Run `ohMyZsh/ohMyZshInstall.sh` to install oh-my-zsh, along with plugins, p10k, and p10k fonts.


### Run stow: (from inside dotfiles directory)
  	
```sh
stow -t $HOME home
```

**Stowed configs:**
- **Konsole**: Color schemes, Leaf Light and Leaf Dark profiles.
- **KWrite**: Various settings.
- **Variety**: Wallpaper changer.
- **VSCode**: Custom CSS
- **Dolphin**: Custom actions.
- **OhMyZsh**: Aliases, theme and functions.
- **P10k**: Config.
- **Zsh**: Theme, plugins, OhMyZsh, fzf.
- **Spicetify**: Config and themes files.
- **yazi**: Config.



### VSCode: 
  
*Custom CSS extension:*
  
Have the Custom CSS and JS Loader extension installed. Add the following to  `settings.json`:

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

### KDE Keyboard Shortcuts:

Import `kde/kde-shortcuts.kksrc` file via Input & Output -> Keyboard -> Shortcuts -> Import.

### Firefox: 
  - Copy the `firefox/chrome` folder to `$HOME/.mozilla/firefox/<profile>/` 
  - Go to `about:config` and set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`.

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