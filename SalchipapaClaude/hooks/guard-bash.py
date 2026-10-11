#!/usr/bin/env python3
"""PreToolUse (Bash): bloquea dos comandos que ya causaron accidentes.

- pkill -f / killall con un patron de nombre: pueden matar procesos del usuario que coinciden
  (un `pkill -f 'herdr server'` cerro su sesion real de herdr). Usar `kill <pid>` del proceso
  que uno lanzo, o parar el servicio por su propio comando/socket.
- sed -i sobre un symlink: sed reemplaza el enlace por un archivo normal y el cambio nunca llega
  al archivo real (paso con ~/.config/starship.toml -> repo). Editar el destino del enlace.
"""
import json
import os
import re
import shlex
import sys


def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def segments(cmd):
    """Parte el comando en subcomandos (por ; && || | y saltos de linea) y los tokeniza."""
    for part in re.split(r"\|\||&&|;|\||\n", cmd):
        try:
            toks = shlex.split(part, comments=True)
        except ValueError:
            toks = part.split()
        if toks:
            yield toks


def main():
    data = json.load(sys.stdin)
    cmd = (data.get("tool_input") or {}).get("command") or ""
    cwd = data.get("cwd") or os.getcwd()

    for toks in segments(cmd):
        # saltar prefijos tipo `sudo`, `env VAR=x`, `timeout 5`
        while toks and (toks[0] in ("sudo", "env", "nohup", "timeout", "command") or "=" in toks[0]
                        or (toks[0].isdigit() and len(toks) > 1)):
            toks = toks[1:]
        if not toks:
            continue
        prog = os.path.basename(toks[0])

        if prog == "killall" or (prog == "pkill" and any(t == "-f" or (t.startswith("-") and not t.startswith("--") and "f" in t[1:]) or t == "--full" for t in toks[1:])):
            deny("Bloqueado: `" + prog + "` con un patrón puede matar procesos del usuario que no lanzaste "
                 "(ya cerró una sesión real de herdr). Usa `kill <pid>` del proceso que tú creaste, "
                 "o detén el servicio con su propio comando (p. ej. `herdr server stop`, `omniroute stop`).")

        if prog == "sed" and any(t == "-i" or t.startswith("-i") or t == "--in-place" or t.startswith("--in-place=") for t in toks[1:]):
            for t in toks[1:]:
                if t.startswith("-"):
                    continue
                p = os.path.join(cwd, os.path.expanduser(t))
                if os.path.islink(p):
                    deny(f"Bloqueado: `sed -i` sobre el symlink {t} lo convertiría en un archivo normal "
                         f"y el cambio no llegaría al archivo real. Edita el destino: {os.path.realpath(p)}")


if __name__ == "__main__":
    main()
