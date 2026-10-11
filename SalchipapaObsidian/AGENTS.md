# Memoria compartida: bóveda de Obsidian

Todos los agentes (Claude Code, Codex, opencode, Copilot CLI) comparten como memoria la bóveda de
Obsidian del usuario, en `~/.config/obsidian` (un repo git privado). Es la memoria **a largo plazo y
entre equipos**. Quién es el usuario (nombre, trabajo, estudios, stack, proyectos) está en `me.md`:
léelo si necesitas contexto sobre él. Responde en su idioma (el de sus notas).

## Sincronización: automática, no la hagas tú
- Al **empezar** cada sesión se suben los cambios que hubieran quedado pendientes y se hace `git pull`;
  al **terminar** se suben los cambios (hooks/plugins).
- **No ejecutes git en la bóveda** (ni pull, ni commit, ni push) salvo que el usuario lo pida.
- La **nota diaria** (`daily/AAAA-MM-DD.md`) se escribe sola: al **cerrar cada sesión** (en cualquier
  equipo) se añade un resumen en `## Sesiones de hoy`, y a las 00:10 un trabajo automático la completa
  con las secciones de la plantilla. **No la crees ni la edites**, salvo que el usuario lo pida.
- Para saber qué hizo el usuario **hoy** (quizá en otro equipo), lee `## Sesiones de hoy` de la diaria
  de hoy.

## Bienvenida al empezar
En tu **primera respuesta** de cada sesión nueva, saluda al usuario en una línea y recuérdale en una
o dos líneas lo último que hizo y lo pendiente más relevante; después atiende lo que pida.
**Excepción:** si el hook de inicio ya te pasó ese resumen, el usuario ya lo vio en pantalla: no lo
repitas ni lo vuelvas a saludar, atiende directamente. Si no te llegó ningún resumen, léelo tú de la
nota más reciente de `daily/` (secciones *Qué hice hoy*, *Mañana*, *Pendiente*) y de las tareas
`- [ ]` de `projects/`.

## Estructura: PARA (Building a Second Brain, Tiago Forte)
Las notas se ordenan por **qué tan accionables son**, no por tema:

| Carpeta | PARA | Qué va ahí |
|---|---|---|
| `projects/` | **Projects** | Esfuerzos **con meta y final**, activos ahora. Un archivo por proyecto con su objetivo y su lista **Estado** (`- [ ]`) |
| `areas/<area>/` | **Areas** | **Responsabilidades** que el usuario mantiene sin fecha de fin (trabajo, estudios, salud…) |
| `resources/<tema>/` | **Resources** | Temas que **consulta**: herramientas, lenguajes, cómo funciona algo |
| `archive/` | **Archives** | Proyectos terminados y áreas o recursos inactivos |
| `inbox/` | Captura | Ideas y notas sueltas sin clasificar todavía |
| `daily/` | Diario | Notas diarias: `## Sesiones de hoy` (resumen al cerrar cada sesión) + secciones de la plantilla (trabajo de las 00:10) |
| `weekly/` | Revisión semanal | `AAAA-Wnn.md`: resumen de la semana y **Propuestas** para ordenar la bóveda (las escribe un trabajo los lunes a las 00:40) |
| `templates/` | — | Plantillas (`daily.md`) |
| `me.md` | — | Quién es el usuario |

Cada carpeta de `areas/` y `resources/` tiene un **hub** `<id>-<tema>-hub.md` que enlaza sus notas.
Para ver qué áreas y recursos existen, lista esas carpetas (`ls ~/.config/obsidian/{areas,resources}`).

## Cuándo leer
- Al empezar una tarea sobre un proyecto, herramienta o tema que pueda estar documentado, busca
  primero en la bóveda (`rg -i "<tema>" ~/.config/obsidian`) y lee la nota relevante (nota del
  proyecto, hub del recurso o del área). Ahí están decisiones, comandos y problemas ya resueltos.
- `archive/` solo si buscas algo de un proyecto ya cerrado.

## Cuándo escribir y dónde (PARA)
Solo conocimiento **duradero** y útil en otra sesión u otro equipo. Para decidir la carpeta,
pregúntate *"¿en qué es más accionable esto?"*:
1. ¿Sirve para un **proyecto activo**? → su nota en `projects/`: bugs resueltos con su causa,
   decisiones con su porqué, y la lista **Estado** (completado → `[x]`, tarea nueva → `[ ]`).
2. ¿Es de una **responsabilidad continua** (trabajo, estudios…)? → `areas/<area>/`.
3. ¿Es **referencia** de una herramienta o tema (comando, atajo, configuración, cómo funciona
   algo)? → la nota de esa herramienta en `resources/<tema>/`, o una nota nueva enlazada desde su hub.
4. ¿No está claro? → `inbox/`, y el usuario la clasifica después.

Ciclo de vida:
- **Proyecto nuevo** (el usuario empieza algo con una meta) → crea `projects/<Nombre>.md` con
  objetivo, descripción y lista **Estado**, y enlázalo desde `me.md` (sección Proyectos).
- **Proyecto terminado** (el usuario dice que lo cerró) → muévelo a `archive/`, quítalo de Proyectos
  en `me.md`, y pasa a `resources/` lo que siga sirviendo como referencia.
- Un tema de `resources/` (o un área) nuevo → carpeta `resources/<tema>/` con su hub.
- Nunca guardes conocimiento de referencia en `projects/` ni proyectos en `resources/`.

## Revisión semanal
Cada lunes a las 00:40 un trabajo automático escribe `weekly/AAAA-Wnn.md` con propuestas `- [ ]` (mover
notas de `inbox/`, archivar proyectos, borrar notas vacías). **No las apliques por tu cuenta.**
Cuando el usuario diga *"aplica la revisión semanal"* (o similar):
1. Abre la `weekly/` más reciente y aplica cada propuesta `- [ ]` de **Propuestas**: mueve la nota,
   enlázala desde el hub de su destino, y si es un proyecto archivado, quítalo de `me.md`.
2. Marca cada una `[x]` al terminarla. Si el usuario descarta alguna, márcala `[x]` con *(descartada)*.
3. Al final, dile en una línea qué moviste.
Solo esa vez puedes mover o borrar las notas que nombran las propuestas.

No escribas: conversación del día, pasos intermedios, intentos fallidos sin conclusión ni nada que
ya esté en la nota.

## Cómo escribir
- Respeta el estilo de la nota: frontmatter (`id`, `aliases`, `tags`), tablas y bloques de código.
- Enlaces con `[[nombre-de-nota]]` (sin carpeta: Obsidian los resuelve por nombre, así mover notas
  no los rompe). Al crear una nota nueva, enlázala desde el hub de su área o recurso.
- Edita lo justo: añade o corrige secciones; no reescribas notas enteras.
- Conciso, en el idioma del usuario.

## Nunca
- Secretos: tokens, claves de API, contraseñas, nada de `.env`. Si hace falta mencionarlos:
  "token de GitHub (revocado)", nunca su valor. La sincronización se niega a subir lo que parezca un secreto.
- Borrar notas, moverlas (salvo archivar un proyecto que el usuario dio por terminado o aplicar la
  revisión semanal cuando la pide) o cambiar `.obsidian/`, sin que el usuario lo pida.
