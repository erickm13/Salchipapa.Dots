#!/usr/bin/env bash
# tests/obsidian.sh — pruebas de la memoria de agentes (SalchipapaObsidian) en un HOME temporal:
# no toca tu boveda, tus agentes ni tus timers. Lo corre el CI y se puede correr a mano:
#   bash tests/obsidian.sh
set -uo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
OBS="$REPO/SalchipapaObsidian"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
export HOME="$T/home" OBSIDIAN_VAULT="$T/home/.config/obsidian" SALCHIPAPA_NO_TIMERS=1
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com
mkdir -p "$HOME"
fails=0
pass() { printf '  ✔ %s\n' "$1"; }
fail() { printf '  ✖ %s\n' "$1"; fails=$((fails + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }
SYNC_LOG="$HOME/.cache/salchipapa-dots/vault-sync.log"

# Boveda de prueba: un repo "remoto" (bare) y su clon en ~/.config/obsidian
git init -q --bare -b main "$T/remote.git"
git clone -q "$T/remote.git" "$OBSIDIAN_VAULT" 2>/dev/null
git -C "$OBSIDIAN_VAULT" checkout -q -b main
echo "# yo" >"$OBSIDIAN_VAULT/me.md"
git -C "$OBSIDIAN_VAULT" add -A && git -C "$OBSIDIAN_VAULT" commit -qm init && git -C "$OBSIDIAN_VAULT" push -q -u origin main 2>/dev/null

echo "setup-agents.py:"
out="$(python3 "$OBS/setup-agents.py" 2>&1)"
rc=$?
check "termina bien (rc=0)" '[ "$rc" -eq 0 ]'
check "informa 'Memoria de agentes lista'" 'grep -q "Memoria de agentes lista" <<<"$out"'
check "crea la estructura PARA" '[ -d "$OBSIDIAN_VAULT/projects" ] && [ -d "$OBSIDIAN_VAULT/inbox" ] && [ -f "$OBSIDIAN_VAULT/templates/daily.md" ]'
check "no sobrescribe me.md" 'grep -qx "# yo" "$OBSIDIAN_VAULT/me.md"'
check "AGENTS.md como CLAUDE.md" '[ "$(readlink "$HOME/.claude/CLAUDE.md")" = "$OBS/AGENTS.md" ]'
check "hooks de Claude: inicio y cierre" 'grep -q "vault-start.sh claude" "$HOME/.claude/settings.json" && grep -q "vault-session-end.sh claude" "$HOME/.claude/settings.json"'
check "servicio systemd con la ruta real" 'grep -q "ExecStart=/usr/bin/bash $OBS/daily-note.sh" "$HOME/.config/systemd/user/obsidian-daily.service"'
python3 "$OBS/setup-agents.py" >/dev/null 2>&1
check "idempotente: un solo hook de inicio" '[ "$(grep -c "vault-start.sh claude" "$HOME/.claude/settings.json")" -eq 1 ]'
echo '{ roto' >"$HOME/.codex/hooks.json"
out="$(python3 "$OBS/setup-agents.py" 2>&1)"
rc=$?
check "JSON roto: sale con 1 y lo explica" '[ "$rc" -eq 1 ] && grep -q "no es JSON valido" <<<"$out"'
echo '{}' >"$HOME/.codex/hooks.json"
python3 "$OBS/setup-agents.py" >/dev/null 2>&1

echo "vault-sync.sh:"
echo "nota nueva" >"$OBSIDIAN_VAULT/inbox/a.md"
bash "$OBS/vault-sync.sh" push test
check "push sube los cambios" '[ "$(git -C "$T/remote.git" log -1 --format=%s main)" = "auto (test): $(date "+%F %H:%M")" ] || git -C "$T/remote.git" log -1 --format=%s main | grep -q "^auto (test)"'
echo "token ghp_$(printf 'A%.0s' {1..36})" >"$OBSIDIAN_VAULT/inbox/b.md"
bash "$OBS/vault-sync.sh" push test
check "se niega a subir un secreto y deja aviso" '[ -f "$HOME/.cache/salchipapa-dots/vault-errors/push" ] && ! git -C "$T/remote.git" show main:inbox/b.md >/dev/null 2>&1'
rm "$OBSIDIAN_VAULT/inbox/b.md"
bash "$OBS/vault-sync.sh" push test
check "el aviso se borra al volver a funcionar" '[ ! -f "$HOME/.cache/salchipapa-dots/vault-errors/push" ]'
echo "pendiente" >"$OBSIDIAN_VAULT/inbox/c.md"
bash "$OBS/vault-sync.sh" start test
check "start sube lo que quedo pendiente" 'git -C "$T/remote.git" show main:inbox/c.md >/dev/null 2>&1'
check "log de sincronizacion" 'grep -q "\[test push\] push ok" "$SYNC_LOG"'

echo "vault-welcome.py:"
D="$(date +%F)"
printf '# %s\n\n## Sesiones de hoy\n\n### 09:10 · claude · otro-equipo\n- Configuré algo\n- Pendiente: probarlo\n' "$D" >"$OBSIDIAN_VAULT/daily/$D.md"
msg="$(OBSIDIAN_OWNER="Ana López" python3 "$OBS/vault-welcome.py" | python3 -c 'import json,sys; print(json.load(sys.stdin)["systemMessage"])')"
check "saluda por el nombre de pila" 'grep -q "¡Hola Ana!" <<<"$msg"'
check "muestra las sesiones de hoy" 'grep -q "09:10 · claude · otro-equipo" <<<"$msg"'
check "lo pendiente de las sesiones va a Pendiente" 'grep -q "probarlo" <<<"$msg"'
mkdir -p "$HOME/.cache/salchipapa-dots/vault-errors"
echo "No se pudo subir (prueba)" >"$HOME/.cache/salchipapa-dots/vault-errors/push"
check "muestra los avisos ⚠" 'python3 "$OBS/vault-welcome.py" | grep -q "⚠ No se pudo subir"'
rm "$HOME/.cache/salchipapa-dots/vault-errors/push"

echo "vault-session-end.sh / session-log.py (sin llamar a Claude):"
printf '{"type":"user","timestamp":"%s","message":{"content":"hola"}}\n' "$(date -u +%FT%TZ)" >"$T/t.jsonl"
printf '{"session_id":"s1","transcript_path":"%s"}' "$T/t.jsonl" >"$T/hook.json"
python3 "$OBS/session-log.py" "$T/hook.json" test
check "sesion corta: no se resume" 'grep -q "sesion corta" "$HOME/.cache/salchipapa-dots/session-log.log"'
printf '{"session_id":"s2"}' | bash "$OBS/vault-session-end.sh" test
for _ in $(seq 50); do compgen -G "$HOME/.cache/salchipapa-dots/session-queue/*.json" >/dev/null || break; sleep 0.2; done
check "el hook de cierre vacia la cola y hace push" '! compgen -G "$HOME/.cache/salchipapa-dots/session-queue/*.json" >/dev/null && grep -q "\[test push\]" "$SYNC_LOG"'

echo
if [ "$fails" -eq 0 ]; then echo "✔ obsidian: todo bien"; else echo "✖ obsidian: $fails fallo(s)"; fi
[ "$fails" -eq 0 ]
