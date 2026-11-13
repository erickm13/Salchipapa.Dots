# fastfetch con el protocolo de imagen correcto segun el terminal (si no, 'auto' sale pixelado
# dentro de herdr). Asi el fetch del arranque Y el manual salen nitidos.
#   - herdr (se abre en kitty): protocolo de kitty, que herdr deja pasar.
#   - foot: sixel (foot no soporta el protocolo de kitty).
#   - kitty/ghostty: 'auto' usa su protocolo nativo.
function fastfetch --wraps fastfetch --description 'fastfetch con protocolo de imagen por terminal'
    # Colores del tema de Salchipapa-Shell (si hay): opciones como --color-keys, una por línea
    set -l theme_args
    test -f ~/.local/state/salchipapa-shell/fastfetch-args
    and set theme_args (string match -v '' < ~/.local/state/salchipapa-shell/fastfetch-args)
    if test "$HERDR_ENV" = 1
        command fastfetch --logo-type kitty $theme_args $argv
    else if string match -qr '^foot' -- "$TERM"
        command fastfetch --logo-type sixel $theme_args $argv
    else
        command fastfetch $theme_args $argv
    end
end
