#!/usr/bin/env bash
# install.sh — deja OpenClaw como administrador de la bóveda de Obsidian (LLM Wiki) en un VPS Ubuntu.
# Se corre EN EL VPS, como el usuario normal (ubuntu), y se puede repetir: no rehace lo que ya está.
#   curl -fsSL https://raw.githubusercontent.com/erickm13/Salchipapa.Dots/main/SalchipapaOpenClaw/install.sh | bash
#   (o, con Dots ya clonado: bash ~/Salchipapa.Dots/SalchipapaOpenClaw/install.sh)
#
# 1) swap de 2 GiB (con 2 GiB de RAM el Gateway moría por OOM)   2) OpenClaw (si falta)
# 3) Salchipapa.Dots en ~/Salchipapa.Dots                         4) token de Padawan-Salchipapa (sin workflows)
# 5) la bóveda en ~/.config/obsidian (commits como Padawan-Salchipapa) 6) los skills `boveda` y `github-padawan` (+ gh)
# 7) el ingest de cada noche (automatización de OpenClaw, 23:45 en $TZ_VAULT)
#
# En el servidor no vive nada importante: la config sin secretos está aquí y la bóveda en GitHub.
# Lo interactivo (login de Codex, token de Telegram, pairing) lo hace `openclaw onboard`: ver README.
set -u

# ── Solarized Osaka (truecolor) ────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
BASE01="\033[38;2;88;110;117m"
BLUE="\033[38;2;38;139;210m"
GREEN="\033[38;2;133;153;0m"
YELLOW="\033[38;2;181;137;0m"
RED="\033[38;2;220;50;47m"

section() { echo -e "\n${BLUE}${BOLD}▸ $1${RESET}"; }
ok() { echo -e "  ${GREEN}✔${RESET} $1"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $1"; }
die() { echo -e "  ${RED}✖${RESET} $1"; exit 1; }

DOTS="${SALCHIPAPA_DOTS:-$HOME/Salchipapa.Dots}"
DOTS_REF="${SALCHIPAPA_DOTS_REF:-main}"
VAULT="${OBSIDIAN_VAULT:-$HOME/.config/obsidian}"
VAULT_REPO="${VAULT_REPO:-erickm13/SalchipapaNotes}"
VAULT_URL="https://github.com/$VAULT_REPO.git"
KEY="$HOME/.ssh/salchipapanotes_deploy" # deploy key anterior: el script la quita si sigue ahí
OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.10.3}"
TZ_VAULT="${TZ_VAULT:-America/Guatemala}"
JOB_NAME="Ingest de la bóveda"
export PATH="$HOME/.npm-global/bin:$PATH"

[ "$(id -u)" -ne 0 ] || die "Córrelo como tu usuario (ubuntu), no como root: usa sudo solo para la swap."

section "Paquetes"
missing=()
for b in git python3 flock ssh-keygen curl; do command -v "$b" >/dev/null || missing+=("$b"); done
if [ "${#missing[@]}" -gt 0 ]; then
  sudo apt-get update -qq && sudo apt-get install -y -qq git python3 util-linux openssh-client curl >/dev/null ||
    die "No se pudo instalar: ${missing[*]}"
fi
ok "git, python3, flock, ssh-keygen, curl"

section "Swap"
if swapon --show=NAME --noheadings | grep -q .; then
  ok "ya hay swap ($(swapon --show=SIZE --noheadings | head -1 | tr -d ' '))"
else
  sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap -q /swapfile && sudo swapon /swapfile &&
    { grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null; } &&
    ok "/swapfile de 2 GiB activo y en /etc/fstab" || warn "no se pudo crear la swap"
fi

section "OpenClaw"
if command -v openclaw >/dev/null; then
  ok "openclaw $(openclaw --version 2>/dev/null | head -1)"
else
  command -v npm >/dev/null || die "Falta Node.js/npm: instálalo (p. ej. con mise o NodeSource) y repite."
  npm config set prefix "$HOME/.npm-global"
  npm install -g --silent "openclaw@$OPENCLAW_VERSION" || die "npm install openclaw@$OPENCLAW_VERSION falló"
  ok "openclaw $OPENCLAW_VERSION instalado en ~/.npm-global"
