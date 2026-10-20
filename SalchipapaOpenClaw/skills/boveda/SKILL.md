---
name: boveda
description: Bóveda de Obsidian del usuario (su memoria y segundo cerebro, un LLM Wiki). Úsalo para guardar lo que manda (enlaces, archivos, ideas), para el ingest de las fuentes de raw/, para responder preguntas sobre sus notas, proyectos o lo que ha hecho, y para revisar la salud de la bóveda ("salud", "health check", "¿cómo está mi bóveda?").
metadata: { "openclaw": { "requires": { "bins": ["git", "python3", "flock"] } } }
---

# Bóveda de Obsidian (LLM Wiki)

La bóveda está en `~/.config/obsidian` (repo privado de GitHub, se sube con una deploy key que solo
sirve para él). Sus reglas están en **`~/.config/obsidian/AGENTS.md`** (el schema): **léelo antes de
escribir**. Quién es el usuario: `me.md`. Responde en español.

Scripts (`DOTS=~/Salchipapa.Dots/SalchipapaObsidian`):
- `bash $DOTS/vault-sync.sh pull openclaw`: baja lo último. **Siempre antes de leer o escribir.**
- `bash $DOTS/vault-sync.sh push openclaw`: commit + push. **Siempre al terminar si escribiste algo.**
  Se niega a subir secretos o cambios a archivos existentes de `raw/`; si falla, el motivo está en
  `~/.cache/salchipapa-dots/vault-errors/push`: díselo al usuario.
- `python3 $DOTS/vault-lint.py --json`: hallazgos y fuentes `pendientes` de ingerir.

No ejecutes otros comandos de git en la bóveda, salvo `git -C ~/.config/obsidian checkout -- raw/`
para deshacer un cambio tuyo en `raw/`.

## Captura (lo que el usuario manda por Telegram)
1. `pull`.
2. Según lo que llegue:
   - **Enlace** → descarga la página y guárdala en `raw/web/AAAA-MM-DD-<slug>.md`: frontmatter con
     `url`, `titulo` y `capturado: AAAA-MM-DD`, y debajo el texto del artículo en markdown (sin menús
     ni anuncios). Es la fuente cruda: no la resumas.
   - **Archivo** (PDF, documento) → cópialo tal cual a `raw/docs/AAAA-MM-DD-<nombre>`; una imagen,
     a `raw/assets/`.
   - **Idea o nota suya** (texto sin enlace) → `inbox/AAAA-MM-DD-HHMM-<slug>.md` con su texto literal.
     Se clasifica en la revisión semanal.
   Si el archivo ya existe, usa otro nombre: **nunca** sobrescribas nada de `raw/`.
3. `push` y contesta con este formato, en una línea:
   - Fuente en `raw/`: `✔ Guardado: raw/web/2026-10-20-ejemplo.md · ⏳ pendiente de ingest (esta noche) · ¿Lo ingiero ahora?`
   - Idea en `inbox/`: `✔ Guardado: inbox/2026-10-20-1530-ejemplo.md · se clasifica en la revisión semanal`
   - Si el push falló: `⚠ Guardado aquí pero no subido: <motivo de vault-errors/push>`
4. Si responde que sí (o pidió el ingest al mandarlo), haz el **Ingest** de esa fuente sola y contesta
   `✔ Ingerido: raw/… → [[pagina-a]], [[pagina-b]]` (o `✔ Ingerido: raw/… → sin cambios en la wiki`).
   Si no contesta, se integra sola en el ingest de la noche.

## Ingest (fuentes de `raw/` → la wiki)
1. `pull`. Pendientes: `pendientes` de `vault-lint.py --json` (las que no están en `log.md`). Como
   mucho 10 por vez, las más antiguas primero.
2. Para cada una, sigue la sección **Ingest** de `AGENTS.md`: lee la fuente completa; página
   `tipo: fuente` en `resources/<tema>/` (salvo las de `raw/sesiones/`, que ya tienen resumen en la
   diaria); actualiza las páginas que toca (Estado de proyectos, recursos, conceptos); contradicciones
   como `> [!warning]`; enlaza lo nuevo desde su hub.
3. Al final de `log.md`, una entrada por fuente, aunque no cambie nada:
   ```
   ## [AAAA-MM-DD] ingest | <ruta de la fuente>
   - Páginas: [[pagina-a]], [[pagina-b]]   (o "- Sin cambios en la wiki")
   ```
4. Si tocaste `raw/` por error: `git -C ~/.config/obsidian checkout -- raw/`. Luego `push`.
5. Responde en 2-3 líneas: cuántas fuentes, qué páginas cambiaron y cuántas quedan pendientes.

Solo hechos que estén en las fuentes; nada de conversación ni pasos intermedios.

## Salud ("salud de la bóveda", "health check", "¿cómo está mi bóveda?")
Solo lectura: no corrijas nada aquí; si el usuario quiere arreglar algo, hazlo después, aparte.
1. `pull`. Si falló, ese es el primer punto del informe.
2. `python3 $DOTS/vault-lint.py --json`:
   - `graves`: problemas que hacen fallar *Verificar bóveda* (frontmatter roto, secreto, `raw/` modificado).
   - `avisos`: cuántos y los 2-3 primeros.
   - `pendientes`: fuentes de `raw/` sin ingerir. Una sesión de `raw/sesiones/` se ingiere la noche
     siguiente; si alguna tiene **más de un día** (fecha del nombre), el ingest nocturno está fallando.
     Es el **único** criterio: tener pendientes o no ver entradas `ingest` en `log.md` no es un fallo.
     Cuenta los días en la zona del usuario, no en la del servidor (UTC): `TZ=America/Guatemala date +%F`.
   - `info`: notas en `inbox/` por clasificar.
3. Errores de subida en este servidor: archivos de `~/.cache/salchipapa-dots/vault-errors/` (su texto).
4. Último ingest y último lint: `grep "^## \[" ~/.config/obsidian/log.md | grep -E " (ingest|lint) " | tail -2`.
5. Revisión semanal: en la `weekly/AAAA-Wnn.md` más reciente, cuántas `- [ ]` quedan en `## Propuestas`.
6. Responde en 5-6 líneas, una por punto, con ✔ o ⚠, y al final una línea con lo más urgente
   (o `Todo en orden`). Ejemplo:
   ```
   ✔ Sincronizada con GitHub
   ✔ Sin problemas graves · ⚠ 3 avisos (frontmatter de [[x]], …)
   ⚠ 2 fuentes sin ingerir, 1 de hace 3 días: el ingest nocturno falla
   ✔ inbox/ vacía · último ingest 2026-10-20
   ⚠ Revisión semanal 2026-W43: 4 propuestas sin aplicar
   Lo más urgente: revisar el ingest nocturno.
   ```

## Consulta (preguntas sobre la bóveda)
1. `pull`. Lee `index.md` primero (una línea por página) y luego las páginas relevantes. Para lo que
   hizo hoy o en días concretos: `daily/AAAA-MM-DD.md` (`## Sesiones de hoy`).
2. Responde breve (es Telegram), citando las páginas por su nombre.
3. Si la respuesta vale la pena guardarla (comparación, análisis, decisión), pregunta al usuario; si
   dice que sí, guárdala según la sección **Query** de `AGENTS.md` (página + `query` en `log.md`) y `push`.

## Nunca
- Escribir secretos (tokens, claves, contraseñas) en la bóveda ni en el chat.
- Editar, renombrar o borrar algo de `raw/`; editar `daily/`, `index.md` o `.obsidian/`.
- Mover o borrar notas sin que el usuario lo pida.
