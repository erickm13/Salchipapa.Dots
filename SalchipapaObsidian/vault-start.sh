#!/usr/bin/env bash
# vault-start.sh [agente] — hook de inicio de sesion de los agentes:
# sincroniza la boveda (sube lo pendiente + baja lo nuevo), da la bienvenida con lo ultimo que hice
# y procesa los resumenes de sesion pendientes (vault-session-end.sh).
HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
bash "$HERE/vault-sync.sh" start "${1:-agente}"
python3 "$HERE/vault-welcome.py"
# Resumenes de sesiones que quedaron sin escribir (el equipo se apago al cerrarlas): en segundo plano
if compgen -G "$HOME/.cache/salchipapa-dots/session-queue/*.json" >/dev/null; then
  setsid -f bash "$HERE/vault-session-end.sh" --drain "${1:-agente}" >/dev/null 2>&1 </dev/null
fi
exit 0
