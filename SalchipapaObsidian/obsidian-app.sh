#!/usr/bin/env bash
# obsidian-app.sh — abre la app de escritorio de Obsidian con sus datos fuera de la boveda.
# Electron usa por defecto ~/.config/obsidian como datos de app (cache, cookies, obsidian.json),
# que es la misma carpeta que la boveda: los mueve a ~/.local/share/obsidian-app.
# setup-agents.py lo enlaza como ~/.local/bin/obsidian y crea un .desktop que lo usa.
self="$(readlink -f "$0")"
IFS=: read -ra dirs <<<"$PATH"
for d in "${dirs[@]}"; do
  bin="$d/obsidian"
  # -f: si ~/.config esta en el PATH, ~/.config/obsidian es la boveda (un directorio)
  if [ -f "$bin" ] && [ -x "$bin" ] &&[ "$(readlink -f "$bin")" != "$self" ]; then
    exec "$bin" --user-data-dir="$HOME/.local/share/obsidian-app" "$@"
  fi
done
echo "obsidian-app.sh: Obsidian no está instalado (no hay otro 'obsidian' en el PATH)" >&2
exit 127
