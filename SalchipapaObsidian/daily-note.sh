#!/usr/bin/env bash
# daily-note.sh [AAAA-MM-DD] — escribe la nota diaria de la boveda con Claude Code, sin intervencion.
# Lo lanza obsidian-daily.timer cada dia a las 00:10, cuando el dia ya termino. Fuentes: las
# "## Sesiones de hoy" que se escriben al cerrar cada sesion (en cualquier equipo), los commits del
# dia en mis repos y claude-mem.
#
# Sin fecha: escribe todos los dias ya terminados que falten, desde el siguiente al ultimo generado
# (como mucho 7 dias atras) hasta ayer. Asi no se pierde ningun dia aunque el equipo estuviera
# apagado (el timer es Persistent: corre al volver a encenderlo). Con fecha: (re)genera ese dia.
set -uo pipefail

VAULT="${OBSIDIAN_VAULT:-$HOME/.config/obsidian}"
HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
STATE="$HOME/.cache/salchipapa-dots"
LOG="$STATE/daily-note.log"
DONE="$STATE/daily-note.done"
mkdir -p "$STATE"
log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG"; }
fail() { mkdir -p "$STATE/vault-errors"; printf '%s\n' "$1" >"$STATE/vault-errors/daily"; log "$1"; }

# Dias a escribir
DATES=()
if [ -n "${1:-}" ]; then
  DATES=("$1")
else
  last_done="$(sort "$DONE" 2>/dev/null | tail -1)"
  for i in 7 6 5 4 3 2 1; do
    d="$(date -d "-$i days" +%F)"
    # Equipo nuevo (sin historial): solo ayer. Si no, lo posterior al ultimo dia generado.
    if [ -z "$last_done" ]; then
      [ "$i" -eq 1 ] && DATES+=("$d")
    elif [[ "$d" > "$last_done" ]] && ! grep -qxF "$d" "$DONE"; then
      DATES+=("$d")
    fi
  done
  [ "${#DATES[@]}" -eq 0 ] && { log "nada pendiente (ultimo: $last_done)"; exit 0; }
fi

[ -d "$VAULT/.git" ] || { log "no hay boveda en $VAULT"; exit 0; }
CLAUDE="$(command -v claude || echo "$HOME/.local/bin/claude")"
[ -x "$CLAUDE" ] || { fail "La nota diaria no se escribió: no se encontró claude."; exit 0; }

bash "$HERE/vault-sync.sh" pull nocturno
EMAILS="$(git config --global user.email)"
failed=()

for D in "${DATES[@]}"; do
  # Mis commits de ese dia en los repos de mi home (sin la propia boveda)
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
1. Si daily/$D.md ya existe, su sección "## Sesiones de hoy": resúmenes que se escribieron al cerrar
   cada sesión con un agente, en cualquiera de los equipos del usuario. Es la fuente principal.
2. Commits del usuario ese día (abajo).
3. claude-mem: busca las observaciones y sesiones del $D (herramientas mcp de claude-mem, con
   dateStart/dateEnd de ese día) para saber qué se hizo, qué se aprendió y qué quedó pendiente.

Reglas:
- Archivo: daily/$D.md. Formato: el de templates/daily.md, con el estilo de las diarias anteriores
  de daily/ (léete la más reciente): secciones Qué hice hoy, Qué aprendí, Problemas / Blockers,
  Mañana, Notas rápidas; tablas de bugs resueltos y enlaces [[nota]] si aplican.
- Si daily/$D.md ya existe, compleméntala sin borrar lo que haya, y conserva "## Sesiones de hoy"
  tal cual al final de la nota.
- Concreto y en español. Solo hechos de las fuentes: no inventes.
- Nunca escribas secretos (tokens, claves, contraseñas).
- No toques otras notas. No ejecutes git (la sincronización es automática).
- Si las fuentes no muestran actividad ese día, no crees nada y responde solo: SIN ACTIVIDAD.

Commits del $D:${COMMITS:- (ninguno)}
EOF

  log "$D: generando ($(printf '%s' "$COMMITS" | grep -c '^- ') commits)"
  # Sin hooks: este claude -p no sincroniza, no saluda, no se resume a si mismo ni lo guarda claude-mem
  out="$(cd "$VAULT" && "$CLAUDE" -p "$PROMPT" \
    --allowedTools "Read,Write,Edit,Glob,Grep,mcp__plugin_claude-mem_mcp-search" \
    --permission-mode acceptEdits --settings '{"disableAllHooks": true}' </dev/null 2>&1)"
  rc=$?
  log "$D: claude rc=$rc: $(printf '%s' "$out" | tail -c 300 | tr '\n' ' ')"
  if [ "$rc" -eq 0 ]; then
    grep -qxF "$D" "$DONE" 2>/dev/null || echo "$D" >>"$DONE"
  else
    failed+=("$D")
  fi
done

bash "$HERE/vault-sync.sh" push nocturno
if [ "${#failed[@]}" -eq 0 ]; then
  rm -f "$STATE/vault-errors/daily"
else
  fail "La nota diaria de ${failed[*]} falló (claude). Se reintenta en la próxima ejecución. Detalle: $LOG"
fi
exit 0
