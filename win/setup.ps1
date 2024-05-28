  $programs_winget = @(
  "Debian.Debian",
  "Docker.DockerDesktop",
  "Duplicati.Duplicati",
  "Git.Git",
  "GitHub.cli",
  "Google.Chrome",
  "gsass1.NTop",
  "IDRIX.VeraCrypt",
  "Insecure.Nmap",
  "JanDeDobbeleer.OhMyPosh",
  "JesseDuffield.lazydocker", 
  "JesseDuffield.lazygit", 
  "MiKTeX.MiKTeX",
  "Microsoft.DotNet.SDK.8",
  "Microsoft.PowerShell",
  "Microsoft.PowerToys",
  "Microsoft.WindowsTerminal",
  "Mozilla.Firefox",
  "Notepad++.Notepad++",
  "Notion.Notion",
  "Obsidian.Obsidian",
  "OpenJS.NodeJS",
  "Python.Python.3.12",
  "VideoLAN.VLC",
  "WiresharkFoundation.Wireshark",
  "gerardog.gsudo",
  "Microsoft.VisualStudioCode",
  "Microsoft.OpenJDK.21",
  "Neovim.Neovim",
  "GoLang.Go"
);


Foreach ($prg in $programs_winget) {
  winget install --exact --silent $prg
}

# make sure path is set correctly
$env:Path = [System.Environment]::GetEnvironmentVariable("Path",
  "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path",
  "User") 


if (!(Test-Path $env:localappdata\nvim)) {
  git clone https://github.com/NvChad/NvChad $env:localappdata\nvim --depth 1 && nvim
}else {
  $cwd = pwd
  cd $HOME\AppData\Local\nvim
  git pull --rebase
  cd $cwd
}

cp -r ../shared/nvchad/ $HOME\AppData\Local\nvim\lua\custom
cp -r ../shared/.git* $HOME
cp ./Microsoft.PowerShell_profile.ps1 $PROFILE
