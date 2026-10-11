#!/usr/bin/env python3
"""vault-welcome.py — bienvenida al empezar una sesion de un agente, leida de la boveda.

Toma la diaria mas reciente (Que hice hoy, Manana, Pendiente) y las tareas abiertas `- [ ]`
de projects/. Imprime JSON de hook: `systemMessage` (lo ve Erick) y `additionalContext`
(lo recibe el agente para saludar y retomar). Sin boveda o sin notas, no imprime nada.
"""
import datetime as dt
import json
import os
import re
import sys
from pathlib import Path

VAULT = Path(os.environ.get("OBSIDIAN_VAULT", Path.home() / ".config/obsidian"))
MAX_ITEMS = 4
MAX_LEN = 90


def sections(text):
    """{titulo de '## seccion' en minusculas: [lineas '- item']}"""
    out, cur = {}, None
    for line in text.splitlines():
        if line.startswith("## "):
            cur = line[3:].strip().lower()
            out[cur] = []
        elif cur and re.match(r"\s*[-*] ", line):
            out[cur].append(line.strip()[2:].strip())
    return out


def plain(s):
    """Markdown -> texto para la terminal."""
    s = re.sub(r"\[\[([^\]|]+)(\|([^\]]+))?\]\]", lambda m: m.group(3) or m.group(1), s)
    s = re.sub(r"\*\*|__|`", "", s)
    s = s.replace("[ ] ", "")
    return s if len(s) <= MAX_LEN else s[:MAX_LEN - 1].rstrip(" ,;:") + "…"


def pick(secs, *names):
    for name in names:
        for title, items in secs.items():
            if title.startswith(name):
                return items
    return []


def when(date):
    days = (dt.date.today() - date).days
    return {0: "hoy", 1: "ayer"}.get(days, f"hace {days} dias")


def main():
    notes = sorted(p for p in (VAULT / "daily").glob("*.md")
                   if re.fullmatch(r"\d{4}-\d{2}-\d{2}", p.stem))
    if not notes:
        return
    last = notes[-1]
    secs = sections(last.read_text(encoding="utf-8"))
    done = pick(secs, "qué hice", "que hice")
    nxt = pick(secs, "mañana", "manana")
    pending = pick(secs, "pendiente", "problemas")

    # Tareas abiertas de los proyectos que no esten ya en la diaria
    seen = {plain(x).lower() for x in nxt + pending}
    tasks = []
    for p in sorted((VAULT / "projects").glob("*.md")):
        for line in p.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\s*- \[ \] (.+)", line)
            if m and not any(plain(m.group(1)).lower().startswith(s[:40]) for s in seen):
                tasks.append(f"{m.group(1).strip()} ({p.stem})")

    date = dt.date.fromisoformat(last.stem)
    lines = [f"👋 ¡Hola Erick! Tu última sesión fue {when(date)} ({last.stem}):"]
    lines += [f"  • {plain(x)}" for x in done[:MAX_ITEMS]]
    if len(done) > MAX_ITEMS:
        lines.append(f"  … y {len(done) - MAX_ITEMS} cosas más (daily/{last.name})")
    todo = nxt + pending + tasks
    if todo:
        lines.append("📌 Pendiente:")
        lines += [f"  • {plain(x)}" for x in todo[:MAX_ITEMS]]
    msg = "\n".join(lines)

    context = (
        f"Memoria de la boveda de Obsidian ({VAULT}), ya sincronizada. Resumen de la ultima "
        f"actividad de Erick, de daily/{last.name}:\n{msg}\n\n"
        "Erick YA VIO este resumen en pantalla (es la bienvenida de la sesion): no lo repitas "
        "ni lo resumas, y no lo saludes con el; atiende directamente lo que pida. Usalo como "
        "contexto, y si quiere detalle, lee la nota diaria completa."
    )
    print(json.dumps({
        "systemMessage": msg,
        "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": context},
    }, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # nunca romper el arranque del agente
        print(f"vault-welcome: {e}", file=sys.stderr)
    sys.exit(0)
