# Herdr — guía de atajos y comandos

[Herdr](https://herdr.dev) es el multiplexor de terminal de estos dotfiles: paneles, pestañas y
sesiones que siguen vivas aunque cierres la terminal, con detección de agentes de IA
(Claude Code, Codex…) y soporte para las imágenes de kitty.

- Configuración: [`config.toml`](config.toml), enlazado en `~/.config/herdr/config.toml`
- Prefijo: **`Ctrl+g`** (como en zellij). Los atajos con prefijo se hacen así: `Ctrl+g`, soltar, y la tecla.
- Lista completa dentro de herdr: `Ctrl+g ?`

> Los atajos con `Alt` los captura herdr antes que el programa del panel. Por ejemplo, en fish
> `Alt ←`/`Alt →` ya no saltan por palabras y `Alt d` no borra la palabra siguiente.

---

## Atajos directos (sin prefijo)

|              | Crear                                  | Moverse                         | Cerrar        |
| ------------ | -------------------------------------- | ------------------------------- | ------------- |
| **Paneles**  | `Alt n` (derecha) · `Alt d` (abajo)    | `Alt h` `j` `k` `l` / `Alt` + flechas | `Alt x`       |
| **Pestañas** | `Alt t`                                | `Alt Shift h` / `Alt Shift l`   | `Alt Shift x` |

| Teclas                       | Acción                                         |
| ---------------------------- | ---------------------------------------------- |
| `Alt n`                      | Nuevo panel a la derecha                       |
| `Alt d`                      | Nuevo panel abajo                              |
| `Alt h` / `Alt l`            | Ir al panel de la izquierda / derecha          |
| `Alt j` / `Alt k`            | Ir al panel de abajo / arriba                  |
| `Alt ←` `↓` `↑` `→`          | Lo mismo con flechas                           |
| `Alt x`                      | Cerrar el panel actual                         |
| `Alt t`                      | Nueva pestaña (con nombre aleatorio)           |
| `Alt Shift h` / `Alt Shift l`| Pestaña anterior / siguiente                   |
| `Alt i` / `Alt o`            | Mover la pestaña actual a la izquierda / derecha (cambia el orden) |
| `Alt Shift x`                | Cerrar la pestaña actual con todos sus paneles |

> **Cuidado:** cerrar un panel o una pestaña termina lo que tenga corriendo (un agente a
> medias, un nvim sin guardar…). No pide confirmación.

---

## Atajos con prefijo (`Ctrl+g` + tecla)

### Paneles

| Teclas                    | Acción                                              |
| ------------------------- | --------------------------------------------------- |
| `Ctrl+g` `v`              | Nuevo panel a la derecha                            |
| `Ctrl+g` `-`              | Nuevo panel abajo                                   |
| `Ctrl+g` `h` `j` `k` `l`  | Moverse entre paneles                               |
| `Ctrl+g` `Tab` / `Shift+Tab` | Panel siguiente / anterior                       |
| `Ctrl+g` `z`              | Ampliar el panel a pantalla completa (otra vez para volver) |
| `Ctrl+g` `r`              | Modo redimensionar (flechas para ajustar, `Esc` para salir) |
| `Ctrl+g` `Shift+p`        | Renombrar el panel                                  |
| `Ctrl+g` `e`              | Abrir el historial del panel en el editor (nvim)    |
| `Ctrl+g` `x`              | Cerrar el panel                                     |

### Pestañas

| Teclas                | Acción                       |
| --------------------- | ---------------------------- |
| `Ctrl+g` `c`          | Nueva pestaña                |
| `Ctrl+g` `n` / `p`    | Pestaña siguiente / anterior |
| `Ctrl+g` `1`…`9`      | Ir a la pestaña número N     |
| `Ctrl+g` `Shift+t`    | Renombrar la pestaña         |
| `Ctrl+g` `Shift+x`    | Cerrar la pestaña            |

### Workspaces (un proyecto o tarea cada uno)

| Teclas                | Acción                                                         |
| --------------------- | -------------------------------------------------------------- |
| `Ctrl+g` `w`          | Elegir workspace                                               |
| `Ctrl+g` `Shift+n`    | Nuevo workspace                                                |
| `Ctrl+g` `Shift+g`    | Nuevo workspace en un git worktree (una rama por workspace)    |
| `Ctrl+g` `Shift+w`    | Renombrar workspace                                            |
| `Ctrl+g` `Shift+d`    | Cerrar workspace                                               |

### General

| Teclas                | Acción                                                      |
| --------------------- | ----------------------------------------------------------- |
| `Ctrl+g` `?`          | Ver todos los atajos                                        |
| `Ctrl+g` `s`          | Ajustes                                                     |
| `Ctrl+g` `b`          | Mostrar / ocultar la barra lateral (spaces y agents)        |
| `Ctrl+g` `o`          | Ir a lo que señala la notificación visible (el agente que te necesita) |
| `Ctrl+g` `g`          | Navegador de sesiones (cambiar entre sesiones con nombre)   |
| `Ctrl+g` `Shift+r`    | Recargar la configuración                                   |
| `Ctrl+g` `q`          | Salir sin cerrar nada (todo sigue corriendo)                |

---

## Ratón

- Clic en un panel o pestaña para enfocarlo; clic en `+` para crear una pestaña.
- Arrastrar los bordes para cambiar el tamaño de los paneles.
- Clic derecho para el menú (dividir, cerrar…).
- Seleccionar arrastrando para copiar.

---

## Comandos

```bash
herdr                           # entrar (o volver) a la sesión
herdr status                    # estado del servidor y del cliente
herdr server stop               # cerrar herdr de verdad (todo lo que corre dentro)
herdr server reload-config      # aplicar cambios de config.toml sin reiniciar
herdr update                    # actualizar herdr

herdr session list              # sesiones guardadas
herdr session attach trabajo    # usar una sesión con nombre, separada de la principal

herdr agent list                # agentes detectados y su estado
herdr integration status        # integraciones (el instalador pone claude, codex y opencode)
herdr integration install claude  # mejor detección de estado y restaurar sesiones del agente
herdr tab list / herdr pane list  # pestañas y paneles (JSON)

herdr --remote usuario@host     # conectarse a herdr en otra máquina por SSH
herdr --default-config          # ver todas las opciones de configuración
```

### Estados de los agentes

| Estado    | Significado                               |
| --------- | ----------------------------------------- |
| `working` | Trabajando                                |
| `blocked` | Esperándote (una pregunta o un permiso)   |
| `done`    | Terminó                                   |
| `idle`    | Sin actividad                             |
| `unknown` | No se sabe                                |

---

## Integración con fish (`SalchipapaFish/fish/config.fish`)

- **Se abre solo al abrir kitty.** Solo en ventanas de kitty (no en VS Code, Windows Terminal
  ni SSH) y nunca dentro de herdr o zellij.
- **Cerrar:**
  - `exit` en el **último panel** que queda: apaga herdr, cierra la ventana de kitty y borra la
    sesión guardada, así que la próxima vez empieza de cero con `shell` + `nvim`.
  - `Ctrl+g q`: sale de herdr y cierra la ventana, pero herdr sigue corriendo en segundo plano;
    al abrir kitty vuelves a todo tal cual.
  - Si herdr falla al arrancar, la ventana no se cierra y se ve el error.
- **Nombres de pestañas.** Un workspace nuevo arranca con las pestañas `shell` y `nvim`; las
  pestañas nuevas sin nombre reciben uno aleatorio estilo `adjetivo-animal` (`cosmic-badger`).
  Herdr no tiene nombre por defecto: sin esto, las pestañas muestran su posición (1, 2, 3…).
- **fastfetch con imagen.** Dentro de herdr, fish espera (máx. 1 s) a que el panel conozca su
  tamaño en píxeles antes de lanzar fastfetch; si no, a veces cae al logo ASCII de Arch.

## Configuración (`config.toml`)

| Opción                                   | Qué hace                                             |
| ---------------------------------------- | ---------------------------------------------------- |
| `prefix = "ctrl+g"`                      | Prefijo como en zellij                               |
| `sidebar_start_collapsed` + `sidebar_collapsed_mode = "hidden"` | Barra lateral oculta al arrancar (`Ctrl+g b`) |
| `accent = "#268bd3"`                     | Azul Solarized Osaka (la pestaña activa de zellij)   |
| `tab_bar_right`                          | `ZOOM` al ampliar un panel y la fecha (formato de zellij) |
| `prompt_new_tab_name = false`            | Las pestañas se crean al instante, sin pedir nombre  |

No se puede replicar de zjstatus: estilo de las pestañas (solo el color de acento), indicador
de modo, barra de atajos inferior ni la rama de git (los comandos de la barra corren en el
servidor de herdr, no en la carpeta del panel). Tampoco hay paneles flotantes ni layouts.
