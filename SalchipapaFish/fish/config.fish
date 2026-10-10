# herdr: nombres de pestañas. Va al principio para que el nombre aparezca al instante.
# herdr no tiene nombre por defecto: las pestañas sin nombre muestran su posicion.
# Workspace nuevo: "shell" + "nvim", como mi layout de zellij.
# Pestañas nuevas sin nombre: adjetivo-animal aleatorio, al estilo de los nombres de zellij.
if status is-interactive; and test "$HERDR_ENV" = 1; and set -q HERDR_TAB_ID; and type -q jq
    set -l label (herdr tab get $HERDR_TAB_ID 2>/dev/null | jq -r '.result.tab.label // empty')
    if string match -qr '^[0-9]+$' -- "$label"
        set -l n_tabs (herdr tab list --workspace $HERDR_WORKSPACE_ID 2>/dev/null | jq -r '.result.tabs | length')
        if test "$n_tabs" = 1
            herdr tab rename $HERDR_TAB_ID shell >/dev/null 2>&1
            herdr tab create --workspace $HERDR_WORKSPACE_ID --label nvim >/dev/null 2>&1
        else
            set -l adj blossoming sleepy jolly cosmic fuzzy brave quiet sunny mighty gentle \
                curious dancing electric frosty golden hidden lucky misty noble rapid silent spicy
            set -l animal bee fox otter panda koala lynx owl raccoon falcon wombat \
                badger heron gecko llama marmot narwhal penguin quokka tapir walrus yak zebra
            herdr tab rename $HERDR_TAB_ID (random choice $adj)-(random choice $animal) >/dev/null 2>&1
        end
    end

    # `exit` en el ultimo panel: cerrar herdr del todo. Si no, herdr crea un workspace nuevo (con
    # "shell" + "nvim" otra vez) y la terminal nunca se cierra. Solo en el fish principal del
    # panel (su padre es herdr), no en un fish abierto dentro de otro.
    if test (ps -o comm= -p (ps -o ppid= -p $fish_pid | string trim)) = herdr
        function __herdr_cerrar_si_ultimo_panel --on-event fish_exit
            # Solo si el unico panel que queda es este (si herdr ya lo quito de la lista, p. ej.
            # al cerrarlo con Alt x, quedan otros y no se toca nada)
            set -l panes (herdr pane list 2>/dev/null | jq -r '.result.panes[].pane_id')
            if test (count $panes) = 1; and test "$panes[1]" = "$HERDR_PANE_ID"
                # Marca para que la fish de kitty borre la sesion guardada: si no, herdr restauraria
                # el ultimo estado (solo la pestaña que quedaba) en vez de empezar con shell + nvim
                mkdir -p ~/.cache/herdr; and touch ~/.cache/herdr/reset-session
                herdr server stop >/dev/null 2>&1
            end
        end
    end
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    # Install Fisher if not installed
    if not functions -q fisher
        curl -sL https://git.io/fisher | source
        fisher install jorgebucaran/fisher
    end

end

# Detect Termux
set -l IS_TERMUX 0
if test -n "$TERMUX_VERSION"; or test -d /data/data/com.termux
    set IS_TERMUX 1
end

if test $IS_TERMUX -eq 1
    # Termux - use PREFIX for binaries
    set -x PATH $PREFIX/bin $HOME/.local/bin $HOME/.cargo/bin $PATH
