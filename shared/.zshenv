if [ -f /etc/os-release ]; then
  # Linux
  BREW_BIN_PATH="/home/linuxbrew/.linuxbrew/bin"
  dev="$HOME/development/"
else
  # macOS
  BREW_BIN_PATH="/opt/homebrew/bin"
  dev="$HOME/Documents/development/"
fi
export PATH="$BREW_BIN_PATH:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"

eval "$($BREW_BIN_PATH/brew shellenv)"
