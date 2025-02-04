oh-my-posh --init --shell pwsh --config "$env:localappdata/Programs/oh-my-posh/themes/craver.omp.json" | Invoke-Expression
Set-Alias lg lazygit
Set-Alias ld lazydocker
Set-Alias g git
Set-Alias vim nvim
Set-Alias htop ntop 
Set-Alias which gcm
Set-Alias y yazi

$VServer="37.120.173.24"
$dev = "E:\Dokumente\Development"

function zsh { wsl.exe zsh }

# Fix winget paths
$wingetPackagesPath = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"
$packageDirs = Get-ChildItem -Directory -Path $wingetPackagesPath

function IsPathInEnvironment {
    param (
        [string]$path
    )
    $envPath = $env:Path
    return $envPath.Split(';') -contains $path
}

foreach ($packageDir in $packageDirs) {
    # Only consider subfolders that contain binaries to be added to path
    $binaryFiles = Get-ChildItem -Path $packageDir.FullName -Recurse -Include *.exe

    if ($binaryFiles) {
        if (-not (IsPathInEnvironment -path $packageDir.FullName)) {
            $env:Path += ";$($packageDir.FullName)"
        }
    }
}

