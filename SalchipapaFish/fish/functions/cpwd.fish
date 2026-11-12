function cpwd --description 'Copia el directorio actual al portapapeles, con $HOME como ~'
    # Basado en craftzdog/dotfiles (pbcopy → wl-copy; clip.exe en WSL)
    set -l dir (string replace -r "^$HOME" '~' -- $PWD)
    if type -q wl-copy; and set -q WAYLAND_DISPLAY
        printf '%s' $dir | wl-copy
    else if type -q clip.exe
        printf '%s' $dir | clip.exe
    else if type -q xclip
        printf '%s' $dir | xclip -selection clipboard
    else
        echo "cpwd: no hay wl-copy, clip.exe ni xclip" >&2
        return 1
    end
    echo "Copiado: $dir"
end
