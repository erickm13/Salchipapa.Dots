# Memoria compartida: bóveda de Obsidian de Erick

Todos los agentes (Claude Code, Codex, opencode, Copilot CLI) comparten como memoria la bóveda de Obsidian de
Erick, en `~/.config/obsidian` (repo privado `erickm13/SalchipapaNotes`). Es la memoria **a largo
plazo y entre equipos**. Responde a Erick en español.

## Sincronización: automática, no la hagas tú
- Al **empezar** cada sesión se suben los cambios que hubieran quedado pendientes y se hace `git pull`;
  al **terminar** se suben los cambios (hooks/plugins).
- **No ejecutes git en la bóveda** (ni pull, ni commit, ni push) salvo que Erick lo pida.
- La **nota diaria** (`daily/AAAA-MM-DD.md`) la escribe un trabajo automático cada noche: **no la
  crees ni la edites**, salvo que Erick lo pida.

## Bienvenida al empezar
En tu **primera respuesta** de cada sesión nueva, saluda a Erick en una línea y recuérdale en una o
dos líneas lo último que hizo y lo pendiente más relevante; después atiende lo que pida. **Excepción:** si el hook
de inicio ya te pasó ese resumen, Erick ya lo vio en pantalla: no lo repitas ni lo vuelvas a
saludar, atiende directamente. Si no te llegó ningún resumen, léelo tú de la nota más reciente de `daily/`
(secciones *Qué hice hoy*, *Mañana*, *Pendiente*) y de las tareas `- [ ]` de `projects/`.

## Estructura
| Carpeta | Qué hay |
|---|---|
| `me.md` | Quién es Erick: estudios, trabajo (QA), stack |
| `areas/<tema>/` | Conocimiento duradero por tema. Cada área tiene un hub `<id>-<tema>-hub.md` que enlaza sus notas: `linux`, `neovim`, `terminal` (herdr, kitty/WezTerm, fish, spotify_player, yt-x), `ia` (Claude Code, Codex, opencode), `programacion`, `qa`, `universidad` |
| `projects/` | Un archivo por proyecto (p. ej. `Salchipapa.Dots.md`, con su lista de Estado) |
| `daily/` | Notas diarias (las escribe el trabajo nocturno) |
| `templates/` | Plantillas (`daily.md`) |
| `limbo/` | Ideas sueltas sin clasificar |

## Cuándo leer
- Al empezar una tarea sobre un proyecto, herramienta o tema que pueda estar documentado, busca
  primero en la bóveda (`rg -i "<tema>" ~/.config/obsidian`) y lee la nota relevante (hub del área,
  nota del proyecto). Ahí están decisiones, comandos y problemas ya resueltos.

## Cuándo escribir
Solo conocimiento **duradero** y útil en otra sesión u otro equipo:
- Un comando, atajo o configuración nueva de una herramienta → la nota de esa herramienta en su área
  (o una nota nueva enlazada desde el hub).
- Un bug resuelto con su causa, o una decisión con su porqué → la nota del proyecto (`projects/`).
- Algo completado de la lista **Estado** de un proyecto → marcarlo `[x]`; una tarea nueva → `[ ]`.

No escribas: conversación del día, pasos intermedios, intentos fallidos sin conclusión ni nada que
ya esté en la nota.

## Cómo escribir
- Respeta el estilo de la nota: frontmatter (`id`, `aliases`, `tags`), tablas y bloques de código.
- Enlaces con `[[nombre-de-nota]]`. Al crear una nota nueva, enlázala desde el hub de su área.
- Edita lo justo: añade o corrige secciones; no reescribas notas enteras.
- En español, conciso.

## Nunca
- Secretos: tokens, claves de API, contraseñas, nada de `.env`. Si hace falta mencionarlos:
  "token de GitHub (revocado)", nunca su valor. La sincronización se niega a subir lo que parezca un secreto.
- Borrar o mover notas, o cambiar `.obsidian/`, sin que Erick lo pida.
