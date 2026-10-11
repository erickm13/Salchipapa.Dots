# Obsidian como memoria compartida de los agentes

La bóveda (`~/.config/obsidian`, repo privado `erickm13/SalchipapaNotes`) es la memoria a largo
plazo de todos los agentes —Claude Code, Codex, opencode y Copilot CLI— y se sincroniza sola con GitHub.

La bóveda sigue **PARA** (*Building a Second Brain*, Tiago Forte): `projects/` (con meta y final),
`areas/` (responsabilidades: qa, universidad), `resources/` (temas de consulta), `archive/`
(terminado), más `inbox/` (captura), `daily/` y `templates/`. `AGENTS.md` les dice a los agentes dónde
va cada cosa y cómo archivar un proyecto terminado. Las notas nuevas de Obsidian y de obsidian.nvim
caen en `inbox/`.

| Archivo | Qué hace |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Instrucciones de memoria para los agentes (genéricas: quién es el usuario lo leen de `me.md` de su bóveda): dónde está la bóveda, estructura, cuándo leer y escribir, nunca secretos. Enlazado como `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.config/opencode/AGENTS.md` y `~/.copilot/copilot-instructions.md` |
| [`vault-start.sh`](vault-start.sh) | Hook de inicio de sesión: `vault-sync.sh start` + bienvenida |
| [`vault-welcome.py`](vault-welcome.py) | Bienvenida: lo último que hice (diaria más reciente) y lo pendiente (`Mañana`, `Pendiente`, tareas `- [ ]` de `projects/`). Lo muestra en pantalla y se lo pasa al agente para que salude |
| [`vault-sync.sh`](vault-sync.sh) | `start` al empezar (sube lo que quedó pendiente de una sesión cerrada de golpe + pull), `push` (commit + pull --rebase + push) al terminar. Lock entre agentes, nunca bloquea, se niega a subir secretos. Log: `~/.cache/salchipapa-dots/vault-sync.log` |
| [`opencode-vault-sync.js`](opencode-vault-sync.js) | Plugin de opencode: `session.created` → start, `session.idle` → push. Enlazado en `~/.config/opencode/plugins/` |
| [`daily-note.sh`](daily-note.sh) | Escribe `daily/AAAA-MM-DD.md` con `claude -p` a partir de los commits del día y de claude-mem; si no hubo actividad no crea nada. Log: `~/.cache/salchipapa-dots/daily-note.log` |
| [`weekly-review.sh`](weekly-review.sh) | Revisión semanal (Building a Second Brain): escribe `weekly/AAAA-Wnn.md` con resumen, logros, aprendizajes y **propuestas** `- [ ]` (clasificar `inbox/`, archivar proyectos). No mueve nada: se aplica diciéndole a un agente *"aplica la revisión semanal"*. Log: `~/.cache/salchipapa-dots/weekly-review.log` |
| [`systemd/`](systemd) | `obsidian-daily.timer`: cada noche a las 23:30; `obsidian-weekly.timer`: domingos a las 20:00 (`Persistent=true`: si WSL estaba apagado, corren al volver) |

**Avisos:** si falla una sincronización, la nota diaria o la revisión semanal, queda un aviso en
`~/.cache/salchipapa-dots/vault-errors/` que la bienvenida muestra (⚠) hasta que ese paso vuelva a
funcionar. La bienvenida también avisa (📋) si la última revisión semanal tiene propuestas sin aplicar.

## Bóveda nueva
Si la bóveda está vacía o no usa PARA, `setup-agents.py` crea lo que falte (nunca sobrescribe):
las carpetas PARA y, desde [`vault-template/`](vault-template), `me.md` (rellénalo: los agentes lo
leen para saber quién eres), `templates/daily.md` y la config de Obsidian (notas nuevas en `inbox/`,
diarias en `daily/`). El nombre del saludo sale de `git config user.name` (o `OBSIDIAN_OWNER`).

## Dónde se engancha cada agente
| Agente | Al empezar (start + bienvenida) | Al terminar (push) |
|---|---|---|
| Claude Code | hook `SessionStart` (`startup`; en `resume` solo pull) en `~/.claude/settings.json` | hook `SessionEnd` |
| Codex | hook `SessionStart` en `~/.codex/hooks.json` | hook `SessionEnd` |
| Copilot CLI | hook `SessionStart` en `~/.copilot/settings.json` | hook `SessionEnd` |
| opencode | plugin, `session.created` | plugin, `session.idle` |

Los agentes que no muestran la salida del hook saludan igual: `AGENTS.md` les pide que, en su
primera respuesta, recuerden lo último que hice leyendo la diaria más reciente.

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
python3 "$DOTS"/SalchipapaObsidian/setup-agents.py
systemctl --user daemon-reload && systemctl --user enable --now obsidian-daily.timer obsidian-weekly.timer
python3 "$DOTS"/SalchipapaObsidian/vault-welcome.py | jq -r .systemMessage   # comprobar
```
La revisión semanal basta con tenerla en un equipo (el que esté encendido los domingos):
`systemctl --user disable --now obsidian-weekly.timer` en los demás.

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
