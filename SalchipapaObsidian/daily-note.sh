#!/usr/bin/env bash
# daily-note.sh [AAAA-MM-DD] — escribe la nota diaria de la boveda con Claude Code, sin intervencion.
# Lo lanza obsidian-daily.timer cada dia a las 00:10, cuando el dia ya termino. Fuentes: las
# "## Sesiones de hoy" que se escriben al cerrar cada sesion (en cualquier equipo), los commits del
# dia en mis repos y claude-mem.
#
# Sin fecha: escribe todos los dias ya terminados que falten, desde el siguiente al ultimo generado
# (como mucho 7 dias atras) hasta ayer. Asi no se pierde ningun dia aunque el equipo estuviera
# apagado (el timer es Persistent: corre al volver a encenderlo). Con fecha: (re)genera ese dia.
#
# En GitHub Actions (GITHUB_ACTIONS=true, workflow del repo de la boveda): los commits salen de la
# API de GitHub (GH_TOKEN), no hay claude-mem, un dia esta hecho si su diaria ya tiene "## Qué hice",
# los dias sin sesiones ni commits se saltan sin llamar a Claude, y un fallo hace fallar el job.
set -uo pipefail

VAULT="${OBSIDIAN_VAULT:-$HOME/.config/obsidian}"
HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
STATE="$HOME/.cache/salchipapa-dots"
LOG="$STATE/daily-note.log"
DONE="$STATE/daily-note.done"
mkdir -p "$STATE"
log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG"; }
fail() { mkdir -p "$STATE/vault-errors"; printf '%s\n' "$1" >"$STATE/vault-errors/daily"; log "$1"; }
CLOUD=0
[ "${GITHUB_ACTIONS:-}" = true ] && CLOUD=1
GH_USER="${DAILY_GITHUB_USER:-${GITHUB_REPOSITORY_OWNER:-}}"

# commits <dia>: mis commits de ese dia, agrupados por repo
commits() {
  local d="$1" gitdir repo c
  if [ "$CLOUD" -eq 1 ]; then
    # API de busqueda de GitHub (repos visibles con GH_TOKEN), con la zona horaria local (TZ)
    local tz
    tz="$(date +%:z)"
    gh api -X GET search/commits -f q="author:$GH_USER committer-date:${d}T00:00:00$tz..${d}T23:59:59$tz" \
      -f per_page=100 --jq '.items | group_by(.repository.name)[] |
        "### \(.[0].repository.name)\n" + (map("- \(.sha[0:7]) \(.commit.message | split("\n")[0])") | join("\n"))' \
      2>>"$LOG" || true
    return
  fi
  while IFS= read -r gitdir; do
    repo="$(dirname "$gitdir")"
    [ "$repo" = "$VAULT" ] && continue
    c="$(git -C "$repo" log --all --since="$d 00:00" --until="$d 23:59:59" \
      --author="$EMAILS" --format='- %h %s' 2>/dev/null)"
    [ -n "$c" ] && printf '### %s\n%s\n' "$(basename "$repo")" "$c"
  done < <(find "$HOME" -maxdepth 3 -name .git -type d -not -path '*/.cache/*' -not -path '*/.local/*' 2>/dev/null)
}

# Dias a escribir
DATES=()
EMAILS="$(git config --global user.email || true)"
if [ -n "${1:-}" ]; then
  DATES=("$1")
elif [ "$CLOUD" -eq 1 ]; then
  # Nube: ultimos 7 dias terminados cuya diaria no esta completa y en los que hubo algo
  for i in 7 6 5 4 3 2 1; do
    d="$(date -d "-$i days" +%F)"
    note="$VAULT/daily/$d.md"
    grep -q '^## Qué hice' "$note" 2>/dev/null && continue
    if [ -f "$note" ] || [ -n "$(commits "$d")" ]; then
      DATES+=("$d")
    fi
  done
  [ "${#DATES[@]}" -eq 0 ] && { log "nada pendiente"; exit 0; }
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
failed=()

for D in "${DATES[@]}"; do
  COMMITS="$(commits "$D")"
  [ -n "$COMMITS" ] && COMMITS=$'\n'"$COMMITS"
  if [ "$CLOUD" -eq 1 ]; then
    MEM="3. (claude-mem no está disponible aquí: usa solo las fuentes 1 y 2.)"
    TOOLS="Read,Write,Edit,Glob,Grep"
  else
    MEM="3. claude-mem: busca las observaciones y sesiones del $D (herramientas mcp de claude-mem, con
   dateStart/dateEnd de ese día) para saber qué se hizo, qué se aprendió y qué quedó pendiente."
    TOOLS="Read,Write,Edit,Glob,Grep,mcp__plugin_claude-mem_mcp-search"
  fi

  read -r -d '' PROMPT <<EOF
Escribe la nota diaria del $D en la bóveda de Obsidian (estás en ella: $VAULT).

Fuentes:
1. Si daily/$D.md ya existe, su sección "## Sesiones de hoy": resúmenes que se escribieron al cerrar
   cada sesión con un agente, en cualquiera de los equipos del usuario. Es la fuente principal.
2. Commits del usuario ese día (abajo).
$MEM

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
    --allowedTools "$TOOLS" \
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
  [ "$CLOUD" -eq 1 ] && exit 1
fi
exit 0
