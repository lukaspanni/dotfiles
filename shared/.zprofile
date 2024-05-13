eval "$(/opt/homebrew/bin/brew shellenv)"

if [ -f /etc/os-releas ]; then
  # Linux
  BREW_PATH="/home/linuxbrew/.linuxbrew/bin" 
else 
  BREW_PATH="/opt/homebrew"
fi
export JAVA_HOME="$BREW_PATH/opt/openjdk"
export XDG_CONFIG_HOME="$HOME/.config"
