function sp --description 'spotify_player: sp | sp play <cancion> | sp next | sp prev | sp pause | sp like | sp vol <0-100> | sp letra [cancion] | sp quit'
    switch "$argv[1]"
        case play next n prev previous p pause like vol volume
            # Los comandos de playback necesitan una instancia corriendo (interfaz o daemon)
            if not pgrep -x spotify_player >/dev/null
                spotify_player -d
                sleep 3
            end
    end

    switch "$argv[1]"
        case ''
            spotify_player
        case play
            if test (count $argv) -lt 2
                spotify_player playback play
                return
            end
            set -l m (__sp_search $argv[2..]); or return 1
            spotify_player playback start track --id $m[1]
            and echo "▶ $m[2] — $m[3]"
        case next n
            spotify_player playback next
        case prev previous p
            spotify_player playback previous
        case pause
            spotify_player playback pause
        case like
            spotify_player like
            and echo "♥ Guardada en tus canciones"
        case vol volume
            spotify_player playback volume $argv[2]
        case letra lyrics
            if test (count $argv) -lt 2
                # Letra de la cancion que esta sonando
                spotify_player lyrics
            else
                set -l m (__sp_search $argv[2..]); or return 1
                spotify_player lyrics --id $m[1]
            end
        case quit salir stop
            if pgrep -x spotify_player >/dev/null
                spotify_player playback pause 2>/dev/null
                pkill -x spotify_player
                echo "■ spotify_player cerrado"
            else
                echo "spotify_player no está corriendo"
            end
        case '*'
            spotify_player $argv
    end
end

# Primer resultado de la busqueda de canciones: imprime id, nombre y primer artista (una linea cada uno)
function __sp_search
    set -l query (string join ' ' $argv)
    set -l m (spotify_player search "$query" | string match -r '"tracks":\[\{"id":"([^"]+)","name":"([^"]*)","artists":\[\{"id":"[^"]+","name":"([^"]*)"')
    if test (count $m) -lt 4
        echo "No encontré ninguna canción para: $query" >&2
        return 1
    end
    printf '%s\n' $m[2..4]
end
