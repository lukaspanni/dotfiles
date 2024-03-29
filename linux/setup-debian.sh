#!/bin/bash

USER=lukas
NODE_VERSION=20

# Setup-Script for Debian-based systems, run as root!

# Install general packages, some should already be installed, but make sure everything is there
apt update
apt install -y zsh tree curl wget git neofetch htop tmux

# Add user if it does not exist
id -u $USER &>/dev/null || adduser --shell /usr/bin/zsh $USER
usermod -aG sudo $USER 
# Copy dotfiles to user's home directory
cp -r . /home/$USER
cp -r ../shared/. /home/$USER

# install GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& apt update \
&& apt install gh -y

# Install nodejs
curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - &&\
apt-get install -y nodejs

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


# Setup tmux
mkdir -p ~/.config/tmux/
cp ../shared/tmux/* ~/.config/tmux/
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
