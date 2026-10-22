# OpenClaw: administrador de la bóveda

[OpenClaw](https://docs.openclaw.ai) en un VPS es el **administrador principal** de la bóveda de
Obsidian (el LLM Wiki de [`SalchipapaObsidian`](../SalchipapaObsidian/README.md)): por Telegram
**captura** enlaces, archivos e ideas, hace el **ingest** de `raw/` cada noche y responde **consultas**.
GitHub Actions queda de respaldo: a las 00:10 hace el ingest solo si quedó algo pendiente en `log.md`.

En el servidor no vive nada importante: lo que no es secreto está aquí y la bóveda está en GitHub.
Cambiar de VPS = instancia nueva + `install.sh` + `openclaw onboard`.

| Archivo | Qué hace |
|---|---|
| [`skills/boveda/SKILL.md`](skills/boveda/SKILL.md) | El skill: captura (enlace → `raw/web/`, archivo → `raw/docs/` o `raw/assets/`, idea → `inbox/`; responde con la ruta, `⏳ pendiente de ingest` y ofrece ingerir ya), ingest según el schema de la bóveda, consulta (`index.md` primero) y **salud** (el informe lo redacta `vault-lint.py --salud` y el agente lo envía tal cual: el modelo no evalúa fechas ni señales). Sincroniza con `vault-sync.sh pull/push openclaw`, que se niega a subir secretos o cambios en `raw/` |
| [`install.sh`](install.sh) | En el VPS, idempotente: swap de 2 GiB, OpenClaw (`OPENCLAW_VERSION`), Dots en `~/Salchipapa.Dots` (`SALCHIPAPA_DOTS_REF`), **deploy key** con escritura solo para la bóveda (host `github-vault`), la bóveda en `~/.config/obsidian` (commits como `Padawan-Salchipapa`), el skill en `~/.openclaw/skills/` y la automatización *Ingest de la bóveda* a las 23:45 (`TZ_VAULT`) |

## Instalar o cambiar de VPS
Ubuntu, 2 GiB de RAM como mínimo (con swap), Node.js con npm.

1. En el VPS:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/erickm13/Salchipapa.Dots/main/SalchipapaOpenClaw/install.sh | bash
   ```
2. La primera vez se para y te da el comando para autorizar la deploy key. Desde tu equipo:
   ```bash
   ssh <vps> cat .ssh/salchipapanotes_deploy.pub >/tmp/openclaw-vps.pub
   gh repo deploy-key add /tmp/openclaw-vps.pub -R erickm13/SalchipapaNotes --allow-write -t openclaw-vps
   ```
   Al cambiar de VPS, borra la del anterior: `gh repo deploy-key list -R erickm13/SalchipapaNotes` y
   `gh repo deploy-key delete <id> -R erickm13/SalchipapaNotes`.
3. Si OpenClaw es nuevo: `openclaw onboard --install-daemon` (login de Codex por dispositivo, Gateway
   en loopback `127.0.0.1:18789`, bot de Telegram con su token oculto) y `loginctl enable-linger $USER`.
   Después, el pairing: `openclaw pairing list telegram` y `openclaw pairing approve telegram <CODIGO>`.
4. Repite `install.sh` (crea la automatización). El resultado del ingest llega por DM al dueño del bot
   (sale de `commands.ownerAllowFrom`; otro chat: `OPENCLAW_TELEGRAM_TO=<chat id>`).

Actualizar el skill o Dots: repetir `install.sh` (copia el skill de nuevo; no toca lo demás).

## Seguridad
- El Gateway escucha solo en loopback: el dashboard se abre con túnel SSH
  (`ssh -L 18789:127.0.0.1:18789 <vps>`); nunca abras el puerto 18789 en el Security Group.
- **Rotar el token del Gateway** si se expuso (p. ej. la salida de `openclaw dashboard --json`):
  `openclaw doctor --generate-gateway-token` (existe en 2026.10.3), `systemctl --user restart
  openclaw-gateway.service` y vuelve a abrir el dashboard (`openclaw gateway auth-token --show` lo
  muestra en la terminal del VPS: no lo copies a ningún chat).
- La deploy key solo da acceso a la bóveda; si el VPS se compromete, bórrala en GitHub y listo.
- Ningún token entra en este repo ni en la bóveda.

## Operación
- Ver el job: `openclaw automations list`; probarlo ya: `openclaw automations run <id> --wait`.
- Si el push falla, el motivo queda en `~/.cache/salchipapa-dots/vault-errors/push` y el log en
  `~/.cache/salchipapa-dots/vault-sync.log`.
- Gateway caído: `free -h`, `openclaw gateway status`,
  `journalctl --user -u openclaw-gateway.service -n 100 --no-pager`.
