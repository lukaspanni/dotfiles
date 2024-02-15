oh-my-posh --init --shell pwsh --config "$env:localappdata/Programs/oh-my-posh/themes/craver.omp.json" | Invoke-Expression
Set-Alias lg lazygit
Set-Alias ld lazydocker
Set-Alias g git
Set-Alias vim nvim
Set-Alias htop ntop 

$VServer="37.120.173.24"
$VServer_Alt="89.163.218.189"

function zsh { wsl.exe zsh }

