# Ctrl+T: el buscador de archivos de fzf.fish (_fzf_search_directory). Con un comando a medias
# (`cp `, `git add `…) Enter inserta la ruta como siempre. Con la línea vacía, Enter abre lo elegido:
#   - un directorio            -> entra en él
#   - archivos de texto        -> nvim (va al historial: flecha arriba lo repite)
#   - un archivo que no es texto (PDF, imagen, vídeo…) -> su app (xdg-open, desligada de la terminal)
#   - otra mezcla              -> se quedan las rutas escritas, como antes
# Texto = _salchipapa_is_text (mira el contenido, no la extensión). El comando `ff` hace lo mismo.
# Alt+C sigue siendo "solo directorios + cd". Ctrl+O / Ctrl+X fuerzan nvim / app desde fzf.
function _salchipapa_fzf_directory --description "Ctrl+T: buscar archivos; con la línea vacía, abrir lo elegido"
    set -l before "$(commandline)"
    _fzf_search_directory
    test -z (string trim -- "$before"); or return

    set -l picked (commandline --tokens-expanded)
    test (count $picked) -gt 0; or return

    # Un directorio: entrar
    if test (count $picked) -eq 1; and test -d "$picked[1]"
        commandline --replace ''
        cd -- $picked[1]
        commandline --function repaint
        return
    end

    # Solo archivos: separar texto de lo demás
    set -l text
    set -l other
    for f in $picked
        if not test -f "$f"
            return # algo que no es un archivo normal (o un directorio entre varios): dejar las rutas
        end
        if _salchipapa_is_text $f
            set -a text $f
        else
            set -a other $f
        end
    end

    if test (count $other) -eq 0
        # Todo texto: ejecutar `nvim <rutas>` como si lo hubieras escrito (queda en el historial)
        commandline --replace "nvim "(string escape -- $text | string join ' ')
        commandline --function execute
    else if test (count $picked) -eq 1
        # Un archivo que no es texto: su app, sin bloquear la terminal
        commandline --replace ''
        setsid -f xdg-open $other[1] >/dev/null 2>&1
        commandline --function repaint
    end
    # Varios archivos y alguno no es texto: se quedan las rutas escritas
end
