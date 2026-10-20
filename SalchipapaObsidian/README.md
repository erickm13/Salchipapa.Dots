# Obsidian como memoria compartida de los agentes

La bóveda (`~/.config/obsidian`, repo privado `erickm13/SalchipapaNotes`) es la memoria a largo
plazo de todos los agentes —Claude Code, Codex, opencode, Copilot CLI y Gemini CLI— y se sincroniza sola con GitHub.

Es un **LLM Wiki** (Karpathy) ordenado con **PARA** (Tiago Forte), en tres capas: **fuentes crudas**
(`raw/`, inmutables), la **wiki** (las carpetas PARA + `index.md` + `log.md`) y el **schema**
(`AGENTS.md` en la raíz de la bóveda, que importan `CLAUDE.md` y `GEMINI.md`, y las plantillas por tipo
de `templates/`). El schema vive **en la bóveda** y lo hacen evolucionar el usuario y los agentes;
[`vault-template/AGENTS.md`](vault-template/AGENTS.md) solo es la semilla para una bóveda nueva.

La bóveda sigue **PARA** (*Building a Second Brain*, Tiago Forte): `projects/` (con meta y final),
`areas/` (responsabilidades: qa, universidad), `resources/` (temas de consulta), `archive/`
(terminado), más `inbox/` (captura), `daily/` y `templates/`. `AGENTS.md` les dice a los agentes dónde
va cada cosa y cómo archivar un proyecto terminado. Las notas nuevas de Obsidian y de obsidian.nvim
caen en `inbox/`.

| Archivo | Qué hace |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Instrucciones globales de memoria (genéricas: quién es el usuario lo leen de `me.md`): dónde está la bóveda, sincronización, bienvenida, nunca secretos, y que **antes de escribir lean el schema de la bóveda** (`<bóveda>/AGENTS.md`). Enlazado como `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.config/opencode/AGENTS.md`, `~/.copilot/copilot-instructions.md` y `~/.gemini/GEMINI.md` |
| [`vault-start.sh`](vault-start.sh) | Hook de inicio de sesión: `vault-sync.sh start` + bienvenida (+ resúmenes de sesión que quedaron en cola) |
| [`vault-session-end.sh`](vault-session-end.sh) + [`session-log.py`](session-log.py) | Hook de fin de sesión (Claude Code, Codex, Copilot CLI y Gemini CLI; opencode solo push): en segundo plano, guarda la conversación limpia en `raw/sesiones/AAAA-MM-DD-HHMM-agente-<sesión>.md` (fuente cruda: secretos como `[SECRETO]`, nunca se reescribe; lo que siga en la sesión va a otro archivo), resume la sesión con `claude -p --model haiku` (sin hooks) y la añade a `daily/<hoy>.md` bajo `## Sesiones de hoy` (`### HH:MM · agente · equipo`), luego push. Así **cualquier otro equipo** ve lo último que hiciste al abrir un agente. Sesiones cortas (menos de 2 mensajes tuyos) no se resumen; el resumen pasa el filtro de secretos; si el equipo se apaga antes, la cola se procesa al empezar la siguiente sesión; si Claude está en su límite de uso, la entrada se queda en la cola sin gastar intentos. Al salir de `claude`, `codex` o `copilot` (funciones de fish), se espera el resultado y se muestra bajo el aviso de `--resume`: `✔ Notas guardadas: resumen de la sesión en daily/… y bóveda subida a GitHub` (Ctrl+C: que siga en segundo plano). Log: `~/.cache/salchipapa-dots/session-log.log` |
| [`pendientes.py`](pendientes.py) | La lista de pendientes vigente del día, para la bienvenida y el resumidor: cada resumen de sesión **reescribe la lista completa** (quita lo resuelto, conserva lo abierto, añade lo nuevo) y su bloque termina con `<!-- pendientes: lista completa -->`; vale la del último bloque así. Si un resumen no trae la lista, no borra la anterior. La primera sesión del día parte del *Mañana* de la diaria anterior |
| [`vault-welcome.py`](vault-welcome.py) | Bienvenida: lo último que hice (diaria más reciente) y lo pendiente (`Mañana`, `Pendiente`, tareas `- [ ]` de `projects/`). Con `vault-lint.py`: ⚠ si hay algo grave, 📥 si hay fuentes de `raw/` sin ingerir desde hace más de un día (el ingest nocturno no funciona) y 🧹 con el número de avisos. Lo muestra en pantalla y se lo pasa al agente para que salude |
| [`vault-sync.sh`](vault-sync.sh) | `start` al empezar (sube lo que quedó pendiente de una sesión cerrada de golpe + pull), `push` (commit + pull --rebase + push) al terminar. Lock entre agentes, nunca bloquea, se niega a subir secretos y cambios a archivos existentes de `raw/` (inmutable). Log: `~/.cache/salchipapa-dots/vault-sync.log` |
| [`vault-guard-raw.py`](vault-guard-raw.py) | Hook antes de editar (Claude Code `PreToolUse`, Gemini CLI `BeforeTool`): bloquea editar un archivo existente de `raw/`; crear fuentes nuevas sí se puede |
| [`vault-lint.py`](vault-lint.py) | Verificador de la wiki, sin LLM: frontmatter (`tipo`, `resumen`, `actualizado`), enlaces rotos (resuelve alias, ignora código), páginas que su hub no enlaza, proyectos largos, sin Estado o terminados, hubs vacíos, archivos fuera de PARA, secretos y, con `--since <rev>`, cambios en `raw/`. Sale con 1 solo si hay algo grave. `--index` regenera `index.md` desde el `resumen` de cada página (lo hace `vault-sync.sh` antes de cada commit); `--json` y `--count` para otros scripts |
| [`opencode-vault-sync.js`](opencode-vault-sync.js) | Plugin de opencode: `session.created` → start, `session.idle` → push. Enlazado en `~/.config/opencode/plugins/` |
| [`daily-note.sh`](daily-note.sh) | Trabajo nocturno. **1) Ingest** (LLM Wiki): las fuentes de `raw/` que no están en `log.md` (máx. `INGEST_MAX`=10 por noche, modelo `INGEST_MODEL`=sonnet) se integran en la wiki según la sección *Ingest* del schema, con una entrada `ingest` por fuente en `log.md`; si el modelo toca `raw/`, se restaura; si OpenClaw ya las ingirió, no se llama a Claude. **2)** Completa `daily/AAAA-MM-DD.md` con `claude -p` cuando el día ya terminó, a partir de `## Sesiones de hoy`, los commits del día y claude-mem; si no hubo actividad no crea nada. Escribe todos los días que falten (hasta 7), así un equipo apagado no pierde días. Log: `~/.cache/salchipapa-dots/daily-note.log` |
| [`weekly-review.sh`](weekly-review.sh) | Revisión semanal (Building a Second Brain): escribe `weekly/AAAA-Wnn.md` con resumen, logros, aprendizajes y **propuestas** `- [ ]`: clasificar `inbox/`, archivar proyectos, arreglar cada hallazgo de `vault-lint.py` (se los pasa) y el *lint con criterio* del LLM Wiki (contradicciones, datos viejos, conceptos sin página, enlaces que faltan). No mueve nada: se aplica diciéndole a un agente *"aplica la revisión semanal"*. Log: `~/.cache/salchipapa-dots/weekly-review.log` |
| [`systemd/`](systemd) | `obsidian-daily.timer`: cada día a las 00:10; `obsidian-weekly.timer`: lunes a las 00:40 (`Persistent=true`: si el equipo estaba apagado, corren al volver) |

