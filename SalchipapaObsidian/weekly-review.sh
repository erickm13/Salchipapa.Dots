#!/usr/bin/env bash
# weekly-review.sh [AAAA-MM-DD] — revision semanal de la boveda (Building a Second Brain) con Claude Code.
# Lo lanza obsidian-weekly.timer los lunes a las 00:40, con las diarias de toda la semana ya
# escritas. Escribe weekly/AAAA-Wnn.md con el resumen de la semana y PROPUESTAS (inbox a clasificar, proyectos a archivar) como tareas `- [ ]`: no mueve nada solo.
# El usuario las aplica diciendole a un agente "aplica la revision semanal".
#
# Semana: lunes a domingo. Sin fecha: la que termina hoy si es domingo; si no, la anterior
# (el lunes a las 00:40 es la que acaba de terminar; el timer es Persistent: corre al volver).
set -uo pipefail

VAULT="${OBSIDIAN_VAULT:-$HOME/.config/obsidian}"
HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
STATE="$HOME/.cache/salchipapa-dots"
LOG="$STATE/weekly-review.log"
mkdir -p "$STATE"
log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG"; }
fail() { mkdir -p "$STATE/vault-errors"; printf '%s\n' "$1" >"$STATE/vault-errors/weekly"; log "$1"; }

# Domingo que cierra la semana
if [ -n "${1:-}" ]; then
  SUN="$(date -d "$1 +$((7 - $(date -d "$1" +%u))) days" +%F)"
else
  SUN="$(date -d "-$(($(date +%u) % 7)) days" +%F)"
fi
MON="$(date -d "$SUN -6 days" +%F)"
W="$(date -d "$SUN" +%G-W%V)"

[ -d "$VAULT/.git" ] || { log "$W: no hay boveda en $VAULT"; exit 0; }
CLAUDE="$(command -v claude || echo "$HOME/.local/bin/claude")"
[ -x "$CLAUDE" ] || { fail "La revisión semanal $W no se escribió: no se encontró claude."; exit 0; }
if [ -z "${1:-}" ] && grep -qxF "$W" "$STATE/weekly-review.done" 2>/dev/null; then
  log "$W: ya generada, se omite"
  exit 0
fi

bash "$HERE/vault-sync.sh" pull semanal

read -r -d '' PROMPT <<EOF
Haz la revisión semanal $W ($MON a $SUN) de la bóveda de Obsidian (estás en ella: $VAULT),
siguiendo Building a Second Brain / PARA (las reglas están en tus instrucciones de memoria):
projects/ (meta y final, activos), areas/ (responsabilidades: qa, universidad), resources/<tema>/
(consulta, cada tema con su hub), archive/ (terminado), inbox/ (captura sin clasificar).

Lee: las notas de daily/ de $MON a $SUN, todo inbox/, y los archivos de projects/ (su lista Estado).

Escribe weekly/$W.md (crea la carpeta si no existe) con estas secciones:
# Semana $W ($MON — $SUN)
## Resumen         2-4 líneas: en qué se fue la semana
## Logros          viñetas, lo más importante (con [[enlaces]] a notas si aplica)
## Aprendizajes    lo que vale la pena recordar
## Propuestas      tareas "- [ ]" concretas para ordenar la bóveda, una por línea:
                   - cada nota de inbox/: "Mover [[nota]] → resources/<tema>/ (porqué corto)"
                     (o areas/, projects/, archive/, o "Borrar [[nota]]" si está vacía)
                   - cada proyecto con todo el Estado en [x] o sin actividad en la semana:
                     "Archivar [[proyecto]] → archive/ (porqué)"
                   - si no hay nada que ordenar: "- Nada que ordenar esta semana"
## Para la semana que viene   viñetas: pendientes de Estado, "Mañana" de la última diaria

Reglas:
- Solo hechos de las notas: no inventes. Concreto y en español. Nunca secretos.
- NO muevas, borres ni edites ninguna otra nota: solo escribe weekly/$W.md. No ejecutes git.
- Si weekly/$W.md ya existe, reescríbela conservando las propuestas ya marcadas [x].
- Si no hay diarias esa semana Y inbox/ está vacía, no crees nada y responde solo: SIN ACTIVIDAD.
EOF

log "$W: generando ($MON a $SUN)"
cd "$VAULT" || exit 0
out="$("$CLAUDE" -p "$PROMPT" \
  --allowedTools "Read,Write,Edit,Glob,Grep" \
  --permission-mode acceptEdits --settings '{"disableAllHooks": true}' </dev/null 2>&1)"
rc=$?
log "$W: claude rc=$rc: $(printf '%s' "$out" | tail -c 300 | tr '\n' ' ')"

if [ "$rc" -eq 0 ]; then
  rm -f "$STATE/vault-errors/weekly"
  echo "$W" >>"$STATE/weekly-review.done"
  bash "$HERE/vault-sync.sh" push semanal
else
  fail "La revisión semanal $W falló (claude rc=$rc). Detalle: $LOG"
fi
exit 0
