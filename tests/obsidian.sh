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
check "crea el schema de la bóveda (AGENTS.md, CLAUDE.md, GEMINI.md, log.md)" '[ -f "$OBSIDIAN_VAULT/AGENTS.md" ] && grep -qx "@AGENTS.md" "$OBSIDIAN_VAULT/CLAUDE.md" && [ -f "$OBSIDIAN_VAULT/GEMINI.md" ] && [ -f "$OBSIDIAN_VAULT/log.md" ]'
check "crea raw/ y las plantillas por tipo" '[ -d "$OBSIDIAN_VAULT/raw/sesiones" ] && [ -d "$OBSIDIAN_VAULT/raw/assets" ] && [ -f "$OBSIDIAN_VAULT/templates/proyecto.md" ] && [ -f "$OBSIDIAN_VAULT/templates/fuente.md" ]'
check "AGENTS.md como GEMINI.md global" '[ "$(readlink "$HOME/.gemini/GEMINI.md")" = "$OBS/AGENTS.md" ]'
check "hooks de Gemini: inicio y cierre" 'grep -q "vault-start.sh gemini" "$HOME/.gemini/settings.json" && grep -q "vault-session-end.sh gemini" "$HOME/.gemini/settings.json"'
check "servicio systemd con la ruta real" 'grep -q "ExecStart=/usr/bin/bash $OBS/daily-note.sh" "$HOME/.config/systemd/user/obsidian-daily.service"'
python3 "$OBS/setup-agents.py" >/dev/null 2>&1
check "idempotente: un solo hook de inicio" '[ "$(grep -c "vault-start.sh claude" "$HOME/.claude/settings.json")" -eq 1 ] && [ "$(grep -c "vault-start.sh gemini" "$HOME/.gemini/settings.json")" -eq 1 ]'
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
python3 "$OBS/session-log.py" "$T/hook.json" test >/dev/null
check "sesion corta: no se resume" 'grep -q "sesion corta" "$HOME/.cache/salchipapa-dots/session-log.log"'
printf '{"session_id":"s2"}' | bash "$OBS/vault-session-end.sh" test
# Se procesa en segundo plano: esperar al resultado, que se escribe al final (tras el push)
for _ in $(seq 100); do [ -f "$HOME/.cache/salchipapa-dots/session-end.status" ] && break; sleep 0.2; done
check "el hook de cierre vacia la cola y hace push" '! compgen -G "$HOME/.cache/salchipapa-dots/session-queue/*.json" >/dev/null && grep -q "\[test push\]" "$SYNC_LOG"'
check "deja el resultado para el aviso al salir" 'grep -q "^✔ Bóveda al día en GitHub" "$HOME/.cache/salchipapa-dots/session-end.status"'
if command -v fish >/dev/null; then
  antes="$(fish --no-config -c "set fish_function_path $REPO/SalchipapaFish/fish/functions \$fish_function_path; __vault_esperar_cierre --antes")"
  printf '{"session_id":"s3"}' | bash "$OBS/vault-session-end.sh" test
  aviso="$(fish --no-config -c "set fish_function_path $REPO/SalchipapaFish/fish/functions \$fish_function_path; __vault_esperar_cierre $antes" 2>&1)"
  check "fish: al salir del agente dice el resultado" 'grep -q "✔ Bóveda al día en GitHub" <<<"$aviso"'
  aviso="$(fish --no-config -c "set fish_function_path $REPO/SalchipapaFish/fish/functions \$fish_function_path; __vault_esperar_cierre (__vault_esperar_cierre --antes)" 2>&1)"
  check "fish: sin sesion nueva no dice nada" '[ -z "$aviso" ]'
fi

