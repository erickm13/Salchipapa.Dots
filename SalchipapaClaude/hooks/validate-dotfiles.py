#!/usr/bin/env python3
"""PostToolUse (Edit|Write): valida los archivos de Salchipapa.Dots al editarlos.

- *.sh, install.sh y scripts bash sin extension -> bash -n + shellcheck -S error
- *.fish                                     -> fish -n
- SalchipapaHerdr/config.toml                -> herdr server reload-config (falla si hay diagnostics)
- SalchipapaWezterm/.wezterm.lua             -> copia a la carpeta de Windows (solo en WSL)

Un error sale con codigo 2: Claude Code le devuelve el mensaje a Claude para que lo corrija.
Archivos fuera del repo se ignoran (codigo 0, sin salida).
"""
import json
import os
import shutil
import subprocess
import sys

DOTS = os.path.realpath(os.path.expanduser("~/Salchipapa.Dots"))


def win_wezterm():
    """~/.wezterm.lua del usuario de Windows (WSL), o None fuera de WSL."""
    try:
        out = subprocess.run(["cmd.exe", "/c", "echo %USERPROFILE%"], capture_output=True,
                             text=True, timeout=10, cwd="/mnt/c").stdout.strip()
        home = subprocess.run(["wslpath", out], capture_output=True, text=True, timeout=5).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return None
    return os.path.join(home, ".wezterm.lua") if home and os.path.isdir(home) else None


def run(cmd):
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.returncode, (p.stdout + p.stderr).strip()


def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)


def is_bash_script(path):
    try:
        with open(path, "rb") as f:
            first = f.readline(200)
    except OSError:
        return False
    return first.startswith(b"#!") and b"bash" in first


def main():
    data = json.load(sys.stdin)
    raw = (data.get("tool_input") or {}).get("file_path") or (data.get("tool_response") or {}).get("filePath")
    if not raw:
        return
    path = os.path.realpath(raw)  # resuelve los symlinks de ~/.config hacia el repo
    if not path.startswith(DOTS + os.sep):
        return
    rel = os.path.relpath(path, DOTS)
    name = os.path.basename(path)

    if name.endswith(".sh") or name == "install.sh" or ("." not in name and is_bash_script(path)):
        rc, out = run(["bash", "-n", path])
        if rc:
            fail(f"bash -n falló en {rel}:\n{out}")
        if shutil.which("shellcheck"):
            rc, out = run(["shellcheck", "-S", "error", path])
            if rc:
                fail(f"shellcheck encontró errores en {rel}:\n{out}")
    elif name.endswith(".fish"):
        rc, out = run(["fish", "-n", path])
        if rc:
            fail(f"fish -n falló en {rel}:\n{out}")
    elif rel == os.path.join("SalchipapaHerdr", "config.toml") and shutil.which("herdr"):
        rc, out = run(["herdr", "server", "reload-config"])
        try:
            diags = json.loads(out).get("result", {}).get("diagnostics", [])
        except (ValueError, AttributeError):
            diags = []  # servidor de herdr no corriendo: nada que recargar
        if diags:
            fail("herdr rechazó parte de la config (" + rel + "):\n" + "\n".join(diags))
    elif rel == os.path.join("SalchipapaWezterm", ".wezterm.lua") and (dst := win_wezterm()):
        shutil.copyfile(path, dst)
        print(json.dumps({"systemMessage": f"WezTerm: config copiada a {dst}"}))


if __name__ == "__main__":
    main()
