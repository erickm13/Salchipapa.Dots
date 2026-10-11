#!/usr/bin/env python3
"""setup-agents.py — conecta los agentes a la boveda de Obsidian (memoria compartida).

Idempotente: se puede correr las veces que haga falta. Lo llama install.sh, o a mano para
actualizar despues de un `git pull`:
    python3 <repo>/SalchipapaObsidian/setup-agents.py   (el repo puede estar en cualquier ruta)

- Si la boveda no tiene la estructura PARA, crea las carpetas y plantillas que falten
  (vault-template/: me.md, templates/daily.md, config de notas nuevas y diarias). Nunca sobrescribe.
- Enlaza AGENTS.md como instrucciones globales de Claude Code, Codex, opencode y Copilot CLI
  (si ya hay un archivo propio, lo respalda como .bak-vault) y el plugin de opencode.
- Anade los hooks de inicio (vault-start.sh) y fin (vault-sync.sh push) de cada agente,
  quitando los de vault-* que hubiera antes y sin tocar el resto de la config.
- Instala los timers systemd de la nota diaria y la revision semanal (los servicios con la ruta
  real del repo, @DIR@) y los activa. Si la revision semanal se desactivo a mano en este equipo
  (para no tenerla en dos), la deja desactivada.

Cada paso informa: ✔ hecho, ✔ ... (ya estaba), ⚠ omitido, ✖ fallo. Sale con 1 si algo fallo.
"""
import json
import shutil
import subprocess
from pathlib import Path

HOME = Path.home()
HERE = Path(__file__).resolve().parent
VAULT = HOME / ".config/obsidian"
UNITS = HOME / ".config/systemd/user"
PARA = ["projects", "areas", "resources", "archive", "inbox", "daily", "weekly", "templates"]
START = f"bash {HERE}/vault-start.sh"
PULL = f"bash {HERE}/vault-sync.sh pull"
PUSH = f"setsid -f bash {HERE}/vault-sync.sh push {{}} >/dev/null 2>&1"

ERRORS = []


def ok(msg):
    print(f"  ✔ {msg}")


def warn(msg):
    print(f"  ⚠ {msg}")


def fail(msg):
    ERRORS.append(msg)
    print(f"  ✖ {msg}")


def short(p):
    return str(p).replace(str(HOME), "~", 1)


