#!/usr/bin/env bash
set -euo pipefail

# ════════════════════════════════════════════════════════════════
#   Salchipapa.Dots — Auto Config Installer
# ════════════════════════════════════════════════════════════════

TARGET_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$TARGET_USER" | cut -d: -f6 || true)"
: "${HOME_DIR:=$HOME}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREW_SHARE="$(dirname "$SCRIPT_DIR")/share/salchipapa-dots"
if [ -d "$BREW_SHARE" ]; then
  DOTS_DIR="$BREW_SHARE"
else
  DOTS_DIR="$HOME_DIR/Salchipapa.Dots"
fi

# ── Solarized Osaka Colors ───────────────────────────────────────
BG0=$(tput setab 0 2>/dev/null || true)     # #001014 - background
FG0=$(tput setaf 7 2>/dev/null || true)     # #9eabac - foreground
YELLOW=$(tput setaf 3 2>/dev/null || true)  # #b28500 - amber
ORANGE=$(tput setaf 5 2>/dev/null || true)  # #d23681 - magenta/pink
RED=$(tput setaf 1 2>/dev/null || true)     # #db302d - red
GREEN=$(tput setaf 2 2>/dev/null || true)   # #849900 - olive green
AQUA=$(tput setaf 6 2>/dev/null || true)    # #29a298 - teal
BLUE=$(tput setaf 4 2>/dev/null || true)    # #268bd3 - blue
PURPLE=$(tput setaf 13 2>/dev/null || true) # #d23681 - bright magenta
GRAY=$(tput setaf 15 2>/dev/null || true)   # #839395 - foreground gray
BOLD=$(tput bold 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)

# ── Logo ────────────────────────────────────────────────────────
LOGO='
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
'

# ════════════════════════════════════════════════════════════════
#   Helpers
# ════════════════════════════════════════════════════════════════

ensure_dir() { [ -d "$1" ] || mkdir -p "$1"; }

append_unique_line() {
  local line="$1" file="$2"
  grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >>"$file"
}

symlink_force() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    rm -rf "$dst"
  fi
  ln -s "$src" "$dst"
}

load_nvm_brew() {
  export NVM_DIR="$HOME_DIR/.nvm"
  mkdir -p "$NVM_DIR"
  local f
  for f in "$(brew --prefix)/opt/nvm/nvm.sh" "$(brew --prefix nvm)/nvm.sh"; do
    [ -s "$f" ] && . "$f" && return 0
  done
  return 1
}

# ════════════════════════════════════════════════════════════════
#   UI
# ════════════════════════════════════════════════════════════════

show_header() {
  clear
  echo -e "${YELLOW}${LOGO}${RESET}"
  echo -e "  ${AQUA}${BOLD}S A L C H I P A P A . D O T S${RESET}"
  echo -e "  ${GRAY}──────────────────────────────────────────────${RESET}\n"
}

section() {
  echo -e "\n${AQUA}${BOLD}  ┌─ $1${RESET}"
}

section_end() {
  echo -e "${AQUA}  └────────────────────────────────────────────${RESET}"
}

step() { echo -e "${BLUE}  │  ${GRAY}$1${RESET}"; }
ok() { echo -e "${GREEN}  │  ✔ ${RESET}$1"; }
warn() { echo -e "${YELLOW}  │  ⚠ ${RESET}$1"; }
err() { echo -e "${RED}  │  ✖ ${RESET}$1"; }

spinner() {
  local pid=$! frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "  ${YELLOW}%s${RESET}\r" "${frames:i++%${#frames}:1}"
    sleep 0.1
  done
}

run_silent() {
  step "$1"
  (eval "$2" &>/dev/null) &
  spinner
}

# ── pick_option: display to stderr, echo choice to stdout ────────
pick_option() {
  local prompt="$1"
  shift
  local options=("$@")

  echo -e "\n  ${AQUA}${BOLD}$prompt${RESET}" >&2
  echo -e "  ${GRAY}  ──────────────────────────────────────${RESET}" >&2
  for i in "${!options[@]}"; do
    echo -e "  ${YELLOW}${BOLD}  $((i + 1)))${RESET}  ${options[$i]}" >&2
  done
  echo -e "  ${GRAY}  ──────────────────────────────────────${RESET}" >&2

  local choice
  while true; do
    printf "  ${ORANGE}▶${RESET}${GRAY} Select [1-%s]: ${RESET}" "${#options[@]}" >&2
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
      echo "${options[$((choice - 1))]}"
      return
    fi
    echo -e "  ${RED}  Invalid option, try again.${RESET}" >&2
  done
}

