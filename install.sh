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
  if [ ! -d "$HOME_DIR/Salchipapa.Dots/.git" ]; then
    git clone https://github.com/erickm13/Salchipapa.Dots.git "$HOME_DIR/Salchipapa.Dots"
  fi
  DOTS_DIR="$HOME_DIR/Salchipapa.Dots"
else
  DOTS_DIR="$HOME_DIR/Salchipapa.Dots"
fi

# ── Distro: Arch (pacman) or Debian-based (apt + Homebrew) ──────
IS_ARCH=0
command -v pacman >/dev/null 2>&1 && IS_ARCH=1

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

# Install packages with pacman on Arch, brew elsewhere
pkg_install() {
  if [ "$IS_ARCH" -eq 1 ]; then
    sudo pacman -S --needed --noconfirm "$@"
  else
    brew install "$@"
  fi
}

# Run a command as the target user (needed for makepkg, which refuses root)
as_user() {
  if [ "$(id -u)" -eq 0 ]; then
    sudo -u "$TARGET_USER" -H "$@"
  else
    "$@"
  fi
}

# Arch: install yay (AUR helper) from yay-bin if missing
install_yay() {
  command -v yay >/dev/null 2>&1 && return 0
  if [ "$TARGET_USER" = "root" ]; then
    warn "yay can't be built as root — create a normal user to use it."
    return 0
  fi
  local tmp
  tmp="$(as_user mktemp -d)"
  as_user git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && as_user makepkg --noconfirm)
  sudo pacman -U --noconfirm "$tmp"/yay-bin/yay-bin-*.pkg.tar.zst
  rm -rf "$tmp"
}

# Arch: carapace isn't in the official repos, install the release binary
install_carapace_bin() {
  command -v carapace >/dev/null 2>&1 && return 0
  local tmp url
  tmp="$(mktemp -d)"
  url="$(curl -fsSL https://api.github.com/repos/carapace-sh/carapace-bin/releases/latest |
    grep -oE '"browser_download_url": "[^"]*linux_amd64\.tar\.gz"' | cut -d'"' -f4)"
  curl -fsSL "$url" -o "$tmp/carapace.tgz"
  tar xzf "$tmp/carapace.tgz" -C "$tmp" carapace
  sudo install -m755 "$tmp/carapace" /usr/local/bin/carapace
  rm -rf "$tmp"
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

# Install-run state: log of every silent step, failures for the final summary, section counter
LOG_FILE=/dev/null
FAILED_STEPS=()
SECTION_N=0
SECTION_TOTAL=0

section() {
  local counter=""
  if [ "$SECTION_TOTAL" -gt 0 ]; then
    SECTION_N=$((SECTION_N + 1))
    counter="${GRAY}[${SECTION_N}/${SECTION_TOTAL}]${RESET}${AQUA}${BOLD} "
  fi
  echo -e "\n${AQUA}${BOLD}  ┌─ ${counter}$1${RESET}"
}

section_end() {
  echo -e "${AQUA}  └────────────────────────────────────────────${RESET}"
}

step() { echo -e "${BLUE}  │  ${GRAY}$1${RESET}"; }
ok() { echo -e "${GREEN}  │  ✔ ${RESET}$1"; }
warn() { echo -e "${YELLOW}  │  ⚠ ${RESET}$1"; }
err() { echo -e "${RED}  │  ✖ ${RESET}$1"; }

