# Memoria compartida: bóveda de Obsidian

Todos los agentes (Claude Code, Codex, opencode, Copilot CLI, Gemini CLI) comparten como memoria la bóveda de
Obsidian del usuario, en `~/.config/obsidian` (un repo git privado). Es la memoria **a largo plazo y
entre equipos**. Quién es el usuario (nombre, trabajo, estudios, stack, proyectos) está en `me.md`:
léelo si necesitas contexto sobre él. Responde en su idioma (el de sus notas).

## El schema está en la bóveda
La bóveda es un **LLM Wiki** (Karpathy) ordenado con **PARA** (Tiago Forte). Sus reglas (capas, dónde
va cada nota, frontmatter, cómo hacer ingest, query y lint, `index.md` y `log.md`) están en
**`~/.config/obsidian/AGENTS.md`**. **Léelo antes de escribir en la bóveda**, aunque trabajes en otro
directorio. Para solo consultar basta con esto:
- Busca primero en `~/.config/obsidian/index.md` (si existe) o con `rg -i "<tema>" ~/.config/obsidian`, y
  lee la nota relevante (nota del proyecto, hub del recurso o del área). Ahí están decisiones, comandos
  y problemas ya resueltos. `archive/` solo si buscas algo de un proyecto ya cerrado.
- Si respondes algo que valga la pena conservar (comparación, análisis, decisión, solución), guárdalo
  como página de la wiki: sección *Query* del schema.

## Sincronización: automática, no la hagas tú
- Al **empezar** cada sesión se suben los cambios que hubieran quedado pendientes y se hace `git pull`;
  al **terminar** se suben los cambios (hooks/plugins).
- **No ejecutes git en la bóveda** (ni pull, ni commit, ni push) salvo que el usuario lo pida.
- La **nota diaria** (`daily/AAAA-MM-DD.md`) se escribe sola: al **cerrar cada sesión** (en cualquier
  equipo) se añade un resumen en `## Sesiones de hoy`, y a las 00:10 un trabajo automático la completa
  con las secciones de la plantilla. **No la crees ni la edites**, salvo que el usuario lo pida.
- Para saber qué hizo el usuario **hoy** (quizá en otro equipo), lee `## Sesiones de hoy` de la diaria
  de hoy.
- Cada lunes a las 00:40 un trabajo automático escribe `weekly/AAAA-Wnn.md` con propuestas `- [ ]`.
  **No las apliques por tu cuenta**: solo cuando el usuario diga *"aplica la revisión semanal"*
  (el procedimiento está en el schema).

## Bienvenida al empezar
En tu **primera respuesta** de cada sesión nueva, saluda al usuario en una línea y recuérdale en una
o dos líneas lo último que hizo y lo pendiente más relevante; después atiende lo que pida.
**Excepción:** si el hook de inicio ya te pasó ese resumen, el usuario ya lo vio en pantalla: no lo
repitas ni lo vuelvas a saludar, atiende directamente. Si no te llegó ningún resumen, léelo tú de la
nota más reciente de `daily/` (secciones *Qué hice hoy*, *Mañana*, *Pendiente*) y de las tareas
`- [ ]` de `projects/`.

## Cuándo escribir
Solo conocimiento **duradero** y útil en otra sesión u otro equipo: decisiones con su porqué, bugs
resueltos con su causa, cambios en el **Estado** de un proyecto, referencia de una herramienta, y
respuestas que valga la pena guardar. Dónde y cómo, según el schema. Si no está claro, a `inbox/`.

## Nunca
- Secretos: tokens, claves de API, contraseñas, nada de `.env`. Si hace falta mencionarlos:
  "token de GitHub (revocado)", nunca su valor. La sincronización se niega a subir lo que parezca un secreto.
- Editar, renombrar o borrar algo de `raw/` (fuentes crudas, inmutables).
- Borrar notas, moverlas (salvo archivar un proyecto que el usuario dio por terminado o aplicar la
  revisión semanal cuando la pide) o cambiar `.obsidian/`, sin que el usuario lo pida.
