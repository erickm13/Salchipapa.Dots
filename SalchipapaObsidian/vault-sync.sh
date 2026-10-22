#!/usr/bin/env bash
# vault-sync.sh pull|push|start [agente] — sincroniza la boveda de Obsidian con GitHub.
#
#   pull  -> git pull --rebase --autostash
#   push  -> commit de lo que haya cambiado + pull --rebase + push (al terminar una sesion)
#   start -> push de lo que quedo pendiente (sesion cerrada de golpe) + pull (al empezar)
#   trust <commit> -> acepta los cambios sensibles que llegaron hasta <commit> (lo corre el usuario)
#
# Nunca bloquea al agente: cualquier fallo se anota en el log y sale con 0. Ademas deja un aviso en
# vault-errors/ (lo muestra la bienvenida) que se borra solo cuando ese paso vuelve a funcionar.
# Un lock evita que dos agentes sincronicen a la vez. No sube nada que parezca un secreto ni cambios
# a archivos existentes de raw/ (fuentes crudas, inmutables). Tampoco aplica, al bajar, cambios ajenos
# a lo que se ejecuta u obedece en este equipo (plugins de Obsidian, schema de los agentes, workflows):
# quien pueda escribir en la boveda (p. ej. el VPS) no debe poder ejecutar codigo aqui. Esos quedan en
# un aviso hasta que el usuario los revisa y corre `vault-sync.sh trust <commit>`.
set -u

VAULT="${OBSIDIAN_VAULT:-$HOME/.config/obsidian}"
HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
LOG="$HOME/.cache/salchipapa-dots/vault-sync.log"
ERRORS="$HOME/.cache/salchipapa-dots/vault-errors"
mode="${1:-}"
agent="${2:-agente}"
[ "$mode" = trust ] && agent=usuario

mkdir -p "$(dirname "$LOG")"
log() { printf '%s [%s %s] %s\n' "$(date '+%F %T')" "$agent" "$mode" "$*" >>"$LOG"; }
# fail <paso> <mensaje> deja el aviso; ok_step <paso> lo quita
fail() { mkdir -p "$ERRORS"; printf '%s (%s, %s)\n' "$2" "$agent" "$(date '+%F %H:%M')" >"$ERRORS/$1"; log "$2"; }
ok_step() { rm -f "$ERRORS/$1"; }

[ -d "$VAULT/.git" ] || exit 0
cd "$VAULT" || exit 0

exec 9>"$VAULT/.git/vault-sync.lock"
flock -w 30 9 || { log "otro sync en curso, se omite"; exit 0; }

# Los mismos patrones que el hook secret-scan de Claude Code
SECRETS='gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{40,}|AIza[0-9A-Za-z_-]{35}|AQ\.[A-Za-z0-9_-]{30,}|sk-[A-Za-z0-9_-]{20,}|oma_(live|test)_[A-Za-z0-9]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----'

# Lo que se ejecuta u obedece en este equipo. `git config vault.guard false` lo desactiva (el VPS,
# que solo recibe cambios del usuario)
SENSITIVE='^(\.obsidian/|\.github/|\.gitignore$|AGENTS\.md$|CLAUDE\.md$|GEMINI\.md$|templates/)'
TRUSTED="$VAULT/.git/vault-sync-trusted"

# guard <commit remoto>: falla si trae cambios a archivos sensibles que el usuario no ha aceptado
guard() {
  local up=$1 base trusted touched
  [ "$(git config --bool vault.guard)" = false ] && return 0
  base="$(git merge-base HEAD "$up")" || return 0
  # Lo aceptado con `trust` ya no cuenta, si sigue en la misma línea de historia
  trusted="$(cat "$TRUSTED" 2>/dev/null)"
  if [ -n "$trusted" ] && git merge-base --is-ancestor "$base" "$trusted" 2>/dev/null &&
    git merge-base --is-ancestor "$trusted" "$up" 2>/dev/null; then
    base="$trusted"
  fi
  touched="$(git diff --name-only "$base" "$up" | grep -E "$SENSITIVE" | tr '\n' ' ')"
  if [ -n "$touched" ]; then
    fail guard "No se bajó la bóveda: llegaron cambios a archivos que se ejecutan u obedecen en este equipo (${touched% }). Revísalos con git -C $VAULT diff $(git rev-parse --short "$base") $(git rev-parse --short "$up") -- ${touched% } y, si los hiciste tú, acéptalos con vault-sync.sh trust $(git rev-parse --short "$up")"
    return 1
  fi
  ok_step guard
}

pull() {
  local out up
  if ! out=$(git fetch -q 2>&1) || ! up="$(git rev-parse -q --verify '@{u}')"; then
    fail pull "No se pudo bajar la bóveda (¿sin red?): $(printf '%s' "$out" | tail -1)"
    return 1
  fi
  ok_step pull
  guard "$up" || return 1
  # Se aplica justo el commit revisado, no lo que haya llegado después
  if ! out=$(git rebase --autostash -q "$up" 2>&1); then
    git rebase --abort >/dev/null 2>&1
    fail pull "No se pudo bajar la bóveda (¿conflicto?): $(printf '%s' "$out" | tail -1)"
    return 1
  fi
  log "pull ok"
}

push() {
  if [ -n "$(git status --porcelain)" ]; then
    # index.md sigue a las paginas: se regenera desde su `resumen` antes de cada commit
    OBSIDIAN_VAULT="$VAULT" python3 "$HERE/vault-lint.py" --index >/dev/null 2>&1 || true
    git add -A
    # raw/ es la capa de fuentes crudas (LLM Wiki): se anaden archivos, nunca se modifican ni borran
    touched="$(git diff --cached --name-status --diff-filter=MDR -- raw/ | grep -v '/\.gitkeep$' | cut -f2- | tr '\t\n' '  ')"
    if [ -n "$touched" ]; then
      git reset -q
      fail push "No se subió la bóveda: se modificó o borró algo de raw/, que es inmutable ($touched). Restáuralo con git -C $VAULT checkout -- raw/ (o súbelo a mano si fue a propósito)."
      return 1
    fi
    if git diff --cached -U0 | grep -E '^\+' | grep -qE "$SECRETS"; then
      git reset -q
      fail push "No se subió la bóveda: hay algo que parece un secreto en los cambios. Revísalo a mano."
      return 1
    fi
    git commit -q -m "auto ($agent): $(date '+%F %H:%M')" && log "commit: $(git log -1 --format=%h) $(git diff --stat HEAD~1 HEAD | tail -1)"
  fi
  if [ -n "$(git log --oneline '@{u}..HEAD' 2>/dev/null)" ]; then
    pull || return 1
    if out=$(git push -q 2>&1); then
      ok_step push
      log "push ok"
    else
      fail push "No se pudo subir la bóveda: $(printf '%s' "$out" | tail -1)"
    fi
  else
    ok_step push
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
trust)
  # Solo el usuario, después de revisar el diff que muestra el aviso
  if ! sha="$(git rev-parse -q --verify "${2:-}^{commit}")"; then
    echo "uso: vault-sync.sh trust <commit>  (el que muestra el aviso)" >&2
    exit 1
  fi
  echo "$sha" >"$TRUSTED"
  log "aceptado hasta $sha"
  echo "Aceptados los cambios hasta $(git log -1 --format='%h %s' "$sha")"
  pull
  ;;
*)
  echo "uso: vault-sync.sh pull|push|start [agente] | trust <commit>" >&2
  ;;
esac
exit 0
