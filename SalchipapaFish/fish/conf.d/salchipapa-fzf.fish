# Aspecto de fzf (atajos de la shell, fzf.fish, fzf-lua en nvim y cualquier `fzf` a mano).
# Incluye lo que fzf.fish pondría si esta variable no existiera (--cycle, --layout=reverse, --border,
# --height, --marker). fzf-lua quita el borde solo.
set -gx FZF_DEFAULT_OPTS "\
--cycle --layout=reverse --height=90% --border=rounded --info=inline-right \
--prompt='❯ ' --pointer='▌' --marker='+' --preview-window=wrap"
# Colores: los escribe Salchipapa-Shell según el tema en un archivo que fzf lee cada vez que se
# abre (cambian al momento con el tema). Sin él, nombres ANSI: siguen la paleta del terminal.
# Van en el archivo o en la variable, no en los dos: la variable se lee después y ganaría.
set -l fzf_colors ~/.local/state/salchipapa-shell/fzf-colors
if test -f $fzf_colors
    set -gx FZF_DEFAULT_OPTS_FILE $fzf_colors
else
    set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS \
--color=fg:-1,bg:-1,gutter:-1,hl:blue,fg+:bright-white,bg+:bright-black,hl+:bright-blue \
--color=prompt:blue,pointer:magenta,marker:green,info:cyan,spinner:cyan,header:yellow,border:bright-black,label:cyan"
end

# Acciones dentro de los buscadores de archivos/directorios (Ctrl+T y Alt+C). No van en
# FZF_DEFAULT_OPTS: ahí también las heredarían el historial, git log, fzf-lua… donde {} no es una ruta.
# Los comandos los ejecuta fzf con $SHELL, que es fish en Ctrl+T (fzf.fish lo fuerza) y puede ser sh
# en Alt+C: por eso solo usan sintaxis que vale en las dos (test, &&, ||, redirecciones).
#   Ctrl+Y   copia la ruta completa (wl-copy -n quita el salto de línea final)
#   Ctrl+O   abre en nvim         Ctrl+E  abre yazi ahí (con un archivo, yazi lo deja señalado)
#   Ctrl+X   abre con la app por defecto (xdg-open, desligado de la terminal)
#   Ctrl+/   muestra/oculta la vista previa   Ctrl+D/U  baja/sube media página la vista previa
# nvim y yazi van con </dev/tty >/dev/tty: Ctrl+T guarda la salida de fzf en una variable y, sin eso,
# no verían la terminal.
set -l fzf_path_binds \
    'ctrl-y:execute-silent(realpath -- {} | wl-copy -n)+abort' \
    'ctrl-o:execute(nvim -- {} </dev/tty >/dev/tty)+abort' \
    'ctrl-e:execute(yazi -- {} </dev/tty >/dev/tty)+abort' \
    'ctrl-x:execute-silent(setsid -f xdg-open {} >/dev/null 2>&1)+abort' \
    'ctrl-/:toggle-preview' \
    'ctrl-d:preview-half-page-down' \
    'ctrl-u:preview-half-page-up'

# Alt+H (solo Ctrl+T): fd no lista archivos ocultos (.config, .local…); esto los muestra u oculta.
# El estado se guarda en el prompt ("Directory+hidden> "). Alt+C no lo necesita: ya los incluye.
set -l fzf_hidden_bind 'alt-h:transform:test "$FZF_PROMPT" = "Directory+hidden> " && echo "change-prompt(Directory> )+reload(fd --color=always)" || echo "change-prompt(Directory+hidden> )+reload(fd --color=always --hidden --exclude .git)"'

# Chuleta en el borde inferior (abajo a la derecha). No como --header: el header sale como una línea
# más de la lista y se confundía con los resultados.
set -l fzf_label_pos --border-label-pos=-2:bottom
set -l fzf_dir_label ' copy-path:^Y  nvim:^O  yazi:^E  open:^X  hidden:M-h  preview:^/ '
set -l fzf_altc_label ' copy-path:^Y  nvim:^O  yazi:^E  open:^X  preview:^/ '

# Alt+C (entrar en un directorio): vista previa de su árbol. FZF_ALT_C_OPTS es una cadena que fzf
# parte como una shell: cada opción entre comillas simples (ninguna lleva comillas simples dentro).
set -l altc_opts "--preview=eza --tree --level=2 --icons --color=always {}" \
    --bind=$fzf_path_binds --border-label=$fzf_altc_label $fzf_label_pos
set -gx FZF_ALT_C_OPTS (printf "'%s' " $altc_opts | string trim)

# Ctrl+T (buscador de archivos de fzf.fish): fzf.fish pasa esta lista tal cual como argumentos de
# fzf, así que va un elemento por opción y sin comillas.
set -g fzf_directory_opts --bind=$fzf_path_binds --bind=$fzf_hidden_bind --border-label=$fzf_dir_label $fzf_label_pos

# bat con la paleta del terminal en vez de un tema fijo. Si existe ~/.config/bat/config (lo escribe
# Salchipapa-Shell con el tema de bat que corresponde al suyo), manda ese: BAT_THEME ganaría, así que
# se quita aunque venga heredada (herdr o la terminal pueden haberse abierto con ella).
if test -f ~/.config/bat/config
    set -e BAT_THEME
else
    set -gx BAT_THEME ansi
end

# Vista previa de archivos con bat (Ctrl+T de fzf.fish y los alias fzfbat/fzfnvim): solo números de
# línea y al ancho de la ventana de vista previa. Sin --terminal-width, bat dibuja cabecera y cuadrícula
# al ancho de la terminal entera y fzf las corta en trozos con ↳. Las comillas simples dejan
# $FZF_PREVIEW_COLUMNS para cuando fzf ejecuta la vista previa.
set -g fzf_preview_file_cmd 'bat --color=always --decorations=always --style=numbers --terminal-width=$FZF_PREVIEW_COLUMNS'
