#!/usr/bin/env python3
"""vault-guard-raw.py — hook antes de editar archivos (Claude Code: PreToolUse; Gemini CLI: BeforeTool).

raw/ de la boveda es la capa de fuentes crudas del LLM Wiki: se anaden archivos, pero los que ya
existen no se editan. Si la herramienta va a escribir sobre un archivo existente de <boveda>/raw/, se
bloquea (exit 2: los dos agentes muestran stderr al modelo como motivo). Crear archivos nuevos en
raw/ si se permite (guardar una fuente). Cualquier otro caso, o un error, deja pasar.
"""
import json
import os
import sys
from pathlib import Path

VAULT = Path(os.environ.get("OBSIDIAN_VAULT", Path.home() / ".config/obsidian")).resolve()


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return 0
    args = data.get("tool_input") or {}
    raw = VAULT / "raw"
    for key in ("file_path", "notebook_path", "path", "absolute_path"):
        value = args.get(key)
        if not isinstance(value, str) or not value:
            continue
        target = Path(os.path.expanduser(value))
        if not target.is_absolute():
            target = Path(data.get("cwd") or os.getcwd()) / target
        target = target.resolve()
        if target.is_relative_to(raw) and target.is_file() and target.name != ".gitkeep":
            print(f"{target} está en raw/ de la bóveda: las fuentes crudas son inmutables (LLM Wiki). "
                  "No la edites: corrige o amplía la página de la wiki que la usa.", file=sys.stderr)
            return 2
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:  # nunca romper al agente por un fallo del hook
        sys.exit(0)
