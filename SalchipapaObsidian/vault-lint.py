#!/usr/bin/env python3
"""vault-lint.py — verificador de la boveda (LLM Wiki + PARA), sin LLM.

    vault-lint.py                 informe en texto; sale con 1 si hay hallazgos graves
    vault-lint.py --json          informe en JSON (lo usan la revision semanal y la bienvenida)
    vault-lint.py --index         ademas regenera index.md (solo lo escribe si cambia)
    vault-lint.py --since <rev>   ademas comprueba que raw/ no se modifico desde <rev> (CI)
    vault-lint.py --count         una linea: "<graves> <avisos> <fuentes sin ingerir>"

Solo encuentra problemas; no corrige nada (eso lo hace el LLM en el ingest o la revision semanal).
Graves (fallan): frontmatter roto, posibles secretos, archivos de raw/ modificados o borrados.
Avisos: frontmatter incompleto, enlaces rotos, paginas que su hub no enlaza, proyectos que no
enlaza me.md, proyectos largos o sin Estado, proyectos terminados, hubs vacios, archivos fuera de PARA.
Info: fuentes de raw/ sin ingerir (su ruta no aparece en log.md) y notas en inbox/.

index.md se arma con el `resumen` del frontmatter de cada pagina (lo escribe el LLM); este script
solo lo junta y lo ordena por PARA.
"""
import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

VAULT = Path(os.environ.get("OBSIDIAN_VAULT", Path.home() / ".config/obsidian"))
WIKI = ["projects", "areas", "resources", "archive"]
ROOT_OK = {"projects", "areas", "resources", "archive", "inbox", "daily", "weekly", "templates", "raw",
           "me.md", "index.md", "log.md", "AGENTS.md", "CLAUDE.md", "GEMINI.md", "README.md"}
TIPOS = {"proyecto", "area", "hub", "recurso", "concepto", "entidad", "fuente"}
REQUIRED = ["id", "tipo", "resumen", "actualizado"]
MAX_PROJECT_LINES = 200
SECRETS = re.compile(
    r"gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{40,}|AIza[0-9A-Za-z_-]{35}|AQ\.[A-Za-z0-9_-]{30,}"
    r"|sk-[A-Za-z0-9_-]{20,}|oma_(live|test)_[A-Za-z0-9]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----")
LINK = re.compile(r"!?\[\[([^\]]+)\]\]")
INDEX_HEADER = "<!-- Generado por vault-lint.py desde el `resumen` de cada página: no lo edites a mano. -->"


def frontmatter(text):
    """(dict, ok). Subconjunto de YAML: `k: v`, `k: [a, b]` y listas con `  - x`."""
    if not text.startswith("---\n"):
        return None, True
    end = text.find("\n---", 4)
    if end < 0:
        return {}, False
    data, key = {}, None
    for line in text[4:end].splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = re.match(r"^\s+-\s*(.*)$", line)
        if m and key:
            if not isinstance(data.get(key), list):
                data[key] = []
            data[key].append(m.group(1).strip().strip("\"'"))
            continue
        m = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if not m:
            return data, False
        key, value = m.group(1), m.group(2).strip()
        if value.startswith("[") and value.endswith("]"):
            data[key] = [v.strip().strip("\"'") for v in value[1:-1].split(",") if v.strip()]
        else:
            data[key] = value.strip("\"'")
    return data, True


def body(text):
    if text.startswith("---\n"):
        end = text.find("\n---", 4)
        if end >= 0:
            return text[end + 4:]
    return text


def without_code(text):
    text = re.sub(r"^\s*```.*?^\s*```", "", text, flags=re.M | re.S)
    return re.sub(r"`[^`\n]*`", "", text)


def links(text):
    out = []
    for raw in LINK.findall(without_code(body(text))):
        target = raw.split("|", 1)[0].split("#", 1)[0].split("^", 1)[0].strip()
        if target:
            out.append(target)
    return out


