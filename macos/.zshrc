eval "$(oh-my-posh --init --shell zsh --config $(brew --prefix oh-my-posh)/themes/craver.omp.json)"
alias python=python3
alias lg=lazygit
alias nv=nvim
alias g=git

export JAVA_HOME="/opt/homebrew/opt/openjdk"
export FLUTTER_HOME="/opt/homebrew/opt/flutter/bin"
export PATH="/opt/homebrew/opt/node@16/bin:$FLUTTER_HOME:$JAVA_HOME:$PATH"

