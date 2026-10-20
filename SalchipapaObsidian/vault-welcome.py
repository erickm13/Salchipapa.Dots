#!/usr/bin/env python3
"""vault-welcome.py — bienvenida al empezar una sesion de un agente, leida de la boveda.

Toma la diaria mas reciente (Que hice hoy, Manana, Pendiente) y las tareas abiertas `- [ ]`
de projects/. Si la de hoy aun no esta consolidada pero tiene "## Sesiones de hoy" (los resumenes que
escribe vault-session-end.sh al cerrar cada sesion, en cualquier equipo), muestra esas sesiones. Antes avisa de fallos de sincronizacion o de los trabajos nocturnos (vault-errors/) y
de propuestas sin aplicar de la ultima revision semanal (weekly/). Imprime JSON de hook: `systemMessage` (lo ve el usuario) y `additionalContext`
(lo recibe el agente para saludar y retomar). Sin boveda o sin notas, no imprime nada.
"""
import datetime as dt
import json
import os
import re
import subprocess
import sys
from pathlib import Path

VAULT = Path(os.environ.get("OBSIDIAN_VAULT", Path.home() / ".config/obsidian"))
HERE = Path(__file__).resolve().parent
ERRORS = Path.home() / ".cache/salchipapa-dots/vault-errors"
MAX_ITEMS = 4
MAX_LEN = 90


def owner():
    """Nombre de pila del usuario: OBSIDIAN_OWNER, o el de `git config user.name`."""
    name = os.environ.get("OBSIDIAN_OWNER", "")
    if not name:
        try:
            name = subprocess.run(["git", "config", "--global", "user.name"],
                                  capture_output=True, text=True, timeout=5).stdout
        except (OSError, subprocess.SubprocessError):
            name = ""
    return name.split()[0] if name.split() else ""


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