def link(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.is_symlink():
        if dst.resolve() == src.resolve():
            ok(f"{short(dst)} (ya estaba)")
            return
        dst.unlink()
    elif dst.exists():
        dst.rename(dst.with_name(dst.name + ".bak-vault"))
        warn(f"{short(dst)} ya existia: respaldado como {dst.name}.bak-vault")
    dst.symlink_to(src)
    if dst.resolve() != src.resolve():
        raise OSError(f"el enlace {dst} no apunta a {src}")
    ok(f"{short(dst)} -> {short(src)}")


def render_unit(src, dst):
    """Unidad systemd con @DIR@ -> ruta de SalchipapaObsidian (reemplaza un enlace antiguo)."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    text = src.read_text().replace("@DIR@", str(HERE))
    if dst.is_symlink():
        dst.unlink()
    elif dst.exists() and dst.read_text() == text:
        ok(f"{dst.name} (ya estaba)")
        return
    dst.write_text(text)
    ok(f"{dst.name} -> {short(HERE)}")


def load(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text().strip():
        try:
            return json.loads(path.read_text())
        except json.JSONDecodeError as e:
            raise ValueError(f"{short(path)} no es JSON valido (linea {e.lineno}, columna {e.colno}): "
                             "corrigelo y vuelve a ejecutar este script") from None
    return {}


def save(path, data):
    target = path.resolve()  # si es un symlink, escribe en el archivo real
    if target.exists():
        shutil.copy2(target, target.with_name(target.name + ".bak-vault"))
    target.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    json.loads(target.read_text())  # comprobar que quedo JSON valido
    ok(f"{short(path)}: inicio (sync + bienvenida) y cierre (push)")


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
    created = []
    for d in PARA:
        path = VAULT / d
        if not path.exists():
            path.mkdir(parents=True)
            (path / ".gitkeep").touch()  # git no sube carpetas vacias
            created.append(f"{d}/")
    template = HERE / "vault-template"
    for src in sorted(p for p in template.rglob("*") if p.is_file()):
        dst = VAULT / src.relative_to(template)
        if not dst.exists():
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            created.append(str(dst.relative_to(VAULT)))
    if created:
        ok("creado: " + ", ".join(created))
    else:
        ok("estructura PARA completa (ya estaba)")


def systemctl(*args):
    p = subprocess.run(["systemctl", "--user", *args], capture_output=True, text=True, timeout=30)
    return p.returncode, (p.stdout + p.stderr).strip()


def timers(weekly_was_installed):
    """daemon-reload y activar los timers. Respeta una revision semanal desactivada a mano."""
    if not shutil.which("systemctl"):
        warn("systemctl no disponible: activa los timers a mano en un sistema con systemd")
        return
    rc, out = systemctl("daemon-reload")
    if rc != 0:
        fail(f"systemctl --user daemon-reload: {out or 'sin sesion de usuario de systemd'}")
        return
    wanted = ["obsidian-daily.timer"]
    rc, _ = systemctl("is-enabled", "obsidian-weekly.timer")
    if rc == 0 or not weekly_was_installed:
        wanted.append("obsidian-weekly.timer")
    else:
        warn("obsidian-weekly.timer desactivado en este equipo: se deja asi "
             "(activar: systemctl --user enable --now obsidian-weekly.timer)")
    for timer in wanted:
        rc, out = systemctl("enable", "--now", timer)
        rc2, state = systemctl("is-active", timer)
        if rc == 0 and rc2 == 0:
            ok(f"{timer} activo")
        else:
            fail(f"{timer}: {out or state}")


def step(title, fn, *args):
    print(title)
    try:
        fn(*args)
    except Exception as e:  # cada paso informa su error y el resto sigue
        fail(f"{e.__class__.__name__}: {e}")


def main():
    if (VAULT / ".git").is_dir():
        step("Boveda (PARA):", scaffold)
    else:
        print("Boveda (PARA):")
        warn(f"no hay boveda en {short(VAULT)} (git clone <tu-repo> {short(VAULT)}): se omite")

    def instructions():
        agents = HERE / "AGENTS.md"
        for dst in [".claude/CLAUDE.md", ".codex/AGENTS.md", ".config/opencode/AGENTS.md",
                    ".copilot/copilot-instructions.md"]:
            link(agents, HOME / dst)
        link(HERE / "opencode-vault-sync.js", HOME / ".config/opencode/plugins/vault-sync.js")

    step("Instrucciones de memoria y plugin de opencode:", instructions)

    print("Hooks de sesion:")
    for fn in (claude, codex, copilot):
        try:
            fn()
        except Exception as e:
            fail(f"{fn.__name__}: {e}")

    weekly_was_installed = (UNITS / "obsidian-weekly.timer").exists()

    def units():
        for unit in ("obsidian-daily.service", "obsidian-daily.timer",
                     "obsidian-weekly.service", "obsidian-weekly.timer"):
            src, dst = HERE / "systemd" / unit, UNITS / unit
            if unit.endswith(".service"):
                render_unit(src, dst)
            else:
                link(src, dst)

    step("Nota diaria y revision semanal (systemd):", units)
    step("Timers:", timers, weekly_was_installed)

    print()
    if ERRORS:
        print(f"✖ Memoria de agentes: {len(ERRORS)} error(es):")
        for e in ERRORS:
            print(f"  - {e}")
        return 1
    print("✔ Memoria de agentes lista: los agentes sincronizan la boveda al empezar y terminar.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
