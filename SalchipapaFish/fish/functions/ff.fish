# ff [búsqueda]: buscar un archivo o directorio y abrirlo (el Enter de Ctrl+T, como comando).
# Directorio -> entra; texto -> nvim; PDF, imagen… -> su app. Mismas teclas que en Ctrl+T
# (^Y copiar ruta, ^O nvim, ^E yazi, ^X app, Alt+H ocultos, ^/ vista previa, ^D/^U desplazarla).
# El prompt es "Directory> " porque Alt+H lo usa para saber si los ocultos están puestos.
function ff --description "Buscar un archivo/directorio y abrirlo (dir → cd, texto → nvim, otro → su app)"
    set -l picked (fd --color=always $fzf_fd_opts 2>/dev/null |
        _fzf_wrapper --multi --ansi --prompt="Directory> " --query="$argv" \
            --preview='_fzf_preview_file {}' $fzf_directory_opts)
    or return
    _salchipapa_open $picked
end