def sessions(text):
    """[(titulo "HH:MM · agente · equipo", [viñetas])] de la seccion "## Sesiones de hoy"."""
    m = re.search(r"^## Sesiones de hoy\s*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    if not m:
        return []
    out = []
    for block in re.split(r"^### ", m.group(1), flags=re.M)[1:]:
        lines = block.strip().splitlines()
        out.append((lines[0].strip(), [l.strip()[2:] for l in lines[1:] if l.strip().startswith("- ")]))
    return out


def norm(s):
    return " ".join(s.split()).rstrip(".")


def tasks(text):
    """Una viñeta puede traer varias tareas unidas con ";" (resúmenes anteriores): se separan, sin partir
    lo que va entre `backticks`, para que cada una se pueda dar por resuelta por separado."""
    return [t.strip() for t in re.split(r";(?=(?:[^`]*`[^`]*`)*[^`]*$)", text) if t.strip()]


def open_pending(sess):
    """Los "Pendiente: ..." de las sesiones que ningun "Resuelto: ..." posterior cerro (texto exacto,
    sin contar espacios ni el punto final: si el resumen lo parafrasea, no se tacha)."""
    out = []
    for _, bullets in sess:
        for b in bullets:
            key, _, rest = b.partition(":")
            if key.lower() == "pendiente" and rest.strip():
                out += tasks(rest)
            elif key.lower() == "resuelto":
                done = {norm(x) for x in tasks(rest)}
                out = [x for x in out if norm(x) not in done]
    return out


def pick(secs, *names):
    for name in names:
        for title, items in secs.items():
            if title.startswith(name):
                return items
    return []


def when(date):
    days = (dt.date.today() - date).days
    return {0: "hoy", 1: "ayer"}.get(days, f"hace {days} días")


def warnings():
    """Avisos de vault-errors/ (sincronizacion, diaria, semanal)."""
    if not ERRORS.is_dir():
        return []
    return [f"⚠ {f.read_text(encoding='utf-8').strip()}" for f in sorted(ERRORS.iterdir()) if f.is_file()]


def weekly():
    """Linea de aviso si la ultima revision semanal tiene propuestas `- [ ]` sin aplicar."""
    notes = sorted((VAULT / "weekly").glob("*-W*.md"))
    if not notes:
        return None
    text = notes[-1].read_text(encoding="utf-8")
    m = re.search(r"^## Propuestas\s*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    n = len(re.findall(r"^\s*- \[ \]", m.group(1), re.M)) if m else 0
    if not n:
        return None
    return (f"📋 Revisión semanal {notes[-1].stem}: {n} propuesta{'s' if n > 1 else ''} para ordenar "
            f"la bóveda. Dile a un agente \"aplica la revisión semanal\".")


def wiki():
    """Lineas del verificador (vault-lint.py): graves (⚠), fuentes de raw/ atascadas (📥) y avisos (🧹)."""
    try:
        p = subprocess.run([sys.executable, str(HERE / "vault-lint.py"), "--json"], capture_output=True,
                           text=True, timeout=15, env={**os.environ, "OBSIDIAN_VAULT": str(VAULT)})
        r = json.loads(p.stdout)
    except (OSError, subprocess.SubprocessError, ValueError):
        return [], []
    lint = f"python3 {HERE / 'vault-lint.py'}"
    top = [f"⚠ La bóveda tiene {len(r['graves'])} problema(s) grave(s): {r['graves'][0]} (detalle: {lint})"] if r["graves"] else []
    bottom = []
    # "atrasadas" lo calcula vault-lint.py (mas de un dia sin ingerir, en la zona del usuario)
    stuck = r.get("atrasadas", [])
    if stuck:
        bottom.append(f"📥 {len(stuck)} fuente(s) de raw/ sin ingerir desde hace más de un día: revisa el "
                      "ingest nocturno (GitHub Actions u OpenClaw)")
    if r["avisos"]:
        bottom.append(f"🧹 {len(r['avisos'])} aviso(s) del verificador de la bóveda (van a la revisión semanal; "
                      f"detalle: {lint})")
    return top, bottom


def main():
    notes = sorted(p for p in (VAULT / "daily").glob("*.md")
                   if re.fullmatch(r"\d{4}-\d{2}-\d{2}", p.stem))
    top, bottom = wiki()
    alerts = warnings() + top
    review = weekly()
    if not notes and not alerts and not review and not bottom:
        return
    if not notes:
        emit("\n".join(alerts + ([review] if review else []) + bottom), "")
        return
    last = notes[-1]
    text = last.read_text(encoding="utf-8")
    secs = sections(text)
    done = pick(secs, "qué hice", "que hice")
    nxt = pick(secs, "mañana", "manana")
    pending = pick(secs, "pendiente", "problemas")
    sess = sessions(text)
    # Lo pendiente de las sesiones de hoy (la mas reciente primero) va antes que el resto, sin lo que
    # una sesion posterior dio por resuelto con el mismo texto ("Resuelto: <pendiente>", session-log.py)
    pending = list(reversed(open_pending(sess))) + pending

    # Tareas abiertas de los proyectos que no esten ya en la diaria
    seen = {plain(x).lower() for x in nxt + pending}
    tasks = []
    for p in sorted((VAULT / "projects").glob("*.md")):
        for line in p.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\s*- \[ \] (.+)", line)
            if m and not any(plain(m.group(1)).lower().startswith(s[:40]) for s in seen):
                tasks.append(f"{m.group(1).strip()} ({p.stem})")

    date = dt.date.fromisoformat(last.stem)
    name = owner()
    hello = f"¡Hola {name}!" if name else "¡Hola!"
    if sess and not done:
        # Dia en curso: las ultimas sesiones (de cualquier equipo)
        lines = alerts + [f"👋 {hello} Hoy llevas {len(sess)} {'sesiones' if len(sess) > 1 else 'sesión'}; lo último:"]
        for title, bullets in sess[-2:]:
            lines.append(f"  ▸ {title}")
            lines += [f"    • {plain(b)}" for b in bullets
                      if not b.lower().startswith(("pendiente:", "decidido:", "resuelto:"))][:3]
        if len(sess) > 2:
            lines.append(f"  … y {len(sess) - 2} {'sesiones' if len(sess) > 3 else 'sesión'} antes (daily/{last.name})")
    else:
        lines = alerts + [f"👋 {hello} Tu última nota diaria es de {when(date)} ({last.stem}):"]
        lines += [f"  • {plain(x)}" for x in done[:MAX_ITEMS]]
        if len(done) > MAX_ITEMS:
            lines.append(f"  … y {len(done) - MAX_ITEMS} cosas más (daily/{last.name})")
    todo = nxt + pending + tasks
    if todo:
        lines.append("📌 Pendiente:")
        lines += [f"  • {plain(x)}" for x in todo[:MAX_ITEMS]]
    if review:
        lines.append(review)
    lines += bottom
    emit("\n".join(lines), last.name)


def emit(msg, daily):
    context = (
        f"Memoria de la boveda de Obsidian ({VAULT}), ya sincronizada. Resumen de la ultima "
        f"actividad del usuario{f', de daily/{daily}' if daily else ''}:\n{msg}\n\n"
        "El usuario YA VIO este resumen en pantalla (es la bienvenida de la sesion): no lo repitas "
        "ni lo resumas, y no lo saludes con el; atiende directamente lo que pida. Usalo como "
        "contexto, y si quiere detalle, lee la nota diaria completa. Antes de escribir en la "
        f"boveda, lee su schema: {VAULT}/AGENTS.md. Si hay avisos ⚠, ofrece "
        "ayudar a resolverlos (detalle en ~/.cache/salchipapa-dots/*.log)."
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