echo "raw/ (fuentes crudas del LLM Wiki, sin llamar a Claude):"
RAW="$OBSIDIAN_VAULT/raw/sesiones"
NOW="$(date -u +%FT%TZ)"
printf '#!/bin/sh\necho "You'"'"'ve hit your session limit · resets 5am" >&2\nexit 1\n' >"$T/claude-limit"
printf '#!/bin/sh\ncat >/dev/null\necho "- Configuré la prueba"\n' >"$T/claude-ok"
chmod +x "$T/claude-limit" "$T/claude-ok"
TOKEN="ghp_$(printf 'B%.0s' {1..36})"
{
  printf '{"type":"user","timestamp":"%s","message":{"content":"configura algo con %s"}}\n' "$NOW" "$TOKEN"
  printf '{"type":"assistant","timestamp":"%s","message":{"content":[{"type":"text","text":"Hecho"}]}}\n' "$NOW"
  printf '{"type":"user","timestamp":"%s","message":{"content":"gracias"}}\n' "$NOW"
} >"$T/t4.jsonl"
printf '{"session_id":"s4abc","transcript_path":"%s"}' "$T/t4.jsonl" >"$T/hook4.json"
CLAUDE_BIN="$T/claude-limit" python3 "$OBS/session-log.py" "$T/hook4.json" test >/dev/null
rc=$?
check "límite de uso: sale con 75 (no gasta un reintento)" '[ "$rc" -eq 75 ]'
check "guarda la conversación en raw/sesiones/ aunque el resumen falle" '[ "$(ls "$RAW"/*-test-s4abc.md 2>/dev/null | wc -l)" -eq 1 ]'
check "los secretos quedan como [SECRETO]" 'grep -q "\[SECRETO\]" "$RAW"/*-test-s4abc.md && ! grep -q "$TOKEN" "$RAW"/*-test-s4abc.md'
CLAUDE_BIN="$T/claude-ok" python3 "$OBS/session-log.py" "$T/hook4.json" test >/dev/null
check "al reintentar no duplica raw/ y escribe el resumen" '[ "$(ls "$RAW"/*-s4abc.md | wc -l)" -eq 1 ] && grep -q "Configuré la prueba" "$OBSIDIAN_VAULT/daily/$(date +%F).md"'
printf '{"type":"user","timestamp":"%s","message":{"content":"otra cosa"}}\n{"type":"user","timestamp":"%s","message":{"content":"y otra"}}\n' \
  "$(date -u -d '+1 minute' +%FT%TZ)" "$(date -u -d '+1 minute' +%FT%TZ)" >>"$T/t4.jsonl"
