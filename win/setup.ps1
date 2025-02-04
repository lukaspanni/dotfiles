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
    "OpenJS.NodeJS",
    "Oven-sh.Bun",
    "Python.Python.3.13",
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

function Copy-Dotfiles {
  $cwd = pwd
  cd $PSScriptRoot
  cp -Recurse ../shared/.git* $HOME
  mkdir -Force $env:localappdata/nvim
  cp -Recurse -Force ../shared/nvim/* $env:localappdata/nvim
  cp ./Microsoft.PowerShell_profile.ps1 $PROFILE
  cd $cwd
}
function Configure {
  try {
    Copy-Dotfiles
    Write-Host -NoNewLine 'To complete nvim setup, run nvim and execute :MasonInstallAll
    Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    nvim
  }
  catch {
    Write-Host "Configuration failed: $_"
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
elseif ($args[0] -like "config*") {
  Configure
}
else {
  Write-Host "Unknown command $args"
}
