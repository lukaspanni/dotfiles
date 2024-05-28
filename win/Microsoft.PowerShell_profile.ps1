oh-my-posh --init --shell pwsh --config "$env:localappdata/Programs/oh-my-posh/themes/craver.omp.json" | Invoke-Expression
Set-Alias lg lazygit
Set-Alias ld lazydocker
Set-Alias g git
Set-Alias vim nvim
Set-Alias htop ntop 
Set-Alias which gcm

$VServer="37.120.173.24"
$dev = "E:\Dokumente\Development"

function zsh { wsl.exe zsh }