CLAUDE_BIN="$T/claude-ok" python3 "$OBS/session-log.py" "$T/hook4.json" test >/dev/null
check "si la sesión sigue, lo nuevo va a otro archivo sin tocar el anterior" '[ "$(ls "$RAW"/*-s4abc.md | wc -l)" -eq 2 ] && grep -q "configura algo" "$(ls "$RAW"/*-s4abc.md | head -1)"'
mkdir -p "$HOME/.copilot/session-state/cop1"
{
  printf '{"type":"user.message","timestamp":"%s","data":{"content":"hola copilot"}}\n' "$NOW"
  printf '{"type":"assistant.message","timestamp":"%s","data":{"content":"hola"}}\n' "$NOW"
  printf '{"type":"user.message","timestamp":"%s","data":{"content":"revisa algo"}}\n' "$NOW"
} >"$HOME/.copilot/session-state/cop1/events.jsonl"
printf '{"sessionId":"cop1"}' >"$T/hook5.json"
CLAUDE_BIN="$T/claude-ok" python3 "$OBS/session-log.py" "$T/hook5.json" copilot >/dev/null
check "Copilot: lee su events.jsonl" 'grep -q "hola copilot" "$RAW"/*-copilot-cop1.md'
{
  printf '{"sessionId":"gem1","startTime":"%s"}\n' "$NOW"
  printf '{"id":"1","timestamp":"%s","type":"user","content":[{"text":"hola gemini"}]}\n' "$NOW"
  printf '{"id":"2","timestamp":"%s","type":"gemini","content":"hola"}\n' "$NOW"
  printf '{"id":"3","timestamp":"%s","type":"user","content":"otra pregunta"}\n' "$NOW"
} >"$T/gem.jsonl"
printf '{"session_id":"gem1","transcript_path":"%s"}' "$T/gem.jsonl" >"$T/hook6.json"
CLAUDE_BIN="$T/claude-ok" python3 "$OBS/session-log.py" "$T/hook6.json" gemini >/dev/null
check "Gemini: lee su transcript JSONL" 'grep -q "hola gemini" "$RAW"/*-gemini-gem1.md'
EXIST="$(ls "$RAW"/*-s4abc.md | head -1)"
printf '{"tool_input":{"file_path":"%s"}}' "$EXIST" | python3 "$OBS/vault-guard-raw.py" 2>/dev/null
check "hook: no deja editar un archivo existente de raw/" '[ $? -eq 2 ]'
printf '{"tool_input":{"file_path":"%s"}}' "$OBSIDIAN_VAULT/raw/web/nuevo.md" | python3 "$OBS/vault-guard-raw.py"
check "hook: sí deja crear una fuente nueva en raw/" '[ $? -eq 0 ]'
bash "$OBS/vault-sync.sh" push test
echo "cambiado" >>"$EXIST"
bash "$OBS/vault-sync.sh" push test
check "vault-sync: no sube cambios a raw/ y deja aviso" 'grep -q "raw/" "$HOME/.cache/salchipapa-dots/vault-errors/push" && ! git -C "$T/remote.git" show "main:${EXIST#$OBSIDIAN_VAULT/}" | grep -q cambiado'
git -C "$OBSIDIAN_VAULT" checkout -q -- raw/
bash "$OBS/vault-sync.sh" push test
check "vault-sync: al restaurar raw/ vuelve a subir y quita el aviso" '[ ! -f "$HOME/.cache/salchipapa-dots/vault-errors/push" ]'

echo "vault-lint.py (verificador de la wiki):"
LINT="$OBS/vault-lint.py"
mkdir -p "$OBSIDIAN_VAULT/resources/demo"
printf -- '---\nid: demo-hub\ntipo: hub\nresumen: Hub de prueba\nactualizado: 2026-10-20\n---\n# Demo\n- [[demo-a]]\n' >"$OBSIDIAN_VAULT/resources/demo/demo-hub.md"
printf -- '---\nid: demo-a\naliases:\n  - Página A\ntipo: recurso\nresumen: Página A de prueba\nactualizado: 2026-10-20\n---\n# A\nVer [[no-existe]] y [[Página A]].\n`[[en-codigo]]`\n```\n[[en-bloque]]\n```\n' >"$OBSIDIAN_VAULT/resources/demo/demo-a.md"
printf -- '---\nid: demo-b\n---\n# B\n' >"$OBSIDIAN_VAULT/resources/demo/demo-b.md"
out="$(python3 "$LINT")"
rc=$?
check "detecta un enlace roto (y resuelve alias)" 'grep -q "demo-a.md: enlace roto \[\[no-existe\]\]" <<<"$out" && ! grep -q "Página A" <<<"$out"'
check "ignora los enlaces dentro de código" '! grep -q "en-codigo\|en-bloque" <<<"$out"'
check "avisa del frontmatter incompleto y de la página que su hub no enlaza" 'grep -q "demo-b.md: falta en el frontmatter: tipo, resumen, actualizado" <<<"$out" && grep -q "demo-b.md: su hub" <<<"$out"'
check "los avisos no fallan (rc=0)" '[ "$rc" -eq 0 ]'
python3 "$LINT" --index >/dev/null
check "genera index.md con el resumen de cada página" 'grep -q "\[\[demo-a\]\] — Página A de prueba" "$OBSIDIAN_VAULT/index.md" && grep -q "no lo edites a mano" "$OBSIDIAN_VAULT/index.md"'
check "cuenta las fuentes de raw/ sin ingerir" '[ "$(python3 "$LINT" --count | cut -d" " -f3)" -ge 1 ]'
REV="$(git -C "$OBSIDIAN_VAULT" rev-parse HEAD)"
git -C "$OBSIDIAN_VAULT" rm -q "$(ls "$RAW"/*-copilot-cop1.md)"
git -C "$OBSIDIAN_VAULT" commit -qm "borra raw"
python3 "$LINT" --since "$REV" >/dev/null
check "--since: borrar algo de raw/ es grave (rc=1)" '[ $? -eq 1 ]'
git -C "$OBSIDIAN_VAULT" revert --no-edit HEAD >/dev/null
rm -f "$OBSIDIAN_VAULT/index.md"
echo "x" >"$OBSIDIAN_VAULT/inbox/z.md"
bash "$OBS/vault-sync.sh" push test
check "vault-sync regenera index.md antes de subir" 'git -C "$T/remote.git" show main:index.md | grep -q "demo-hub"'