class Vault:
    def __init__(self, root):
        self.root = root
        self.files = [p for p in root.rglob("*") if p.is_file() and ".git" not in p.parts
                      and ".obsidian" not in p.parts and ".trash" not in p.parts]
        self.notes = {p: p.read_text(encoding="utf-8", errors="replace") for p in self.files if p.suffix == ".md"}
        self.meta = {p: frontmatter(t) for p, t in self.notes.items()}
        self.names = {}
        for p in self.files:
            self.names.setdefault(p.stem.lower(), p)
            self.names.setdefault(p.name.lower(), p)
        for p, (fm, _) in self.meta.items():
            for alias in (fm or {}).get("aliases") or []:
                if isinstance(alias, str) and alias:
                    self.names.setdefault(alias.lower(), p)

    def rel(self, p):
        return str(p.relative_to(self.root))

    def resolve(self, target):
        t = target.lower().removesuffix(".md")
        if "/" in t:
            for p in self.files:
                r = self.rel(p).lower()
                if r == t or r.removesuffix(".md") == t or r.endswith("/" + t) or r.removesuffix(".md").endswith("/" + t):
                    return p
            t = t.rsplit("/", 1)[1]
        return self.names.get(t) or self.names.get(t + ".md")

    def wiki_pages(self):
        return sorted(p for p in self.notes if p.parts[len(self.root.parts)] in WIKI)


def is_hub(p):
    return p.stem.endswith("-hub") or p.stem == "hub"


def lint(v, since=None):
    graves, avisos, info = [], [], []
    inbound = {}
    for p, text in v.notes.items():
        for target in links(text):
            hit = v.resolve(target)
            if hit:
                inbound.setdefault(hit, set()).add(p)
            # raw/, daily/ y weekly/ son registros historicos: sus enlaces pueden romperse y no se corrigen
            elif not v.rel(p).startswith(("raw/", "daily/", "weekly/", "templates/")) and v.rel(p) != "index.md":
                avisos.append(f"{v.rel(p)}: enlace roto [[{target}]]")
        if SECRETS.search(text):
            graves.append(f"{v.rel(p)}: parece contener un secreto")

    for p in v.wiki_pages():
        rel = v.rel(p)
        fm, ok = v.meta[p]
        if not ok:
            graves.append(f"{rel}: frontmatter mal formado")
            continue
        missing = [k for k in REQUIRED if not (fm or {}).get(k)]
        if missing:
            avisos.append(f"{rel}: falta en el frontmatter: {', '.join(missing)}")
        tipo = (fm or {}).get("tipo")
        if tipo and tipo not in TIPOS:
            avisos.append(f"{rel}: tipo '{tipo}' no existe (usa: {', '.join(sorted(TIPOS))})")
        top = p.parts[len(v.root.parts)]
        if top in ("areas", "resources") and not is_hub(p):
            hubs = [h for h in p.parent.glob("*.md") if is_hub(h)]
            if hubs and not any(h in inbound.get(p, ()) for h in hubs):
                avisos.append(f"{rel}: su hub ({hubs[0].name}) no la enlaza")
            if not hubs:
                avisos.append(f"{rel}: su carpeta no tiene hub")
        if top in ("areas", "resources") and is_hub(p):
            # Un hub corto sin paginas al lado es una carpeta vacia; uno largo es contenido en si
            filled = sum(1 for line in body(v.notes[p]).splitlines() if line.strip())
            if not any(q != p and q.parent == p.parent for q in v.notes) and filled < 20:
                avisos.append(f"{rel}: hub vacío (su carpeta no tiene páginas)")
        if top == "projects":
            text = v.notes[p]
            if (v.root / "me.md") in v.notes and (v.root / "me.md") not in inbound.get(p, ()):
                avisos.append(f"{rel}: me.md no enlaza este proyecto")
            lines = text.count("\n") + 1
            if lines > MAX_PROJECT_LINES:
                avisos.append(f"{rel}: {lines} líneas; la referencia va a resources/ (solo objetivo, decisiones, entregables y Estado)")
            estado = re.search(r"^## Estado\b[^\n]*$(.*?)(?=^## |\Z)", text, re.M | re.S)
            if not estado:
                avisos.append(f"{rel}: no tiene ## Estado")
            else:
                done = len(re.findall(r"^\s*- \[x\]", estado.group(1), re.M | re.I))
                todo = len(re.findall(r"^\s*- \[ \]", estado.group(1), re.M))
                if done and not todo:
                    avisos.append(f"{rel}: todo el Estado en [x]: ¿archivarlo?")

    for p in v.root.iterdir():
        if p.name not in ROOT_OK and not p.name.startswith("."):
            avisos.append(f"{p.name}: fuera de PARA (no es una carpeta ni un archivo de la bóveda)")

    log = v.notes.get(v.root / "log.md", "")
    pending = [v.rel(p) for p in v.files if v.rel(p).startswith("raw/") and p.name != ".gitkeep"
               and not v.rel(p).startswith("raw/assets/") and v.rel(p) not in log]
    if pending:
        info.append(f"{len(pending)} fuente(s) de raw/ sin ingerir")
    inbox = [v.rel(p) for p in v.notes if v.rel(p).startswith("inbox/")]
    if inbox:
        info.append(f"{len(inbox)} nota(s) en inbox/ por clasificar")

    if since:
        out = subprocess.run(["git", "-C", str(v.root), "diff", "--name-status", "--diff-filter=MDR", since, "--", "raw/"],
                             capture_output=True, text=True)
        for line in out.stdout.splitlines():
            if not line.endswith(".gitkeep"):
                graves.append(f"raw/ es inmutable y cambió: {line.replace(chr(9), ' ')}")
    return {"graves": graves, "avisos": sorted(set(avisos)), "info": info, "pendientes": sorted(pending)}