else if test (uname) = Darwin
    # macOS - check for Apple Silicon vs Intel
    if test -f /opt/homebrew/bin/brew
        # Apple Silicon (M1/M2/M3)
        set BREW_BIN /opt/homebrew/bin/brew
    else if test -f /usr/local/bin/brew
        # Intel Mac
        set BREW_BIN /usr/local/bin/brew
    end
    set -x PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.config $HOME/.cargo/bin /usr/local/lib/* $PATH
else
    # Linux
    set BREW_BIN /home/linuxbrew/.linuxbrew/bin/brew
    set -x PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.config $HOME/.cargo/bin /usr/local/lib/* $PATH
end

# Only eval brew shellenv if brew is installed (not on Termux)
if test $IS_TERMUX -eq 0; and set -q BREW_BIN; and test -f $BREW_BIN
    eval ($BREW_BIN shellenv)
end

# Abrir herdr al abrir kitty. Solo en ventanas de kitty (no en VS Code, Windows Terminal ni SSH) y
# nunca dentro de herdr o zellij. Al salir de herdr (Ctrl+g q, o exit en el ultimo panel) se
# cierra la ventana; si herdr falla al arrancar (dura menos de 2 s) se queda en esta fish.
if status is-interactive; and set -q KITTY_WINDOW_ID; and not set -q HERDR_ENV; and not set -q ZELLIJ
    and type -q herdr
    set -l herdr_inicio (date +%s)
    herdr
    set -l herdr_duro (math (date +%s) - $herdr_inicio)
    # Salida normal: limpiar ya el mensaje de herdr ("server shut down…") para que no se vea
    # mientras se cierra la ventana. Si fallo al arrancar (< 2 s) el mensaje se queda visible.
    test $herdr_duro -ge 2; and clear
    # Se salio con exit en el ultimo panel: borrar la sesion guardada para que la proxima vez herdr
    # empiece de cero (con Ctrl+g q no hay marca y la sesion se conserva)
    if test -e ~/.cache/herdr/reset-session
        # En segundo plano y fuera de kitty (setsid) para que la ventana se cierre ya: esperar
        # (max 2 s) a que el servidor termine de apagarse y de guardar la sesion, y borrarla
        setsid -f fish --no-config -c '
            for i in (seq 20)
                herdr status server 2>/dev/null | string match -q "status: not running"; and break
                sleep 0.1
            end
            rm -f ~/.cache/herdr/reset-session ~/.config/herdr/session.json' >/dev/null 2>&1
    end
    # `exit` en config.fish solo deja de leer este archivo (fish sigue abierto a medias);
    # `exec true` reemplaza fish por un comando que termina al instante y la ventana se cierra
    test $herdr_duro -ge 2; and exec true
end

# fastfetch al abrir la terminal. Va antes de inicializar starship/zoxide/atuin/fzf/carapace para
# que aparezca cuanto antes (despues de brew shellenv: en Debian fastfetch viene de Homebrew).
# zellij se abre a mano: no deja pasar las imagenes de kitty.
if status is-interactive
    clear
    if not set -q ZELLIJ; and type -q fastfetch
        # Al arrancar herdr la terminal a veces aun no sabe su tamaño en pixeles y fastfetch cae al
        # logo ASCII. Esperamos (max 1 s) a que el pty lo tenga; se lee con ioctl, sin secuencias
        # de escape que interfieran con las consultas de fastfetch.
        if test "$HERDR_ENV" = 1; and type -q python3
            python3 -Ic '
import fcntl, struct, termios, time
for _ in range(50):
    try:
        with open("/dev/tty") as t:
            if struct.unpack("HHHH", fcntl.ioctl(t, termios.TIOCGWINSZ, b"\0" * 8))[2] > 0:
                break
    except OSError:
        break
    time.sleep(0.02)'
        end
        fastfetch
    end
end

# Initialize tools
starship init fish | source
zoxide init fish | source
atuin init fish | source
fzf --fish | source

set -x PATH $HOME/.cargo/bin $PATH

# Carapace completions
set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'

if not test -d ~/.config/fish/completions
    mkdir -p ~/.config/fish/completions
end

if not test -f ~/.config/fish/completions/.initialized
    if not test -d ~/.config/fish/completions
        mkdir -p ~/.config/fish/completions
    end
    carapace --list | awk '{print $1}' | xargs -I{} touch ~/.config/fish/completions/{}.fish
    touch ~/.config/fish/completions/.initialized
end

# `carapace _carapace` tarda ~125 ms en cada arranque y siempre genera lo mismo: se cachea y solo se
# regenera cuando cambia el binario de carapace (o el cache no existe)
set -l carapace_cache ~/.cache/carapace/init.fish
set -l carapace_bin (command -s carapace)
if test -n "$carapace_bin"
    if not test -s $carapace_cache; or test $carapace_bin -nt $carapace_cache
        mkdir -p (path dirname $carapace_cache)
        carapace _carapace >$carapace_cache
    end
    source $carapace_cache
end

set -g fish_greeting ""

# Enable vi mode
fish_vi_key_bindings

# Set nvim as default editor for opencode and other tools
set -gx EDITOR nvim
set -gx VISUAL nvim

## alias
alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias lt="eza --tree --icons"
alias lt2="eza --tree --icons --level=2"
alias lt3="eza --tree --icons --level=3"
alias lt4="eza --tree --icons --level=4"

# Alias for files and directories
alias ld="eza -lD --icons"
alias lf="eza -la --icons -f"

# Alias order for size and date
# for Date
alias lr="eza -la --icons --sort=modified --reverse"
# for size
alias lS="eza -la --icons --sort=size --reverse"

alias fzfbat='fzf --preview="bat --theme=\"Solarized (dark)\" --color=always {}"'
alias fzfnvim='nvim (fzf --preview="bat --theme=\"Solarized (dark)\" --color=always {}")'

# Alias to git
alias gs="git status"
alias gp="git push"
alias gl="git log --oneline --graph"
alias gc="git commit -m"

# Claude Code con bypass permissions
alias cl="claude --dangerously-skip-permissions"

# Obsidian vault sync
alias obs="git -C ~/.config/obsidian add . && git -C ~/.config/obsidian commit -m 'update notes' && git -C ~/.config/obsidian push"

# Alias for navegation
alias win="z /mnt/c/Users/Salchipapa"

# Gentleman theme (backup)
# set -l foreground F3F6F9 normal
# set -l selection 263356 normal
# set -l comment 8394A3 brblack
# set -l red CB7C94 red
# set -l orange DEBA87 orange
# set -l yellow FFE066 yellow
# set -l green B7CC85 green
# set -l purple A3B5D6 purple
# set -l cyan 7AA89F cyan
# set -l pink FF8DD7 magenta
#
# # Syntax Highlighting Colors
# set -g fish_color_normal $foreground
# set -g fish_color_command $cyan
# set -g fish_color_keyword $pink
# set -g fish_color_quote $yellow
# set -g fish_color_redirection $foreground
# set -g fish_color_end $orange
# set -g fish_color_error $red
# set -g fish_color_param $purple
# set -g fish_color_comment $comment
# set -g fish_color_selection --background=$selection
# set -g fish_color_search_match --background=$selection
# set -g fish_color_operator $green
# set -g fish_color_escape $pink
# set -g fish_color_autosuggestion $comment
#
# # Completion Pager Colors
# set -g fish_pager_color_progress $comment
# set -g fish_pager_color_prefix $cyan
# set -g fish_pager_color_completion $foreground
# set -g fish_pager_color_description $comment

# Solarized Osaka theme
set -l foreground 839395
set -l selection 073642
set -l comment 586e75
set -l red db302d
set -l orange c94c16
set -l yellow b28500
set -l green 849900
set -l blue 268bd3
set -l cyan 29a298
set -l magenta d23681

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $blue
set -g fish_color_keyword $magenta
set -g fish_color_quote $green
set -g fish_color_redirection 9eabac
set -g fish_color_end $cyan
set -g fish_color_error $red
set -g fish_color_param $foreground
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $cyan
set -g fish_color_escape $green
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $foreground
set -g fish_pager_color_prefix $blue
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment

# Fix valid path color (no underline)
set -g fish_color_valid_path $blue

# Fix WSL other-writable directories (Windows folders)
set -gx LS_COLORS "di=01;34:ow=01;34:ln=01;36:ex=01;32:*.tar=01;31:*.zip=01;31"
