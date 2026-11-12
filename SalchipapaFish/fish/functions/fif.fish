# fif [texto]: buscar DENTRO de los archivos con ripgrep mientras escribes y abrir nvim en esa línea.
# Desde el directorio actual (rg respeta .gitignore y salta los ocultos). Vista previa con bat centrada
# en la línea encontrada. ^Y copia la ruta del archivo; ^/ muestra/oculta la vista previa.
# Los --bind los ejecuta sh (SHELL=/bin/sh): {q} y {1}/{2} los cita fzf.
function fif --description "Buscar texto en los archivos (ripgrep) y abrir nvim en esa línea"
    set -l rg 'rg --column --line-number --no-heading --color=always --smart-case'
    set -l reload "[ -n {q} ] && $rg -- {q} || true"
    set -l sel (SHELL=/bin/sh fzf --ansi --disabled --query="$argv" --prompt='fif> ' \
        --delimiter=: \
        --bind="start:reload:$reload" --bind="change:reload:sleep 0.1; $reload" \
        --preview='bat --color=always --decorations=always --style=numbers --highlight-line {2} --terminal-width=$FZF_PREVIEW_COLUMNS -- {1}' \
        --preview-window='+{2}/2' \
        --bind='ctrl-y:execute-silent(realpath -- {1} | wl-copy -n)+abort' \
        --bind='ctrl-/:toggle-preview' --bind='ctrl-d:preview-half-page-down' --bind='ctrl-u:preview-half-page-up' \
        --border-label=' Enter: nvim en la línea  copy-path:^Y  preview:^/ ' --border-label-pos=-2:bottom)
    or return
    set -l parts (string split --max 2 : -- $sel[1])
    nvim +$parts[2] -- $parts[1]
end
