#!/usr/bin/env bash
# vault-sync.sh pull|push|start [agente] — sincroniza la boveda de Obsidian con GitHub.
#
#   pull  -> git pull --rebase --autostash
#   push  -> commit de lo que haya cambiado + pull --rebase + push (al terminar una sesion)
#   start -> push de lo que quedo pendiente (sesion cerrada de golpe) + pull (al empezar)
#
# Nunca bloquea al agente: cualquier fallo se anota en el log y sale con 0.
# Un lock evita que dos agentes sincronicen a la vez. No sube nada que parezca un secreto.
set -u

VAULT="${OBSIDIAN_VAULT:-$HOME/.config/obsidian}"
LOG="$HOME/.cache/salchipapa-dots/vault-sync.log"
mode="${1:-}"
agent="${2:-agente}"

mkdir -p "$(dirname "$LOG")"
log() { printf '%s [%s %s] %s\n' "$(date '+%F %T')" "$agent" "$mode" "$*" >>"$LOG"; }

[ -d "$VAULT/.git" ] || exit 0
cd "$VAULT" || exit 0

exec 9>"$VAULT/.git/vault-sync.lock"
flock -w 30 9 || { log "otro sync en curso, se omite"; exit 0; }

# Los mismos patrones que el hook secret-scan de Claude Code
SECRETS='gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{40,}|AIza[0-9A-Za-z_-]{35}|AQ\.[A-Za-z0-9_-]{30,}|sk-[A-Za-z0-9_-]{20,}|oma_(live|test)_[A-Za-z0-9]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----'

pull() {
  if ! out=$(git pull --rebase --autostash -q 2>&1); then
    git rebase --abort >/dev/null 2>&1
    log "pull falló (¿conflicto?), boveda sin cambios: $out"
    return 1
  fi
  log "pull ok"
}

push() {
  if [ -n "$(git status --porcelain)" ]; then
    git add -A
    if git diff --cached -U0 | grep -E '^\+' | grep -qE "$SECRETS"; then
      git reset -q
      log "NO se sube: hay algo que parece un secreto en los cambios. Revisar a mano."
      return 1
    fi
    git commit -q -m "auto ($agent): $(date '+%F %H:%M')" && log "commit: $(git log -1 --format=%h) $(git diff --stat HEAD~1 HEAD | tail -1)"
  fi
  if [ -n "$(git log --oneline '@{u}..HEAD' 2>/dev/null)" ]; then
    pull || return 1
    if out=$(git push -q 2>&1); then log "push ok"; else log "push falló: $out"; fi
  else
    log "sin cambios que subir"
  fi
}

case "$mode" in
pull)
  pull
  ;;
push)
  push
  ;;
start)
  # Al empezar: subir lo que dejo pendiente una sesion que se cerro mal (si lo hay) y bajar lo nuevo
  if [ -n "$(git status --porcelain)" ] || [ -n "$(git log --oneline '@{u}..HEAD' 2>/dev/null)" ]; then
    log "cambios pendientes de una sesion anterior: se suben"
    push
  fi
  pull
  ;;
*)
  echo "uso: vault-sync.sh pull|push|start [agente]" >&2
  ;;
esac
exit 0
