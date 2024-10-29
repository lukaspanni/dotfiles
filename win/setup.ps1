function Install-Packages {
  param (
    [switch]$FullInstall
  )

  $programs_winget = @(
    "Canonical.Ubuntu2404",
    "Docker.DockerDesktop",
    "Git.Git",
    "GitHub.cli",
    "Google.Chrome",
    "gsass1.NTop",
    "JanDeDobbeleer.OhMyPosh",
    "JesseDuffield.lazydocker", 
    "JesseDuffield.lazygit", 
    "Microsoft.DotNet.SDK.8",
    "Microsoft.PowerShell",
    "Microsoft.PowerToys",
    "Microsoft.WindowsTerminal",
    "Mozilla.Firefox",
    "Notepad++.Notepad++",
    "Obsidian.Obsidian",
    "Oven-sh.Bun",
    "OpenJS.NodeJS",
    "Python.Python.3.13",
    "gerardog.gsudo",
    "Microsoft.VisualStudioCode",
    "Neovim.Neovim",
    "GoLang.Go"
  )

  $optional_winget = @(
    "IDRIX.VeraCrypt",
    "Duplicati.Duplicati",
    "Insecure.Nmap",
    "WiresharkFoundation.Wireshark",
    "MiKTeX.MiKTeX",
    "Microsoft.OpenJDK.21",
    "VideoLAN.VLC",
    "Notion.Notion"
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

function Configure {
  try {
    $cwd = pwd
    cd $PSScriptRoot
    cp -r ../shared/.git* $HOME
    cp -r ../shared/nvim $env:localappdata/nvim
    Write-Host -NoNewLine 'To complete nvim setup, run nvim and execute :MasonInstallAll
    Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    nvim
    cp ./Microsoft.PowerShell_profile.ps1 $PROFILE
    cd $cwd
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
elseif ($args[0] -like "config*") {
  Configure
}
else {
  Write-Host "Unknown command $args"
}
