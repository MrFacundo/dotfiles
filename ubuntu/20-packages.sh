#!/usr/bin/env bash
# Phase 4 - everything installable. Lists live in packages-ubuntu.sh.
# Idempotent: re-running skips what is already there.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/packages-ubuntu.sh"

KEYRING_DIR=/usr/share/keyrings
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

have() { command -v "$1" >/dev/null 2>&1; }

gh_latest() { # repo, asset grep pattern
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    grep -oE '"browser_download_url": *"[^"]+"' |
    cut -d'"' -f4 | grep -E "$2" | head -n1
}

install_deb_from_url() { # name, url
  local dir="$WORK_DIR/$1"
  mkdir -p "$dir"
  curl -fsSL "$2" -o "$dir/pkg.deb"
  sudo apt-get install -y "$dir/pkg.deb"
}

# ------------------------------------------------------------------- apt base
install_apt() {
  echo "==> apt packages"
  sudo apt-get update
  sudo apt-get install -y "${apt_pkgs[@]}"
}

# --------------------------------------------------------- third-party repos
install_apt_repos() {
  echo "==> Third-party apt repositories"
  local entry name key_url repo_line pkg keyring
  local -a pkgs=()

  for entry in "${apt_repos[@]}"; do
    IFS='|' read -r name key_url repo_line pkg <<<"$entry"
    keyring="$KEYRING_DIR/$name.gpg"

    if [ ! -f "$keyring" ]; then
      echo "    key: $name"
      curl -fsSL "$key_url" | gpg --dearmor | sudo tee "$keyring" >/dev/null
      sudo chmod 644 "$keyring"
    fi

    echo "${repo_line//%KEY%/$keyring}" |
      sudo tee "/etc/apt/sources.list.d/$name.list" >/dev/null
    pkgs+=("$pkg")
  done

  local ppa ppa_pkg
  for entry in "${apt_ppas[@]}"; do
    IFS='|' read -r ppa ppa_pkg <<<"$entry"
    echo "    ppa: $ppa"
    sudo add-apt-repository -y "$ppa"
    pkgs+=("$ppa_pkg")
  done

  # Prefer the PPA Firefox deb over the Ubuntu snap transitional package.
  printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' |
    sudo tee /etc/apt/preferences.d/mozilla-firefox >/dev/null

  sudo apt-get update
  sudo apt-get install -y "${pkgs[@]}"
}

# ----------------------------------------------------------------- flatpak
install_flatpak() {
  echo "==> flatpak"
  sudo apt-get install -y flatpak plasma-discover-backend-flatpak
  sudo flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install -y flathub "${flatpak_pkgs[@]}"
}

# -------------------------------------------------------------------- rust
install_cargo() {
  echo "==> rust toolchain and cargo packages"
  if ! have rustup; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$WORK_DIR/rustup.sh"
    sh "$WORK_DIR/rustup.sh" -y --no-modify-path
  fi
  # shellcheck disable=SC1091
  . "$HOME/.cargo/env"
  cargo install "${cargo_pkgs[@]}"
}

# -------------------------------------------------------------------- node
install_node() {
  echo "==> nvm, node and global npm packages"
  if [ ! -d "$HOME/.nvm" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh |
      PROFILE=/dev/null bash
  fi
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"

  local v
  for v in "${node_versions[@]}"; do
    nvm install "$v"
  done
  nvm alias default "${node_versions[0]}"
  nvm use default

  npm install -g "${npm_global_pkgs[@]}"
}

# ------------------------------------------------------------------ python
install_python_tools() {
  echo "==> uv"
  have uv || curl -fsSL https://astral.sh/uv/install.sh | sh
}

# ------------------------------------------------- manual binaries/tarballs
install_manual() {
  echo "==> Manually installed tools"

  if ! have starship; then
    echo "    starship"
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
  fi

  if ! have claude; then
    echo "    claude"
    curl -fsSL https://claude.ai/install.sh | bash
  fi

  if ! have aichat; then
    echo "    aichat"
    install_deb_from_url aichat "$(gh_latest sigoden/aichat 'x86_64-unknown-linux-musl\.deb$')"
  fi

  if ! have lazygit; then
    echo "    lazygit"
    local dir="$WORK_DIR/lazygit"
    mkdir -p "$dir"
    curl -fsSL "$(gh_latest jesseduffield/lazygit 'Linux_x86_64\.tar\.gz$')" -o "$dir/lazygit.tar.gz"
    tar -C "$dir" -xzf "$dir/lazygit.tar.gz" lazygit
    sudo install -m 755 "$dir/lazygit" /usr/local/bin/lazygit
  fi

  if ! have fastfetch; then
    echo "    fastfetch"
    install_deb_from_url fastfetch "$(gh_latest fastfetch-cli/fastfetch 'linux-amd64\.deb$')"
  fi

  if [ ! -x /opt/nvim-linux-x86_64/bin/nvim ]; then
    echo "    neovim"
    local dir="$WORK_DIR/nvim"
    mkdir -p "$dir"
    curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
      -o "$dir/nvim.tar.gz"
    sudo tar -C /opt -xzf "$dir/nvim.tar.gz"
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  fi

  if ! have go; then
    echo "    go"
    sudo apt-get install -y golang-go
  fi

  for tool in zen insomnia nchat cliamp; do
    have "$tool" || echo "    $tool: install by hand, see ubuntu/README.md"
  done
}

# ------------------------------------------------------------------ docker
setup_containers() {
  echo "==> docker group"
  sudo groupadd -f docker
  sudo usermod -aG docker "$USER"
  sudo systemctl enable --now docker.service || true
  echo "    log out and back in for the docker group to take effect"
}

main() {
  install_apt
  install_apt_repos
  install_flatpak
  install_cargo
  install_node
  install_python_tools
  install_manual
  setup_containers
  echo
  echo "Packages done. Next: 30-configure.sh"
}

main "$@"