echo "daily-note.sh: ingest nocturno de raw/ (Claude simulado):"
mkdir -p "$T/bin"
cat >"$T/bin/claude" <<'STUB'
#!/usr/bin/env bash
# Claude simulado: guarda el prompt; en el ingest registra las fuentes en log.md e intenta tocar raw/
prompt="$2"
printf '%s\n=====\n' "$prompt" >>"$PROMPTS"
if grep -q "Haz el INGEST" <<<"$prompt"; then
  grep -oE '^- raw/[^ ]+' <<<"$prompt" | sed 's/^- //' | while read -r src; do
    printf '\n## [hoy] ingest | %s\n- Sin cambios en la wiki\n' "$src" >>log.md
  done
  first="$(grep -oE '^- raw/[^ ]+' <<<"$prompt" | head -1 | sed 's/^- //')"
  echo "editado por el modelo" >>"$first"
fi
echo ok
STUB
chmod +x "$T/bin/claude"
export PROMPTS="$T/prompts.txt"
before="$(python3 "$LINT" --count | cut -d' ' -f3)"
PATH="$T/bin:$PATH" bash "$OBS/daily-note.sh"
check "manda a Claude las fuentes pendientes de raw/" 'grep -q "Haz el INGEST" "$PROMPTS" && grep -q "^- raw/sesiones/" "$PROMPTS"'
check "después del ingest no quedan fuentes pendientes (había $before)" '[ "$(python3 "$LINT" --count | cut -d" " -f3)" -eq 0 ]'
check "si el modelo toca raw/, se restaura antes de subir" '[ -z "$(git -C "$OBSIDIAN_VAULT" status --porcelain -- raw/)" ] && grep -q "restaurado" "$HOME/.cache/salchipapa-dots/daily-note.log"'
check "el log de la wiki llega a GitHub" 'git -C "$T/remote.git" show main:log.md | grep -q "ingest | raw/sesiones/"'
: >"$PROMPTS"
printf '%s\n' "$(date -d yesterday +%F)" >>"$HOME/.cache/salchipapa-dots/daily-note.done"
PATH="$T/bin:$PATH" bash "$OBS/daily-note.sh"
check "sin fuentes ni días pendientes no llama a Claude" '[ ! -s "$PROMPTS" ]'

echo "weekly-review.sh (Claude simulado):"
mkdir -p "$OBSIDIAN_VAULT/areas/trabajo"
: >"$PROMPTS"
PATH="$T/bin:$PATH" bash "$OBS/weekly-review.sh" "$(date +%F)"
check "la semanal recibe los hallazgos del verificador" 'grep -q "Hallazgos del verificador" "$PROMPTS" && grep -q "demo-b.md: falta en el frontmatter" "$PROMPTS"'
check "la semanal lista las áreas reales y pide lint con criterio" 'grep -q "responsabilidades: trabajo" "$PROMPTS" && grep -q "LINT CON CRITERIO" "$PROMPTS"'

echo
if [ "$fails" -eq 0 ]; then echo "✔ obsidian: todo bien"; else echo "✖ obsidian: $fails fallo(s)"; fi
[ "$fails" -eq 0 ]
