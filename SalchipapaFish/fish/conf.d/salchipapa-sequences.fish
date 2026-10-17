# Colores de terminal (OSC) de Salchipapa-Shell — aplicados al abrir una shell interactiva
if status is-interactive
    and test -f "$HOME/.local/state/salchipapa-shell/sequences.txt"
    cat "$HOME/.local/state/salchipapa-shell/sequences.txt"
end
