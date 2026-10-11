#!/usr/bin/env python3
"""session-log.py <hook.json> <agente> — resume una sesion de un agente en la nota diaria de hoy.

Lo lanza vault-session-end.sh en segundo plano al cerrar una sesion (Claude Code, Codex). Lee la
conversacion (transcript_path del JSON del hook), toma solo lo nuevo desde el ultimo resumen de esa
sesion (y como mucho lo de hoy), lo resume con `claude -p` y lo anade a daily/AAAA-MM-DD.md bajo
"## Sesiones de hoy". Asi, al abrir un agente en otro equipo, la bienvenida ya muestra lo ultimo.

Sesiones cortas (menos de MIN_TURNS mensajes del usuario) no se resumen. El resumen pasa por el
mismo filtro de secretos que la sincronizacion. Sale con 0 si no habia nada que hacer.
Imprime una linea con el resultado (la usa vault-session-end.sh para avisar al cerrar el agente):
"resumen daily/AAAA-MM-DD.md", "corta", "nada" o "sin-transcript".
"""
import datetime as dt
import fcntl
import json
import os
import re
import socket
import subprocess
import sys
from pathlib import Path

VAULT = Path(os.environ.get("OBSIDIAN_VAULT", Path.home() / ".config/obsidian"))
STATE = Path.home() / ".cache/salchipapa-dots"
SEEN = STATE / "session-log.json"  # session_id -> timestamp del ultimo mensaje ya resumido
MIN_TURNS = 2
MAX_CHARS = 60_000
SECRETS = re.compile(
    r"gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{40,}|AIza[0-9A-Za-z_-]{35}|AQ\.[A-Za-z0-9_-]{30,}"
    r"|sk-[A-Za-z0-9_-]{20,}|oma_(live|test)_[A-Za-z0-9]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----")
PROMPT = """Resume esta sesión de trabajo con un agente de IA para la nota diaria del usuario, para que
al abrir un agente en otro equipo se sepa qué se hizo. Responde SOLO con viñetas en español
(entre 3 y 7), sin títulos ni introducción:
- primero lo que se hizo o se cambió (concreto: archivos, comandos, herramientas, versiones);
- luego, si las hay, una viñeta "Decidido: ..." y una "Pendiente: ...".
Nunca incluyas secretos (tokens, claves, contraseñas): si aparecen, di solo que se mencionaron.
Si en la conversación no se hizo nada de sustancia, responde exactamente: NADA"""


def log(msg):
    STATE.mkdir(parents=True, exist_ok=True)
    with open(STATE / "session-log.log", "a") as f:
        f.write(f"{dt.datetime.now():%F %T} {msg}\n")


def clean(text):
    text = re.sub(r"<system-reminder>.*?</system-reminder>", "", text, flags=re.S)
    return text.strip()


def messages(path):
    """[(timestamp, rol, texto)] de un transcript de Claude Code o de Codex."""
    out = []
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        ts = d.get("timestamp", "")
        if d.get("type") in ("user", "assistant") and not d.get("isSidechain") and not d.get("isMeta"):
            content = (d.get("message") or {}).get("content")
            parts = [content] if isinstance(content, str) else [
                c.get("text", "") for c in content or [] if isinstance(c, dict) and c.get("type") == "text"]
            role = d["type"]
        elif d.get("type") == "response_item" and (d.get("payload") or {}).get("type") == "message":
            p = d["payload"]
            role = p.get("role")
            if role not in ("user", "assistant"):
                continue
            parts = [c.get("text", "") for c in p.get("content") or []
                     if c.get("type") in ("input_text", "output_text")]
        else:
            continue
        text = clean("\n".join(parts))
        # Fuera: salidas de comandos, contexto inyectado (<environment_context>, <command-...>)
        if text and not text.startswith("<"):
            out.append((ts, role, text))
    return out


def main():
    hook = json.loads(Path(sys.argv[1]).read_text() or "{}")
    agent = sys.argv[2] if len(sys.argv) > 2 else "agente"
    transcript, sid = hook.get("transcript_path"), hook.get("session_id") or "?"
    if not transcript or not Path(transcript).is_file():
        log(f"[{agent}] sin transcript en el hook: no hay resumen")
        print("sin-transcript")
        return 0
    if not (VAULT / ".git").is_dir():
        return 0

    today = dt.date.today()
    seen = json.loads(SEEN.read_text()) if SEEN.exists() else {}
    since = seen.get(sid, "")
    msgs = []
    for ts, role, text in messages(transcript):
        if ts and ts <= since:
            continue
        try:
            local_day = dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone().date()
        except ValueError:
            local_day = today
        if local_day == today:
            msgs.append((ts, role, text))
    if sum(1 for m in msgs if m[1] == "user") < MIN_TURNS:
        log(f"[{agent}] {sid[:8]}: sesion corta, sin resumen")
        print("corta")
        return 0

    convo = "\n\n".join(f"{'USUARIO' if r == 'user' else 'AGENTE'}: {t}" for _, r, t in msgs)[-MAX_CHARS:]
    claude = os.environ.get("CLAUDE_BIN") or "claude"
    # Sin hooks: que este `claude -p` no sincronice, no salude ni se resuma a si mismo, ni lo guarde claude-mem
    p = subprocess.run([claude, "-p", PROMPT, "--model", "haiku", "--settings", '{"disableAllHooks": true}'],
                       input=convo, capture_output=True, text=True, timeout=300)
    summary = p.stdout.strip()
    if p.returncode != 0 or not summary:
        log(f"[{agent}] {sid[:8]}: claude rc={p.returncode}: {(p.stderr or p.stdout)[-300:]}")
        return 1
    if summary == "NADA":
        log(f"[{agent}] {sid[:8]}: sin nada de sustancia")
        print("nada")
    elif SECRETS.search(summary):
        log(f"[{agent}] {sid[:8]}: el resumen parecia contener un secreto: no se escribe")
        return 1
    else:
        bullets = [l if l.startswith("- ") else f"- {l.lstrip('-* ')}" for l in summary.splitlines() if l.strip()]
        host = socket.gethostname() + (" (WSL)" if os.environ.get("WSL_DISTRO_NAME") else "")
        block = f"### {dt.datetime.now():%H:%M} · {agent} · {host}\n" + "\n".join(bullets) + "\n"
        note = VAULT / "daily" / f"{today}.md"
        note.parent.mkdir(exist_ok=True)
        # El mismo lock que vault-sync.sh: no escribir mientras se hace pull o push
        with open(VAULT / ".git" / "vault-sync.lock", "w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            text = note.read_text(encoding="utf-8") if note.exists() else f"# {today}\n"
            if "## Sesiones de hoy" not in text:
                text = text.rstrip("\n") + "\n\n## Sesiones de hoy\n"
            note.write_text(text.rstrip("\n") + "\n\n" + block, encoding="utf-8")
        log(f"[{agent}] {sid[:8]}: {len(bullets)} viñetas en daily/{today}.md")
        print(f"resumen daily/{today}.md")

    seen[sid] = msgs[-1][0] or seen.get(sid, "")
    STATE.mkdir(parents=True, exist_ok=True)
    SEEN.write_text(json.dumps(seen, indent=1))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:  # en segundo plano: que quede en el log
        log(f"error: {e.__class__.__name__}: {e}")
        sys.exit(1)
