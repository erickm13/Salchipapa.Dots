# Obsidian como memoria compartida de los agentes

La bóveda (`~/.config/obsidian`, repo privado `erickm13/SalchipapaNotes`) es la memoria a largo
plazo de todos los agentes —Claude Code, Codex, opencode y Copilot CLI— y se sincroniza sola con GitHub.

| Archivo | Qué hace |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Instrucciones de memoria para los agentes: dónde está la bóveda, estructura, cuándo leer y escribir, nunca secretos. Enlazado como `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.config/opencode/AGENTS.md` y `~/.copilot/copilot-instructions.md` |
| [`vault-start.sh`](vault-start.sh) | Hook de inicio de sesión: `vault-sync.sh start` + bienvenida |
| [`vault-welcome.py`](vault-welcome.py) | Bienvenida: lo último que hice (diaria más reciente) y lo pendiente (`Mañana`, `Pendiente`, tareas `- [ ]` de `projects/`). Lo muestra en pantalla y se lo pasa al agente para que salude |
| [`vault-sync.sh`](vault-sync.sh) | `start` al empezar (sube lo que quedó pendiente de una sesión cerrada de golpe + pull), `push` (commit + pull --rebase + push) al terminar. Lock entre agentes, nunca bloquea, se niega a subir secretos. Log: `~/.cache/salchipapa-dots/vault-sync.log` |
| [`opencode-vault-sync.js`](opencode-vault-sync.js) | Plugin de opencode: `session.created` → start, `session.idle` → push. Enlazado en `~/.config/opencode/plugins/` |
| [`daily-note.sh`](daily-note.sh) | Escribe `daily/AAAA-MM-DD.md` con `claude -p` a partir de los commits del día y de claude-mem; si no hubo actividad no crea nada. Log: `~/.cache/salchipapa-dots/daily-note.log` |
| [`systemd/`](systemd) | `obsidian-daily.timer`: cada noche a las 23:30 (`Persistent=true`: si WSL estaba apagado, corre al volver) |

## Dónde se engancha cada agente
| Agente | Al empezar (start + bienvenida) | Al terminar (push) |
|---|---|---|
| Claude Code | hook `SessionStart` (`startup`; en `resume` solo pull) en `~/.claude/settings.json` | hook `SessionEnd` |
| Codex | hook `SessionStart` en `~/.codex/hooks.json` | hook `SessionEnd` |
| Copilot CLI | hook `SessionStart` en `~/.copilot/settings.json` | hook `SessionEnd` |
| opencode | plugin, `session.created` | plugin, `session.idle` |

Los agentes que no muestran la salida del hook saludan igual: `AGENTS.md` les pide que, en su
primera respuesta, recuerden lo último que hice leyendo la diaria más reciente.

## Comandos útiles
```bash
tail ~/.cache/salchipapa-dots/vault-sync.log            # qué sincronizó cada agente
python3 ~/Salchipapa.Dots/SalchipapaObsidian/vault-welcome.py | jq -r .systemMessage   # ver la bienvenida
systemctl --user list-timers obsidian-daily.timer        # próxima nota diaria
bash ~/Salchipapa.Dots/SalchipapaObsidian/daily-note.sh 2026-10-10   # (re)generar una diaria a mano
systemctl --user disable --now obsidian-daily.timer      # desactivar la diaria automática
```
