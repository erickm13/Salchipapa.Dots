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
# Cada sesion deja su resultado en session-end/<VAULT_SESSION_TOKEN>: la marca que la funcion de fish
# (claude/codex/copilot) le pasa al agente; __vault_esperar_cierre la espera y la muestra al salir, asi
# cada ventana ve el de su propia sesion. session-end.status guarda el ultimo (compatibilidad).
HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
STATE="$HOME/.cache/salchipapa-dots"
QUEUE="$STATE/session-queue"
STATUS="$STATE/session-end.status"
DONE="$STATE/session-end"   # un archivo por sesion cerrada, con el nombre de su marca
mkdir -p "$QUEUE"

if [ "${1:-}" = "--drain" ] || [ "${1:-}" = "--drain-hook" ]; then
  mode="$1"
  agent="${2:-agente}"
  # Un solo vaciado a la vez
  exec 8>"$QUEUE/.lock"
  flock -n 8 || exit 0
  mkdir -p "$DONE"
  find "$DONE" -type f -mmin +1440 -delete 2>/dev/null # resultados que nadie leyo
  toks=() kinds=() all=() attempted=" " limited=0
  # Hasta que no quede nada nuevo: un cierre que llega mientras se vacia la cola tambien se procesa
  while :; do
    batch=()
    for f in "$QUEUE"/*.json; do
      [ -e "$f" ] || break
      base="$(basename "$f" .json)"
      base="${base%%.try*}"
      case "$attempted" in *" $base "*) ;; *) batch+=("$f") ;; esac
    done
    [ "${#batch[@]}" -eq 0 ] && break
    for f in "${batch[@]}"; do
      name="$(basename "$f" .json)"   # <fecha>-<pid>-<agente>[.tryN]
      base="${name%%.try*}"
      attempted+="$base "
      a="${base#*-*-}"
      tok="$(cat "$QUEUE/$base.token" 2>/dev/null)"
      result="$(python3 "$HERE/session-log.py" "$f" "$a")"
      rc=$?
      if [ "$rc" -eq 0 ]; then
        rm -f "$f" "$QUEUE/$base.token" "$STATE/vault-errors/session"
        kind="$result"
      elif [ "$rc" -eq 75 ]; then
        # Claude en su limite de uso: se queda en la cola sin gastar un intento (la conversacion ya
        # esta en raw/); se reintenta al abrir la proxima sesion
        kind="limite" limited=1
      else
        kind="fallo"
        tries="${name##*.try}"
        [ "$tries" = "$name" ] && tries=0
        if [ "$tries" -ge 2 ]; then
          mkdir -p "$STATE/vault-errors"
          printf 'No se pudo resumir una sesion de %s en la nota de hoy (3 intentos). Detalle: %s\n' \
            "$a" "$STATE/session-log.log" >"$STATE/vault-errors/session"
          rm -f "$f" "$QUEUE/$base.token"
        else
          mv "$f" "$QUEUE/$base.try$((tries + 1)).json"
        fi
      fi
      toks+=("$tok") kinds+=("$kind")
    done
  done
  bash "$HERE/vault-sync.sh" push "$agent"

  # El resultado de cada sesion, para la ventana que la cerro (su marca VAULT_SESSION_TOKEN)
  message() {
    if [ -f "$STATE/vault-errors/push" ]; then
      echo "⚠ La bóveda no se pudo subir: $(cat "$STATE/vault-errors/push") — se reintenta al abrir la próxima sesión"
      return
    fi
    case "$1" in
    resumen\ *) echo "✔ Notas guardadas: resumen de la sesión en ${1#resumen } y bóveda subida a GitHub" ;;
    limite) echo "⚠ Claude está en su límite de uso: la conversación quedó en raw/ y el resumen se escribe al abrir la próxima sesión; bóveda subida a GitHub" ;;
    fallo) echo "⚠ No se pudo escribir el resumen de la sesión (se reintenta al abrir la próxima); bóveda subida a GitHub" ;;
    nada) echo "✔ Bóveda al día en GitHub (sin resumen: la sesión no dejó nada que anotar)" ;;
    sin-transcript) echo "✔ Bóveda al día en GitHub (sin resumen: no hubo conversación o el agente no entrega su transcript)" ;;
    *) echo "✔ Bóveda al día en GitHub (sin resumen: no hubo mensajes nuevos desde el último resumen)" ;;
    esac
  }
  last=""
  for k in "${!kinds[@]}"; do
    msg="$(message "${kinds[$k]}")"
    last="$msg"
    if [ -n "${toks[$k]}" ]; then
      printf '%s\n' "$msg" >"$DONE/${toks[$k]}.tmp" && mv "$DONE/${toks[$k]}.tmp" "$DONE/${toks[$k]}"
    fi
  done
  if [ "$mode" = "--drain-hook" ] && [ -n "$last" ]; then
    # Ultimo resultado procesado (compatibilidad: lo usan las pruebas y quien no tenga marca)
    printf '%s\n%s\n' "$(date +%s%N)" "$last" >"$STATUS.tmp" && mv "$STATUS.tmp" "$STATUS"
  fi
  exit 0
fi

# Modo hook: guardar el JSON (stdin) y seguir en segundo plano para que el agente cierre ya
agent="${1:-agente}"
name="$(date +%Y%m%d%H%M%S)-$$-$agent"
# La marca de la ventana que abrio el agente (funciones de fish claude/codex/copilot): su resultado
# se escribe en session-end/<marca> y esa ventana lo muestra al salir
if [ -n "${VAULT_SESSION_TOKEN:-}" ]; then
  printf '%s\n' "$VAULT_SESSION_TOKEN" >"$QUEUE/$name.token"
fi
cat >"$QUEUE/$name.json"
setsid -f bash "$0" --drain-hook "$agent" >/dev/null 2>&1 </dev/null
exit 0
