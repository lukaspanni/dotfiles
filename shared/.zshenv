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

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"