# ════════════════════════════════════════════════════════════════
#   Setup: Shell
# ════════════════════════════════════════════════════════════════

setup_fish() {
  local brew_prefix="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
  local brew_fish="$brew_prefix/bin/fish"

  run_silent "Installing fish..." "brew install fish"

  if ! grep -qxF "$brew_fish" /etc/shells; then
    step "Adding fish to /etc/shells..."
    echo "$brew_fish" | sudo tee -a /etc/shells >/dev/null
  fi
  run_silent "Setting fish as default shell..." "sudo chsh -s '$brew_fish' '$TARGET_USER'"

  ensure_dir "$HOME_DIR/.config"
  step "Linking fish config..."
  symlink_force "$DOTS_DIR/SalchipapaFish/fish" "$HOME_DIR/.config/fish"
  ok "fish config linked."

  run_silent "Installing Fisher + plugins..." \
    "sudo -u '$TARGET_USER' -H $brew_fish -c '
      if not functions -q fisher
        curl -sL https://git.io/fisher | source
        fisher install jorgebucaran/fisher
      end
      fisher install jorgebucaran/nvm.fish patrickf1/fzf.fish oh-my-fish/plugin-pj
    '"

  run_silent "Installing Node LTS via nvm.fish..." \
    "sudo -u '$TARGET_USER' -H $brew_fish -c 'nvm install lts && nvm alias default lts'"

  ok "Fish ready."
}

setup_zsh() {
  local brew_prefix="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
  local brew_zsh="$brew_prefix/bin/zsh"

  run_silent "Installing zsh + plugins..." \
    "brew install zsh zsh-autocomplete zsh-syntax-highlighting zsh-autosuggestions"

  if ! grep -qxF "$brew_zsh" /etc/shells; then
    step "Adding zsh to /etc/shells..."
    echo "$brew_zsh" | sudo tee -a /etc/shells >/dev/null
  fi
  run_silent "Setting zsh as default shell..." "sudo chsh -s '$brew_zsh' '$TARGET_USER'"

  step "Linking .zshrc..."
  symlink_force "$DOTS_DIR/SalchipapaZsh/.zshrc" "$HOME_DIR/.zshrc"
  ok ".zshrc linked."

  run_silent "Installing Oh My Zsh (KEEP_ZSHRC)..." \
    'export RUNZSH=no CHSH=no KEEP_ZSHRC=yes; sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

  if ! brew list nvm >/dev/null 2>&1; then
    run_silent "Installing nvm via brew..." "brew install nvm"
  fi

  local bashrc="$HOME_DIR/.bashrc" zshrc="$HOME_DIR/.zshrc"
  for rc in "$bashrc" "$zshrc"; do
    touch "$rc"
    append_unique_line 'export NVM_DIR="$HOME/.nvm"' "$rc"
    append_unique_line '[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh"' "$rc"
    append_unique_line '[ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh"' "$rc"
    append_unique_line 'nvm use default >/dev/null 2>&1' "$rc"
  done

  if load_nvm_brew; then
    run_silent "Installing Node LTS..." "nvm install --lts && nvm alias default 'lts/*' && nvm use default"
  else
    warn "Could not load nvm. Run option 'Install CLIs + Lazy sync' after restarting shell."
  fi

  ok "Zsh ready."
}

# ════════════════════════════════════════════════════════════════
#   Setup: Multiplexer
# ════════════════════════════════════════════════════════════════

setup_zellij() {
  run_silent "Installing zellij..." "brew install zellij"
  ensure_dir "$HOME_DIR/.config"
  step "Linking zellij config..."
  symlink_force "$DOTS_DIR/SalchipapaZellij/zellij" "$HOME_DIR/.config/zellij"
  ok "Zellij ready."
}

setup_tmux() {
  run_silent "Installing tmux..." "brew install tmux"
  step "Linking tmux config..."
  symlink_force "$DOTS_DIR/SalchipapaTmux" "$HOME_DIR/.config/tmux"
  ok "tmux config linked."

  if [ ! -d "$HOME_DIR/.tmux/plugins/tpm" ]; then
    run_silent "Installing TPM..." \
      "git clone --depth=1 https://github.com/tmux-plugins/tpm '$HOME_DIR/.tmux/plugins/tpm'"
    ok "TPM installed. Press <prefix>+I inside tmux to load plugins."
  else
    warn "TPM already installed."
  fi

  ok "Tmux ready."
}

# ════════════════════════════════════════════════════════════════
#   Setup: Terminal
# ════════════════════════════════════════════════════════════════

