oh-my-posh --init --shell pwsh --config $env:localappdata'/Programs/oh-my-posh/themes/craver.omp.json' | Invoke-Expression
Set-Alias lg lazygit
Set-Alias g git
Set-Alias vim nvim
function zsh { wsl.exe zsh }
