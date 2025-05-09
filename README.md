### Clean Arch - KDE system: 
- Install the following packages:
```sh
sudo pacman -S 7zip bat bc chromium clang cmake cmatrix cowsay docker docker-compose dysks eza fastfetch fzf git gnu-netcat gwenview htop kcolorchooser kdeconnect ksystemlog ktorrent less libreoffice-fresh man-db man-pages musescore ncdu npm okular php ranger samba spectacle timeshift tree unrar unzip valgrind vi vim vlc zoxide
```
- Install yay:
```sh
cd
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
```
- Install the following AUR packages:
```sh
yay -S koi stremio slack-desktop spotify
```
- Setup Github SSH key:
```sh
ssh-keygen -t ed25519 -C "<EMAIL>"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```
- Copy the public key:
```sh
clip < ~/.ssh/id_ed25519.pub
```
- Add the key to the Github account.

### Clone this repository: (using SSH)

	```sh
	git clone git@github.com:MrFacundo/dotfiles.git
	cd dotfiles
	```

### Install and run stow: (from inside dotfiles directory)
  	
	```sh
	sudo pacman -S stow
	stow -t $HOME home
	```

**Stowed configs:**
- **Konsole**: Color schemes, Leaf Light and Leaf Dark profiles.
- **KWrite**: Various settings.
- **Variety**: Wallpaper changer.
- **VSCode**: Custom CSS
- **Dolphin**: Custom actions.
- **OhMyZsh**: Aliases, theme and functions.
- **P10k**: Configuration.
- **Zsh**: Theme, plugins, OhMyZsh, fzf

### OhMyZsh: 
Run `ohMyZsh/ohMyZshInstall.sh` to install oh-my-zsh, along with plugins, p10k, and p10k fonts.

### VSCode: 
  
*Custom CSS extension:*
  
Have the Custom CSS and JS Loader extension installed. Add the following to  `settings.json`:

    ```json
    "vscode_custom_css.imports": [
        "file:///home/<USERNAME>/.config/vscode/.config/vscode/style.css"
    ],
    ```

Run the following commands to adjust the permissions for VSCode:

    ```sh
    sudo chown -R $(whoami) "$(which code)"
    sudo chown -R $(whoami) /opt/visual-studio-code #(arch)
    ```

Leaf Theme:


	- `git clone https://github.com/LynithDev/leaf-vscode`
	- In VSCode, select `Install Extension From Location`
	- Locate the theme and click install.

### KDE Keyboard Shortcuts:

Import the `kde-shortcuts.kksrc` file via Input & Output -> Keyboard -> Shortcuts -> Import.

### Firefox: 
  - Copy the `chrome` folder to `$HOME/.mozilla/firefox/<profile>/` 
  - Go to `about:config` and set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`.

### Dynamic Theming script:

- Install Koi from the AUR.
- Use the scripts at ./themeTogglingScripts in the Custom BASH Script config option.