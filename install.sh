#!/usr/bin/env bash
set -euo pipefail

# === Usuario/paths ===
TARGET_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$TARGET_USER" | cut -d: -f6 || true)"
: "${HOME_DIR:=$HOME}"

# === Colores Gruvbox ===
BG0=$(tput setab 235 || true)
FG0=$(tput setaf 223 || true)
YELLOW=$(tput setaf 214 || true)
ORANGE=$(tput setaf 208 || true)
RED=$(tput setaf 167 || true)
GREEN=$(tput setaf 142 || true)
AQUA=$(tput setaf 108 || true)
BLUE=$(tput setaf 109 || true)
PURPLE=$(tput setaf 175 || true)
GRAY=$(tput setaf 243 || true)
BOLD=$(tput bold || true)
RESET=$(tput sgr0 || true)

# === Logo ===
logo='
⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣶⡋⠉⠙⠒⢤⡀⠀⠀⠀⠀⠀⢠⠖⠉⠉⠙⠢⡄⠀
⠀⠀⠀⠀⠀⠀⢀⣼⣟⡒⠒⠀⠀⠀⠀⠀⠙⣆⠀⠀⠀⢠⠃⠀⠀⠀⠀⠀⠹⡄
⠀⠀⠀⠀⠀⠀⣼⠷⠖⠀⠀⠀⠀⠀⠀⠀⠀⠘⡆⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⢷
⠀⠀⠀⠀⠀⠀⣷⡒⠀⠀⢐⣒⣒⡒⠀⣐⣒⣒⣧⠀⠀⡇⠀⢠⢤⢠⡠⠀⠀⢸
⠀⠀⠀⠀⠀⢰⣛⣟⣂⠀⠘⠤⠬⠃⠰⠑⠥⠊⣿⠀⢴⠃⠀⠘⠚⠘⠑⠐⠀⢸
⠀⠀⠀⠀⠀⢸⣿⡿⠤⠀⠀⠀⠀⠀⢀⡆⠀⠀⣿⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⣸
⠀⠀⠀⠀⠀⠈⠿⣯⡭⠀⠀⠀⠀⢀⣀⠀⠀⠀⡟⠀⠀⢸⠀⠀⠀⠀⠀⠀⢠⠏
⠀⠀⠀⠀⠀⠀⠀⠈⢯⡥⠄⠀⠀⠀⠀⠀⠀⡼⠁⠀⠀⠀⠳⢄⣀⣀⣀⡴⠃⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢱⡦⣄⣀⣀⣀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠈⠉⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⣤⣾⠛⠃⠀⠀⠀⢹⠳⡶⣤⡤⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣠⢴⣿⣿⣿⡟⡷⢄⣀⣀⣀⡼⠳⡹⣿⣷⠞⣳⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢰⡯⠭⠹⡟⠿⠧⠷⣄⣀⣟⠛⣦⠔⠋⠛⠛⠋⠙⡆⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢸⣿⠭⠉⠀⢠⣤⠀⠀⠀⠘⡷⣵⢻⠀⠀⠀⠀⣼⠀⣇⠀⠀⠀⠀⠀⠀⠀
⠀⠀⡇⣿⠍⠁⠀⢸⣗⠂⠀⠀⠀⣧⣿⣼⠀⠀⠀⠀⣯⠀⢸⠀⠀⠀⠀⠀⠀⠀

S A L C H I P A P A   N E O V I M
'

# === Spinner ===
spinner() {
  local pid=$!
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf " ${YELLOW}%s${RESET}\r" "${frames:i++%${#frames}:1}"
    sleep 0.1
  done
}

run_command() {
  local command=$1
  local show="${2:-Yes}"
  if [ "$show" = "Yes" ]; then
    eval "$command"
  else
    (eval "$command" &>/dev/null) &
    spinner
  fi
}

select_option() {
  local prompt_message="$1"
  shift
  local options=("$@")
  PS3="${ORANGE}${BOLD}$prompt_message${RESET} "
  select opt in "${options[@]}"; do
    if [ -n "${opt:-}" ]; then
      echo "$opt"
      break
    else
      echo -e "${RED}Invalid option. Try again.${RESET}"
    fi
  done
}

show_header() {
  clear
  echo -e "${YELLOW}${logo}${RESET}"
  echo -e "${AQUA}${BOLD}Welcome to Salchipapa.Dots — Auto Config!${RESET}\n"
}

