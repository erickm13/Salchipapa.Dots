# keys: chuleta del setup de Salchipapa.Dots en la terminal (comandos propios, abreviaturas, teclas
# de fish, de fzf y de atuin). Las abreviaturas se leen en vivo de `abbr --show`; lo demás está
# escrito aquí: al añadir un comando o un atajo, añádelo también a esta lista.
# Uso: `keys` lo muestra todo; `keys <sección>` solo una (shell, git, lazygit, nvim, herdr).
# `keys --json [sección]`: lo mismo en JSON ([{section, key, desc}]) para el glosario de
# Salchipapa-Shell (Super+/, pestaña Terminal), así la lista vive en un solo sitio.
function keys --description "Chuleta: comandos, abreviaturas y teclas de este setup"
    if test "$argv[1]" = --json
        # Cada fila sale como "sección<TAB>tecla<TAB>descripción" y jq la convierte
        set -lx __keys_tsv 1
        keys $argv[2..] | jq -Rn '[inputs | split("\t") | select(length == 3) | {section: .[0], key: .[1], desc: .[2]}]'
        return
    end
    set -l secciones shell git lazygit nvim herdr
    set -l ver $secciones
    if set -q argv[1]
        if not contains -- $argv[1] $secciones
            echo "Secciones: $secciones"
            return 1
        end
        set ver $argv[1]
    end

    set -l h (set_color --bold blue)
    set -l k (set_color green)
    set -l d (set_color normal)
    set -l g (set_color brblack)

    set -l seccion
    function __keys_section --no-scope-shadowing --argument-names titulo nota
        set seccion $titulo
        set -q __keys_tsv; and return
        echo $h$titulo$g$nota$d
    end
    function __keys_row --no-scope-shadowing --argument-names key desc
        if set -q __keys_tsv
            printf '%s\t%s\t%s\n' $seccion (string trim -- $key) (string trim -- $desc)
        else
            printf '  %s%-22s%s %s\n' $k $key $d $desc
        end
    end

    if contains shell $ver
        __keys_section "Comandos"
        __keys_row "ff [texto]" "buscar y abrir (dir → cd, texto → nvim, PDF/imagen → su app)"
        __keys_row "fif [texto]" "buscar DENTRO de los archivos; Enter abre nvim en la línea"
        __keys_row "fbr [texto]" "cambiar de rama de git"
        __keys_row "zi" "directorios frecuentes (zoxide)   ·   z <nombre>  saltar directo"
        __keys_row "y [ruta]" "yazi; al salir con q te quedas en ese directorio"
        __keys_row "fpi / fpr [texto]" "buscar e instalar / quitar paquetes (Tab marca varios)"
        __keys_row "typioca" "test de mecanografía"
        __keys_row "tldr <cmd>" "ejemplos cortos de un comando"
        __keys_row "cpwd" "copiar el directorio actual (con ~) al portapapeles"
        __keys_row "theme [nombre]" "tema de nvim + herdr a la vez (sin nombre: actual y lista)"
        set -q __keys_tsv; or echo

        __keys_section "Abreviaturas" "  (se expanden al pulsar espacio)"
        for line in (abbr --show)
            # abbr -a [opciones] -- nombre 'expansión'
            set -l parts (string match -r -- '-- (\S+) (.*)$' $line)
            test (count $parts) -eq 3; or continue
            __keys_row $parts[2] (string trim -c "'" -- $parts[3] | string replace '%' '▏')
        end
        set -q __keys_tsv; or echo

        __keys_section "En la línea de comandos"
        __keys_row "Ctrl+T" "buscar archivos: inserta la ruta; con la línea vacía, la abre"
        __keys_row "Alt+C" "buscar un directorio y entrar"
        __keys_row "Ctrl+R / ↑" "historial (atuin): todo / solo este directorio"
        __keys_row "Ctrl+Alt+L / S" "git log / git status con fzf"
        __keys_row "Ctrl+Alt+P / E" "procesos / variables con fzf"
        __keys_row "Alt+S" "añadir o quitar sudo"
        __keys_row "Alt+H" "man del comando que escribes (necesita man-db)"
        __keys_row "Alt+← / Alt+→" "directorio anterior / siguiente"
        set -q __keys_tsv; or echo

        __keys_section "Dentro de fzf" "  (Ctrl+T, Alt+C, ff)"
        __keys_row "Tab" "marcar varios"
        __keys_row "Ctrl+Y" "copiar la ruta"
        __keys_row "Ctrl+O / Ctrl+E" "abrir en nvim / en yazi"
        __keys_row "Ctrl+X" "abrir con su app"
        __keys_row "Alt+H" "mostrar u ocultar archivos ocultos (Ctrl+T, ff)"
        __keys_row "Ctrl+/" "mostrar u ocultar la vista previa"
        __keys_row "Ctrl+D / Ctrl+U" "bajar / subir la vista previa"
        set -q __keys_tsv; or echo
    end

    if contains git $ver
        __keys_section "Git" "  (los diffs salen con delta: n / N saltan de archivo)"
        __keys_row "git hist" "grafo de todo el historial, una línea por commit"
        __keys_row "git llog" "grafo con los archivos que tocó cada commit"
        __keys_row "git st / d / co / br" "status / diff / checkout / branch"
        __keys_row "git ps / pl" "push / pull de la rama actual"
        __keys_row "git open" "abrir el repo en GitHub"
        __keys_row "git edit-unmerged" "abrir en nvim los archivos con conflicto (add-unmerged los añade)"
        __keys_row "git stash push -m x" "apartar cambios   ·   git stash list / pop"
        __keys_row "git reset HEAD~1" "deshacer el último commit sin perder cambios (--soft: en stage)"
        __keys_row "gh pr create --fill" "crear PR de la rama actual   ·   --web en el navegador"
        set -q __keys_tsv; or echo
    end

    if contains lazygit $ver
        __keys_section "Lazygit" "  (lazygit, o Espacio g g en nvim)"
        __keys_row "Espacio" "stage / unstage del archivo"
        __keys_row "c / C" "commit escribiendo el mensaje / commit con Claude (lo que está en stage)"
        __keys_row "e" "abrir el archivo en nvim   ·   NO uses o en archivos: se traba"
        __keys_row "s / S" "stash de todo / opciones de stash   ·   panel [5]: g pop, d borrar"
        __keys_row "A" "amend: meter los cambios en el último commit"
        __keys_row "g (en commits)" "reset a ese commit: mixed / soft / hard"
        __keys_row "o (en ramas)" "crear o abrir el PR de la rama"
        __keys_row "?" "todas las teclas del panel"
        set -q __keys_tsv; or echo
    end

    if contains nvim $ver
        __keys_section "Nvim" "  (Espacio = leader)"
        __keys_row "Espacio g v" "codediff: archivos cambiados + diff lado a lado"
        __keys_row "Espacio g V" "codediff: historial del archivo (en visual: de esas líneas)"
        __keys_row "  ]f [f / ]c [c" "  en codediff: archivo / cambio siguiente y anterior"
        __keys_row "  - / Esp h s/u" "  en codediff: stage o unstage del archivo / del cambio"
        __keys_row "  t / gc / g? / q" "  en codediff: lado a lado↔en línea / compacto / ayuda / cerrar"
        __keys_row "]c [c / ]C [C" "siguiente/anterior cambio de git / último/primero (mini.diff)"
        __keys_row "Espacio g o" "ver el diff dentro del archivo (overlay)"
        __keys_row "ghgh / gHgH" "stage del cambio / DESCARTAR el cambio (no se deshace)"
        __keys_row "Espacio g g" "lazygit flotante"
        __keys_row "Espacio g P / g i" "PRs / issues de GitHub"
        __keys_row "Espacio y f / y p" "copiar ruta relativa / absoluta con la línea (para agentes)"
        __keys_row "Espacio y c" "en visual: copiar la selección como bloque de código con archivo y línea"
        __keys_row "Espacio b h" "cerrar los buffers que no se ven"
        __keys_row "Ctrl+a / Ctrl+x" "subir / bajar el número, fecha o true/false bajo el cursor"
        __keys_row "Espacio E" "Oil flotante con vista previa"
        __keys_row "x" "borra sin pisar el portapapeles"
        __keys_row "te / Tab / Shift+Tab" "pestaña nueva / siguiente / anterior (la barra sale con 2 o más)"
        set -q __keys_tsv; or echo
    end

    if contains herdr $ver
        __keys_section "Herdr" "  (prefijo Ctrl+g)"
        __keys_row "Ctrl+g b" "abrir o plegar la barra lateral (workspaces y agentes)"
        __keys_row "Alt+t" "nueva pestaña (se abre en el directorio del panel actual)"
        __keys_row "Alt+Shift+h / l" "pestaña anterior / siguiente"
        __keys_row "Alt+i / o" "mover la pestaña a la izquierda / derecha"
        __keys_row "Alt+h j k l" "moverse entre paneles"
        __keys_row "Alt+n / Alt+d" "dividir en vertical / en horizontal"
        __keys_row "Alt+x / Alt+Shift+x" "cerrar panel / cerrar pestaña"
        __keys_row "Ctrl+g g" "lazygit en un panel ampliado (directorio actual)"
        __keys_row "Ctrl+g e" "cerrar los demás paneles de la pestaña"
        __keys_row "Ctrl+g Shift+h j k l" "redimensionar el panel"
        __keys_row "Ctrl+g u / Shift+e" "navegador de sesiones / historial del panel en nvim"
        __keys_row "Ctrl+g ;" "volver al último panel"
        __keys_row "Ctrl+g o / Shift+o" "abrir la carpeta en el explorador / ir a la notificación"
        __keys_row "Alt+Shift+k / j" "subir / bajar el workspace"
        __keys_row "rueda / Ctrl+g [" "subir y bajar en el historial del panel / modo copia (teclado)"
        __keys_row "  j / k · q" "  en modo copia: bajar / subir · salir"
        __keys_row "ide" "layout: panel arriba y tres abajo"
        set -q __keys_tsv; or echo
    end

    functions -e __keys_row __keys_section
end
