#!/usr/bin/env bash
# vault-session-end.sh [agente]          — hook de fin de sesion (lee el JSON del hook por stdin)
# vault-session-end.sh --drain [agente]  — procesa la cola pendiente (lo llama vault-start.sh)
#
# Al cerrar una sesion: guarda el JSON del hook en una cola y, en segundo plano, resume la sesion en
# la nota diaria de hoy (session-log.py) y sube la boveda (vault-sync.sh push). El agente no espera.
# La cola sobrevive a un apagado (WSL se apaga al cerrar la ultima terminal): lo pendiente se procesa
# al empezar la siguiente sesion. Una entrada que falla 3 veces se descarta con un aviso (vault-errors/);
# si falla por el limite de uso de Claude no cuenta como intento. La conversacion ya quedo en raw/.
#
# El vaciado lanzado por un cierre deja el resultado en session-end.status (1a linea: marca en ns; 2a: el
# mensaje). La funcion de fish __vault_esperar_cierre lo muestra al salir de claude/codex/copilot.
HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
STATE="$HOME/.cache/salchipapa-dots"
QUEUE="$STATE/session-queue"
STATUS="$STATE/session-end.status"
mkdir -p "$QUEUE"

if [ "${1:-}" = "--drain" ] || [ "${1:-}" = "--drain-hook" ]; then
  mode="$1"
  agent="${2:-agente}"
  # Un solo vaciado a la vez
  exec 8>"$QUEUE/.lock"
  flock -n 8 || exit 0
  notes=() results=() pending=0 limited=0
  for f in "$QUEUE"/*.json; do
    [ -e "$f" ] || break
    name="$(basename "$f" .json)"   # <fecha>-<pid>-<agente>[.tryN]
    a="${name#*-*-}"
    a="${a%%.try*}"
    result="$(python3 "$HERE/session-log.py" "$f" "$a")"
    rc=$?
    if [ "$rc" -eq 0 ]; then
      rm -f "$f" "$STATE/vault-errors/session"
      results+=("$result")
      case "$result" in resumen\ *) notes+=("${result#resumen }") ;; esac
    elif [ "$rc" -eq 75 ]; then
      # Claude en su limite de uso: se queda en la cola sin gastar un intento (la conversacion ya
      # esta en raw/); se reintenta al abrir la proxima sesion
      pending=1 limited=1
    else
      pending=1
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

  if [ "$mode" = "--drain-hook" ]; then
    if [ -f "$STATE/vault-errors/push" ]; then
      msg="⚠ La bóveda no se pudo subir: $(cat "$STATE/vault-errors/push") — se reintenta al abrir la próxima sesión"
    elif [ "$limited" -eq 1 ]; then
      msg="⚠ Claude está en su límite de uso: la conversación quedó en raw/ y el resumen se escribe al abrir la próxima sesión; bóveda subida a GitHub"
    elif [ "$pending" -eq 1 ]; then
      msg="⚠ No se pudo escribir el resumen de la sesión (se reintenta al abrir la próxima); bóveda subida a GitHub"
    elif [ "${#notes[@]}" -gt 0 ]; then
      msg="✔ Notas guardadas: resumen de la sesión en ${notes[*]} y bóveda subida a GitHub"
    else
      case " ${results[*]} " in
      *" nada "*) why="la sesión no dejó nada que anotar" ;;
      *" sin-transcript "*) why="no hubo conversación (sesión vacía) o el agente no entrega su transcript" ;;
      *) why="no hubo mensajes nuevos desde el último resumen" ;;
      esac
      msg="✔ Bóveda al día en GitHub (sin resumen: $why)"
    fi
    printf '%s\n%s\n' "$(date +%s%N)" "$msg" >"$STATUS.tmp" && mv "$STATUS.tmp" "$STATUS"
  fi
  exit 0
fi

# Modo hook: guardar el JSON (stdin) y seguir en segundo plano para que el agente cierre ya
agent="${1:-agente}"
cat >"$QUEUE/$(date +%Y%m%d%H%M%S)-$$-$agent.json"
setsid -f bash "$0" --drain-hook "$agent" >/dev/null 2>&1 </dev/null
exit 0
