# Línea en blanco entre la salida de un comando y el siguiente prompt (sustituye a add_newline de
# starship, que la pone también en el primer prompt y tras `clear` y deja el prompt bajado del borde).
# Ctrl+L y un Enter vacío no lanzan fish_postexec, así que tampoco la ponen.
function __salchipapa_prompt_newline --on-event fish_postexec
    # Sin línea si la línea de comandos acaba en `clear` (`clear`, `ls; clear`, `make && clear`…)
    string match -qr '(^|[;&|]|\band\b|\bor\b)\s*clear\s*$' -- $argv[1]; and return
    echo
end
