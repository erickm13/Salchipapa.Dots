# atajos: chuleta del setup de Salchipapa.Dots en la terminal (comandos propios, abreviaturas, teclas
# de fish, de fzf y de atuin). Las abreviaturas se leen en vivo de `abbr --show`; lo demás está
# escrito aquí: al añadir un comando o un atajo, añádelo también a esta lista.
# Uso: `atajos` lo muestra todo; `atajos <sección>` solo una (shell, git, lazygit, nvim, herdr).
function atajos --description "Chuleta: comandos, abreviaturas y teclas de este setup"
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

    function __atajos_row --no-scope-shadowing --argument-names key desc
        printf '  %s%-22s%s %s\n' $k $key $d $desc
    end

    if contains shell $ver
        echo $h"Comandos"$d
        __atajos_row "ff [texto]" "buscar y abrir (dir → cd, texto → nvim, PDF/imagen → su app)"
        __atajos_row "fif [texto]" "buscar DENTRO de los archivos; Enter abre nvim en la línea"
        __atajos_row "fbr [texto]" "cambiar de rama de git"
        __atajos_row "zi" "directorios frecuentes (zoxide)   ·   z <nombre>  saltar directo"
        __atajos_row "y [ruta]" "yazi; al salir con q te quedas en ese directorio"
        __atajos_row "fpi / fpr [texto]" "buscar e instalar / quitar paquetes (Tab marca varios)"
        __atajos_row "typioca" "test de mecanografía"
        __atajos_row "tldr <cmd>" "ejemplos cortos de un comando"
        __atajos_row "cpwd" "copiar el directorio actual (con ~) al portapapeles"
        echo

        echo $h"Abreviaturas"$g"  (se expanden al pulsar espacio)"$d
        for line in (abbr --show)
            # abbr -a [opciones] -- nombre 'expansión'
            set -l parts (string match -r -- '-- (\S+) (.*)$' $line)
            test (count $parts) -eq 3; or continue
            __atajos_row $parts[2] (string trim -c "'" -- $parts[3] | string replace '%' '▏')
        end
        echo

        echo $h"En la línea de comandos"$d
        __atajos_row "Ctrl+T" "buscar archivos: inserta la ruta; con la línea vacía, la abre"
        __atajos_row "Alt+C" "buscar un directorio y entrar"
        __atajos_row "Ctrl+R / ↑" "historial (atuin): todo / solo este directorio"
        __atajos_row "Ctrl+Alt+L / S" "git log / git status con fzf"
        __atajos_row "Ctrl+Alt+P / E" "procesos / variables con fzf"
        __atajos_row "Alt+S" "añadir o quitar sudo"
        __atajos_row "Alt+H" "man del comando que escribes (necesita man-db)"
        __atajos_row "Alt+← / Alt+→" "directorio anterior / siguiente"
        echo

        echo $h"Dentro de fzf"$g"  (Ctrl+T, Alt+C, ff)"$d
        __atajos_row "Tab" "marcar varios"
        __atajos_row "Ctrl+Y" "copiar la ruta"
        __atajos_row "Ctrl+O / Ctrl+E" "abrir en nvim / en yazi"
        __atajos_row "Ctrl+X" "abrir con su app"
        __atajos_row "Alt+H" "mostrar u ocultar archivos ocultos (Ctrl+T, ff)"
        __atajos_row "Ctrl+/" "mostrar u ocultar la vista previa"
        __atajos_row "Ctrl+D / Ctrl+U" "bajar / subir la vista previa"
        echo
    end

    if contains git $ver
        echo $h"Git"$g"  (los diffs salen con delta: n / N saltan de archivo)"$d
        __atajos_row "git hist" "grafo de todo el historial, una línea por commit"
        __atajos_row "git llog" "grafo con los archivos que tocó cada commit"
        __atajos_row "git st / d / co / br" "status / diff / checkout / branch"
        __atajos_row "git ps / pl" "push / pull de la rama actual"
        __atajos_row "git open" "abrir el repo en GitHub"
        __atajos_row "git edit-unmerged" "abrir en nvim los archivos con conflicto (add-unmerged los añade)"
        __atajos_row "git stash push -m x" "apartar cambios   ·   git stash list / pop"
        __atajos_row "git reset HEAD~1" "deshacer el último commit sin perder cambios (--soft: en stage)"
        __atajos_row "gh pr create --fill" "crear PR de la rama actual   ·   --web en el navegador"
        echo
    end

    if contains lazygit $ver
        echo $h"Lazygit"$g"  (lazygit, o Espacio g g en nvim)"$d
        __atajos_row "Espacio" "stage / unstage del archivo"
        __atajos_row "c / C" "commit escribiendo el mensaje / commit con Claude (lo que está en stage)"
        __atajos_row "e" "abrir el archivo en nvim   ·   NO uses o en archivos: se traba"
        __atajos_row "s / S" "stash de todo / opciones de stash   ·   panel [5]: g pop, d borrar"
        __atajos_row "A" "amend: meter los cambios en el último commit"
        __atajos_row "g (en commits)" "reset a ese commit: mixed / soft / hard"
        __atajos_row "o (en ramas)" "crear o abrir el PR de la rama"
        __atajos_row "?" "todas las teclas del panel"
        echo
    end

    if contains nvim $ver
        echo $h"Nvim"$g"  (Espacio = leader)"$d
        __atajos_row "Espacio g v" "codediff: archivos cambiados + diff lado a lado"
        __atajos_row "Espacio g V" "codediff: historial del archivo (en visual: de esas líneas)"
        __atajos_row "  ]f [f / ]c [c" "  en codediff: archivo / cambio siguiente y anterior"
        __atajos_row "  - / Esp h s/u" "  en codediff: stage o unstage del archivo / del cambio"
        __atajos_row "  t / gc / g? / q" "  en codediff: lado a lado↔en línea / compacto / ayuda / cerrar"
        __atajos_row "]c [c / ]C [C" "siguiente/anterior cambio de git / último/primero (mini.diff)"
        __atajos_row "Espacio g o" "ver el diff dentro del archivo (overlay)"
        __atajos_row "ghgh / gHgH" "stage del cambio / DESCARTAR el cambio (no se deshace)"
        __atajos_row "Espacio g g" "lazygit flotante"
        __atajos_row "Espacio g P / g i" "PRs / issues de GitHub"
        __atajos_row "Espacio y f / y p" "copiar ruta relativa / absoluta con la línea (para agentes)"
        __atajos_row "Espacio y c" "en visual: copiar la selección como bloque de código con archivo y línea"
        __atajos_row "Espacio b h" "cerrar los buffers que no se ven"
        __atajos_row "Ctrl+a / Ctrl+x" "subir / bajar el número, fecha o true/false bajo el cursor"
        __atajos_row "Espacio E" "Oil flotante con vista previa"
        __atajos_row "x" "borra sin pisar el portapapeles"
        echo
    end

    if contains herdr $ver
        echo $h"Herdr"$g"  (prefijo Ctrl+g)"$d
        __atajos_row "Ctrl+g b" "abrir o plegar la barra lateral (workspaces y agentes)"
        __atajos_row "Alt+t" "nueva pestaña (se abre en el directorio del panel actual)"
        __atajos_row "Alt+Shift+h / l" "pestaña anterior / siguiente"
        __atajos_row "Alt+i / o" "mover la pestaña a la izquierda / derecha"
        __atajos_row "Alt+h j k l" "moverse entre paneles"
        __atajos_row "Alt+n / Alt+d" "dividir en vertical / en horizontal"
        __atajos_row "Alt+x / Alt+Shift+x" "cerrar panel / cerrar pestaña"
        __atajos_row "Ctrl+g g" "lazygit en un panel ampliado (directorio actual)"
        __atajos_row "Ctrl+g e" "cerrar los demás paneles de la pestaña"
        __atajos_row "Ctrl+g Shift+h j k l" "redimensionar el panel"
        __atajos_row "Ctrl+g u / Shift+e" "navegador de sesiones / historial del panel en nvim"
        __atajos_row "Ctrl+g ;" "volver al último panel"
        __atajos_row "Ctrl+g o / Shift+o" "abrir la carpeta en el explorador / ir a la notificación"
        __atajos_row "Ctrl+Shift+↑ / ↓" "subir / bajar el workspace"
        __atajos_row "ide" "layout: panel arriba y tres abajo"
        echo
    end

    functions -e __atajos_row
end
