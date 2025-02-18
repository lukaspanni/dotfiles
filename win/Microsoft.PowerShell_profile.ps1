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

function startWebUI {
 docker run -d -p 8080:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart unless-stopped ghcr.io/open-webui/open-webui:main
}

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
    foreach ($binaryFile in $binaryFiles) {
        $binaryFolder = $binaryFile.DirectoryName
        if (-not (IsPathInEnvironment -path $binaryFolder)) {
            $env:Path += ";$binaryFolder"
        }
    }
}

