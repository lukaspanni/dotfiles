function Install-Packages {
  param (
    [switch]$FullInstall
  )

  $programs_winget = @(
    "Canonical.Ubuntu2404",
    "Derailed.k9s",
    "Docker.DockerDesktop",
    "Git.Git",
    "GitHub.cli",
    "GoLang.Go",
    "Google.Chrome",
    "JanDeDobbeleer.OhMyPosh",
    "JesseDuffield.lazydocker",
    "JesseDuffield.lazygit",
    "Microsoft.DotNet.SDK.9",
    "Microsoft.PowerShell",
    "Microsoft.PowerToys",
    "Microsoft.VisualStudioCode",
    "Microsoft.WindowsTerminal",
    "Mozilla.Firefox",
    "Neovim.Neovim",
    "Notepad++.Notepad++",
    "Obsidian.Obsidian",
    "Ollama.Ollama",
    "OpenJS.NodeJS",
    "Oven-sh.Bun",
    "gerardog.gsudo",
    "gsass1.NTop",
    "sxyazi.yazi"
  )

  $optional_winget = @(
    "Duplicati.Duplicati",
    "IDRIX.VeraCrypt",
    "Insecure.Nmap",
    "MiKTeX.MiKTeX",
    "Microsoft.OpenJDK.21",
    "VideoLAN.VLC",
    "WiresharkFoundation.Wireshark"
  )

  $all_programs = $programs_winget
  if ($FullInstall) {
    $all_programs += $optional_winget
  }

  foreach ($prg in $all_programs) {
    try {
      winget install --exact --silent $prg
    }
    catch {
      Write-Host "Failed to install $prg"
    }
  }
}

function Get-BunPath {
  $bun = Get-Command bun -ErrorAction SilentlyContinue
  if ($bun) {
    return $bun.Source
  }

  $wingetBunDir = Get-ChildItem -Directory -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter "Oven-sh.Bun*" -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $wingetBunDir) {
    return $null
  }

  $bunExe = Get-ChildItem -Path $wingetBunDir.FullName -Recurse -Filter "bun.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($bunExe) {
    return $bunExe.FullName
  }

  return $null
}

function Install-OpenCode {
  try {
    $bunPath = Get-BunPath

    if (-not $bunPath) {
      throw "bun executable not found."
    }

    & $bunPath add -g opencode-ai
  }
  catch {
    Write-Host "Failed to install opencode-ai: $_"
  }
}

function Install-OpenCodeConfigDependencies {
  try {
    $bunPath = Get-BunPath
    if (-not $bunPath) {
      throw "bun executable not found."
    }

    $configDir = "$HOME/.config/opencode"
    if (-not (Test-Path "$configDir/package.json")) {
      return
    }

    & $bunPath install --cwd "$configDir"
  }
  catch {
    Write-Host "Failed to install opencode config dependencies: $_"
  }
}

function Sync-FileToRepo {
  param (
    [string]$Source,
    [string]$Destination
  )

  if (-not (Test-Path $Source)) {
    return
  }

  mkdir -Force (Split-Path $Destination) | Out-Null
  cp -Force $Source $Destination
}

function Sync-DirectoryToRepo {
  param (
    [string]$Source,
    [string]$Destination,
    [string[]]$Exclude = @()
  )

  if (-not (Test-Path $Source)) {
    return
  }

  mkdir -Force $Destination | Out-Null
  Get-ChildItem -Force -LiteralPath $Source | ForEach-Object {
    if ($Exclude -contains $_.Name) {
      return
    }

    cp -Recurse -Force -LiteralPath $_.FullName -Destination $Destination
  }
}

function Copy-Dotfiles {
  $cwd = pwd
  cd $PSScriptRoot
  cp -Recurse ../shared/.git* $HOME
  mkdir -Force $env:localappdata/nvim
  cp -Recurse -Force ../shared/nvim/* $env:localappdata/nvim
  mkdir -Force "$HOME/.config"
  mkdir -Force "$HOME/.config/opencode"
  cp -Recurse -Force ../shared/opencode/* "$HOME/.config/opencode"
  mkdir -Force (Split-Path $PROFILE)
  cp ./Microsoft.PowerShell_profile.ps1 $PROFILE
  cd $cwd
}
function Configure {
  try {
    Install-OpenCode
    Copy-Dotfiles
    Install-OpenCodeConfigDependencies
    Write-Host "Run nvim and execute :MasonInstallAll to complete nvim setup."
  }
  catch {
    Write-Host "Configuration failed: $_"
  }
}

function Sync-FromSystem {
  $cwd = pwd
  cd $PSScriptRoot

  try {
    Sync-FileToRepo "$HOME/.gitconfig" "../shared/.gitconfig"
    Sync-FileToRepo "$HOME/.gitignore_global" "../shared/.gitignore_global"
    Sync-FileToRepo "$HOME/.zshenv" "../shared/.zshenv"
    Sync-FileToRepo "$HOME/.zshrc" "../shared/.zshrc"
    Sync-DirectoryToRepo "$env:localappdata/nvim" "../shared/nvim"
    Sync-FileToRepo "$HOME/.config/opencode/AGENTS.md" "../shared/opencode/AGENTS.md"
    Sync-FileToRepo "$HOME/.config/opencode/opencode.jsonc" "../shared/opencode/opencode.jsonc"
    Sync-FileToRepo $PROFILE "./Microsoft.PowerShell_profile.ps1"
  }
  finally {
    cd $cwd
  }
}

if ($args[0] -eq "install" -or $args[0] -eq "") {
  Install-Packages -FullInstall:$false
  Configure
}
elseif ($args[0] -eq "install-full") {
  Install-Packages -FullInstall:$true
  Configure
}
elseif ($args[0] -eq "update-dotfiles") {
  Copy-Dotfiles
}
elseif ($args[0] -eq "sync-from-system") {
  Sync-FromSystem
}
elseif ($args[0] -like "config*") {
  Configure
}
else {
  Write-Host "Unknown command $args"
}
