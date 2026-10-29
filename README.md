# Clean Arch - KDE system setup:

Dotfiles and setup scripts for an Arch + KDE Plasma machine. The CSW work
laptop runs KDE Neon instead; `ubuntu/README.md` covers that one.

## Automated setup:

```sh
git clone https://github.com/MrFacundo/dotfiles.git ~/dotfiles
~/dotfiles/scripts/install.sh
```

```sh
./scripts/install.sh --list          # the steps, in order
./scripts/install.sh --skip aur      # skip one (repeatable)
./scripts/install.sh --only stow     # run one and stop
```

| Step | Does |
|---|---|
| `preflight` | git, curl, python, sudo; caches the sudo credential |
| `install_pacman_packages` | refreshes `archlinux-keyring`, installs `pacman_pkgs`; anything the repos do not carry is deferred to the AUR step |
| `install_yay` | builds yay from the AUR when it is missing |
| `install_aur_packages` | prompts, then installs `aur_pkgs` (`INSTALL_AUR=y` answers for a non-interactive run) |
| `install_lazyvim` | clones the LazyVim starter, skipped when already present |
| `update_kwinrc` | krohnkite, blur and focus settings, backing up `kwinrc` first |
| `setup_firefox_config` | links `~/.config/firefox` to the profile, enables custom CSS |
| `install_plasmoids` (`plasmoids`) | installs the third-party Plasma widgets the panel layout needs, at pinned tags |
| `run_stow` | backs up the files KDE writes on first login, then stows |
| `enable_services` (`services`) | enables `bluetooth` and `docker` (system) and `syncthing` (user), adds you to the `docker` group |
| `gh_auth_login` | `gh auth login`, skipped when already authenticated |

Every step is idempotent. Package lists live in `scripts/packages.sh`; after
editing them run `scripts/sync-readme.sh` to refresh the lists below.
Third-party Plasma widgets are pinned in `scripts/install-plasmoids.sh`.

## Manual setup:

### Install Yay:
```sh
cd
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
```

### Install Pacman packages:
```sh
yay -S 7zip aichat bat bc bluetui bluez bluez-utils cava chromium clang cmake cmatrix cowsay docker docker-compose eza fastfetch fd ffmpeg fzf ghostty git github-cli glow gwenview kcolorchooser kdeconnect ktorrent less libreoffice-fresh man-db man-pages mpv-mpris musescore ncdu neovim npm okular playerctl qt5-tools spectacle spotify-player starship stow syncthing timeshift tree unrar unzip vlc yazi zoxide zsh
```

### Install AUR packages:
```sh
yay -S brave-bin cliamp gowall kwin-effects-forceblur kwin-effect-rounded-corners-git kwin-scripts-krohnkite-git nchat stremio ventoy visual-studio-code-bin webapp-manager
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
Manually add the key on GitHub.

### Clone this repository:

```sh
git clone git@github.com:MrFacundo/dotfiles.git
cd dotfiles
```

### Install OhMyZsh and plugins:
Run `scripts/ohMyZshInstall.sh`

### Install Lazyvim:

```sh
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

### Stow: run inside the dotfiles directory

```sh
stow --no-folding -t $HOME home
```

**Stowed configs:**
- **Aichat**: Roles, config, theme.
- **AI CLIs**: Claude settings, instructions, plugin list and skills; Gemini and Copilot settings.
- **Autokey / input-remapper / Vial**: Input mappings.
- **Breeze**: No title bar in windows.
- **Cava**: Config.
- **Fastfetch**: Config.
- **Dolphin**: Custom actions.
- **Git**: Email, name, editor, global ignore.
- **Ghostty**: Leaf themes, keybindings.
- **KDE Plasma** : Color schemes, global theme, key bindings, window rules, panel layout and panel views, Spectacle, hotkeys
- **KWin Rules**: Window transparency for some app windows.
- **Lazygit**: Config.
- **Mpv**: Config.
- **Nchat**: Config, theme, keybindings.
- **OhMyZsh**: Aliases, theme and functions.
- **Okular**: Panel, page layout.
- **Spicetify**: Config.
- **Starship**: prompt config.
- **VSCode**: Custom CSS
- **Yazi**: Layout.
- **yt-dlp**: Config.
- **Zsh**: Path additions, environment, prompt, plugins, fzf.

### Extra configurations:
  
Adjust permissions for the Custom CSS extension:

```sh
  ccss
```

Add API keys for aichat at `~/.config/aichat/.env`:

```env
GEMINI_API_KEY=api_key_here
```

Still manual after the script:

- KDE Store KWin scripts and effects: krohnkite, geometry change (the panel
  widgets are installed by the `plasmoids` step)
- apply the Plasma global theme
- `ccss` for the VS Code custom CSS permissions
- printer, bluetooth and kdeconnect pairing
- first Timeshift snapshot
