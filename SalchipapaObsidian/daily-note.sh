#!/usr/bin/env bash
# daily-note.sh [AAAA-MM-DD] — escribe la nota diaria de la boveda con Claude Code, sin intervencion.
# Lo lanza cada noche obsidian-daily.timer. Fuentes: los commits del dia en mis repos + claude-mem.
#
# Sin fecha: hoy si son las 18:00 o mas tarde; si no, ayer (el timer es Persistent: si WSL estaba
# apagado a las 23:30, corre al volver a encenderlo y escribe la del dia que falto).
set -uo pipefail

VAULT="${OBSIDIAN_VAULT:-$HOME/.config/obsidian}"
HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
STATE="$HOME/.cache/salchipapa-dots"
LOG="$STATE/daily-note.log"
mkdir -p "$STATE"
log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG"; }
fail() { mkdir -p "$STATE/vault-errors"; printf '%s\n' "$1" >"$STATE/vault-errors/daily"; log "$1"; }

if [ -n "${1:-}" ]; then
  D="$1"
elif [ "$(date +%H)" -ge 18 ]; then
  D="$(date +%F)"
else
  D="$(date -d yesterday +%F)"
fi

[ -d "$VAULT/.git" ] || { log "$D: no hay boveda en $VAULT"; exit 0; }
CLAUDE="$(command -v claude || echo "$HOME/.local/bin/claude")"
[ -x "$CLAUDE" ] || { fail "La nota diaria del $D no se escribió: no se encontró claude."; exit 0; }
if [ -z "${1:-}" ] && grep -qxF "$D" "$STATE/daily-note.done" 2>/dev/null; then
  log "$D: ya generada, se omite"
  exit 0
fi

bash "$HERE/vault-sync.sh" pull nocturno

# Mis commits de ese dia en los repos de mi home (sin la propia boveda)
EMAILS="$(git config --global user.email)"
COMMITS=""
while IFS= read -r gitdir; do
  repo="$(dirname "$gitdir")"
  [ "$repo" = "$VAULT" ] && continue
  c="$(git -C "$repo" log --all --since="$D 00:00" --until="$D 23:59:59" \
    --author="$EMAILS" --format='- %h %s' 2>/dev/null)"
  [ -n "$c" ] && COMMITS+=$'\n'"### $(basename "$repo")"$'\n'"$c"
done < <(find "$HOME" -maxdepth 3 -name .git -type d -not -path '*/.cache/*' -not -path '*/.local/*' 2>/dev/null)

read -r -d '' PROMPT <<EOF
Escribe la nota diaria del $D en la bóveda de Obsidian (estás en ella: $VAULT).

Fuentes:
1. Commits del usuario ese día (abajo).
2. claude-mem: busca las observaciones y sesiones del $D (herramientas mcp de claude-mem, con
   dateStart/dateEnd de ese día) para saber qué se hizo, qué se aprendió y qué quedó pendiente.

Reglas:
- Archivo: daily/$D.md. Formato: el de templates/daily.md, con el estilo de las diarias anteriores
  de daily/ (léete la más reciente): secciones Qué hice hoy, Qué aprendí, Problemas / Blockers,
  Mañana, Notas rápidas; tablas de bugs resueltos y enlaces [[nota]] si aplican.
- Si daily/$D.md ya existe, compleméntala sin borrar lo que haya.
- Concreto y en español. Solo hechos de las fuentes: no inventes.
- Nunca escribas secretos (tokens, claves, contraseñas).
- No toques otras notas. No ejecutes git (la sincronización es automática).
- Si las fuentes no muestran actividad ese día, no crees nada y responde solo: SIN ACTIVIDAD.

Commits del $D:${COMMITS:- (ninguno)}
EOF

log "$D: generando ($(printf '%s' "$COMMITS" | grep -c '^- ') commits)"
cd "$VAULT" || exit 0
out="$("$CLAUDE" -p "$PROMPT" \
  --allowedTools "Read,Write,Edit,Glob,Grep,mcp__plugin_claude-mem_mcp-search" \
  --permission-mode acceptEdits </dev/null 2>&1)"
rc=$?
log "$D: claude rc=$rc: $(printf '%s' "$out" | tail -c 300 | tr '\n' ' ')"

if [ "$rc" -eq 0 ]; then
  rm -f "$STATE/vault-errors/daily"
  echo "$D" >>"$STATE/daily-note.done"
  bash "$HERE/vault-sync.sh" push nocturno
else
  fail "La nota diaria del $D falló (claude rc=$rc). Detalle: $LOG"
fi
exit 0
