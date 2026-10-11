# Claude Code — hooks

Hooks de Claude Code que convierten en barreras automáticas errores que ya pasaron trabajando en
estos dotfiles. `install.sh` los activa en `~/.claude/settings.json` (solo añade los que falten y
guarda una copia en `settings.json.bak`). Verlos o desactivarlos: `/hooks` dentro de Claude Code.

| Script | Evento | Qué hace |
| ------ | ------ | -------- |
| [`hooks/validate-dotfiles.py`](hooks/validate-dotfiles.py) | Después de `Edit`/`Write` | En archivos de `~/Salchipapa.Dots` (también editados vía los symlinks de `~/.config`): `bash -n` + `shellcheck -S error` para scripts, `fish -n` para fish, recarga herdr y avisa si rechaza algo de `SalchipapaHerdr/config.toml`, y en WSL copia `SalchipapaWezterm/.wezterm.lua` a la carpeta de Windows. Un error se le devuelve a Claude para que lo corrija. |
| [`hooks/guard-bash.py`](hooks/guard-bash.py) | Antes de `Bash` | Bloquea `pkill -f` / `killall` (un patrón puede matar procesos del usuario: cerró una sesión real de herdr) y `sed -i` sobre un symlink (lo convierte en archivo normal y el cambio no llega al repo). |
| [`hooks/secret-scan.py`](hooks/secret-scan.py) | Antes de `Bash` | En `git commit` / `git push`, busca tokens de GitHub, claves de Google, `sk-…`, `oma_…` y claves privadas en lo que se va a subir. Si hay alguno, bloquea y dice el archivo, sin mostrar el secreto. |

Requisitos: `python3` y `jq` (el instalador los instala en Arch).

Los dos hooks de `Bash` actúan en cualquier proyecto donde uses Claude Code; el de validación
solo mira archivos de este repo.
