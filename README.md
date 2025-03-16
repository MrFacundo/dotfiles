- **Clone the repository**:
	```sh
	git clone https://github.com/MrFacundo/dotfiles
	cd dotfiles
	```
- **OhMyZsh**: Run `ohMyZshInstall.sh` to install oh-my-zsh, along with plugins, p10k, and p10k fonts.


- **Install and run stow**: 
  	
	```sh
	sudo pacman -S stow
	cd home
	stow -t $HOME *
	```

	*stowed configs:*
	- **Konsole**: Color schemes, profiles, bars visibility and keybindings.
	- **Variety**: Wallpaper changer.
	- **VSCode**: Custom CSS
	- **Dolphin**: Custom actions.
	- **OhMyZsh**: Aliases, theme and functions.
	- **P10k**: Configuration.
	- **Zsh**: Theme, plugins, OhMyZsh, fzf

- **Konsole**: Execute `crontab $HOME/.config/konsole/mycron` to run a script that toggles the profile between Leaf Light and Dark themes.

- **VSCode**: 
  
  *Custom CSS extension:*
  
  Have the Custom CSS and JS Loader extension installed. Add the following to your `settings.json` file:

    ```json
    "vscode_custom_css.imports": [
        " $HOME/.config/vscode/style.css"
    ],
    ```

    Run the following commands to adjust the permissions for VSCode:

    ```sh
    sudo chown -R $(whoami) "$(which code)"
    sudo chown -R $(whoami) /opt/visual-studio-code #(arch)
    ```

	*Leaf Theme:*


	- `git clone https://github.com/LynithDev/leaf-vscode`
	- In VSCode, select `Install Extension From Location`
	- Locate the theme and click install.

- **KDE Keyboard Shortcuts**: Import the `kde-shortcuts.kksrc` file via Input & Output -> Keyboard -> Shortcuts -> Import.

- **Firefox**: 
  - Copy the `chrome` folder to `$HOME/.mozilla/firefox/<profile>/` 
  - Go to `about:config` and set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`.
