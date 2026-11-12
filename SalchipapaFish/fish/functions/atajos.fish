# atajos: chuleta del setup de Salchipapa.Dots en la terminal (comandos propios, abreviaturas, teclas
# de fish, de fzf y de atuin). Las abreviaturas se leen en vivo de `abbr --show`; lo demás está
# escrito aquí: al añadir un comando o un atajo, añádelo también a esta lista.
function atajos --description "Chuleta: comandos, abreviaturas y teclas de este setup"
    set -l h (set_color --bold blue)
    set -l k (set_color green)
    set -l d (set_color normal)
    set -l g (set_color brblack)

    function __atajos_row --no-scope-shadowing --argument-names key desc
        printf '  %s%-18s%s %s\n' $k $key $d $desc
    end

    echo $h"Comandos"$d
    __atajos_row "ff [texto]" "buscar y abrir (dir → cd, texto → nvim, PDF/imagen → su app)"
    __atajos_row "fif [texto]" "buscar DENTRO de los archivos; Enter abre nvim en la línea"
    __atajos_row "fbr [texto]" "cambiar de rama de git"
    __atajos_row "zi" "directorios frecuentes (zoxide)   ·   z <nombre>  saltar directo"
    __atajos_row "y [ruta]" "yazi; al salir con q te quedas en ese directorio"
    __atajos_row "fpi / fpr [texto]" "buscar e instalar / quitar paquetes (Tab marca varios)"
    __atajos_row "typioca" "test de mecanografía"
    __atajos_row "tldr <cmd>" "ejemplos cortos de un comando"
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

    functions -e __atajos_row
end
