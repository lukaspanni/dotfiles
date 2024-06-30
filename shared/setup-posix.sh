#!/bin/bash
USER=lukas
SCRIPT_DIR=$(cd "$(dirname $0)" && pwd)
HOMEBREW_PACKAGES=("neovim" "go" "yq" "btop" "k9s" "lazygit" "gh" "node" "fzf")

install_packages() {
  if [ -f /etc/os-release ]; then
    LINUX=true
    LINUX_VARIANT="$(sed -n 's/^ID_LIKE=\(.*\)/\1/p' </etc/os-release)"
    if [ -z "$LINUX_VARIANT" ]; then
      LINUX_VARIANT="$(sed -n 's/^ID=\(.*\)/\1/p' </etc/os-release)"
    fi
  fi

  # Setup-Script for POSIX systems, expects to be run as root!
  if [ "$(whoami)" != "root" ]; then
    echo "Package install needs to be run as root!"
    exit 1
  fi

  # Add user if it does not exist
  id -u $USER &>/dev/null || adduser --shell /usr/bin/zsh $USER
  usermod -aG sudo $USER

  if [[ "$LINUX" == "true" && $LINUX_VARIANT == "debian" ]]; then
    install_debian_packages
  fi
  # TODO: automate macos + arch setup

  # Add pwsh installation

  # Drop root privileges
  su - $USER

  install_homebrew_packages

}

install_debian_packages() {
  # Install general packages, some should already be installed, but make sure everything is there
  apt update
  apt install -y zsh tree curl wget git neofetch htop tmux python-is-python3 python3-pip
}

install_homebrew_packages() {
  # Install homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install jandedobbeleer/oh-my-posh/oh-my-posh

  # Install packages
  for pkg in "${HOMEBREW_PACKAGES[@]}"; do
    brew install "$pkg"
  done
}

configure() {
  # Copy dotfiles to user's home directory
  cp "$SCRIPT_DIR"/.* "$HOME"

  # Set nvchad config
  if [ ! -d ~/.config/nvim ]; then
    git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim
  else
    wd=$(pwd)
    cd ~/.config/nvim && git pull && nvim
    cd "$wd"
  fi
  cp -r "$SCRIPT_DIR"/nvchad/ ~/.config/nvim/lua/custom/

  # Setup tmux
  mkdir -p ~/.config/tmux/
  cp "$SCRIPT_DIR"/tmux/* ~/.config/tmux/
  if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  else
    wd=$(pwd)
    cd ~/.tmux/plugins/tpm && git pull
    cd "$wd"
  fi
}

if [[ -z "$*" || "$*" == "install" ]]; then
  install_packages
  configure
elif [[ "$*" == config* ]]; then
  configure
else
  echo "Unknown command: $*"
  exit 1
fi