# === Helpers ===
ensure_dir() { [ -d "$1" ] || mkdir -p "$1"; }
append_unique_line() {
  local line="$1" file="$2"
  grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >>"$file"
}
symlink_force() {
  local src="$1" dst="$2"
  [ -e "$dst" ] || [ -L "$dst" ] && rm -rf "$dst"
  ln -s "$src" "$dst"
}

# Localizar/cargar NVM desde Linuxbrew de forma robusta
load_nvm() {
  export NVM_DIR="$HOME_DIR/.nvm"
  mkdir -p "$NVM_DIR"
  local f
  for f in "$(brew --prefix)/opt/nvm/nvm.sh" "$(brew --prefix nvm)/nvm.sh"; do
    if [ -s "$f" ]; then
      # shellcheck disable=SC1090
      . "$f"
      return 0
    fi
  done
  return 1
}

# === Acción principal: Install ===
accion_install() {
  clear
  show_header
  echo -e "${ORANGE}→ Installing Salchipapa.Dots...${RESET}"
  (sleep 1) &
  spinner

  echo -e "${BLUE}• Updating system (apt)…${RESET}"
  run_command "sudo apt-get update -y && sudo apt-get upgrade -y" "No"
  echo -e "${BLUE}• Installing build-essential, curl, git…${RESET}"
  run_command "sudo apt-get install -y build-essential curl git ca-certificates" "No"

  # Homebrew
  if ! command -v brew >/dev/null 2>&1; then
    echo -e "${BLUE}• Installing Homebrew (Linuxbrew)…${RESET}"
    run_command 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' "No"
  else
    echo -e "${GRAY}  Homebrew already installed.${RESET}"
  fi

  # PATH de brew en bashrc del usuario
  BREW_PREFIX="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
  BASHRC_PATH="$HOME_DIR/.bashrc"
  ensure_dir "$HOME_DIR"
  touch "$BASHRC_PATH"
  append_unique_line "" "$BASHRC_PATH"
  append_unique_line 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' "$BASHRC_PATH"
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"

  echo -e "${BLUE}• Installing brew packages…${RESET}"
  run_command "brew update" "No"
  run_command "brew install gcc nvim zsh zsh-autocomplete zsh-syntax-highlighting zsh-autosuggestions carapace fzf zoxide atuin zellij fd eza bat nvm" "No"

  # NVM + Node (sin CLIs globales aquí; van en Opción 2)
  echo -e "${BLUE}• Configuring nvm and Node…${RESET}"
  if ! brew list nvm >/dev/null 2>&1; then run_command "brew install nvm" "No"; fi
  if load_nvm; then
    run_command "nvm install --lts" "No"
    run_command "nvm alias default 'lts/*'" "No"
    run_command "nvm use default" "No"
  else
    echo -e "${RED}✖ Could not load nvm.sh from Homebrew. You can still use Option 2 to install CLIs.${RESET}"
  fi

  # Zsh brew como shell por defecto
  BREW_ZSH="$BREW_PREFIX/bin/zsh"
  if ! grep -qxF "$BREW_ZSH" /etc/shells; then
    echo -e "${BLUE}• Adding brew zsh to /etc/shells…${RESET}"
    echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
  fi
  echo -e "${BLUE}• Setting brew zsh as default shell…${RESET}"
  run_command "sudo chsh -s '$BREW_ZSH' '$TARGET_USER'" "No"

  # Zsh config + Oh My Zsh (no sobrescribir .zshrc)
  echo -e "${BLUE}• Linking Zsh config…${RESET}"
  symlink_force "$HOME_DIR/Salchipapa.Dots/SalchipapaZsh/.zshrc" "$HOME_DIR/.zshrc"

  echo -e "${BLUE}• Installing Oh My Zsh (KEEP_ZSHRC)…${RESET}"
  run_command 'export RUNZSH=no CHSH=no KEEP_ZSHRC=yes; sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"' "No"

  # NVM en bash y zsh para futuras sesiones
  append_unique_line 'export NVM_DIR="$HOME/.nvm"' "$BASHRC_PATH"
  append_unique_line '[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh"' "$BASHRC_PATH"
  append_unique_line '[ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh"' "$BASHRC_PATH"
  append_unique_line 'nvm use default >/dev/null 2>&1' "$BASHRC_PATH"

  ZSHRC_PATH="$HOME_DIR/.zshrc"
  append_unique_line 'export NVM_DIR="$HOME/.nvm"' "$ZSHRC_PATH"
  append_unique_line '[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh"' "$ZSHRC_PATH"
  append_unique_line '[ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh"' "$ZSHRC_PATH"
  append_unique_line 'nvm use default >/dev/null 2>&1' "$ZSHRC_PATH"

  # Zellij / Neovim symlinks
  ensure_dir "$HOME_DIR/.config"
  echo -e "${BLUE}• Linking Zellij config…${RESET}"
  symlink_force "$HOME_DIR/Salchipapa.Dots/SalchipapaZellij/zellij" "$HOME_DIR/.config/zellij"
  echo -e "${BLUE}• Linking Neovim config…${RESET}"
  symlink_force "$HOME_DIR/Salchipapa.Dots/SalchipapaNvim/nvim" "$HOME_DIR/.config/nvim"

  # Source zshrc en subshell y Lazy sync
  echo -e "${BLUE}• Sourcing .zshrc (subshell)…${RESET}"
  run_command "sudo -u '$TARGET_USER' -H $BREW_ZSH -ic 'source ~/.zshrc'" "No"

  echo -e "${BLUE}• Running Lazy sync (Neovim)…${RESET}"
  run_command "sudo -u '$TARGET_USER' -H nvim --headless '+Lazy! sync' +qa" "No"

  echo -e "${GREEN}✔ Installation completed successfully!${RESET}\n"
  read -rp "Press [ENTER] to return to menu…"
}

