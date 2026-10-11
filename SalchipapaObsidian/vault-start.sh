#!/usr/bin/env bash
# vault-start.sh [agente] — hook de inicio de sesion de los agentes:
# sincroniza la boveda (sube lo pendiente + baja lo nuevo) y da la bienvenida con lo ultimo que hice.
HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
bash "$HERE/vault-sync.sh" start "${1:-agente}"
python3 "$HERE/vault-welcome.py"
exit 0
