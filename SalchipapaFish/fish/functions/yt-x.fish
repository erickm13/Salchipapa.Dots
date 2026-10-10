function yt-x --description 'yt-x; en WSL reproduce con el mpv de Windows (GPU, 4K)'
    set -l win_mpv "/mnt/c/Program Files/MPV Player/mpv.exe"
    if not test -x "$win_mpv"
        # Linux nativo: mpv normal
        command yt-x $argv
        return
    end

    # yt-x usa `mpv` si esta en el PATH: le ponemos delante un `mpv` que llama al de Windows
    set -l bin ~/.cache/yt-x-win-mpv
    if not test -x $bin/mpv
        mkdir -p $bin
        printf '#!/bin/sh\nexec "%s" "$@"\n' "$win_mpv" >$bin/mpv
        chmod +x $bin/mpv
    end
    PATH="$bin:$PATH" command yt-x $argv
end
