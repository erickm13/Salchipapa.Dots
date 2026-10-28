"""pendientes.py — la lista de pendientes vigente de la nota diaria (la usan session-log.py y vault-welcome.py).

Cada sesion, al cerrarse, reescribe la LISTA COMPLETA de pendientes (quita lo resuelto, conserva lo
abierto, anade lo nuevo) y su bloque de "## Sesiones de hoy" termina con MARK. La lista vigente es la
del ultimo bloque marcado, mas los "Pendiente:" de bloques sin marca posteriores a el. Asi no hay que
emparejar textos para tachar: si el resumen parafrasea un pendiente, da igual.

Bloques sin marca (anteriores a este cambio): un "Resuelto: X" posterior cierra el "Pendiente: X" con el
mismo texto, y las vinetas con ";" se parten en tareas.

Un pendiente de "ingerir" se descarta solo cuando el ingest ya se hizo (sin_ingeridos): el resumen no
mira log.md, y si no, arrastra el pendiente dias despues del ingest nocturno.
"""
import re

MARK = "<!-- pendientes: lista completa -->"
NONE = "sin pendientes"
INGEST = re.compile(r"\bingerir\b", re.I)
RAW_PATH = re.compile(r"raw/[^\s`'\")\]]+\.\w+")


def norm(s):
    return " ".join(s.split()).rstrip(".")


def tasks(text):
    """Separa tareas unidas con ";" (sin partir lo que va entre `backticks`)."""
    return [t.strip() for t in re.split(r";(?=(?:[^`]*`[^`]*`)*[^`]*$)", text) if t.strip()]


def blocks(text):
    """[(vinetas, marcado)] de los bloques "### ..." de "## Sesiones de hoy"."""
    m = re.search(r"^## Sesiones de hoy\s*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    out = []
    for block in re.split(r"^### ", m.group(1) if m else "", flags=re.M)[1:]:
        bullets = [l.strip()[2:].strip() for l in block.splitlines()[1:] if l.strip().startswith("- ")]
        out.append((bullets, MARK in block))
    return out


def current(text):
    """Pendientes vigentes del dia, en orden."""
    out = []
    for bullets, marked in blocks(text):
        if marked:
            out = []
        for b in bullets:
            key, _, rest = b.partition(":")
            if key.strip().lower() == "pendiente" and rest.strip():
                out += tasks(rest)
            elif key.strip().lower() == "resuelto" and not marked:
                done = {norm(x) for x in tasks(rest)}
                out = [x for x in out if norm(x) not in done]
    seen, unique = set(), []
    for x in out:
        if norm(x).lower() not in seen:
            seen.add(norm(x).lower())
            unique.append(x)
    return unique


def is_list(bullets):
    """El resumen trae la lista completa: al menos un "Pendiente:" o la vineta "Sin pendientes"."""
    return any(b.lower().startswith("pendiente:") or norm(b).lower() == NONE for b in bullets)


def carried(text):
    """De una diaria ya cerrada: lo que paso a "Mañana" y "Pendiente" (primer dia sin sesiones)."""
    out, cur = [], None
    for line in text.splitlines():
        if line.startswith("## "):
            title = line[3:].strip().lower()
            cur = title.startswith(("mañana", "manana", "pendiente"))
        elif cur and re.match(r"\s*[-*] ", line):
            item = re.sub(r"^\s*[-*] (\[ \] )?", "", line).strip()
            if item and item != "-":
                out.append(item)
    return out


def sin_ingeridos(items, vault):
    """Quita los pendientes de "ingerir" ya hechos: si citan rutas de raw/, cuando todas estan en log.md;
    si no citan ninguna, cuando no queda ninguna fuente sin ingerir (la misma regla que vault-lint.py)."""
    if not any(INGEST.search(x) for x in items):
        return items
    log = vault / "log.md"
    log = log.read_text(encoding="utf-8") if log.exists() else ""
    raw = vault / "raw"
    left = [r for r in (p.relative_to(vault).as_posix() for p in raw.rglob("*") if p.is_file())
            if not r.endswith("/.gitkeep") and not r.startswith("raw/assets/") and r not in log] if raw.is_dir() else []
    out = []
    for x in items:
        paths = RAW_PATH.findall(x) if INGEST.search(x) else None
        if paths is None or (any(p not in log for p in paths) if paths else left):
            out.append(x)
    return out