# === Opción 2: instalar CLIs por separado + Lazy sync ===
accion_cli() {
  clear
  show_header
  echo -e "${ORANGE}→ Installing Gemini/Angular CLIs and running Lazy sync…${RESET}"

  if ! command -v brew >/dev/null 2>&1; then
    echo -e "${RED}✖ Homebrew no está instalado. Ejecuta primero la opción 'Install'.${RESET}"
    read -rp "Press [ENTER] to return to menu…"
    return
  fi

  BREW_PREFIX="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
  BREW_ZSH="$BREW_PREFIX/bin/zsh"

  if ! brew list nvm >/dev/null 2>&1; then
    echo -e "${BLUE}• Installing nvm via Homebrew…${RESET}"
    run_command "brew install nvm" "No"
  fi

  # Bootstrap NVM dentro de Zsh del usuario y luego instalar cada CLI
  NVM_BOOT='
    export NVM_DIR="$HOME/.nvm";
    mkdir -p "$NVM_DIR";
    for f in "$(brew --prefix)/opt/nvm/nvm.sh" "$(brew --prefix nvm)/nvm.sh"; do
      [ -s "$f" ] && . "$f" && break
    done
    nvm install --lts >/dev/null 2>&1 || true
    nvm alias default "lts/*" >/dev/null 2>&1 || true
    nvm use default >/dev/null 2>&1 || true
  '

  echo -e "${BLUE}• Installing @google/gemini-cli…${RESET}"
  run_command "sudo -u '$TARGET_USER' -H $BREW_ZSH -ic '$NVM_BOOT && npm i -g @google/gemini-cli'" "No"

  echo -e "${BLUE}• Installing @angular/cli…${RESET}"
  run_command "sudo -u '$TARGET_USER' -H $BREW_ZSH -ic '$NVM_BOOT && npm i -g @angular/cli'" "No"

  echo -e "${BLUE}• Verifying commands…${RESET}"
  run_command "sudo -u '$TARGET_USER' -H $BREW_ZSH -ic 'command -v gemini && gemini --version || true'" "No"
  run_command "sudo -u '$TARGET_USER' -H $BREW_ZSH -ic 'command -v ng && ng version || true'" "No"

  echo -e "${BLUE}• Running Neovim Lazy sync…${RESET}"
  run_command "sudo -u '$TARGET_USER' -H nvim --headless '+Lazy! sync' +qa" "No"

  echo -e "${GREEN}✔ CLIs installed and Lazy sync completed!${RESET}\n"
  read -rp "Press [ENTER] to return to menu…"
}

# === Salir ===
accion_quit() {
  clear
  echo -e "${RED}${BOLD}Goodbye 👋${RESET}"
  exit 0
}

# === Loop principal ===
while true; do
  show_header
  echo -e "${GRAY}${BOLD}-------------------------------------------${RESET}"
  choice=$(select_option "Choose an option:" "Install" "Install CLIs + Lazy sync" "Quit")
  case "$choice" in
  Install) accion_install ;;
  "Install CLIs + Lazy sync") accion_cli ;;
  Quit) accion_quit ;;
  esac
done
