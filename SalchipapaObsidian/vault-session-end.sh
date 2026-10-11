#!/usr/bin/env bash
# vault-session-end.sh [agente]          — hook de fin de sesion (lee el JSON del hook por stdin)
# vault-session-end.sh --drain [agente]  — procesa la cola pendiente (lo llama vault-start.sh)
#
# Al cerrar una sesion: guarda el JSON del hook en una cola y, en segundo plano, resume la sesion en
# la nota diaria de hoy (session-log.py) y sube la boveda (vault-sync.sh push). El agente no espera.
# La cola sobrevive a un apagado (WSL se apaga al cerrar la ultima terminal): lo pendiente se procesa
# al empezar la siguiente sesion. Una entrada que falla 3 veces se descarta con un aviso (vault-errors/).
HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
STATE="$HOME/.cache/salchipapa-dots"
QUEUE="$STATE/session-queue"
mkdir -p "$QUEUE"

if [ "${1:-}" = "--drain" ]; then
  agent="${2:-agente}"
  # Un solo vaciado a la vez
  exec 8>"$QUEUE/.lock"
  flock -n 8 || exit 0
  for f in "$QUEUE"/*.json; do
    [ -e "$f" ] || break
    name="$(basename "$f" .json)"   # <fecha>-<pid>-<agente>[.tryN]
    a="${name#*-*-}"
    a="${a%%.try*}"
    if python3 "$HERE/session-log.py" "$f" "$a"; then
      rm -f "$f" "$STATE/vault-errors/session"
    else
      tries="${name##*.try}"
      [ "$tries" = "$name" ] && tries=0
      if [ "$tries" -ge 2 ]; then
        mkdir -p "$STATE/vault-errors"
        printf 'No se pudo resumir una sesion de %s en la nota de hoy (3 intentos). Detalle: %s\n' \
          "$a" "$STATE/session-log.log" >"$STATE/vault-errors/session"
        rm -f "$f"
      else
        mv "$f" "$QUEUE/${name%%.try*}.try$((tries + 1)).json"
      fi
    fi
  done
  bash "$HERE/vault-sync.sh" push "$agent"
  exit 0
fi

# Modo hook: guardar el JSON (stdin) y seguir en segundo plano para que el agente cierre ya
agent="${1:-agente}"
cat >"$QUEUE/$(date +%Y%m%d%H%M%S)-$$-$agent.json"
setsid -f bash "$0" --drain "$agent" >/dev/null 2>&1 </dev/null
exit 0