**Avisos:** si falla una sincronización, la nota diaria o la revisión semanal, queda un aviso en
`~/.cache/salchipapa-dots/vault-errors/` que la bienvenida muestra (⚠) hasta que ese paso vuelva a
funcionar. La bienvenida también avisa (📋) si la última revisión semanal tiene propuestas sin aplicar.

## Bóveda nueva
Si la bóveda está vacía o no usa PARA, `setup-agents.py` crea lo que falte (nunca sobrescribe):
las carpetas PARA y `raw/{sesiones,web,docs,assets}` y, desde [`vault-template/`](vault-template), el
schema (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`), `log.md`, `me.md` (rellénalo: los agentes lo leen para
saber quién eres), las plantillas (`daily`, `proyecto`, `recurso`, `concepto`, `hub`, `fuente`) y la
config de Obsidian (notas nuevas en `inbox/`, diarias en `daily/`, plantillas en `templates/`). El nombre del saludo sale de `git config user.name` (o `OBSIDIAN_OWNER`).

## Dónde se engancha cada agente
| Agente | Al empezar (start + bienvenida) | Al terminar (resumen de la sesión + push) |
|---|---|---|
| Claude Code | hook `SessionStart` (`startup`; en `resume` solo pull) en `~/.claude/settings.json` | hook `SessionEnd` |
| Codex | hook `SessionStart` en `~/.codex/hooks.json` | hook `SessionEnd` |
| Copilot CLI | hook `SessionStart` en `~/.copilot/settings.json` | hook `SessionEnd` (la conversación se lee de `~/.copilot/session-state/<id>/events.jsonl`) |
| opencode | plugin, `session.created` | plugin, `session.idle` (solo push) |
| Gemini CLI | hook `SessionStart` (`startup`; en `resume` solo pull) en `~/.gemini/settings.json` | hook `SessionEnd`; `BeforeTool` protege `raw/` |

Los agentes que no muestran la salida del hook saludan igual: `AGENTS.md` les pide que, en su
primera respuesta, recuerden lo último que hice leyendo la diaria más reciente.

## Diaria y semanal en GitHub Actions (opcional, recomendado)
Con los timers locales, la diaria y la semanal corren en **cada** equipo y solo si está encendido.
En GitHub Actions corren una sola vez, a su hora, aunque todos tus equipos estén apagados:

1. Token de tu suscripción de Claude para CI (lo creas tú; no lo pegues en ningún chat):
   ```bash
   claude setup-token                                            # abre el navegador y muestra el token
   gh secret set CLAUDE_CODE_OAUTH_TOKEN -R <usuario>/<bóveda>   # lo pide oculto
   ```
2. Copia [`github-actions/daily-note.yml`](github-actions/daily-note.yml),
   [`github-actions/weekly-review.yml`](github-actions/weekly-review.yml) y
   [`github-actions/vault-lint.yml`](github-actions/vault-lint.yml) a `<bóveda>/.github/workflows/`
   (ajusta `TZ` y el `cron` a tu zona horaria). Bajan los scripts de `erickm13/Salchipapa.Dots`; si usas
   un fork, crea en la bóveda la variable de Actions `SALCHIPAPA_DOTS_REPO` = `<usuario>/<fork>`.
   `vault-lint.yml` corre en cada push (también lo que sube Obsidian desde Windows o el iPhone) y falla
   solo por algo grave: frontmatter roto, un posible secreto o `raw/` modificado.
   **Versiones fijas** (variables de Actions de la bóveda): `SALCHIPAPA_DOTS_REF` = commit o tag de los
   scripts (sin ella, `main`: un commit roto en Dots rompería la diaria de esa noche) y
   `CLAUDE_CODE_VERSION` (sin ella, la última). Tras actualizar Dots, sube la versión:
   ```bash
   gh variable set SALCHIPAPA_DOTS_REF -R <usuario>/<bóveda> -b "$(git -C "$DOTS" rev-parse HEAD)"
   gh variable set CLAUDE_CODE_VERSION -R <usuario>/<bóveda> -b "$(claude --version | cut -d' ' -f1)"
   ```
3. En cada equipo: `setup-agents.py` ve los workflows y **desactiva** los timers locales.

En la nube no hay claude-mem (es local): la diaria se hace con `## Sesiones de hoy` y tus commits
(API de GitHub: con el token del workflow, los repos públicos; para incluir los privados, crea el
secret `DAILY_GH_TOKEN` con un token de solo lectura). Si un trabajo falla, GitHub te avisa por correo.
Lanzarlo a mano: pestaña **Actions** de la bóveda → *Nota diaria* → *Run workflow* (con fecha opcional).

## Conectar otro equipo
En un equipo que ya tiene Salchipapa.Dots (sin reinstalar todo). El instalador hace lo mismo si
eliges login de GitHub y pones la URL de tu bóveda:
```bash
gh auth login && gh auth setup-git                       # GitHub (la bóveda es privada)
git config --global user.name "Tu Nombre"                # la bienvenida saluda con tu nombre de pila
git config --global user.email "tu@correo"
DOTS=~/Salchipapa.Dots      # o donde tengas clonado el repo (en fish: set DOTS ~/Salchipapa.Dots)
cd "$DOTS" && git pull
[ -d ~/.config/obsidian/.git ] && git -C ~/.config/obsidian pull --rebase --autostash \
  || gh repo clone erickm13/SalchipapaNotes ~/.config/obsidian
python3 "$DOTS"/SalchipapaObsidian/setup-agents.py      # instrucciones, hooks, plugin y timers
python3 "$DOTS"/SalchipapaObsidian/vault-welcome.py | jq -r .systemMessage   # comprobar
```
`setup-agents.py` informa de cada paso (✔ hecho / ya estaba, ⚠ omitido, ✖ fallo con el motivo), termina
con un resumen y sale con 1 si algo falló. También activa los timers (`daemon-reload` + `enable --now`).

**Actualizar un equipo ya conectado** (tras cambios en el repo): `git pull` y volver a ejecutar
`setup-agents.py`; es idempotente.

La revisión semanal basta con tenerla en un equipo (el que esté encendido los domingos):
`systemctl --user disable --now obsidian-weekly.timer` en los demás. `setup-agents.py` respeta esa
decisión y no la vuelve a activar.

## Comandos útiles
`$DOTS` es la carpeta del repo (por defecto `~/Salchipapa.Dots`; los scripts funcionan desde cualquier ruta).
```bash
tail ~/.cache/salchipapa-dots/vault-sync.log            # qué sincronizó cada agente
python3 "$DOTS"/SalchipapaObsidian/vault-welcome.py | jq -r .systemMessage   # ver la bienvenida
systemctl --user list-timers 'obsidian-*'                # próxima diaria y revisión semanal
bash "$DOTS"/SalchipapaObsidian/weekly-review.sh 2026-10-10  # (re)generar la semanal de esa semana
bash "$DOTS"/SalchipapaObsidian/daily-note.sh 2026-10-10   # (re)generar una diaria a mano
systemctl --user disable --now obsidian-daily.timer      # desactivar la diaria automática
```
