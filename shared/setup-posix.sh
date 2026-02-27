#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

HOMEBREW_PACKAGES=(
  "btop"
  "fzf"
  "gh"
  "go"
  "jandedobbeleer/oh-my-posh/oh-my-posh"
  "k9s"
  "lazydocker"
  "lazygit"
  "neovim"
  "node"
  "oven-sh/bun/bun"
  "tmux"
  "yazi"
  "yq"
)

DEBIAN_PACKAGES=(
  "zsh"
  "tree"
  "curl"
  "wget"
  "git"
  "neofetch"
  "htop"
  "tmux"
)

ensure_non_root() {
  if [ "$(id -u)" -eq 0 ]; then
    echo "Run as a normal user. Script uses sudo when needed."
    exit 1
  fi
}

is_debian_family() {
  if [ ! -f /etc/os-release ]; then
    return 1
  fi

  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == "debian" || "${ID:-}" == "ubuntu" || "${ID_LIKE:-}" == *debian* ]]
}

install_debian_packages() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "apt-get not found. Unsupported Linux distribution."
    exit 1
  fi

  sudo apt-get update
  sudo apt-get install -y "${DEBIAN_PACKAGES[@]}"
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

setup_brew_shellenv() {
  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    return
  fi

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return
  fi

  if [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    return
  fi

  if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    return
  fi

  echo "brew not found after install."
  exit 1
}

install_homebrew_packages() {
  for pkg in "${HOMEBREW_PACKAGES[@]}"; do
    brew install "$pkg"
  done
}

install_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    return
  fi

  if [ "$(uname -s)" = "Darwin" ]; then
    export PNPM_HOME="$HOME/Library/pnpm"
  else
    export PNPM_HOME="$HOME/.local/share/pnpm"
  fi

  curl -fsSL https://get.pnpm.io/install.sh | sh -
}

install_opencode() {
  if ! command -v bun >/dev/null 2>&1; then
    echo "bun not found after package install."
    exit 1
  fi

  bun add -g opencode-ai
}

install_opencode_config_dependencies() {
  if [ ! -f "$HOME/.config/opencode/package.json" ]; then
    return
  fi

  (
    cd "$HOME/.config/opencode"
    bun install
  )
}

copy_dotfiles() {
  shopt -s dotglob nullglob

  for filepath in "$SCRIPT_DIR"/.*; do
    if [ -f "$filepath" ]; then
      cp -f "$filepath" "$HOME/$(basename "$filepath")"
    fi
  done

  shopt -u dotglob nullglob
}

sync_dotfiles_from_home() {
  shopt -s dotglob nullglob

  for filepath in "$SCRIPT_DIR"/.*; do
    if [ -f "$filepath" ]; then
      dotfile=$(basename "$filepath")
      if [ -f "$HOME/$dotfile" ]; then
        cp -f "$HOME/$dotfile" "$filepath"
      fi
    fi
  done

  shopt -u dotglob nullglob
}

sync_configs() {
  mkdir -p "$HOME/.config/nvim"
  cp -rf "$SCRIPT_DIR"/nvim/* "$HOME/.config/nvim/"

  mkdir -p "$HOME/.config/tmux"
  cp -rf "$SCRIPT_DIR"/tmux/* "$HOME/.config/tmux/"

  mkdir -p "$HOME/.config/opencode"
  cp -rf "$SCRIPT_DIR"/opencode/* "$HOME/.config/opencode/"
}

sync_configs_from_home() {
  if [ -d "$HOME/.config/nvim" ]; then
    mkdir -p "$SCRIPT_DIR/nvim"
    cp -rf "$HOME/.config/nvim"/* "$SCRIPT_DIR/nvim/"
  fi

  if [ -d "$HOME/.config/tmux" ]; then
    mkdir -p "$SCRIPT_DIR/tmux"
    cp -rf "$HOME/.config/tmux"/* "$SCRIPT_DIR/tmux/"
  fi

  if [ -d "$HOME/.config/opencode" ]; then
    mkdir -p "$SCRIPT_DIR/opencode"
    if [ -f "$HOME/.config/opencode/AGENTS.md" ]; then
      cp -f "$HOME/.config/opencode/AGENTS.md" "$SCRIPT_DIR/opencode/AGENTS.md"
    fi
    if [ -f "$HOME/.config/opencode/opencode.jsonc" ]; then
      cp -f "$HOME/.config/opencode/opencode.jsonc" "$SCRIPT_DIR/opencode/opencode.jsonc"
    fi
  fi
}

configure_zsh() {
  bash -c "NO_INPUT=1 $(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
  zsh -c "source ~/.zshrc && zinit self-update"
}

configure_tmux() {
  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  else
    git -C "$HOME/.tmux/plugins/tpm" pull
  fi
}

set_default_shell() {
  if command -v zsh >/dev/null 2>&1; then
    chsh -s "$(command -v zsh)" || true
  fi
}

install_packages() {
  case "$(uname -s)" in
    Linux)
      if is_debian_family; then
        install_debian_packages
      else
        echo "Only Debian/Ubuntu Linux is supported by this script."
        exit 1
      fi
      ;;
    Darwin)
      ;;
    *)
      echo "Unsupported OS: $(uname -s)"
      exit 1
      ;;
  esac

  install_homebrew
  setup_brew_shellenv
  install_homebrew_packages
  install_pnpm
  install_opencode
  set_default_shell
}

configure() {
  copy_dotfiles
  sync_configs
  install_opencode_config_dependencies
  configure_zsh
  configure_tmux

  echo "Run nvim and execute :MasonInstallAll to complete nvim setup."
  echo "Run tmux and press C-Space + I to install tmux plugins."
}

sync_from_system() {
  sync_dotfiles_from_home
  sync_configs_from_home
}

ensure_non_root

if [[ -z "${*:-}" || "${1:-}" == "install" ]]; then
  install_packages
  configure
elif [[ "${1:-}" == "update-dotfiles" ]]; then
  copy_dotfiles
  sync_configs
elif [[ "${1:-}" == "sync-from-system" ]]; then
  sync_from_system
elif [[ "${1:-}" == config* ]]; then
  configure
else
  echo "Unknown command: $*"
  exit 1
fi
