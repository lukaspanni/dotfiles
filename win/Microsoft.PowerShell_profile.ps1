oh-my-posh --init --shell pwsh --config "$env:localappdata/Programs/oh-my-posh/themes/quick-term.omp.json" | Invoke-Expression
Set-Alias lg lazygit
Set-Alias ld lazydocker
Set-Alias g git
Set-Alias vim nvim
Set-Alias htop ntop 
Set-Alias which gcm
Set-Alias docker podman
Set-Alias postman posting
Set-Alias y yazi

function zsh { wsl.exe zsh }

# OpenCode stuff
function oc { opencode }
$env:EDITOR = "code --wait"

# Codex
function cx { codex }

# Claude Code
function cc { claude --dangerously-skip-permissions }

$bunBin = Join-Path $HOME ".bun\bin"
if ((Test-Path $bunBin) -and -not (($env:Path -split ';') -contains $bunBin)) {
    $env:Path += ";$bunBin"
}

$VServer="37.120.173.24"
$dev = "E:\Dokumente\Development"

function zsh { wsl.exe zsh }

function startWebUI {
 docker run -d -p 8080:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart unless-stopped ghcr.io/open-webui/open-webui:main
}


# Git helpers
function gitFix {
  git add -A && git commit -m "fix" && git push
}

function gitFixup {
  git add -A && git fix && git fpush
}

function gitDiffClip {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Branch,
        
        [Parameter(Mandatory=$false)]
        [string]$CompareBranch = $null
    )
    
    if (!$CompareBranch) {
        $CompareBranch = git rev-parse --abbrev-ref HEAD
    }
    
    git diff "$CompareBranch..$Branch" | Set-Clipboard
    Write-Host "✓ Diff copied to clipboard" -ForegroundColor Green
}

function New-WorktreeFromMain {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BranchName,
        [string]$BaseBranch = "main"
    )

    $repoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $repoRoot) {
        Write-Error "Not inside a git repository."
        return
    }

    $worktreeBase = "$dev\.worktrees"
    if (-not (Test-Path $worktreeBase)) {
        New-Item -ItemType Directory -Path $worktreeBase | Out-Null
    }

    $safeBranch = [regex]::Replace($BranchName.Trim(), "[^a-zA-Z0-9-]", "-")
    if (-not $safeBranch) {
        $safeBranch = "branch"
    }

    $tempName = "$safeBranch-$(Get-Date -Format 'yyyyMMddHHmmssfff')"
    $worktreePath = Join-Path $worktreeBase $tempName

    Push-Location $repoRoot
    try {
        git rev-parse --verify --quiet $BranchName *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Error "Branch '$BranchName' already exists."
            return
        }

        $remote = "origin"
        $refName = $BaseBranch
        if ($BaseBranch -match "(.+?)/(.+)") {
            $remote = $Matches[1]
            $refName = $Matches[2]
        }

        git fetch $remote $refName | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to fetch $remote/$refName."
            return
        }

        git worktree add $worktreePath -b $BranchName "$remote/$refName" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "git worktree add failed."
            return
        }
    }
    finally {
        Pop-Location
    }

    $envFiles = Get-ChildItem -Path $repoRoot -Recurse -File -Force | Where-Object {
        $_.Name -match '^\.env($|\.)' -and $_.FullName -notmatch '\\node_modules\\' -and $_.FullName -notmatch '\\.git\\'
    }

    foreach ($file in $envFiles) {
        $repoUri = [Uri]::new("$repoRoot" + [IO.Path]::DirectorySeparatorChar)
        $fileUri = [Uri]::new($file.FullName)
        $relativePath = $repoUri.MakeRelativeUri($fileUri).ToString().Replace('/', [IO.Path]::DirectorySeparatorChar)
        $destination = Join-Path $worktreePath $relativePath
        $destDir = Split-Path -Path $destination -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
    }

    Push-Location $worktreePath
    try {
        $installCommand = @("pnpm", "install")
        if (Test-Path (Join-Path $worktreePath "bun.lock")) {
            $installCommand = @("bun", "install")
        }
        & $installCommand[0] $installCommand[1]
    }
    finally {
        Pop-Location
    }

    code $worktreePath | Out-Null
    Write-Host "Worktree ready at: $worktreePath"
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
