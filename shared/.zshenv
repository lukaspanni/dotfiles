if [ -f /etc/os-release ]; then
  # Linux
  BREW_BIN_PATH="/home/linuxbrew/.linuxbrew/bin"
else
  BREW_BIN_PATH="/opt/homebrew/bin"
fi
export PATH="$BREW_BIN_PATH:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"

eval "$($BREW_BIN_PATH/brew shellenv)"