setup_alacritty() {
  ensure_dir "$HOME_DIR/.config"
  step "Linking alacritty config..."
  symlink_force "$DOTS_DIR/SalchipapaAlacritty" "$HOME_DIR/.config/alacritty"
  ok "Alacritty config linked."
}

setup_wezterm() {
  step "Linking .wezterm.lua..."
  symlink_force "$DOTS_DIR/SalchipapaWezterm/.wezterm.lua" "$HOME_DIR/.wezterm.lua"
  ok "Wezterm config linked."
}

# ════════════════════════════════════════════════════════════════
#   Action: Full Install
# ════════════════════════════════════════════════════════════════

accion_install() {
  show_header

  # ── Ask configuration ──────────────────────────────────────
  local shell_choice mux_choice term_choice cli_gemini cli_angular cli_claude
  shell_choice=$(pick_option "Default shell:" "Fish" "Zsh" "Skip")
  mux_choice=$(pick_option "Terminal multiplexer:" "Zellij" "Tmux" "Skip")
  term_choice=$(pick_option "Terminal emulator config:" "Alacritty" "Wezterm" "Skip")
  cli_choice=$(pick_option "CLIs to install:" "All (Gemini + Angular + Claude Code)" "Gemini CLI" "Angular CLI" "Claude Code" "Skip")

  # ── Summary ────────────────────────────────────────────────
  echo -e "\n  ${AQUA}${BOLD}Summary${RESET}"
  echo -e "  ${GRAY}  ──────────────────────────────────────${RESET}"
  echo -e "  ${YELLOW}  Shell:${RESET}        $shell_choice"
  echo -e "  ${YELLOW}  Multiplexer:${RESET}  $mux_choice"
  echo -e "  ${YELLOW}  Terminal:${RESET}     $term_choice"
  echo -e "  ${YELLOW}  CLIs:${RESET}         $cli_choice"
  echo -e "  ${GRAY}  ──────────────────────────────────────${RESET}"
  printf "  ${ORANGE}▶${RESET}${GRAY} Proceed? [Y/n]: ${RESET}"
  read -r confirm
  [[ "${confirm,,}" =~ ^(n|no)$ ]] && {
    echo -e "  ${RED}Aborted.${RESET}\n"
    return
  }

  # ── System ─────────────────────────────────────────────────
  section "System"
  run_silent "apt update & upgrade..." "sudo apt-get update -y && sudo apt-get upgrade -y"
  run_silent "build-essential, curl, git, ca-certificates, unzip..." \
    "sudo apt-get install -y build-essential curl git ca-certificates unzip"
  ok "System packages ready."
  section_end

  # ── Homebrew ───────────────────────────────────────────────
  section "Homebrew"
  local brew_prefix="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
  if ! command -v brew >/dev/null 2>&1; then
    run_silent "Installing Homebrew..." \
      'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  else
    warn "Homebrew already installed — skipping."
  fi
  touch "$HOME_DIR/.bashrc"
  append_unique_line "" "$HOME_DIR/.bashrc"
  append_unique_line 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' "$HOME_DIR/.bashrc"
  eval "$("$brew_prefix/bin/brew" shellenv)"
  run_silent "brew update..." "brew update"
  ok "Homebrew ready."
  section_end

  # ── Core packages ──────────────────────────────────────────
  section "Core Tools"
  run_silent "gcc, nvim, node, starship, carapace, fzf, zoxide, atuin, fd, eza, bat, asm-lsp, lazygit, fastfetch, , yazi, btop..." \
    "brew install gcc nvim node starship carapace fzf zoxide atuin fd eza bat asm-lsp lazygit btop fastfetch yazi"
  ok "Core tools installed."
  section_end

  # ── Shell ──────────────────────────────────────────────────
  section "Shell — $shell_choice"
  case "$shell_choice" in
  Fish) setup_fish ;;
  Zsh) setup_zsh ;;
  Skip) ok "Skipped." ;;
  esac
  section_end

  # ── Multiplexer ────────────────────────────────────────────
  section "Multiplexer — $mux_choice"
  case "$mux_choice" in
  Zellij) setup_zellij ;;
  Tmux) setup_tmux ;;
  Skip) ok "Skipped." ;;
  esac
  section_end

  # ── Terminal ───────────────────────────────────────────────
  section "Terminal — $term_choice"
  case "$term_choice" in
  Alacritty) setup_alacritty ;;
  Wezterm) setup_wezterm ;;
  Skip) ok "Skipped." ;;
  esac
  section_end

  # ── CLIs ───────────────────────────────────────────────────
  section "CLIs"
  local brew_fish_cli="$brew_prefix/bin/fish"
  local brew_zsh_cli="$brew_prefix/bin/zsh"

  local NVM_ZSH_BOOT='
    export NVM_DIR="$HOME/.nvm"; mkdir -p "$NVM_DIR"
    for f in "$(brew --prefix)/opt/nvm/nvm.sh" "$(brew --prefix nvm)/nvm.sh"; do
      [ -s "$f" ] && . "$f" && break
    done
    nvm install --lts >/dev/null 2>&1 || true
    nvm alias default "lts/*" >/dev/null 2>&1 || true
    nvm use default >/dev/null 2>&1 || true
  '

  install_npm_cli() {
    local pkg="$1"
    if [ -x "$brew_fish_cli" ]; then
      run_silent "Installing $pkg..." \
        "sudo -u '$TARGET_USER' -H $brew_fish_cli -c 'nvm use lts --silent 2>/dev/null || true; npm i -g $pkg'"
    else
      run_silent "Installing $pkg..." \
        "sudo -u '$TARGET_USER' -H $brew_zsh_cli -ic '$NVM_ZSH_BOOT && npm i -g $pkg'"
    fi
  }

  case "$cli_choice" in
    "All (Gemini + Angular + Claude Code)")
      install_npm_cli "@google/gemini-cli"
      install_npm_cli "@angular/cli"
      install_npm_cli "@anthropic-ai/claude-code"
      ;;
    "Gemini CLI")   install_npm_cli "@google/gemini-cli" ;;
    "Angular CLI")  install_npm_cli "@angular/cli" ;;
    "Claude Code")  install_npm_cli "@anthropic-ai/claude-code" ;;
    "Skip")         ok "Skipped." ;;
  esac
  ok "CLIs done."
  section_end

  # ── Common symlinks ────────────────────────────────────────
  section "Config Symlinks"
  ensure_dir "$HOME_DIR/.config"

  step "Neovim..."
  symlink_force "$DOTS_DIR/SalchipapaNvim/nvim" "$HOME_DIR/.config/nvim"
  ok "Neovim linked."

  step "Starship..."
  symlink_force "$DOTS_DIR/starship.toml" "$HOME_DIR/.config/starship.toml"
  ok "Starship linked."

  step "Fastfetch..."
  symlink_force "$DOTS_DIR/SalchipapaFastfetch" "$HOME_DIR/.config/fastfetch"
  ok "Fastfetch linked."

  # ── Obsidian vault ─────────────────────────────────────────
  step "Obsidian vault..."
  if [ ! -d "$HOME_DIR/.config/obsidian/.git" ]; then
    git clone https://github.com/erickm13/SalchipapaNotes.git "$HOME_DIR/.config/obsidian"
  else
    warn "Obsidian vault already exists — skipping clone."
  fi
  ok "Obsidian vault ready at ~/.config/obsidian."
  section_end

  # ── Neovim Lazy sync ───────────────────────────────────────
  section "Neovim"
  run_silent "Running Lazy sync..." "nvim --headless '+Lazy! sync' +qa"
  ok "Lazy sync done."
  section_end

  # ── WSL clipboard note ─────────────────────────────────────
  if grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; then
    echo -e "\n  ${YELLOW}${BOLD}  ⚠  WSL Clipboard${RESET}"
    echo -e "  ${GRAY}  Neovim uses win32yank for clipboard in WSL.${RESET}"
    echo -e "  ${GRAY}  Install it on the Windows side:${RESET}"
    echo -e "  ${BLUE}    scoop install win32yank${RESET}${GRAY}  or  ${RESET}${BLUE}choco install win32yank${RESET}"
    echo -e "  ${GRAY}  Then make sure win32yank.exe is in your Windows PATH.${RESET}"
  fi

  echo -e "\n  ${GREEN}${BOLD}✔  Installation complete!${RESET}\n"
  echo -e "  ${YELLOW}${BOLD}  ⚠  Restart your terminal${RESET}"
  echo -e "  ${GRAY}  Close this window and open a new one for all tools to load correctly.${RESET}\n"
  read -rp "  Press [ENTER] to return to menu… "
}

# ════════════════════════════════════════════════════════════════
#   Action: Quit
# ════════════════════════════════════════════════════════════════

accion_quit() {
  clear
  echo -e "\n  ${AQUA}${BOLD}Goodbye!${RESET}  ${GRAY}salchipapa.dots${RESET}\n"
  exit 0
}

# ════════════════════════════════════════════════════════════════
#   Main Menu
# ════════════════════════════════════════════════════════════════

while true; do
  show_header
  choice=$(pick_option "What do you want to do?" \
    "Install everything" \
    "Quit")
  case "$choice" in
  "Install everything") accion_install ;;
  "Quit") accion_quit ;;
  esac
done
