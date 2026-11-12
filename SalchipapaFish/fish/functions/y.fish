# y [ruta]: yazi, y al salir (q) la terminal se queda en el directorio donde estabas en yazi.
# Es el envoltorio que recomienda yazi (--cwd-file). Salir con Q (mayúscula) no cambia de directorio.
function y --description "yazi; al salir, quedarse en ese directorio"
    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    yazi $argv --cwd-file=$tmp
    if read -z cwd <$tmp; and test -n "$cwd"; and test "$cwd" != "$PWD"; and test -d "$cwd"
        builtin cd -- $cwd
    end
    rm -f -- $tmp
end
