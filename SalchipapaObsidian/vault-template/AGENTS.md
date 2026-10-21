# Schema de la bóveda: LLM Wiki + Second Brain

Esta bóveda es la memoria a largo plazo del usuario y de sus agentes. Combina dos modelos:
- **LLM Wiki** (Karpathy): un LLM mantiene la wiki a partir de fuentes crudas, siguiendo este schema.
- **Building a Second Brain** (Tiago Forte): la wiki se ordena con PARA y sirve para CODE.

Este archivo es el **schema**: léelo antes de escribir en la bóveda. Lo hacen evolucionar el usuario y los
agentes: si una regla no funciona, propón el cambio al usuario (y anótalo en `log.md` como `schema`).
Quién es el usuario: `me.md`.

## Las 3 capas

| Capa | Dónde | Quién escribe | Regla |
|---|---|---|---|
| **1 · Fuentes crudas** | `raw/sesiones/`, `raw/web/`, `raw/docs/`, `raw/assets/` | Hook de cierre de sesión, Web Clipper, el usuario, OpenClaw (captura) | **Inmutables**: se añaden; nunca se editan, renombran ni borran |
| **2 · Wiki** | `projects/`, `areas/`, `resources/`, `archive/` + `index.md` + `log.md` | El LLM (y el usuario) | Ordenada con PARA; cada página con su frontmatter |
| **3 · Schema** | `AGENTS.md` (este), `CLAUDE.md`, `GEMINI.md`, `templates/` | El usuario, o un agente con su aprobación | — |

Fuera de las capas: `inbox/` (captura del usuario sin clasificar), `daily/` y `weekly/` (vistas de tiempo
que escriben las automatizaciones) y `me.md`.

## Capa 1 · Fuentes crudas (`raw/`)
- `sesiones/AAAA-MM-DD-HHMM-agente-<sesion>.md`: la conversación limpia de cada sesión (solo lo que dicen
  el usuario y el agente; los secretos aparecen como `[SECRETO]` y las menciones `[[nota]]` van escapadas,
  como texto). Solo la escribe el hook de cierre; si
  la sesión sigue después, lo nuevo va a otro archivo.
- `web/`: artículos (Obsidian Web Clipper). `docs/`: PDFs, material de clase, documentación.
  `assets/`: imágenes (carpeta de adjuntos de Obsidian).
- **Nunca** edites, renombres ni borres nada de `raw/`. Si una fuente está mal, corrígelo en la wiki.
- Una fuente está **pendiente de ingerir** si su ruta no aparece en `log.md`.

## Capa 2 · La wiki

### Dónde va cada página (PARA)
Pregúntate *"¿en qué es más accionable esto?"*:
1. **`projects/<Nombre>.md`**: esfuerzo con meta y final, activo ahora. Solo lleva el objetivo, las
   decisiones con su porqué, `## Entregables` y `## Estado` (`- [ ]`). La **referencia** (cómo funciona
   algo, comandos, configuración) **no va aquí**: va a `resources/` y se enlaza.
2. **`areas/<area>/`**: responsabilidad sin fecha de fin (trabajo, universidad…).
3. **`resources/<tema>/`**: referencia. Herramientas, conceptos, entidades (repos, programas, cursos),
   fuentes resumidas y respuestas guardadas.
4. **`archive/`**: proyectos terminados y áreas o recursos inactivos.
5. ¿No está claro? → **`inbox/`**, y el usuario lo clasifica después.

Cada carpeta de `areas/` y `resources/` tiene un **hub** `<id>-<tema>-hub.md` que enlaza todas sus
páginas. Tema nuevo → carpeta + hub, enlazado desde un hub relacionado.

### Tipos de página y frontmatter
Toda página de la wiki lleva este frontmatter (las anteriores a este schema se completan al editarlas):

```yaml
---
id: <slug-unico>
aliases: []
tipo: proyecto | area | hub | recurso | concepto | entidad | fuente
resumen: <una línea: qué es y para qué sirve (es su línea en index.md)>
fuentes: []          # de dónde sale lo escrito: "[[raw/web/…]]", "[[raw/sesiones/…]]" u otras páginas
actualizado: AAAA-MM-DD
tags: []
---
```

| `tipo` | Qué es | Plantilla |
|---|---|---|
| `proyecto` | Un proyecto de `projects/` | `templates/proyecto.md` |
| `area`, `hub` | El hub de un área o de un tema de recursos | `templates/hub.md` |
| `recurso` | Referencia de una herramienta o tema | `templates/recurso.md` |
| `entidad` | Algo concreto: un repo, un programa, un curso | `templates/recurso.md` |
| `concepto` | Una idea que aparece en varias fuentes | `templates/concepto.md` |
| `fuente` | Lo clave de una fuente de `raw/` | `templates/fuente.md` |

Si un valor lleva `: ` o empieza por un carácter especial, va entre comillas: `resumen: "Linux: Arch y paquetes"`
(sin ellas no es YAML válido y Obsidian muestra *Invalid properties*; `vault-lint.py` lo marca).

