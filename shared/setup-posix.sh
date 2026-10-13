#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

HOMEBREW_PACKAGES=(
  "btop"
  "fzf"
  "gh"
  "go"
  "herdr"
  "jandedobbeleer/oh-my-posh/oh-my-posh"
  "k9s"
  "lazydocker"
  "lazygit"
  "neovim"
  "node"
  "oven-sh/bun/bun"
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

install_pi() {
  curl -fsSL https://pi.dev/install.sh | sh
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

copy_config_file() {
  local source=$1 target=$2 base_key=${3:-${1#"$SCRIPT_DIR"/}} base answer temp
  base="$HOME/.dotfiles-config-base/$base_key"
  echo "Updating config: $target"
  mkdir -p "$(dirname "$target")"

  if [ -d "$target" ]; then
    echo "Skipping config because target is a directory: $target"
    return
  fi

  if [ ! -e "$target" ]; then
    cp -f "$source" "$target"
    mkdir -p "$(dirname "$base")"
    cp -f "$source" "$base"
    return
  fi

  if cmp -s "$source" "$target"; then
    echo "Already up to date: $target"
    mkdir -p "$(dirname "$base")"
    cp -f "$source" "$base"
    return
  fi

  if [ ! -t 0 ]; then
    echo "Skipping existing config (no interactive input): $target"
    return
  fi

  while true; do
    read -r -p "'$target' exists: [o]verwrite, [m]erge, [s]kip? " answer
    case "$answer" in
      o|O)
        cp -f "$source" "$target"
        mkdir -p "$(dirname "$base")"
        cp -f "$source" "$base"
        echo "Overwrote config: $target"
        return
        ;;
      m|M)
        if [ ! -f "$base" ] || ! command -v git >/dev/null 2>&1; then
          echo "Cannot safely merge '$target' without its previous config version and git; leaving it unchanged."
          return
        fi
        temp=$(mktemp)
        cp -f "$target" "$temp"
        if git merge-file "$temp" "$base" "$source"; then
          cp -f "$temp" "$target"
          cp -f "$source" "$base"
          echo "Merged config: $target"
        else
          echo "Merge conflicted or failed; leaving config unchanged: $target"
        fi
        rm -f "$temp"
        return
        ;;
      s|S)
        echo "Skipped config: $target"
        return
        ;;
    esac
  done
}

copy_config_directory() {
  local source_dir=$1 target_dir=$2 filepath relative
  while IFS= read -r -d '' filepath; do
    relative=${filepath#"$source_dir"/}
    copy_config_file "$filepath" "$target_dir/$relative"
  done < <(find "$source_dir" -type d -name .git -prune -o -type f ! -name .git -print0)
}

copy_dotfiles() {
  shopt -s dotglob nullglob

  for filepath in "$SCRIPT_DIR"/.*; do
    if [ -f "$filepath" ]; then
      copy_config_file "$filepath" "$HOME/$(basename "$filepath")"
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
        copy_config_file "$HOME/$dotfile" "$filepath" "$dotfile"
      fi
    fi
  done

  shopt -u dotglob nullglob
}

copy_herdr_config() {
  local source=$1 target=$2 base_key=${3:-herdr/config.toml} base rendered status
  base="$HOME/.dotfiles-config-base/$base_key"
  rendered=$(mktemp)
  sed 's/default_shell = "${DEFAULT_SHELL}"/default_shell = "zsh"/' "$source" > "$rendered"
  if [ -f "$base" ]; then
    sed 's/default_shell = "${DEFAULT_SHELL}"/default_shell = "zsh"/' "$base" > "$base.tmp"
    mv -f "$base.tmp" "$base"
  fi
  if copy_config_file "$rendered" "$target" "$base_key"; then status=0; else status=$?; fi
  rm -f "$rendered"
  return "$status"
}

sync_herdr_config_from_home() {
  local source=$1 target=$2 base_key=${3:-herdr/config.toml} base normalized status
  base="$HOME/.dotfiles-config-base/$base_key"
  normalized=$(mktemp)
  sed 's/default_shell = "zsh"/default_shell = "${DEFAULT_SHELL}"/' "$source" > "$normalized"
  if [ -f "$base" ]; then
    sed 's/default_shell = "zsh"/default_shell = "${DEFAULT_SHELL}"/' "$base" > "$base.tmp"
    mv -f "$base.tmp" "$base"
  fi
  if copy_config_file "$normalized" "$target" "$base_key"; then status=0; else status=$?; fi
  rm -f "$normalized"
  return "$status"
}

sync_configs() {
  copy_config_directory "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
  copy_herdr_config "$SCRIPT_DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml"
  copy_config_directory "$SCRIPT_DIR/opencode" "$HOME/.config/opencode"
  copy_config_file "$SCRIPT_DIR/pi/settings.json" "$HOME/.pi/agent/settings.json"
}

sync_config_directory_from_home() {
  local source_dir=$1 target_dir=$2 filepath relative base_key
  while IFS= read -r -d '' filepath; do
    relative=${filepath#"$source_dir"/}
    base_key=${target_dir#"$SCRIPT_DIR"/}/$relative
    copy_config_file "$filepath" "$target_dir/$relative" "$base_key"
  done < <(find "$source_dir" -type d -name .git -prune -o -type f ! -name .git -print0)
}

sync_configs_from_home() {
  if [ -d "$HOME/.config/nvim" ]; then
    sync_config_directory_from_home "$HOME/.config/nvim" "$SCRIPT_DIR/nvim"
  fi

  if [ -f "$HOME/.config/herdr/config.toml" ]; then
    sync_herdr_config_from_home "$HOME/.config/herdr/config.toml" "$SCRIPT_DIR/herdr/config.toml"
  fi

  if [ -d "$HOME/.config/opencode" ]; then
    sync_config_directory_from_home "$HOME/.config/opencode" "$SCRIPT_DIR/opencode"
  fi

  if [ -f "$HOME/.pi/agent/settings.json" ]; then
    copy_config_file "$HOME/.pi/agent/settings.json" "$SCRIPT_DIR/pi/settings.json" "pi/settings.json"
  fi
}

configure_zsh() {
  bash -c "NO_INPUT=1 $(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
  zsh -c "source ~/.zshrc && zinit self-update"
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
  install_pi
  set_default_shell
}

configure() {
  copy_dotfiles
  sync_configs
  install_opencode_config_dependencies
  configure_zsh

  echo "Run nvim and execute :MasonInstallAll to complete nvim setup."
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