fi
onboarded=1
[ -f "$HOME/.openclaw/openclaw.json" ] || onboarded=0

section "Salchipapa.Dots"
if [ -d "$DOTS/.git" ]; then
  git -C "$DOTS" fetch -q origin && git -C "$DOTS" checkout -q "$DOTS_REF" &&
    { [ "$DOTS_REF" != main ] || git -C "$DOTS" merge -q --ff-only origin/main; } || die "No se pudo actualizar $DOTS a $DOTS_REF"
else
  git clone -q https://github.com/erickm13/Salchipapa.Dots.git "$DOTS" && git -C "$DOTS" checkout -q "$DOTS_REF" ||
    die "No se pudo clonar Salchipapa.Dots"
fi
ok "$DOTS en $(git -C "$DOTS" rev-parse --short HEAD) ($DOTS_REF)"

section "Acceso a la bóveda"
# Token clásico de Padawan-Salchipapa (colaborador con escritura solo en la bóveda), con el scope `repo`
# y SIN `workflow`: GitHub le rechaza cambios a .github/workflows/, así que quien entre en el VPS no
# puede alterar las Actions ni leer sus secrets. Se guarda a mano (nunca pasa por el chat ni por Dots).
CREDS="$HOME/.git-credentials"
GIT_CRED=(-c credential.helper=store -c credential.useHttpPath=true)
if ! grep -q "@github.com/$VAULT_REPO.git\$" "$CREDS" 2>/dev/null ||
  ! GIT_TERMINAL_PROMPT=0 git "${GIT_CRED[@]}" ls-remote -q "$VAULT_URL" >/dev/null 2>&1; then
  warn "Falta el token de Padawan-Salchipapa (o ya no vale). Desde tu terminal, con el token copiado:"
  echo -e "    ${BOLD}ssh -t <este-vps> 'read -rsp \"Token de Padawan: \" T; echo; umask 077; printf \"https://Padawan-Salchipapa:%s@github.com/$VAULT_REPO.git\\\\n\" \"\$T\" > ~/.git-credentials; unset T'${RESET}"
  echo -e "  ${BASE01}Token (classic) de Padawan-Salchipapa, solo el scope repo (sin workflow); Padawan, colaborador con escritura de $VAULT_REPO.${RESET}"
  exit 2
fi
ok "token de Padawan-Salchipapa: escritura en $VAULT_REPO, sin permiso para tocar workflows"
# Restos de la deploy key anterior (2026-10-22): ya no se usan
if [ -f "$KEY" ] || grep -q "^Host github-vault\$" "$HOME/.ssh/config" 2>/dev/null; then
  rm -f "$KEY" "$KEY.pub"
  [ -f "$HOME/.ssh/config" ] && awk '/^Host github-vault$/{skip=1; next} /^Host /{skip=0} !skip' "$HOME/.ssh/config" | cat -s >"$HOME/.ssh/config.tmp" &&
    mv "$HOME/.ssh/config.tmp" "$HOME/.ssh/config" && chmod 600 "$HOME/.ssh/config"
  ok "quitada la deploy key anterior del VPS (bórrala también en GitHub si sigue ahí)"
fi

section "GitHub CLI (Padawan-Salchipapa)"
# Para issues y PRs (skill github). Mismo token; `gh auth login` exige read:org, así que se escribe su
# config directamente (600, como haría él)
command -v gh >/dev/null || { sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq gh >/dev/null 2>&1 ||
  warn "no se pudo instalar gh (apt)"; }
if command -v gh >/dev/null && [ "$(gh api user --jq .login 2>/dev/null)" != Padawan-Salchipapa ]; then
  (umask 077 && mkdir -p "$HOME/.config/gh" && T="$(sed -n 's#^https://Padawan-Salchipapa:\(.*\)@github.com/.*#\1#p' "$CREDS" | head -1)" &&
    printf 'github.com:\n    users:\n        Padawan-Salchipapa:\n            oauth_token: %s\n    oauth_token: %s\n    user: Padawan-Salchipapa\n    git_protocol: https\n' "$T" "$T" >"$HOME/.config/gh/hosts.yml")
