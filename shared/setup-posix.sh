#!/bin/bash

if [ -f /etc/os-release ]; then
  LINUX=true
  LINUX_VARIANT="$(cat /etc/os-release | sed -n 's/^ID_LIKE=\(.*\)/\1/p')"
  if [ -z "$LINUX_VARIANT" ]; then
    LINUX_VARIANT="$(cat /etc/os-release | sed -n 's/^ID=\(.*\)/\1/p')"
  fi
fi

USER=lukas
NODE_VERSION=20

# Setup-Script for POSIX systems, expects to be run as root!
if [ $(whoami) != "root" ]; then
  echo "Needs to run as root!"
  exit 1
fi


if [ $LINUX ] && [[ $LINUX_VARIANT == "debian" ]]; then
  # Install general packages, some should already be installed, but make sure everything is there
  apt update
  apt install -y zsh tree curl wget git neofetch htop tmux

  # install GitHub CLI
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \ 
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update && \
    apt install gh -y

  # Install nodejs
  curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - &&\
    apt install -y nodejs
  # Add user if it does not exist
  id -u $USER &>/dev/null || adduser --shell /usr/bin/zsh $USER
  usermod -aG sudo $USER 
fi
# TODO: macos + arch setup
# maybe move more to homebrew installable stuff
# Add pwsh, yq, golang installation

# Copy dotfiles to user's home directory
cp -r . /home/$USER
cp -r ../shared/. /home/$USER


# Drop root privileges
su - $USER

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install jandedobbeleer/oh-my-posh/oh-my-posh

# Install neovim + nvchad
brew install neovim
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim
# Set nvchad config
cp ../shared/chadrc.lua ~/.config/nvim/lua/custom/
# Setup global git config
cp -r ../shared/.git* $HOME

# Setup tmux
mkdir -p ~/.config/tmux/
cp ../shared/tmux/* ~/.config/tmux/
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
