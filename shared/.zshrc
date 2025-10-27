if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  exec tmux
fi

eval "$(oh-my-posh --init --shell zsh --config $(brew --prefix oh-my-posh)/themes/quick-term.omp.json)"

alias lg=lazygit
alias ld=lazydocker
alias nv=nvim
alias g=git
alias top=btop
alias ls='ls --color=auto '
alias y=yazi

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

source <(fzf --zsh)

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
  bash -c "NO_INPUT=1 $(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
fi
source "${ZINIT_HOME}/zinit.zsh"

if command -v zinit &> /dev/null; then
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  zinit light Aloxaf/fzf-tab
  zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
  zinit load zdharma-continuum/history-search-multi-word
else 
  echo "zinit not found or not configured correctly, skipping zsh plugins"
fi