Las páginas de más de ~150 líneas llevan un `## Resumen` al principio.

### `index.md` y `log.md`
- **`index.md`**: catálogo de todas las páginas, ordenado por PARA, una línea por página con su
  `resumen`. Lo genera `vault-lint.py` desde el frontmatter: **no lo edites a mano**; para cambiar una
  línea, cambia el `resumen` de la página. Al buscar algo, léelo **primero** (mientras no exista, usa los hubs).
- **`log.md`**: registro cronológico; solo se añade al final. Cada entrada:
  ```
  ## [AAAA-MM-DD] ingest | raw/web/articulo.md
  - Páginas: [[pagina-a]], [[pagina-b]]
  ```
  Tipos: `ingest`, `query`, `lint`, `archive`, `schema`. Últimas: `grep "^## \[" log.md | tail -5`.

## Operaciones

### Ingest (una fuente → la wiki)
1. Lee la fuente completa.
2. Crea su página `tipo: fuente` en `resources/<tema>/` con lo clave (lo más importante en **negrita**).
   Excepción: las de `raw/sesiones/` ya tienen su resumen en la diaria, así que no llevan página `fuente`.
3. Actualiza las páginas que toca: Estado y decisiones del proyecto, recursos, conceptos y entidades.
   Crea un concepto o una entidad si aparece en dos o más fuentes o es central. Añade la fuente a
   `fuentes` y pon `actualizado`.
4. Si contradice lo que ya está escrito, **no lo borres**: anótalo en la página con las dos fuentes:
   `> [!warning] Contradicción: …`.
5. Enlaza cada página nueva desde su hub.
6. Añade la entrada `ingest` a `log.md`.

### Query (preguntas sobre la bóveda)
1. Lee `index.md`, luego las páginas relevantes; cita con `[[enlaces]]`.
2. Si la respuesta vale la pena (comparación, análisis, decisión, solución a un problema), guárdala
   como página (`recurso` o `concepto`): es un *paquete intermedio*. Enlázala desde su hub y, si sirve
   a un proyecto, desde su `## Entregables`. Añade `query` a `log.md`. Si dudas de que valga la pena, pregunta.

### Lint (salud de la wiki)
- `vault-lint.py` revisa lo mecánico: frontmatter, enlaces rotos, páginas huérfanas, `raw/`
  modificado, proyectos con referencia dentro, cobertura de `index.md`.
- La **revisión semanal** (lunes) añade lo que necesita criterio: contradicciones, datos viejos,
  conceptos sin página, enlaces que faltan, huecos que una búsqueda llenaría. Todo como propuestas
  `- [ ]` en `weekly/AAAA-Wnn.md`: **no se aplica sola**.
- Cuando el usuario diga *"aplica la revisión semanal"*: abre la `weekly/` más reciente, aplica cada
  propuesta `- [ ]` de **Propuestas** (mueve la nota, enlázala desde el hub de su destino; si es un
  proyecto archivado, quítalo de `me.md`), márcala `[x]` (o `[x] (descartada)` si el usuario la
  descarta), añade `lint` a `log.md` y dile en una línea qué moviste.

## Second Brain (CODE)
| Paso | Dónde |
|---|---|
| **Capture** | `inbox/` (el usuario) y `raw/` (fuentes) |
| **Organize** | PARA + revisión semanal |
| **Distill** | `raw/` → página `fuente` con lo clave → `resumen` en `index.md`; `## Resumen` en las páginas largas |
| **Express** | Respuestas guardadas (paquetes intermedios) + `## Entregables` de cada proyecto |

## Ciclo de vida
- **Proyecto nuevo** (el usuario empieza algo con una meta): `projects/<Nombre>.md` desde
  `templates/proyecto.md`, enlazado desde `me.md` (sección Proyectos).
- **Proyecto terminado** (el usuario dice que lo cerró): muévelo a `archive/`, quítalo de `me.md`,
  pasa a `resources/` lo que siga sirviendo y añade `archive` a `log.md`.

## Cómo escribir
- Enlaces `[[nombre-de-nota]]`, sin carpeta (Obsidian los resuelve por nombre). Nunca `[[url]]`: para
  URLs usa `[texto](url)`.
- Edita lo justo: añade o corrige secciones; no reescribas notas enteras.
- Solo conocimiento duradero y útil en otra sesión u otro equipo. No guardes conversación, pasos
  intermedios ni intentos fallidos sin conclusión.
- Conciso y en español.

## Nunca
- Secretos: tokens, claves de API, contraseñas, nada de `.env`. Si hace falta mencionarlos:
  "token de GitHub (revocado)", nunca su valor.
- Editar, renombrar o borrar algo de `raw/`.
- Mover o borrar notas, o cambiar `.obsidian/`, sin que el usuario lo pida (salvo archivar un proyecto
  que dio por terminado o aplicar la revisión semanal cuando la pide).
- Editar `daily/` o `index.md` a mano, salvo que el usuario lo pida.
- Ejecutar git en la bóveda: la sincronización es automática.
