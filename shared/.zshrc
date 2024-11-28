if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  exec tmux
fi

eval "$(oh-my-posh --init --shell zsh --config $(brew --prefix oh-my-posh)/themes/craver.omp.json)"

alias lg=lazygit
alias nv=nvim
alias g=git
alias top=btop
alias ls='ls --color=auto '

source <(fzf --zsh)
