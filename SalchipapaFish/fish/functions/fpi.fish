# fpi [búsqueda]: buscar paquetes en los repos y en AUR con fzf e instalarlos. Tab marca varios;
# la vista previa es su descripción (paru -Si). Usa paru, o yay, o solo pacman si no hay ninguno.
function fpi --description "Buscar e instalar paquetes (repos + AUR) con fzf"
    if not type -q pacman
        echo "fpi: solo funciona en Arch (pacman)" >&2
        return 1
    end
    set -l helper (command -s paru; or command -s yay)
    set -l list pacman -Slq
    set -l info pacman -Si
    if test -n "$helper"
        set list $helper -Slq
        set info $helper -Si
    end
    set -l sel ($list 2>/dev/null | SHELL=/bin/sh fzf --multi --query="$argv" --prompt='install> ' \
        --preview="$info {}" --preview-window=wrap \
        --border-label=' Tab: marcar varios  Enter: instalar ' --border-label-pos=-2:bottom)
    or return
    if test -n "$helper"
        $helper -S $sel # paru/yay piden sudo solos
    else
        sudo pacman -S $sel
    end
end
