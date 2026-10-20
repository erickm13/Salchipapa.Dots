#!/usr/bin/env bash
# install.sh — deja OpenClaw como administrador de la bóveda de Obsidian (LLM Wiki) en un VPS Ubuntu.
# Se corre EN EL VPS, como el usuario normal (ubuntu), y se puede repetir: no rehace lo que ya está.
#   curl -fsSL https://raw.githubusercontent.com/erickm13/Salchipapa.Dots/main/SalchipapaOpenClaw/install.sh | bash
#   (o, con Dots ya clonado: bash ~/Salchipapa.Dots/SalchipapaOpenClaw/install.sh)
#
# 1) swap de 2 GiB (con 2 GiB de RAM el Gateway moría por OOM)   2) OpenClaw (si falta)
# 3) Salchipapa.Dots en ~/Salchipapa.Dots                         4) deploy key solo para la bóveda
# 5) la bóveda en ~/.config/obsidian (commits como salchipapa-bot) 6) el skill `boveda`
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
KEY="$HOME/.ssh/salchipapanotes_deploy"
HOST_ALIAS="github-vault"
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

section "Deploy key de la bóveda"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ ! -f "$KEY" ]; then
  ssh-keygen -q -t ed25519 -N "" -C "openclaw-vps@$(hostname)" -f "$KEY"
  ok "clave nueva: $KEY"
fi
if ! grep -q "^Host $HOST_ALIAS\$" "$HOME/.ssh/config" 2>/dev/null; then
  printf '\nHost %s\n    HostName github.com\n    User git\n    IdentityFile %s\n    IdentitiesOnly yes\n' \
    "$HOST_ALIAS" "$KEY" >>"$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
fi
ssh-keygen -F github.com >/dev/null 2>&1 || ssh-keyscan -t ed25519 github.com 2>/dev/null >>"$HOME/.ssh/known_hosts"
if ! git ls-remote -q "git@$HOST_ALIAS:$VAULT_REPO.git" >/dev/null 2>&1; then
  warn "GitHub aún no acepta la clave. Añádela desde tu equipo (con escritura) y repite este script:"
  echo -e "    ${BOLD}ssh <este-vps> cat .ssh/${KEY##*/}.pub >/tmp/openclaw-vps.pub${RESET}"
  echo -e "    ${BOLD}gh repo deploy-key add /tmp/openclaw-vps.pub -R $VAULT_REPO --allow-write -t openclaw-vps${RESET}"
  echo -e "  ${BASE01}Clave pública: $(cat "$KEY.pub")${RESET}"
  exit 2
fi
ok "acceso de escritura solo a $VAULT_REPO"

section "Bóveda"
if [ -d "$VAULT/.git" ]; then
  git -C "$VAULT" remote set-url origin "git@$HOST_ALIAS:$VAULT_REPO.git"
  git -C "$VAULT" pull -q --rebase --autostash || warn "no se pudo hacer pull de la bóveda"
else
  mkdir -p "$(dirname "$VAULT")"
  git clone -q "git@$HOST_ALIAS:$VAULT_REPO.git" "$VAULT" || die "No se pudo clonar la bóveda"
fi
# Los commits del VPS son automatización: los firma el bot, no el usuario
git -C "$VAULT" config user.name "salchipapa-bot"
git -C "$VAULT" config user.email "salchipapa-bot@users.noreply.github.com"
ok "$VAULT ($(grep -c '^## \[' "$VAULT/log.md" 2>/dev/null || echo 0) entradas en log.md)"

section "Skill boveda"
# Copia, no enlace: OpenClaw no sigue symlinks fuera de sus carpetas salvo que se le autorice
mkdir -p "$HOME/.openclaw/skills"
rm -rf "$HOME/.openclaw/skills/boveda"
cp -r "$DOTS/SalchipapaOpenClaw/skills/boveda" "$HOME/.openclaw/skills/boveda"
ok "$HOME/.openclaw/skills/boveda"

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