def summary_of(v, p):
    fm = v.meta[p][0] or {}
    if fm.get("resumen"):
        return fm["resumen"]
    for line in body(v.notes[p]).splitlines():
        line = line.strip()
        if line and not line.startswith(("#", "-", "|", ">", "```", "<")):
            return "(sin resumen) " + line[:100]
    return "(sin resumen)"


def build_index(v, result):
    titles = {"projects": "Proyectos", "areas": "Áreas", "resources": "Recursos", "archive": "Archivo"}
    out = ["# Índice de la wiki", "", INDEX_HEADER, "",
           "Una línea por página, desde su `resumen`. Para buscar algo, empieza aquí y abre la página.", ""]
    pages = v.wiki_pages()
    for top in WIKI:
        group = [p for p in pages if p.parts[len(v.root.parts)] == top]
        if not group:
            continue
        out += [f"## {titles[top]}", ""]
        folders = sorted({p.parent for p in group})
        for folder in folders:
            members = sorted((p for p in group if p.parent == folder), key=lambda p: (not is_hub(p), p.stem.lower()))
            if folder != v.root / top:
                out.append(f"### {folder.name}")
            for p in members:
                out.append(f"- [[{p.stem}]] — {summary_of(v, p)}")
            out.append("")
    out += ["## Estado", "",
            f"- Páginas: {len(pages)}",
            f"- Fuentes de raw/ sin ingerir: {len(result['pendientes'])}",
            f"- Avisos del linter: {len(result['avisos'])}", ""]
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--index", action="store_true")
    ap.add_argument("--count", action="store_true")
    ap.add_argument("--since")
    a = ap.parse_args()
    if not VAULT.is_dir():
        print(f"no hay bóveda en {VAULT}", file=sys.stderr)
        return 0
    v = Vault(VAULT)
    result = lint(v, a.since)
    if a.index:
        text = build_index(v, result)
        index = VAULT / "index.md"
        old = index.read_text(encoding="utf-8") if index.exists() else ""
        if old != text:
            index.write_text(text, encoding="utf-8")
    if a.count:
        print(len(result["graves"]), len(result["avisos"]), len(result["pendientes"]))
    elif a.json:
        print(json.dumps(result, ensure_ascii=False, indent=1))
    else:
        for title, key, mark in (("Graves", "graves", "✖"), ("Avisos", "avisos", "⚠"), ("Info", "info", "·")):
            if result[key]:
                print(f"{title} ({len(result[key])}):")
                for item in result[key]:
                    print(f"  {mark} {item}")
        if not result["graves"] and not result["avisos"]:
            print("✔ bóveda sin problemas")
    return 1 if result["graves"] else 0


if __name__ == "__main__":
    sys.exit(main())
