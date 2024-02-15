Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString("https://community.chocolatey.org/install.ps1"))


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
  "Microsoft.DotNet.SDK.7",
  "Microsoft.PowerShell",
  "Microsoft.PowerToys",
  "Microsoft.WindowsTerminal",
  "Mozilla.Firefox",
  "Notepad++.Notepad++",
  "Notion.Notion",
  "Obsidian.Obsidian",
  "OpenJS.NodeJS",
  "Python.Python.3.11",
  "VideoLAN.VLC",
  "WiresharkFoundation.Wireshark",
  "gerardog.gsudo",
  "Microsoft.VisualStudioCode"

);

$programs_choco = @(
  "Temurin11",
  "ghc",
  "haskell-stack",
  "make", 
  "neovim"
)

Foreach ($prg in $programs_winget) {
  winget install --exact --silent $prg
}

Foreach ($prg in $programs_choco) {
  choco install -y $prg
}

# make sure path is set correctly
$env:Path = [System.Environment]::GetEnvironmentVariable("Path",
  "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path",
  "User") 


git clone https://github.com/NvChad/NvChad $HOME\AppData\Local\nvim --depth 1 && nvim
cp -r ../shared/nvchad/ $HOME\AppData\Local\nvim\lua\custom
