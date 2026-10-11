#!/usr/bin/env python3
"""setup-agents.py — conecta los agentes a la boveda de Obsidian (memoria compartida).

Idempotente: se puede correr las veces que haga falta. Lo llama install.sh, o a mano:
    python3 ~/Salchipapa.Dots/SalchipapaObsidian/setup-agents.py

- Enlaza AGENTS.md como instrucciones globales de Claude Code, Codex, opencode y Copilot CLI
  (si ya hay un archivo propio, lo respalda como .bak-vault).
- Anade los hooks de inicio (vault-start.sh) y fin (vault-sync.sh push) de cada agente,
  quitando los de vault-* que hubiera antes y sin tocar el resto de la config.
- Si la boveda no tiene la estructura PARA, crea las carpetas y plantillas que falten
  (vault-template/: me.md, templates/daily.md, config de notas nuevas y diarias). Nunca sobrescribe.
- Enlaza el plugin de opencode y las unidades systemd de la nota diaria y la revision semanal.
"""
import json
import shutil
from pathlib import Path

HOME = Path.home()
HERE = Path(__file__).resolve().parent
VAULT = HOME / ".config/obsidian"
PARA = ["projects", "areas", "resources", "archive", "inbox", "daily", "weekly", "templates"]
START = f"bash {HERE}/vault-start.sh"
PULL = f"bash {HERE}/vault-sync.sh pull"
PUSH = f"setsid -f bash {HERE}/vault-sync.sh push {{}} >/dev/null 2>&1"


def link(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.is_symlink():
        if dst.resolve() == src.resolve():
            return
        dst.unlink()
    elif dst.exists():
        dst.rename(dst.with_name(dst.name + ".bak-vault"))
        print(f"  respaldo: {dst}.bak-vault")
    dst.symlink_to(src)
    print(f"  enlace: {dst} -> {src}")


def load(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text().strip():
        return json.loads(path.read_text())
    return {}


def save(path, data):
    target = path.resolve()  # si es un symlink, escribe en el archivo real
    if target.exists():
        shutil.copy2(target, target.with_name(target.name + ".bak-vault"))
    target.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    print(f"  hooks: {path}")


def drop_vault(entries, key):
    """Quita los hooks vault-* anteriores (en grupos {hooks: [...]} o planos)."""
    out = []
    for e in entries or []:
        if "hooks" in e:
            e["hooks"] = [h for h in e["hooks"] if "SalchipapaObsidian/vault-" not in h.get(key, "")]
            if e["hooks"]:
                out.append(e)
        elif "SalchipapaObsidian/vault-" not in e.get(key, ""):
            out.append(e)
    return out


def claude():
    p = HOME / ".claude/settings.json"
    s = load(p)
    hooks = s.setdefault("hooks", {})
    ss = hooks["SessionStart"] = drop_vault(hooks.get("SessionStart"), "command")
    ss.append({"matcher": "^startup$", "hooks": [{"type": "command", "command": f"{START} claude",
               "timeout": 45, "statusMessage": "Sincronizando Obsidian..."}]})
    ss.append({"matcher": "^resume$", "hooks": [{"type": "command", "command": f"{PULL} claude",
               "timeout": 30, "statusMessage": "Sincronizando Obsidian..."}]})
    se = hooks["SessionEnd"] = drop_vault(hooks.get("SessionEnd"), "command")
    se.append({"hooks": [{"type": "command", "command": PUSH.format("claude"), "timeout": 10}]})
    save(p, s)


def codex():
    p = HOME / ".codex/hooks.json"
    s = load(p)
    hooks = s.setdefault("hooks", {})
    ss = hooks["SessionStart"] = drop_vault(hooks.get("SessionStart"), "command")
    ss.append({"hooks": [{"type": "command", "command": f"{START} codex", "timeout": 45}]})
    se = hooks["SessionEnd"] = drop_vault(hooks.get("SessionEnd"), "command")
    se.append({"hooks": [{"type": "command", "command": PUSH.format("codex"), "timeout": 10}]})
    save(p, s)


def copilot():
    p = HOME / ".copilot/settings.json"
    s = load(p)
    hooks = s.setdefault("hooks", {})
    ss = hooks["SessionStart"] = drop_vault(hooks.get("SessionStart"), "bash")
    ss.append({"type": "command", "bash": f"{START} copilot", "timeoutSec": 45})
    se = hooks["SessionEnd"] = drop_vault(hooks.get("SessionEnd"), "bash")
    se.append({"type": "command", "bash": PUSH.format("copilot"), "timeoutSec": 10})
    save(p, s)


def scaffold():
    """Estructura PARA y plantillas en la boveda: solo lo que falte."""
    if not (VAULT / ".git").is_dir():
        print(f"  sin boveda en {VAULT}: se omite")
        return
    for d in PARA:
        path = VAULT / d
        if not path.exists():
            path.mkdir(parents=True)
            (path / ".gitkeep").touch()  # git no sube carpetas vacias
            print(f"  carpeta: {d}/")
    template = HERE / "vault-template"
    for src in sorted(p for p in template.rglob("*") if p.is_file()):
        dst = VAULT / src.relative_to(template)
        if not dst.exists():
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            print(f"  plantilla: {dst.relative_to(VAULT)}")


def main():
    print("Boveda (PARA):")
    scaffold()

    agents = HERE / "AGENTS.md"
    print("Instrucciones de memoria:")
    for dst in [".claude/CLAUDE.md", ".codex/AGENTS.md", ".config/opencode/AGENTS.md",
                ".copilot/copilot-instructions.md"]:
        link(agents, HOME / dst)
    link(HERE / "opencode-vault-sync.js", HOME / ".config/opencode/plugins/vault-sync.js")

    print("Hooks de sesion:")
    for fn in (claude, codex, copilot):
        try:
            fn()
        except (OSError, ValueError) as e:
            print(f"  ! {fn.__name__}: {e} (se omite)")

    print("Nota diaria y revision semanal (systemd):")
    for unit in ("obsidian-daily.service", "obsidian-daily.timer",
                 "obsidian-weekly.service", "obsidian-weekly.timer"):
        link(HERE / "systemd" / unit, HOME / ".config/systemd/user" / unit)


if __name__ == "__main__":
    main()