# spinner <pid> <label> <start-seconds>: one line with the label and elapsed time, redrawn in place
spinner() {
  local pid="$1" label="$2" start="$3" frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r${BLUE}  │  ${YELLOW}%s ${GRAY}%s ${BLUE}%ss${RESET}\033[K" \
      "${frames:i++%${#frames}:1}" "$label" "$((SECONDS - start))"
    sleep 0.1
  done
  printf "\r\033[K"
}

# run_silent <label> <command>: runs the command quietly (output to LOG_FILE), then shows ✔ or ✖.
# A failure is recorded for the final summary and shows the step's last log lines; the install goes on.
run_silent() {
  local label="$1" cmd="$2" start=$SECONDS rc=0 before=0 pid
  if [ "$LOG_FILE" != /dev/null ]; then
    before=$(wc -l <"$LOG_FILE")
    printf '\n### %s\n$ %s\n' "$label" "$cmd" >>"$LOG_FILE"
  fi
  (eval "$cmd") >>"$LOG_FILE" 2>&1 &
  pid=$!
  spinner "$pid" "$label" "$start"
  wait "$pid" || rc=$?
  if [ "$rc" -eq 0 ]; then
    ok "$label ${GRAY}($((SECONDS - start))s)${RESET}"
  else
    err "$label ${GRAY}($((SECONDS - start))s, exit $rc)${RESET}"
    FAILED_STEPS+=("$label")
    if [ "$LOG_FILE" != /dev/null ]; then
      # skip the 3 header lines this step wrote (blank, "### label", "$ command")
      tail -n +"$((before + 4))" "$LOG_FILE" | tail -n 5 | sed "s/^/  │    ${GRAY}/; s/\$/${RESET}/"
    fi
  fi
  return 0
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

# picked <option-prefix> <choices...>: true if one of the choices starts with the prefix
picked() {
  local want="$1" c
  shift
  for c in "$@"; do [[ "$c" == "$want"* ]] && return 0; done
  return 1
}

# join_list <items...>: "a, b, c" (or "Skip" when empty)
join_list() {
  local s
  s="$(printf '%s, ' "$@")"
  s="${s%, }"
  echo "${s:-Skip}"
}

# ── pick_multi: several choices ("1 3 4", "a" = all, Enter = none); one per line to stdout ──
pick_multi() {
  local prompt="$1"
  shift
  local options=("$@") i n

  echo -e "\n  ${AQUA}${BOLD}$prompt${RESET}" >&2
  echo -e "  ${GRAY}  ──────────────────────────────────────${RESET}" >&2
  for i in "${!options[@]}"; do
    echo -e "  ${YELLOW}${BOLD}  $((i + 1)))${RESET}  ${options[$i]}" >&2
  done
  echo -e "  ${GRAY}  ──────────────────────────────────────${RESET}" >&2

  local input ok_input
  while true; do
    printf "  ${ORANGE}▶${RESET}${GRAY} Select (e.g. 1 3, a = all, Enter = none): ${RESET}" >&2
    read -r input
    input="${input//,/ }"
    if [ -z "$input" ]; then
      return
    elif [ "${input,,}" = "a" ]; then
      printf '%s\n' "${options[@]}"
      return
    fi
    ok_input=1
    for n in $input; do
      if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ] || [ "$n" -gt "${#options[@]}" ]; then
        ok_input=0
      fi
    done
    if [ "$ok_input" -eq 1 ]; then
      for i in "${!options[@]}"; do
        [[ " $input " == *" $((i + 1)) "* ]] && echo "${options[$i]}"
      done
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
  [ "$IS_ARCH" -eq 1 ] && brew_fish="/usr/bin/fish"

  step "Installing fish..."
  pkg_install fish

  if ! grep -qxF "$brew_fish" /etc/shells; then
    step "Adding fish to /etc/shells..."
    echo "$brew_fish" | sudo tee -a /etc/shells >/dev/null
  fi
  step "Setting fish as default shell..."
  sudo chsh -s "$brew_fish" "$TARGET_USER"

  ensure_dir "$HOME_DIR/.config"
  step "Linking fish config..."
  symlink_force "$DOTS_DIR/SalchipapaFish/fish" "$HOME_DIR/.config/fish"
  ok "fish config linked."

  step "Installing Fisher + plugins..."
  sudo -u "$TARGET_USER" -H "$brew_fish" --no-config -c '
    if test -f ~/.config/fish/functions/fisher.fish
      source ~/.config/fish/functions/fisher.fish
    else
      curl -sL https://git.io/fisher | source
      fisher install jorgebucaran/fisher >/dev/null 2>&1
    end
    rm -f ~/.config/fish/functions/_nvm_version_activate.fish \
          ~/.config/fish/functions/_nvm_version_deactivate.fish \
          ~/.config/fish/functions/_nvm_index_update.fish \
          ~/.config/fish/functions/_nvm_list.fish \
          ~/.config/fish/completions/nvm.fish \
          ~/.config/fish/conf.d/nvm.fish \
          ~/.config/fish/functions/pj.fish \
          ~/.config/fish/completions/pj.fish
    fisher install jorgebucaran/nvm.fish patrickf1/fzf.fish oh-my-fish/plugin-pj >/dev/null 2>&1
  '

  ok "Fish ready."
}

setup_zsh() {
  local brew_prefix="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
  local brew_zsh="$brew_prefix/bin/zsh"
  [ "$IS_ARCH" -eq 1 ] && brew_zsh="/usr/bin/zsh"

  run_silent "Installing zsh + plugins..." \
    "pkg_install zsh zsh-autocomplete zsh-syntax-highlighting zsh-autosuggestions"

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

  # Arch: Node comes from pacman (nodejs/npm); .zshrc loads the nvm package if present
  if [ "$IS_ARCH" -eq 1 ]; then
    ok "Zsh ready."
    return
  fi

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
    warn "Could not load nvm. Re-run the installer after restarting the shell."
  fi

  ok "Zsh ready."
}

# ════════════════════════════════════════════════════════════════
#   Setup: Multiplexer
# ════════════════════════════════════════════════════════════════

setup_zellij() {
  run_silent "Installing zellij..." "pkg_install zellij"
  ensure_dir "$HOME_DIR/.config"
  step "Linking zellij config..."
  symlink_force "$DOTS_DIR/SalchipapaZellij/zellij" "$HOME_DIR/.config/zellij"
  ok "Zellij ready."
}

setup_tmux() {
  run_silent "Installing tmux..." "pkg_install tmux"
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

# Claude Code hooks from SalchipapaClaude/hooks, merged into ~/.claude/settings.json:
# only missing hooks are added (matched by command), existing settings are kept.
setup_claude_hooks() {
  local settings="$HOME_DIR/.claude/settings.json" hooks_dir="$DOTS_DIR/SalchipapaClaude/hooks" tmp
  if ! command -v jq >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
    warn "Claude Code hooks skipped (need jq and python3)."
    return 0
  fi
  as_user mkdir -p "$HOME_DIR/.claude"
  [ -s "$settings" ] || printf '{}\n' | write_as_user "$settings"
  if ! jq empty "$settings" 2>/dev/null; then
    warn "$settings is not valid JSON — Claude Code hooks skipped."
    return 0
  fi
  as_user cp "$settings" "$settings.bak"
  tmp="$(mktemp)"
  jq --arg guard "python3 $hooks_dir/guard-bash.py" \
    --arg secrets "python3 $hooks_dir/secret-scan.py" \
    --arg validate "python3 $hooks_dir/validate-dotfiles.py" '
    def addhook(ev; m; h):
      .hooks[ev] = ((.hooks[ev] // []) as $arr
        | if any($arr[]?.hooks[]?; .command == h.command) then $arr
          elif any($arr[]?; .matcher == m) then $arr | map(if .matcher == m then .hooks += [h] else . end)
          else $arr + [{matcher: m, hooks: [h]}] end);
    .hooks //= {}
    | addhook("PreToolUse"; "Bash"; {type: "command", command: $guard, timeout: 10, statusMessage: "Revisando comando peligroso..."})
    | addhook("PreToolUse"; "Bash"; {type: "command", command: $secrets, timeout: 20, statusMessage: "Buscando secretos antes de subir..."})
    | addhook("PostToolUse"; "Edit|Write"; {type: "command", command: $validate, timeout: 30, statusMessage: "Validando dotfiles..."})
  ' "$settings" >"$tmp" && write_as_user "$settings" <"$tmp"
  rm -f "$tmp"
  ok "Claude Code hooks: guard-bash, secret-scan, validate-dotfiles (backup: $settings.bak)."
}

# setup_github <mode> <name> <email> <token>: GitHub login through gh (browser or token) and git identity.
# The token only reaches gh through stdin (printf is a builtin: never in ps, the log or a file of ours);
# gh keeps it in the system keyring. `gh auth setup-git` lets git use it for HTTPS (private vault clone).
setup_github() {
  local mode="$1" name="$2" email="$3" token="$4" login
  if [ "$mode" != "Git name/email only" ]; then
    if ! command -v gh >/dev/null 2>&1; then
      if [ "$IS_ARCH" -eq 1 ]; then
        run_silent "github-cli..." "sudo pacman -S --needed --noconfirm github-cli"
      else
        run_silent "gh..." "brew install gh"
      fi
    fi
    if as_user gh auth status >/dev/null 2>&1; then
      ok "GitHub: already logged in as $(as_user gh api user -q .login 2>/dev/null)."
    elif [ "$mode" = "Log in with a token" ]; then
      if [ -z "$token" ]; then
        warn "No token entered — GitHub login skipped."
      elif printf '%s\n' "$token" | as_user gh auth login --hostname github.com --git-protocol https --with-token >>"$LOG_FILE" 2>&1; then
        ok "GitHub: logged in with the token."
      else
        err "GitHub token rejected (check its scopes: repo, read:org)."
        FAILED_STEPS+=("GitHub login (token)")
      fi
    else
      # Interactive: one-time code + browser (on WSL it opens the Windows browser through wslview)
      step "GitHub login: copy the one-time code and confirm it in the browser..."
      if as_user gh auth login --hostname github.com --git-protocol https --web </dev/tty; then
        ok "GitHub: logged in."
      else
        err "GitHub login failed or was cancelled."
        FAILED_STEPS+=("GitHub login (browser)")
      fi
    fi
    if as_user gh auth status >/dev/null 2>&1; then
      as_user gh auth setup-git >>"$LOG_FILE" 2>&1 && ok "git uses gh for GitHub over HTTPS."
      # Identity from the GitHub account when left empty (private email → GitHub's noreply address)
      login="$(as_user gh api user -q .login 2>/dev/null)"
      [ -n "$name" ] || [ -n "$(as_user git config --global user.name)" ] ||
        name="$(as_user gh api user -q '.name // .login' 2>/dev/null)"
      [ -n "$email" ] || [ -n "$(as_user git config --global user.email)" ] ||
        email="$(as_user gh api user -q '.email // empty' 2>/dev/null)"
      [ -n "$email" ] || [ -n "$(as_user git config --global user.email)" ] || [ -z "$login" ] ||
        email="$(as_user gh api user -q .id 2>/dev/null)+$login@users.noreply.github.com"
    fi
  fi
  [ -n "$name" ] && as_user git config --global user.name "$name"
  [ -n "$email" ] && as_user git config --global user.email "$email"
  name="$(as_user git config --global user.name)"
  email="$(as_user git config --global user.email)"
  if [ -n "$name" ] && [ -n "$email" ]; then
    ok "Git identity: $name <$email>"
  else
    warn "Git identity incomplete — set it with: git config --global user.name/user.email"
  fi
}

# Obsidian vault as shared memory of Claude Code / Codex / opencode / Copilot CLI (SalchipapaObsidian):
# instructions, session hooks (sync + welcome), opencode plugin and the nightly daily-note timer.
setup_agent_memory() {
  if ! command -v python3 >/dev/null 2>&1; then
    warn "Agent memory skipped (needs python3)."
    return 0
  fi
  step "Agent memory (Obsidian)..."
  if as_user python3 "$DOTS_DIR/SalchipapaObsidian/setup-agents.py" >>"$LOG_FILE" 2>&1; then
    ok "Agents share the vault: sync on session start/end + welcome."
  else
    err "Agent memory setup failed (see $LOG_FILE)."
    return 0
  fi
  if as_user systemctl --user daemon-reload >/dev/null 2>&1 &&
    as_user systemctl --user enable --now obsidian-daily.timer obsidian-weekly.timer >/dev/null 2>&1; then
    ok "Daily note (23:30) and weekly review (Sun 20:00) timers enabled."
  else
    warn "Enable them later: systemctl --user enable --now obsidian-daily.timer obsidian-weekly.timer"
  fi
}

setup_herdr() {
  # Official installer: release binary to ~/.local/bin with SHA-256 check (updates: `herdr update`)
  if ! as_user sh -c 'command -v herdr || test -x "$HOME/.local/bin/herdr"' >/dev/null 2>&1; then
    run_silent "Installing herdr..." "as_user sh -c 'curl -fsSL https://herdr.dev/install.sh | sh'"
  else
    warn "herdr already installed — skipping (update with: herdr update)."
  fi
  # Only link config.toml: ~/.config/herdr also holds herdr's sockets, logs and session state
  as_user mkdir -p "$HOME_DIR/.config/herdr"
  step "Linking herdr config..."
  symlink_force "$DOTS_DIR/SalchipapaHerdr/config.toml" "$HOME_DIR/.config/herdr/config.toml"
  # Agent integrations: better state detection and native session restore
  local herdr_bin="$HOME_DIR/.local/bin/herdr" target
  [ -x "$herdr_bin" ] || herdr_bin="$(command -v herdr || true)"
  if [ -n "$herdr_bin" ]; then
    for target in claude codex opencode copilot; do
      as_user "$herdr_bin" integration install "$target" >/dev/null 2>&1 ||
        warn "herdr integration for $target failed — run: herdr integration install $target"
    done
    ok "herdr integrations: claude, codex, opencode, copilot."
  fi
  ok "Herdr ready."
}

# ════════════════════════════════════════════════════════════════
#   Setup: Terminal
# ════════════════════════════════════════════════════════════════

setup_alacritty() {
  [ "$IS_ARCH" -eq 1 ] && run_silent "Installing alacritty..." "pkg_install alacritty"
  ensure_dir "$HOME_DIR/.config"
  step "Linking alacritty config..."
  symlink_force "$DOTS_DIR/SalchipapaAlacritty" "$HOME_DIR/.config/alacritty"
  ok "Alacritty config linked."
}

setup_wezterm() {
  if is_wsl; then
    setup_wezterm_windows
    return
  fi
  [ "$IS_ARCH" -eq 1 ] && run_silent "Installing wezterm..." "pkg_install wezterm"
  step "Linking .wezterm.lua..."
  symlink_force "$DOTS_DIR/SalchipapaWezterm/.wezterm.lua" "$HOME_DIR/.wezterm.lua"
  ok "Wezterm config linked."
}

# WSL: WezTerm runs natively on Windows (much smoother than a Linux terminal through WSLg) and
# opens this distro. Its config lives in the Windows home and must be a plain copy: loading it
# from \\wsl.localhost made WezTerm crash.
setup_wezterm_windows() {
  local winhome distro fontdir
  winhome="$(win_home)"
  distro="${WSL_DISTRO_NAME:-archlinux}"

  step "Windows: WezTerm (winget)..."
  (cd /mnt/c && powershell.exe -NoProfile -Command \
    "winget install --id wez.wezterm --exact --source winget --silent --accept-package-agreements --accept-source-agreements" \
    >/dev/null 2>&1) || true

  # WezTerm is a Windows app: it can't see Linux fonts. Per-user install, no admin needed.
  fontdir="$winhome/AppData/Local/Microsoft/Windows/Fonts"
  if ! compgen -G "$fontdir/IosevkaTermNerdFont-*.ttf" >/dev/null &&
    ! compgen -G "/mnt/c/Windows/Fonts/IosevkaTermNerdFont-*.ttf" >/dev/null; then
    step "Windows: IosevkaTerm Nerd Font..."
    local tmp f
    tmp="$(mktemp -d)"
    if curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip -o "$tmp/font.zip" &&
      unzip -q -o "$tmp/font.zip" 'IosevkaTermNerdFont-*.ttf' -d "$tmp/ttf"; then
      mkdir -p "$fontdir"
      for f in "$tmp"/ttf/*.ttf; do
        cp "$f" "$fontdir/" || { warn "Could not copy $(basename "$f")"; continue; }
        (cd /mnt/c && reg.exe add 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts' \
          /v "$(basename "$f" .ttf) (TrueType)" /t REG_SZ /d "$(wslpath -w "$fontdir/$(basename "$f")")" /f \
          >/dev/null 2>&1) || true
      done
    else
      warn "Could not download IosevkaTerm Nerd Font — install it on Windows by hand."
    fi
    rm -rf "$tmp"
  fi

  # Copy the config, pointing default_prog at this distro (the repo file says "archlinux")
  step "Windows: .wezterm.lua (distro: $distro)..."
  sed "s/\"-d\", \"archlinux\"/\"-d\", \"$distro\"/" "$DOTS_DIR/SalchipapaWezterm/.wezterm.lua" \
    >"$winhome/.wezterm.lua"
  ok "WezTerm ready (Windows). Edit the repo file and re-run, or copy it to $(wslpath -w "$winhome")\\.wezterm.lua"
}

setup_kitty() {
  [ "$IS_ARCH" -eq 1 ] && run_silent "Installing kitty..." "pkg_install kitty"
  ensure_dir "$HOME_DIR/.config"
  step "Linking kitty config..."
  symlink_force "$DOTS_DIR/SalchipapaKitty" "$HOME_DIR/.config/kitty"
  ok "Kitty config linked."
}

# ════════════════════════════════════════════════════════════════
#   Setup: WSL extras (Windows side + WSL-only tweaks)
# ════════════════════════════════════════════════════════════════

is_wsl() { grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; }

# Write a file as the target user (the script may be running under sudo)
write_as_user() {
  local dst="$1"
  as_user mkdir -p "$(dirname "$dst")"
  as_user tee "$dst" >/dev/null
}

# Windows home as a WSL path, e.g. /mnt/c/Users/name
win_home() {
  wslpath "$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')"
}

setup_wsl() {
  local winhome
  winhome="$(win_home)"

  # ── Windows: mpv + yt-dlp (yt-x plays through the Windows mpv: GPU decoding, 4K)
  step "Windows: mpv + yt-dlp (winget)..."
  (cd /mnt/c && powershell.exe -NoProfile -Command \
    "winget install --id shinchiro.mpv --exact --source winget --silent --accept-package-agreements --accept-source-agreements; \
     winget install --id yt-dlp.yt-dlp --exact --source winget --silent --accept-package-agreements --accept-source-agreements" \
    >/dev/null 2>&1) || true

  # winget's PATH changes aren't visible until WSL restarts, so point mpv at yt-dlp.exe directly
  local ytdlp mpv_conf="$winhome/AppData/Roaming/mpv/mpv.conf"
  ytdlp="$(find "$winhome/AppData/Local/Microsoft/WinGet/Packages" -maxdepth 2 -path '*yt-dlp.yt-dlp_*' -name yt-dlp.exe 2>/dev/null | head -1)"
  if [ -f "$mpv_conf" ]; then
    warn "Windows mpv.conf already exists — left untouched."
  elif [ -n "$ytdlp" ]; then
    mkdir -p "$(dirname "$mpv_conf")"
    cat >"$mpv_conf" <<EOF
# mpv de Windows (lo usa yt-x desde WSL para ver en 4K con la GPU)

# Decodificacion por GPU
hwdec=auto-safe
vo=gpu-next

# yt-dlp instalado con winget
script-opts=ytdl_hook-ytdl_path=$(wslpath -w "$ytdlp")
EOF
    ok "Windows mpv configured."
  else
    warn "yt-dlp.exe not found — Windows mpv may not open YouTube links."
  fi

  # ── win32yank: Neovim clipboard (lazy.lua uses it under WSL)
  if ! command -v win32yank.exe >/dev/null 2>&1; then
    step "win32yank (Neovim clipboard)..."
    local tmp url
    tmp="$(mktemp -d)"
    url="$(curl -fsSL https://api.github.com/repos/equalsraf/win32yank/releases/latest |
      grep -oE '"browser_download_url": "[^"]*x64\.zip"' | cut -d'"' -f4)"
    curl -fsSL "$url" -o "$tmp/win32yank.zip" &&
      unzip -o -q "$tmp/win32yank.zip" -d "$tmp" &&
      sudo install -m755 "$tmp/win32yank.exe" /usr/local/bin/win32yank.exe
    rm -rf "$tmp"
  fi

  # ── wslu: wslview opens links in the Windows browser (gh auth, etc.)
  if ! command -v wslview >/dev/null 2>&1; then
    step "wslu (wslview)..."
    if [ "$IS_ARCH" -eq 1 ]; then
      command -v yay >/dev/null 2>&1 && as_user yay -S --needed --noconfirm wslu || warn "wslu skipped (needs yay)."
    else
      sudo apt-get install -y wslu >/dev/null 2>&1 || warn "wslu not available via apt."
    fi
  fi

  # ── kitty: render with the GPU through D3D12 instead of llvmpipe
  local kitty_bin
  kitty_bin="$(type -ap kitty 2>/dev/null | grep -v '^/usr/local/bin/kitty$' | head -1 || true)"
  if [ -n "$kitty_bin" ] && [ ! -e /usr/local/bin/kitty ]; then
    step "kitty GPU wrapper (D3D12)..."
    printf '#!/bin/sh\n# Usa la GPU via D3D12 (WSL) en vez de renderizado por software (llvmpipe)\nexport GALLIUM_DRIVER=d3d12\nexec %s "$@"\n' "$kitty_bin" |
      sudo tee /usr/local/bin/kitty >/dev/null
    sudo chmod +x /usr/local/bin/kitty
  fi

  # ── mpv: every `mpv` call (yt-x, yazi, terminal) goes to the Windows mpv.
  # WSLg has no hardware decoding and can't show 1080p60 smoothly; the Windows
  # mpv decodes on the GPU. Linux file paths are translated to \\wsl.localhost\...
  if [ -x "/mnt/c/Program Files/MPV Player/mpv.exe" ] && [ ! -e /usr/local/bin/mpv ]; then
    step "mpv -> Windows mpv wrapper..."
    sudo tee /usr/local/bin/mpv >/dev/null <<'EOF'
#!/bin/sh
# mpv en WSL -> mpv de Windows (decodificacion por GPU, 4K).
# Traduce las rutas de archivos de Linux a rutas de Windows (\\wsl.localhost\...).
win_mpv="/mnt/c/Program Files/MPV Player/mpv.exe"
[ -x "$win_mpv" ] || exec /usr/bin/mpv "$@"

for arg in "$@"; do
  shift
  case "$arg" in
    --*=*)
      key="${arg%%=*}"; val="${arg#*=}"
      if [ -e "$val" ]; then set -- "$@" "$key=$(wslpath -w "$val")"; else set -- "$@" "$arg"; fi
      ;;
    -*) set -- "$@" "$arg" ;;
    *)
      if [ -e "$arg" ]; then set -- "$@" "$(wslpath -w "$arg")"; else set -- "$@" "$arg"; fi
      ;;
  esac
done
exec "$win_mpv" "$@"
EOF
    sudo chmod +x /usr/local/bin/mpv
  fi

  ok "WSL extras ready."
}

# ════════════════════════════════════════════════════════════════
#   Action: Full Install
# ════════════════════════════════════════════════════════════════

accion_install() {
  show_header

  # ── Ask configuration ──────────────────────────────────────
  local shell_choice mux_choice term_choice cli_list
  local -a cli_choices
  shell_choice=$(pick_option "Default shell:" "Fish" "Zsh" "Skip")
  mux_choice=$(pick_option "Terminal multiplexer:" "Herdr" "Zellij" "Tmux" "Skip")
  term_choice=$(pick_option "Terminal emulator config:" "Kitty" "Alacritty" "Wezterm" "Skip")
  mapfile -t cli_choices < <(pick_multi "AI agents & dev CLIs:" \
    "Claude Code" "Codex" "opencode" "Copilot CLI" "Gemini CLI" "Angular CLI")
  cli_list="$(join_list "${cli_choices[@]}")"

  # Each config REPLACES what is there (rm -rf + symlink): leave out what your desktop already
  # manages (e.g. caelestia ships its own starship and fastfetch)
  local -a cfg_choices extra_choices
  mapfile -t cfg_choices < <(pick_multi "Configs to link (each one replaces the existing config):" \
    "Neovim (LazyVim + Lazy sync)" "Starship prompt" "Fastfetch" "Claude Code hooks")
  mapfile -t extra_choices < <(pick_multi "Extras:" \
    "spotify_player (Spotify in the terminal)" "yt-x (YouTube in the terminal)")

  # Git & GitHub: asked before the vault, which is usually a private repo
  local git_choice git_name="" git_email="" gh_token="" spotify_id="" cur
  git_choice=$(pick_option "Git & GitHub (needed to clone a private vault):" \
    "Log in with GitHub CLI (browser)" "Log in with a token" "Git name/email only" "Skip")
  if [ "$git_choice" != "Skip" ]; then
    if [ "$git_choice" = "Git name/email only" ]; then
      echo -e "  ${GRAY}Empty = keep the current value.${RESET}"
    else
      echo -e "  ${GRAY}Empty = keep the current value, or take it from your GitHub account.${RESET}"
    fi
    cur="$(as_user git config --global user.name 2>/dev/null || true)"
    printf "  ${BOLD}Name${RESET}${GRAY} [%s]:${RESET} " "$cur" >&2
    read -r git_name </dev/tty
    cur="$(as_user git config --global user.email 2>/dev/null || true)"
    printf "  ${BOLD}Email${RESET}${GRAY} [%s]:${RESET} " "$cur" >&2
    read -r git_email </dev/tty
  fi
  if [ "$git_choice" = "Log in with a token" ]; then
    echo -e "  ${GRAY}Classic token with scopes: repo, read:org, workflow (github.com/settings/tokens).${RESET}"
    echo -e "  ${GRAY}It goes straight to gh (system keyring): not saved by this installer nor written to the log.${RESET}"
    printf "  ${BOLD}Token${RESET}${GRAY} (hidden):${RESET} " >&2
    read -rs gh_token </dev/tty
    echo >&2
  fi

  # spotify_player reads the client_id of your own Spotify app from a file outside the repo
  if picked spotify_player "${extra_choices[@]}" && [ ! -s "$HOME_DIR/.config/salchipapa-dots/spotify-client-id" ]; then
    echo -e "\n  ${AQUA}${BOLD}Spotify${RESET}"
    echo -e "  ${GRAY}client_id of your app at developer.spotify.com/dashboard, or leave empty to skip.${RESET}"
    printf "  ${BOLD}client_id:${RESET} " >&2
    read -r spotify_id </dev/tty
  fi

  echo -e "\n  ${AQUA}${BOLD}Obsidian vault${RESET}"
  echo -e "  ${GRAY}Enter your vault repo URL (SSH or HTTPS), or leave empty to skip.${RESET}"
  printf "  ${BOLD}URL:${RESET} " >&2
  read -r vault_url </dev/tty

  # ── Summary ────────────────────────────────────────────────
  echo -e "\n  ${AQUA}${BOLD}Summary${RESET}"
  echo -e "  ${GRAY}  ──────────────────────────────────────${RESET}"
  echo -e "  ${YELLOW}  Shell:${RESET}        $shell_choice"
  echo -e "  ${YELLOW}  Multiplexer:${RESET}  $mux_choice"
  echo -e "  ${YELLOW}  Terminal:${RESET}     $term_choice"
  echo -e "  ${YELLOW}  CLIs:${RESET}         $cli_list"
  echo -e "  ${YELLOW}  Configs:${RESET}      $(join_list "${cfg_choices[@]}")"
  echo -e "  ${YELLOW}  Extras:${RESET}       $(join_list "${extra_choices[@]}")"
  echo -e "  ${YELLOW}  Git/GitHub:${RESET}   $git_choice"
  echo -e "  ${YELLOW}  Vault:${RESET}        ${vault_url:-Skip}"
  echo -e "  ${GRAY}  ──────────────────────────────────────${RESET}"
  # Explicit answer required: an empty Enter used to count as "yes"
  while true; do
    printf "  ${ORANGE}▶${RESET}${GRAY} Proceed? [y/n]: ${RESET}"
    read -r confirm
    case "${confirm,,}" in
    y | yes | s | si | sí) break ;;
    n | no)
      echo -e "  ${RED}Aborted.${RESET}\n"
      return
      ;;
    *) echo -e "  ${RED}  Please answer y or n.${RESET}" ;;
    esac
  done

  # Ask for the sudo password up front so silent steps don't hang on it
  sudo -v

  # Log for every silent step, run timer and section counter
  as_user mkdir -p "$HOME_DIR/.cache/salchipapa-dots"
  LOG_FILE="$HOME_DIR/.cache/salchipapa-dots/install-$(date +%Y%m%d-%H%M%S).log"
  : >"$LOG_FILE"
  FAILED_STEPS=()
  INSTALL_START=$SECONDS
  SECTION_N=0
  # System + Core Tools (+ Homebrew on Debian), Shell, Multiplexer, Terminal, CLIs, Symlinks, Neovim (+ WSL)
  SECTION_TOTAL=$((IS_ARCH == 1 ? 8 : 9))
  is_wsl && SECTION_TOTAL=$((SECTION_TOTAL + 1))
  [ "$git_choice" != "Skip" ] && SECTION_TOTAL=$((SECTION_TOTAL + 1))
  picked Neovim "${cfg_choices[@]}" || SECTION_TOTAL=$((SECTION_TOTAL - 1))

  local brew_prefix="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"

  if [ "$IS_ARCH" -eq 1 ]; then
    # ── System (Arch) ────────────────────────────────────────
    section "System — Arch Linux"
    run_silent "pacman -Syu..." "sudo pacman -Syu --noconfirm"
    run_silent "base-devel, curl, git, ca-certificates, unzip..." \
      "sudo pacman -S --needed --noconfirm base-devel curl git ca-certificates unzip"
    step "yay (AUR helper)..."
    install_yay
    ok "System packages ready."
    section_end

    # ── Core packages (Arch) ─────────────────────────────────
    section "Core Tools"
    run_silent "neovim, node, starship, fzf, zoxide, atuin, fd, eza, bat, lazygit, fastfetch, yazi, btop, fonts..." \
      "sudo pacman -S --needed --noconfirm gcc neovim nodejs npm starship fzf zoxide atuin fd eza bat lazygit btop fastfetch yazi ripgrep tree-sitter-cli imagemagick chafa wl-clipboard ttf-iosevkaterm-nerd noto-fonts-emoji jq python"
    picked spotify_player "${extra_choices[@]}" &&
      run_silent "spotify-player..." "sudo pacman -S --needed --noconfirm spotify-player"
    picked yt-x "${extra_choices[@]}" &&
      run_silent "mpv, yt-dlp (for yt-x)..." "sudo pacman -S --needed --noconfirm mpv yt-dlp"
    run_silent "carapace (GitHub release)..." "install_carapace_bin"
    if command -v yay >/dev/null 2>&1; then
      # Not silent: yay may ask for the user's sudo password
      local aur=(asm-lsp)
      picked yt-x "${extra_choices[@]}" && aur+=(yt-x-git gum)
      step "${aur[*]} (AUR)..."
      as_user yay -S --needed --noconfirm "${aur[@]}" || warn "AUR packages failed — install them later with: yay -S ${aur[*]}"
    else
      warn "AUR packages skipped (need yay): asm-lsp$(picked yt-x "${extra_choices[@]}" && echo ", yt-x")."
    fi
    ok "Core tools installed."
    section_end
  else
    # ── System (Debian) ──────────────────────────────────────
    section "System"
    run_silent "apt update & upgrade..." "sudo apt-get update -y && sudo apt-get upgrade -y"
    run_silent "build-essential, curl, git, ca-certificates, unzip..." \
      "sudo apt-get install -y build-essential curl git ca-certificates unzip"
    ok "System packages ready."
    section_end

    # ── Homebrew ─────────────────────────────────────────────
    section "Homebrew"
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

    # ── Core packages ────────────────────────────────────────
    section "Core Tools"
    run_silent "gcc, nvim, node, starship, carapace, fzf, zoxide, atuin, fd, eza, bat, asm-lsp, lazygit, fastfetch, yazi, btop..." \
      "brew install gcc nvim node starship carapace fzf zoxide atuin fd eza bat asm-lsp lazygit btop fastfetch yazi jq"
    picked spotify_player "${extra_choices[@]}" &&
      run_silent "spotify_player..." "brew install spotify_player"
    picked yt-x "${extra_choices[@]}" &&
      warn "yt-x: no package here — install it by hand (github.com/Benexl/yt-x); its config gets linked."
    ok "Core tools installed."
    section_end
  fi

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
  Herdr) setup_herdr ;;
  Zellij) setup_zellij ;;
  Tmux) setup_tmux ;;
  Skip) ok "Skipped." ;;
  esac
  section_end

  # ── Terminal ───────────────────────────────────────────────
  section "Terminal — $term_choice"
  case "$term_choice" in
  Kitty) setup_kitty ;;
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
    step "Installing $pkg..."
    # pacman's npm uses a global prefix under /usr, which needs root
    if [ "$IS_ARCH" -eq 1 ]; then
      sudo npm i -g "$pkg"
    else
      npm i -g "$pkg"
    fi
  }

  local cli
  for cli in "${cli_choices[@]}"; do
    case "$cli" in
    "Claude Code")
      # Official native installer (~/.local/bin/claude, auto-updates); skipped if already there
      if as_user sh -c 'command -v claude || test -x "$HOME/.local/bin/claude"' >/dev/null 2>&1; then
        ok "Claude Code already installed."
      else
        run_silent "Claude Code (native installer)..." "as_user bash -c 'curl -fsSL https://claude.ai/install.sh | bash'"
      fi
      ;;
    "Codex")
      if [ "$IS_ARCH" -eq 1 ]; then
        run_silent "Codex (pacman)..." "sudo pacman -S --needed --noconfirm openai-codex"
      else
        install_npm_cli "@openai/codex"
      fi
      ;;
    "opencode")
      if [ "$IS_ARCH" -eq 1 ]; then
        run_silent "opencode (pacman)..." "sudo pacman -S --needed --noconfirm opencode"
      else
        install_npm_cli "opencode-ai"
      fi
      ;;
    "Copilot CLI") install_npm_cli "@github/copilot" ;;
    "Gemini CLI") install_npm_cli "@google/gemini-cli" ;;
    "Angular CLI") install_npm_cli "@angular/cli" ;;
    esac
  done
  if [ "${#cli_choices[@]}" -eq 0 ]; then
    ok "Skipped."
  else
    ok "CLIs done."
  fi
  section_end

  # ── Git & GitHub (before the vault clone) ──────────────────
  if [ "$git_choice" != "Skip" ]; then
    section "Git & GitHub"
    setup_github "$git_choice" "$git_name" "$git_email" "$gh_token"
    section_end
  fi
  gh_token=""

  # ── Common symlinks ────────────────────────────────────────
  section "Config Symlinks"
  ensure_dir "$HOME_DIR/.config"

  if picked Neovim "${cfg_choices[@]}"; then
    step "Neovim..."
    symlink_force "$DOTS_DIR/SalchipapaNvim/nvim" "$HOME_DIR/.config/nvim"
    ok "Neovim linked."
  fi

  if picked Starship "${cfg_choices[@]}"; then
    step "Starship..."
    symlink_force "$DOTS_DIR/starship.toml" "$HOME_DIR/.config/starship.toml"
    ok "Starship linked."
  fi

  if picked Fastfetch "${cfg_choices[@]}"; then
    step "Fastfetch..."
    symlink_force "$DOTS_DIR/SalchipapaFastfetch" "$HOME_DIR/.config/fastfetch"
    ok "Fastfetch linked."
  fi

  if picked spotify_player "${extra_choices[@]}"; then
    step "spotify_player..."
    symlink_force "$DOTS_DIR/SalchipapaSpotify" "$HOME_DIR/.config/spotify-player"
    ok "spotify_player linked."
    if [ -n "$spotify_id" ]; then
      printf '%s\n' "$spotify_id" | write_as_user "$HOME_DIR/.config/salchipapa-dots/spotify-client-id"
      ok "Spotify client_id saved (~/.config/salchipapa-dots/spotify-client-id)."
    fi
  fi

  if picked yt-x "${extra_choices[@]}"; then
    step "yt-x..."
    symlink_force "$DOTS_DIR/SalchipapaYtx" "$HOME_DIR/.config/yt-x"
    ok "yt-x linked."
  fi

  if picked "Claude Code hooks" "${cfg_choices[@]}"; then
    step "Claude Code hooks..."
    setup_claude_hooks
  fi

  # ── Obsidian vault ─────────────────────────────────────────
  if [ -n "$vault_url" ]; then
    step "Obsidian vault..."
    if [ ! -d "$HOME_DIR/.config/obsidian/.git" ]; then
      sudo -u "$TARGET_USER" git clone "$vault_url" "$HOME_DIR/.config/obsidian"
    else
      warn "Obsidian vault already exists — skipping clone."
    fi
    ok "Obsidian vault ready at ~/.config/obsidian."
  else
    warn "Obsidian vault skipped."
  fi
  if [ -d "$HOME_DIR/.config/obsidian/.git" ]; then
    setup_agent_memory
  fi
  section_end

  # ── Neovim Lazy sync ───────────────────────────────────────
  if picked Neovim "${cfg_choices[@]}"; then
    section "Neovim"
    run_silent "Running Lazy sync..." "sudo -u '$TARGET_USER' nvim --headless '+Lazy! sync' +qa"
    ok "Lazy sync done."
    section_end
  fi

  # ── WSL extras ─────────────────────────────────────────────
  if is_wsl; then
    section "WSL"
    setup_wsl
    section_end
  fi

  show_summary "$shell_choice"
}

# ── Final summary: time, failed steps, log, next steps; then the chosen shell ──
show_summary() {
  local shell_choice="$1" elapsed=$((SECONDS - INSTALL_START)) f shell_bin=""
  local took="$((elapsed / 60))m $((elapsed % 60))s"

  echo
  if [ "${#FAILED_STEPS[@]}" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✔  Installation complete${RESET} ${GRAY}in ${took}${RESET}"
  else
    echo -e "  ${YELLOW}${BOLD}⚠  Finished with ${#FAILED_STEPS[@]} failed step(s)${RESET} ${GRAY}in ${took}${RESET}"
    for f in "${FAILED_STEPS[@]}"; do
      echo -e "     ${RED}✖${RESET} $f"
    done
    echo -e "  ${GRAY}  Re-run the installer or run those steps by hand; details in the log.${RESET}"
  fi
  echo -e "  ${GRAY}  Log: ${RESET}$LOG_FILE"

  echo -e "\n  ${AQUA}${BOLD}Next steps${RESET}"
  command -v gh >/dev/null 2>&1 && ! as_user gh auth status >/dev/null 2>&1 &&
    echo -e "  ${GRAY}  •${RESET} gh auth login && gh auth setup-git   ${GRAY}GitHub (git push, Claude Code GitHub plugin)${RESET}"
  command -v claude >/dev/null 2>&1 && echo -e "  ${GRAY}  •${RESET} claude, then /login           ${GRAY}sign in to Claude Code${RESET}"
  if command -v spotify_player >/dev/null 2>&1; then
    [ -s "$HOME_DIR/.config/salchipapa-dots/spotify-client-id" ] ||
      echo -e "  ${GRAY}  •${RESET} echo <client_id> > ~/.config/salchipapa-dots/spotify-client-id   ${GRAY}your Spotify app${RESET}"
    echo -e "  ${GRAY}  •${RESET} spotify_player authenticate   ${GRAY}Spotify login${RESET}"
  fi
  echo -e "  ${GRAY}  •${RESET} Open a new terminal           ${GRAY}to load fonts, shell and multiplexer${RESET}"
  echo

  case "$shell_choice" in
  Fish) shell_bin="$(command -v fish || true)" ;;
  Zsh) shell_bin="$(command -v zsh || true)" ;;
  esac
  if [ -n "$shell_bin" ]; then
    read -rp "  Press [ENTER] to launch $(basename "$shell_bin")… " </dev/tty
    exec "$shell_bin"
  fi
}

# ════════════════════════════════════════════════════════════════
#   Action: Quit
# ════════════════════════════════════════════════════════════════

accion_quit() {
  clear
  echo -e "\n  ${AQUA}${BOLD}Goodbye!${RESET}  ${GRAY}salchipapa.dots${RESET}\n"
  exit 0
}

accion_uninstall() {
  section "Uninstall"
  warn "This will remove all symlinks created by salchipapa-dots."

  # Ensure brew is in PATH
  if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  local confirm
  printf "\n  ${BOLD}Type 'yes' to confirm: ${RESET}" >&2
  read -r confirm </dev/tty
  if [ "$confirm" != "yes" ]; then
    warn "Uninstall cancelled."
    return
  fi

  local symlinks=(
    "$HOME_DIR/.config/fish"
    "$HOME_DIR/.config/zellij"
    "$HOME_DIR/.config/herdr/config.toml"
    "$HOME_DIR/.config/tmux"
    "$HOME_DIR/.config/alacritty"
    "$HOME_DIR/.config/kitty"
    "$HOME_DIR/.config/nvim"
    "$HOME_DIR/.config/starship.toml"
    "$HOME_DIR/.config/fastfetch"
    "$HOME_DIR/.config/spotify-player"
    "$HOME_DIR/.config/yt-x"
    "$HOME_DIR/.wezterm.lua"
    "$HOME_DIR/.zshrc"
  )

  for link in "${symlinks[@]}"; do
    if [ -L "$link" ]; then
      rm "$link"
      ok "Removed symlink: $link"
    fi
  done

  usermod -s "$(command -v bash)" "$TARGET_USER" 2>/dev/null && ok "Default shell restored to bash." || true

  if [ -d "$HOME_DIR/.config/obsidian" ]; then
    rm -rf "$HOME_DIR/.config/obsidian"
    ok "Removed ~/.config/obsidian"
  fi

  if command -v brew &>/dev/null; then
    local brew_pkgs=(
      fish zsh zsh-autocomplete zsh-syntax-highlighting zsh-autosuggestions
      zellij tmux alacritty
      gcc nvim node starship carapace fzf zoxide atuin fd eza bat asm-lsp lazygit btop fastfetch yazi
      nvm
    )
    step "Uninstalling brew packages..."
    for pkg in "${brew_pkgs[@]}"; do
      brew uninstall --ignore-dependencies "$pkg" 2>/dev/null || true
    done
    ok "Brew packages removed."

    if [ -d "/home/linuxbrew/.linuxbrew/etc/fish" ]; then
      rm -rf "/home/linuxbrew/.linuxbrew/etc/fish"
      ok "Removed /home/linuxbrew/.linuxbrew/etc/fish"
    fi

    step "Uninstalling npm CLIs..."
    npm uninstall -g @google/gemini-cli @angular/cli @anthropic-ai/claude-code @openai/codex opencode-ai @github/copilot 2>/dev/null || true
    ok "npm CLIs removed."

    brew uninstall salchipapa-dots 2>/dev/null && ok "Removed salchipapa-dots formula." || true
  fi

  cd "$HOME_DIR" || cd /tmp
  rm -rf "$HOME_DIR/Salchipapa.Dots"
  ok "Removed ~/Salchipapa.Dots"

  section_end
  echo -e "\n  ${AQUA}${BOLD}Uninstall complete.${RESET}  ${GRAY}salchipapa.dots${RESET}\n"
  read -rp "  Press [ENTER] to continue… " </dev/tty
  exec su -s /bin/bash "$TARGET_USER"
}

# ════════════════════════════════════════════════════════════════
#   Main Menu
# ════════════════════════════════════════════════════════════════

while true; do
  show_header
  choice=$(pick_option "What do you want to do?" \
    "Install everything" \
    "Uninstall" \
    "Quit")
  case "$choice" in
  "Install everything") accion_install ;;
  "Uninstall") accion_uninstall ;;
  "Quit") accion_quit ;;
  esac
done
