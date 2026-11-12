# fpr [búsqueda]: elegir con fzf paquetes que instalaste tú (pacman -Qe) y quitarlos con sus
# dependencias que ya nadie use (pacman -Rns). Tab marca varios; pacman pide confirmación antes de borrar.
function fpr --description "Elegir paquetes instalados con fzf y quitarlos (pacman -Rns)"
    if not type -q pacman
        echo "fpr: solo funciona en Arch (pacman)" >&2
        return 1
    end
    set -l sel (pacman -Qqe | SHELL=/bin/sh fzf --multi --query="$argv" --prompt='remove> ' \
        --preview='pacman -Qi {}' --preview-window=wrap \
        --border-label=' Tab: marcar varios  Enter: quitar ' --border-label-pos=-2:bottom)
    or return
    sudo pacman -Rns $sel
end
