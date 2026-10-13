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
    "Herdr.Herdr.Preview",
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

function Install-Pi {
  try {
    Invoke-RestMethod https://pi.dev/install.ps1 | Invoke-Expression
  }
  catch {
    Write-Host "Failed to install Pi: $_"
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

  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path.TrimEnd('\')
  $destinationPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot $Destination))
  $baseKey = $destinationPath.Substring($repoRoot.Length).TrimStart('\')
  Copy-ConfigFile $Source $destinationPath $baseKey
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

  $sourcePath = (Resolve-Path -LiteralPath $Source).Path.TrimEnd('\')
  Get-ChildItem -Force -LiteralPath $sourcePath -File -Recurse | Where-Object {
    $relative = $_.FullName.Substring($sourcePath.Length).TrimStart('\')
    $_.Name -ne ".git" -and $_.FullName -notmatch '[\\/]\.git[\\/]' -and $Exclude -notcontains ($relative -split '[\\/]')[0]
  } | ForEach-Object {
    $relative = $_.FullName.Substring($sourcePath.Length).TrimStart('\')
    Sync-FileToRepo $_.FullName (Join-Path $Destination $relative)
  }
}

function Copy-ConfigFile {
  param (
    [string]$Source,
    [string]$Destination,
    [string]$BaseKey
  )

  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path.TrimEnd('\')
  $sourcePath = (Resolve-Path -LiteralPath $Source).Path
  if (-not $BaseKey) {
    $BaseKey = $sourcePath.Substring($repoRoot.Length).TrimStart('\')
  }
  $base = Join-Path "$HOME/.dotfiles-config-base" $BaseKey
  Write-Host "Updating config: $Destination"
  mkdir -Force (Split-Path $Destination) | Out-Null

  if (Test-Path $Destination -PathType Container) {
    Write-Host "Skipping config because target is a directory: $Destination"
    return
  }

  if (-not (Test-Path $Destination)) {
    Copy-Item -LiteralPath $sourcePath -Destination $Destination -Force
    mkdir -Force (Split-Path $base) | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $base -Force
    return
  }

  if ((Get-FileHash -LiteralPath $sourcePath).Hash -eq (Get-FileHash -LiteralPath $Destination).Hash) {
    Write-Host "Already up to date: $Destination"
    mkdir -Force (Split-Path $base) | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $base -Force
    return
  }

  if ([Console]::IsInputRedirected) {
    Write-Host "Skipping existing config (no interactive input): $Destination"
    return
  }

  while ($true) {
    $choice = Read-Host "'$Destination' exists: [o]verwrite, [m]erge, [s]kip"
    if ($choice -in @("o", "O")) {
      Copy-Item -LiteralPath $sourcePath -Destination $Destination -Force
      mkdir -Force (Split-Path $base) | Out-Null
      Copy-Item -LiteralPath $sourcePath -Destination $base -Force
      Write-Host "Overwrote config: $Destination"
      return
    }
    if ($choice -in @("m", "M")) {
      if (-not (Test-Path $base) -or -not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Cannot safely merge '$Destination' without its previous config version and git; leaving it unchanged."
        return
      }
      $temp = Join-Path $env:TEMP "dotfiles-merge-$([guid]::NewGuid()).tmp"
      try {
        Copy-Item -LiteralPath $Destination -Destination $temp
        & git merge-file $temp $base $sourcePath
        if ($LASTEXITCODE -eq 0) {
          Copy-Item -LiteralPath $temp -Destination $Destination -Force
          Copy-Item -LiteralPath $sourcePath -Destination $base -Force
          Write-Host "Merged config: $Destination"
        }
        else {
          Write-Host "Merge conflicted or failed; leaving config unchanged: $Destination"
        }
      }
      finally {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
      }
      return
    }
    if ($choice -in @("s", "S")) {
      Write-Host "Skipped config: $Destination"
      return
    }
  }
}

function Set-HerdrShellValue {
  param (
    [string]$Path,
    [string]$From,
    [string]$To
  )

  $content = [IO.File]::ReadAllText($Path)
  $content = $content.Replace(('default_shell = "' + $From + '"'), ('default_shell = "' + $To + '"'))
  [IO.File]::WriteAllText($Path, $content, [Text.UTF8Encoding]::new($false))
}

function Copy-HerdrConfig {
  param (
    [string]$Source,
    [string]$Destination
  )

  $base = Join-Path "$HOME/.dotfiles-config-base" "herdr/config.toml"
  $rendered = [IO.Path]::GetTempFileName()
  try {
    Copy-Item -LiteralPath $Source -Destination $rendered -Force
    Set-HerdrShellValue $rendered '${DEFAULT_SHELL}' 'pwsh.exe'
    if (Test-Path $base) {
      Set-HerdrShellValue $base '${DEFAULT_SHELL}' 'pwsh.exe'
    }
    Copy-ConfigFile $rendered $Destination "herdr/config.toml"
  }
  finally {
    Remove-Item -LiteralPath $rendered -Force -ErrorAction SilentlyContinue
  }
}

function Sync-HerdrConfigToRepo {
  param (
    [string]$Source,
    [string]$Destination
  )

  $base = Join-Path "$HOME/.dotfiles-config-base" "herdr/config.toml"
  $normalized = [IO.Path]::GetTempFileName()
  try {
    Copy-Item -LiteralPath $Source -Destination $normalized -Force
    Set-HerdrShellValue $normalized 'pwsh.exe' '${DEFAULT_SHELL}'
    if (Test-Path $base) {
      Set-HerdrShellValue $base 'pwsh.exe' '${DEFAULT_SHELL}'
    }
    Copy-ConfigFile $normalized $Destination "herdr/config.toml"
  }
  finally {
    Remove-Item -LiteralPath $normalized -Force -ErrorAction SilentlyContinue
  }
}

function Copy-ConfigDirectory {
  param (
    [string]$Source,
    [string]$Destination
  )

  $sourcePath = (Resolve-Path -LiteralPath $Source).Path.TrimEnd('\')
  Get-ChildItem -LiteralPath $sourcePath -File -Recurse -Force | Where-Object {
    $_.Name -ne ".git" -and $_.FullName -notmatch '[\\/]\.git[\\/]'
  } | ForEach-Object {
    $relative = $_.FullName.Substring($sourcePath.Length).TrimStart('\')
    Copy-ConfigFile $_.FullName (Join-Path $Destination $relative)
  }
}

function Copy-Dotfiles {
  $shared = Join-Path $PSScriptRoot "../shared"
  Get-ChildItem -LiteralPath $shared -File -Force | Where-Object Name -Like ".*" | ForEach-Object {
    Copy-ConfigFile $_.FullName (Join-Path $HOME $_.Name)
  }
  Copy-ConfigDirectory (Join-Path $shared "nvim") "$env:LOCALAPPDATA/nvim"
  Copy-ConfigDirectory (Join-Path $shared "opencode") "$HOME/.config/opencode"
  Copy-ConfigFile (Join-Path $shared "pi/settings.json") "$HOME/.pi/agent/settings.json"
  Copy-HerdrConfig (Join-Path $shared "herdr/config.toml") "$env:APPDATA/herdr/config.toml"
  Copy-ConfigFile (Join-Path $PSScriptRoot "Microsoft.PowerShell_profile.ps1") $PROFILE
}
function Configure {
  try {
    Install-OpenCode
    Install-Pi
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
    Sync-HerdrConfigToRepo "$env:APPDATA/herdr/config.toml" (Join-Path $PSScriptRoot "../shared/herdr/config.toml")
    Sync-FileToRepo "$HOME/.config/opencode/AGENTS.md" "../shared/opencode/AGENTS.md"
    Sync-FileToRepo "$HOME/.config/opencode/opencode.jsonc" "../shared/opencode/opencode.jsonc"
    Sync-FileToRepo "$HOME/.pi/agent/settings.json" "../shared/pi/settings.json"
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
