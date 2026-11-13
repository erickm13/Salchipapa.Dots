# Ajustes del plugin done (conf.d/done.fish): notificación al terminar un comando largo si la terminal
# no está enfocada (en Hyprland lo mira con hyprctl). Sale en la isla de Salchipapa-Shell (notify-send).
# Se carga después de done.fish, pero estas variables las lee al terminar cada comando.
set -g __done_min_cmd_duration 10000 # avisar si tardó más de 10 s
# Sin aviso para programas interactivos (los cierras tú: no hay nada que avisar) ni para git que no
# sea push/pull/fetch (el valor por defecto de done)
set -g __done_exclude \
    '^git (?!push|pull|fetch)' \
    '^(sudo )?(vi|vim|nvim|y|yazi|lazygit|btop|htop|top|man|less|more|ssh|mosh)\b' \
    '^(claude|cl|codex|opencode|gemini|copilot|herdr|zellij|tmux)\b' \
    '^(fzf|ff|fif|fbr|zi|fpi|fpr|keys|typioca|smassh|spotify_player|sp|mpv|yt-x|watch)\b'
