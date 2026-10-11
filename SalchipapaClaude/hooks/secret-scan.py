#!/usr/bin/env python3
"""PreToolUse (Bash): antes de `git commit` o `git push`, busca secretos en lo que se va a subir.

- git commit -> lineas añadidas en el area de preparacion (git diff --cached)
- git push   -> lineas añadidas en los commits que aun no estan en el remoto (@{u}..HEAD)

Si encuentra algo, deniega el comando y dice el archivo y el tipo de secreto (sin mostrarlo).
"""
import json
import os
import re
import shlex
import subprocess
import sys

PATTERNS = {
    "token de GitHub (ghp_/gho_/ghu_/ghs_/ghr_)": r"gh[pousr]_[A-Za-z0-9]{36,}",
    "token de GitHub (github_pat_)": r"github_pat_[A-Za-z0-9_]{40,}",
    "clave de Google (AIza)": r"AIza[0-9A-Za-z_\-]{35}",
    "clave de Google AI Studio (AQ.)": r"AQ\.[A-Za-z0-9_\-]{30,}",
    "clave de OpenAI/Anthropic/OmniRoute (sk-)": r"sk-[A-Za-z0-9_\-]{20,}",
    "clave de OmniRoute (oma_)": r"oma_(?:live|test)_[A-Za-z0-9]{16,}",
    "clave privada": r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
}


def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def git(repo, *args):
    p = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True)
    return p.returncode, p.stdout


def find_actions(cmd, cwd):
    """Devuelve [(accion, repo)] para cada `git commit`/`git push` del comando, siguiendo `cd X` y `git -C X`."""
    actions, here = [], cwd
    for part in re.split(r"\|\||&&|;|\n", cmd):
        try:
            toks = shlex.split(part, comments=True)
        except ValueError:
            toks = part.split()
        if not toks:
            continue
        if toks[0] == "cd" and len(toks) > 1:
            here = os.path.join(here, os.path.expanduser(toks[1]))
            continue
        if os.path.basename(toks[0]) != "git":
            continue
        repo, i = here, 1
        while i < len(toks) and toks[i].startswith("-"):
            if toks[i] == "-C" and i + 1 < len(toks):
                repo = os.path.join(here, os.path.expanduser(toks[i + 1]))
                i += 2
            elif toks[i] == "-c" and i + 1 < len(toks):
                i += 2
            else:
                i += 1
        if i < len(toks) and toks[i] in ("commit", "push"):
            actions.append((toks[i], repo))
    return actions


def scan(diff):
    hits, current = [], "?"
    for line in diff.splitlines():
        if line.startswith("+++ "):
            current = line[6:] if line.startswith("+++ b/") else line[4:]
        elif line.startswith("+") and not line.startswith("+++"):
            for label, rx in PATTERNS.items():
                if re.search(rx, line):
                    hits.append(f"{current}: {label}")
    return sorted(set(hits))


def main():
    data = json.load(sys.stdin)
    cmd = (data.get("tool_input") or {}).get("command") or ""
    if "git" not in cmd:
        return
    for action, repo in find_actions(cmd, data.get("cwd") or os.getcwd()):
        if action == "commit":
            # `git commit -a` también sube los cambios sin preparar: se revisan ambos
            _, staged = git(repo, "diff", "--cached")
            _, unstaged = git(repo, "diff") if re.search(r"\scommit\b.*\s-[a-zA-Z]*a", cmd) else (0, "")
            diff = staged + unstaged
        else:
            rc, diff = git(repo, "log", "-p", "@{u}..HEAD")
            if rc:  # rama sin upstream: revisar los commits que no estan en ningun remoto
                _, diff = git(repo, "log", "-p", "HEAD", "--not", "--remotes")
        hits = scan(diff)
        if hits:
            deny("Bloqueado: posible secreto en lo que se va a subir con `git " + action + "`:\n  - "
                 + "\n  - ".join(hits)
                 + "\nQuítalo (y si ya estuvo expuesto, revócalo) antes de subir. "
                 "Si es un falso positivo, revísalo y haz el commit/push tú mismo.")


if __name__ == "__main__":
    main()
