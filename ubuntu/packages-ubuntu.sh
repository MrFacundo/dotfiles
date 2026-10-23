#!/usr/bin/env bash
# Package lists for the Ubuntu / KDE Neon setup.
# Sourced by 20-packages.sh. Not meant to be run on its own.

# ---- apt: Neon / Ubuntu repositories ----
apt_pkgs=(
    apt-transport-https
    autokey-qt
    bat
    bc
    bluez
    build-essential
    ca-certificates
    cava
    clang
    cmake
    cmatrix
    cowsay
    curl
    docker-compose
    docker.io
    dos2unix
    fd-find
    ffmpeg
    fzf
    gamemode
    gimp
    git
    gnupg
    grub-customizer
    gwenview
    htop
    imagemagick
    input-remapper
    jq
    kcolorchooser
    kdeconnect
    kdenlive
    kde-spectacle
    ktorrent
    less
    libreoffice
    man-db
    manpages
    mpv
    mpv-mpris
    ncdu
    nmap
    p7zip-full
    pdfarranger
    pipx
    playerctl
    podman
    python3-pip
    python3-venv
    qttools5-dev-tools
    ripgrep
    stow
    syncthing
    timeshift
    tree
    unrar
    unzip
    vlc
    webapp-manager
    wget
    wl-clipboard
    xclip
    yt-dlp
    zip
    zsh
)

# ---- apt: third-party repositories ----
# Each entry: name|gpg key URL|sources.list line|package to install
# %KEY% in the sources line is replaced with the installed keyring path.
apt_repos=(
    "microsoft-edge|https://packages.microsoft.com/keys/microsoft.asc|deb [arch=amd64 signed-by=%KEY%] https://packages.microsoft.com/repos/edge stable main|microsoft-edge-stable"
    "vscode|https://packages.microsoft.com/keys/microsoft.asc|deb [arch=amd64 signed-by=%KEY%] https://packages.microsoft.com/repos/code stable main|code"
    "slack|https://packagecloud.io/slacktechnologies/slack/gpgkey|deb [arch=amd64 signed-by=%KEY%] https://packagecloud.io/slacktechnologies/slack/debian/ jessie main|slack-desktop"
    "element-io|https://packages.element.io/debian/element-io-archive-keyring.gpg|deb [signed-by=%KEY%] https://packages.element.io/debian/ default main|element-desktop"
    "teams-for-linux|https://repo.teamsforlinux.de/teams-for-linux.asc|deb [arch=amd64 signed-by=%KEY%] https://repo.teamsforlinux.de/debian/ stable main|teams-for-linux"
    "github-cli|https://cli.github.com/packages/githubcli-archive-keyring.gpg|deb [arch=amd64 signed-by=%KEY%] https://cli.github.com/packages stable main|gh"
    "ghostty|https://packagecloud.io/atotto/tools/gpgkey|deb [arch=amd64 signed-by=%KEY%] https://packagecloud.io/atotto/tools/ubuntu/ noble main|ghostty"
)

# PPAs, added with add-apt-repository. Each entry: ppa|package to install
apt_ppas=(
    "ppa:mozillateam/ppa|firefox"
)

# ---- flatpak ----
flatpak_pkgs=(
    org.chromium.Chromium
)

# ---- cargo (needs rustup first) ----
cargo_pkgs=(
    bluetui
    eza
    xremap
)

# ---- node ----
# First entry becomes the default; 20.18.0 is pinned for the PSPS webapp.
node_versions=(
    22
    20.18.0
)

npm_global_pkgs=(
    "@google/gemini-cli"
    "@github/copilot"
)

# ---- Installed by hand in 20-packages.sh (see install_manual_*) ----
# aichat, claude, cliamp, fastfetch, go, insomnia, lazygit, nchat, neovim,
# starship, uv, zen