fi
if [ "$(gh api user --jq .login 2>/dev/null)" = Padawan-Salchipapa ]; then
  ok "gh como Padawan-Salchipapa (escritura solo en $VAULT_REPO; en lo demás, PRs desde su fork)"
else
  warn "gh no quedó con la cuenta de Padawan-Salchipapa: el skill github no podrá usarse"
fi

section "Bóveda"
if [ -d "$VAULT/.git" ]; then
  git -C "$VAULT" remote set-url origin "$VAULT_URL"
else
  mkdir -p "$(dirname "$VAULT")"
  git "${GIT_CRED[@]}" clone -q "$VAULT_URL" "$VAULT" || die "No se pudo clonar la bóveda"
fi
git -C "$VAULT" config credential.helper store
git -C "$VAULT" config credential.useHttpPath true
git -C "$VAULT" pull -q --rebase --autostash || warn "no se pudo hacer pull de la bóveda"
# Los commits del VPS son automatización: los firma el bot, no el usuario. Global (el VPS es del bot:
# también los forks que clone para proponer PRs) y en la bóveda
BOT_NAME="Padawan-Salchipapa"
BOT_EMAIL="346263417+Padawan-Salchipapa@users.noreply.github.com"
git config --global user.name "$BOT_NAME" && git config --global user.email "$BOT_EMAIL"
git -C "$VAULT" config user.name "$BOT_NAME" && git -C "$VAULT" config user.email "$BOT_EMAIL"
# El filtro de vault-sync.sh protege a los equipos del usuario de lo que suba el VPS: aquí no aplica
git -C "$VAULT" config vault.guard false
ok "$VAULT ($(grep -c '^## \[' "$VAULT/log.md" 2>/dev/null || echo 0) entradas en log.md)"

section "Skills"
# Copia, no enlace: OpenClaw no sigue symlinks fuera de sus carpetas salvo que se le autorice
mkdir -p "$HOME/.openclaw/skills"
for skill in boveda github-padawan; do
  rm -rf "$HOME/.openclaw/skills/$skill"
  cp -r "$DOTS/SalchipapaOpenClaw/skills/$skill" "$HOME/.openclaw/skills/$skill"
  ok "$HOME/.openclaw/skills/$skill"
done

section "Ingest de cada noche"
if [ "$onboarded" -eq 0 ]; then
  warn "OpenClaw no está configurado: corre 'openclaw onboard --install-daemon' (README) y repite este script."
  exit 2
fi
if openclaw skills check 2>/dev/null | grep -q boveda; then ok "el agente ve el skill"; else warn "revisa 'openclaw skills check': no aparece boveda"; fi
if openclaw automations list --all 2>/dev/null | grep -qF "$JOB_NAME"; then
  ok "ya existe ($JOB_NAME)"
else
  # Antes de las 00:10, cuando GitHub Actions hace el ingest de respaldo (solo si quedó algo pendiente).
  # El resultado va al DM del dueño (el primer telegram:<id> de commands.ownerAllowFrom): sin ruta
  # explícita, OpenClaw intenta "last" y la entrega falla.
  to="${OPENCLAW_TELEGRAM_TO:-$(grep -o '"telegram:[0-9]*"' "$HOME/.openclaw/openclaw.json" | head -1 | tr -dc 0-9)}"
  deliver=(--no-deliver)
  [ -n "$to" ] && deliver=(--announce --channel telegram --to "$to")
  openclaw automations add --name "$JOB_NAME" --cron "45 23 * * *" --tz "$TZ_VAULT" --session isolated --agent main \
    --message "Usa el skill boveda: haz el ingest de las fuentes pendientes de raw/ y sube la bóveda." \
    "${deliver[@]}" >/dev/null && ok "todos los días a las 23:45 ($TZ_VAULT)" ||
    warn "no se pudo crear la automatización: créala a mano (README)"
fi

echo -e "\n${GREEN}${BOLD}✔ OpenClaw administra la bóveda.${RESET} ${BASE01}Prueba por Telegram: \"¿qué hice hoy?\"${RESET}"
