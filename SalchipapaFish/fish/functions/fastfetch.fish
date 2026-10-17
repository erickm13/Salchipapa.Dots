# fastfetch con el protocolo de imagen correcto segun el terminal (si no, 'auto' sale pixelado
# dentro de herdr). Asi el fetch del arranque Y el manual salen nitidos.
#   - herdr (se abre en kitty): protocolo de kitty, que herdr deja pasar.
#   - foot: sixel (foot no soporta el protocolo de kitty).
#   - kitty/ghostty: 'auto' usa su protocolo nativo.
function fastfetch --wraps fastfetch --description 'fastfetch con protocolo de imagen por terminal'
    if test "$HERDR_ENV" = 1
        command fastfetch --logo-type kitty $argv
    else if string match -qr '^foot' -- "$TERM"
        command fastfetch --logo-type sixel $argv
    else
        command fastfetch $argv
    end
end
