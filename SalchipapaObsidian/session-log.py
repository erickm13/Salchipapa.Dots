#!/usr/bin/env python3
"""session-log.py <hook.json> <agente> — resume una sesion de un agente en la nota diaria de hoy.

Lo lanza vault-session-end.sh en segundo plano al cerrar una sesion (Claude Code, Codex). Lee la
conversacion (transcript_path del JSON del hook), toma solo lo nuevo desde el ultimo resumen de esa
sesion (y como mucho lo de hoy), lo resume con `claude -p` y lo anade a daily/AAAA-MM-DD.md bajo
"## Sesiones de hoy". Asi, al abrir un agente en otro equipo, la bienvenida ya muestra lo ultimo.

Antes de resumir guarda la conversacion limpia en raw/sesiones/ (capa de fuentes crudas del LLM Wiki):
solo lo dicho por el usuario y el agente, con los secretos cambiados por [SECRETO] y los [[enlaces]]
escapados (texto, no enlaces: Obsidian no los reescribe al renombrar una nota). Ese archivo no se
vuelve a tocar; si la sesion sigue (resume), lo nuevo va a otro archivo. Asi la conversacion no se
pierde aunque el resumen falle. Lee transcripts de Claude Code, Codex, Copilot CLI y Gemini CLI.

Sesiones cortas (menos de MIN_TURNS mensajes del usuario) no se guardan ni se resumen. El resumen pasa
por el mismo filtro de secretos que la sincronizacion. Sale con 0 si no habia nada que hacer, con
LIMIT (75) si Claude esta en su limite de uso (vault-session-end.sh no gasta un reintento) y con 1 si
fallo otra cosa.
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
SEEN = STATE / "session-log.json"  # session_id -> ultimo mensaje resumido; "raw:"+id -> ultimo guardado en raw/
COPILOT = Path.home() / ".copilot/session-state"
LIMIT = 75
WIKILINK = re.compile(r"(!?)\[\[([^\[\]\n]+)\]\]")


def unlink(text):
    """[[nota]] -> \\[\\[nota\\]\\]: se lee igual en Obsidian, pero no es un enlace. Asi, al renombrar una
    nota Obsidian no reescribe raw/ (inmutable) y los enlaces de una conversacion nunca quedan rotos."""
    return WIKILINK.sub(lambda m: m.group(1) + "\\[\\[" + m.group(2) + "\\]\\]", text)
MIN_TURNS = 2
MAX_CHARS = 60_000
SECRETS = re.compile(
    r"gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{40,}|AIza[0-9A-Za-z_-]{35}|AQ\.[A-Za-z0-9_-]{30,}"
    r"|sk-[A-Za-z0-9_-]{20,}|oma_(live|test)_[A-Za-z0-9]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----")
PROMPT = """Resume esta sesión de trabajo con un agente de IA para la nota diaria del usuario, para que
al abrir un agente en otro equipo se sepa qué se hizo. Responde SOLO con viñetas en español
(entre 3 y 7), sin títulos ni introducción:
- primero lo que se hizo o se cambió (concreto: archivos, comandos, herramientas, versiones);
- luego, si las hay, viñetas "Decidido: ..." y una viñeta "Pendiente: ..." POR CADA tarea pendiente
  (nunca varias tareas en la misma viñeta ni unidas con ";").
Nunca incluyas secretos (tokens, claves, contraseñas): si aparecen, di solo que se mencionaron.
Si en la conversación no se hizo nada de sustancia, responde exactamente: NADA"""
# Lo que quedo pendiente en sesiones anteriores de hoy: si esta lo resolvio, el resumen lo dice con el
# texto exacto y la bienvenida (y la diaria de la noche) dejan de mostrarlo. Parafraseado no se tacha.
RESOLVED = """

