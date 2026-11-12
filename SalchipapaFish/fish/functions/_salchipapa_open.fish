# Abre lo elegido en un buscador (lo usa `ff`): un directorio -> entra; archivos de texto -> nvim;
# un archivo que no es texto -> su app (xdg-open, desligada de la terminal). Otra mezcla (varios
# archivos con alguno que no es texto, o directorios entre archivos) -> imprime las rutas.
function _salchipapa_open --description "Abrir rutas: dir → cd, texto → nvim, otro → su app"
    test (count $argv) -gt 0; or return 1
    if test (count $argv) -eq 1; and test -d "$argv[1]"
        cd -- $argv[1]
        return
    end
    set -l text
    set -l other
    for f in $argv
        if not test -f "$f"
            printf '%s\n' $argv
            return
        end
        if _salchipapa_is_text $f
            set -a text $f
        else
            set -a other $f
        end
    end
    if test (count $other) -eq 0
        nvim -- $text
    else if test (count $argv) -eq 1
        setsid -f xdg-open $other[1] >/dev/null 2>&1
    else
        printf '%s\n' $argv
    end
end