Pendientes de sesiones anteriores de hoy (uno por línea):
{}
Si en esta conversación quedó resuelto por completo alguno (el usuario dice que ya lo hizo, o se hizo
aquí), añade una viñeta "Resuelto: " seguida del texto de ese pendiente copiado tal cual, carácter por
carácter, sin cambiarlo ni resumirlo; una viñeta por pendiente. Si solo se resolvió una parte, no lo
pongas. Lo que siga sin resolver no lo repitas como "Pendiente:" (ya consta)."""


def norm(s):
    return " ".join(s.split()).rstrip(".")


def tasks(text):
    """Una viñeta puede traer varias tareas unidas con ";" (resúmenes anteriores): se separan, sin partir
    lo que va entre `backticks`, para que cada una se pueda dar por resuelta por separado."""
    return [t.strip() for t in re.split(r";(?=(?:[^`]*`[^`]*`)*[^`]*$)", text) if t.strip()]


def open_pending(text):
    """Los "Pendiente: ..." de "## Sesiones de hoy" que ningun "Resuelto: ..." posterior cerro.
    La misma regla que vault-welcome.py."""
    m = re.search(r"^## Sesiones de hoy\s*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    out = []
    for line in (m.group(1) if m else "").splitlines():
        b = line.strip()[2:].strip() if line.strip().startswith("- ") else ""
        key, _, rest = b.partition(":")
        if key.lower() == "pendiente" and rest.strip():
            out += tasks(rest)
        elif key.lower() == "resuelto":
            done = {norm(x) for x in tasks(rest)}
            out = [x for x in out if norm(x) not in done]
    return out


def log(msg):
    STATE.mkdir(parents=True, exist_ok=True)
    with open(STATE / "session-log.log", "a") as f:
        f.write(f"{dt.datetime.now():%F %T} {msg}\n")


def clean(text):
    text = re.sub(r"<system-reminder>.*?</system-reminder>", "", text, flags=re.S)
    return text.strip()


def parts_text(content):
    """Texto de un content que puede ser str o lista de partes ({text: ...})."""
    if isinstance(content, str):
        return [content]
    return [c.get("text", "") for c in content or [] if isinstance(c, dict)
            and c.get("type", "text") in ("text", "input_text", "output_text")]


def records(path):
    """Objetos JSON del transcript: JSONL, o un solo JSON con una lista "messages"."""
    text = Path(path).read_text(encoding="utf-8", errors="replace")
    try:
        whole = json.loads(text)
        if isinstance(whole, dict) and isinstance(whole.get("messages"), list):
            return whole["messages"]
    except ValueError:
        pass
    out = []
    for line in text.splitlines():
        try:
            d = json.loads(line)
        except ValueError:
            continue
        if isinstance(d, dict):
            out.append(d)
    return out


def messages(path):
    """[(timestamp, rol, texto)] de un transcript de Claude Code, Codex, Copilot CLI o Gemini CLI."""
    out = []
    for d in records(path):
        ts = d.get("timestamp", "")
        data = d.get("data") if isinstance(d.get("data"), dict) else {}
        if d.get("type") in ("user.message", "assistant.message"):  # Copilot CLI (events.jsonl)
            role = "user" if d["type"] == "user.message" else "assistant"
            parts = parts_text(data.get("content"))
        elif d.get("type") in ("user", "gemini", "model") and "message" not in d:  # Gemini CLI
            role = "user" if d["type"] == "user" else "assistant"
            parts = parts_text(d.get("content"))
        elif d.get("type") in ("user", "assistant") and not d.get("isSidechain") and not d.get("isMeta"):
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
        # Fuera: salidas de comandos, contexto inyectado (<environment_context>, <command-...>, y las
        # instrucciones AGENTS.md que Codex mete como primer mensaje del usuario)
        if text and not text.startswith("<") and not text.startswith("# AGENTS.md instructions"):
            out.append((ts, role, text))
    return out


def transcript_of(hook, agent):
    """(ruta del transcript, session_id). Copilot no manda la ruta: se busca su events.jsonl."""
    path = hook.get("transcript_path") or hook.get("transcriptPath")
    sid = hook.get("session_id") or hook.get("sessionId") or ""
    if not path and agent == "copilot" and COPILOT.is_dir():
        if sid and (COPILOT / sid / "events.jsonl").is_file():
            path = COPILOT / sid / "events.jsonl"
        else:  # la sesion que se acaba de cerrar: el events.jsonl modificado hace menos de 10 min
            recent = [p for p in COPILOT.glob("*/events.jsonl") if dt.datetime.now().timestamp() - p.stat().st_mtime < 600]
            if recent:
                path = max(recent, key=lambda p: p.stat().st_mtime)
                sid = sid or path.parent.name
    return path, sid or "?"


def local(ts):
    try:
        return dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone()
    except (ValueError, AttributeError):
        return dt.datetime.now().astimezone()


def save_raw(msgs, agent, sid, host):
    """Guarda la conversacion en un archivo nuevo de raw/sesiones/ (inmutable: nunca reescribe uno que
    exista; si el nombre esta ocupado, anade -2, -3...). Lo ya guardado lo marca main() en SEEN."""
    start = local(msgs[0][0])
    tag = re.sub(r"[^A-Za-z0-9]", "", sid)[:8] or "sesion"
    name = f"{start:%Y-%m-%d-%H%M}-{agent}-{tag}"
    path, n = VAULT / "raw" / "sesiones" / f"{name}.md", 1
    while path.exists():
        n += 1
        path = path.with_name(f"{name}-{n}.md")
    body = [f"---\ntipo: sesion\nagente: {agent}\nequipo: {host}\nsesion: {sid}\n"
            f"inicio: {start.isoformat(timespec='minutes')}\nfin: {local(msgs[-1][0]).isoformat(timespec='minutes')}\n---\n",
            f"# Sesión de {agent} · {start:%Y-%m-%d %H:%M}\n"]
    for ts, role, text in msgs:
        body.append(f"### {'Usuario' if role == 'user' else 'Agente'} · {local(ts):%H:%M}\n{unlink(SECRETS.sub('[SECRETO]', text))}\n")
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(VAULT / ".git" / "vault-sync.lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        path.write_text("\n".join(body), encoding="utf-8")
    return path


def main():
    hook = json.loads(Path(sys.argv[1]).read_text() or "{}")
    agent = sys.argv[2] if len(sys.argv) > 2 else "agente"
    transcript, sid = transcript_of(hook, agent)
    if not transcript or not Path(transcript).is_file():
        log(f"[{agent}] sin transcript en el hook (campos: {', '.join(sorted(hook)) or 'ninguno'}): no hay resumen")
        print("sin-transcript")
        return 0
    if not (VAULT / ".git").is_dir():
        return 0

    today = dt.date.today()
    host = socket.gethostname() + (" (WSL)" if os.environ.get("WSL_DISTRO_NAME") else "")
    seen = json.loads(SEEN.read_text()) if SEEN.exists() else {}
    every = messages(transcript)

    # 1) Fuente cruda: lo nuevo desde lo ultimo guardado en raw/, de cualquier dia
    raw_since = seen.get("raw:" + sid, "")
    new = [m for m in every if not (m[0] and m[0] <= raw_since)]
    if sum(1 for m in new if m[1] == "user") >= MIN_TURNS:
        path = save_raw(new, agent, sid, host)
        log(f"[{agent}] {sid[:8]}: conversacion en {path.relative_to(VAULT)}")
        seen["raw:" + sid] = new[-1][0] or raw_since
        STATE.mkdir(parents=True, exist_ok=True)
        SEEN.write_text(json.dumps(seen, indent=1))

    # 2) Resumen para la diaria: lo nuevo desde el ultimo resumen, solo de hoy
    since = seen.get(sid, "")
    msgs = []
    for ts, role, text in every:
        if ts and ts <= since:
            continue
        if local(ts).date() == today:
            msgs.append((ts, role, text))
    if sum(1 for m in msgs if m[1] == "user") < MIN_TURNS:
        log(f"[{agent}] {sid[:8]}: sesion corta, sin resumen")
        print("corta")
        return 0

    note = VAULT / "daily" / f"{today}.md"
    pending = open_pending(note.read_text(encoding="utf-8")) if note.exists() else []
    prompt = PROMPT + (RESOLVED.format("\n".join(pending)) if pending else "")
    convo = "\n\n".join(f"{'USUARIO' if r == 'user' else 'AGENTE'}: {t}" for _, r, t in msgs)[-MAX_CHARS:]
    claude = os.environ.get("CLAUDE_BIN") or "claude"
    # Sin hooks: que este `claude -p` no sincronice, no salude ni se resuma a si mismo, ni lo guarde claude-mem
    p = subprocess.run([claude, "-p", prompt, "--model", "haiku", "--settings", '{"disableAllHooks": true}'],
                       input=convo, capture_output=True, text=True, timeout=300)
    summary = p.stdout.strip()
    if p.returncode != 0 or not summary:
        err = (p.stderr or p.stdout)[-300:]
        log(f"[{agent}] {sid[:8]}: claude rc={p.returncode}: {err}")
        # Limite de uso: se reintenta sin gastar intentos (la conversacion ya esta en raw/)
        return LIMIT if re.search(r"hit your (session|usage|weekly) limit|usage limit", err, re.I) else 1
    if summary == "NADA":
        log(f"[{agent}] {sid[:8]}: sin nada de sustancia")
        print("nada")
    elif SECRETS.search(summary):
        log(f"[{agent}] {sid[:8]}: el resumen parecia contener un secreto: no se escribe")
        return 1
    else:
        bullets = [l if l.startswith("- ") else f"- {l.lstrip('-* ')}" for l in summary.splitlines() if l.strip()]
        block = f"### {dt.datetime.now():%H:%M} · {agent} · {host}\n" + "\n".join(bullets) + "\n"
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
