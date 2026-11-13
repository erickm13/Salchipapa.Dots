# tema: cambia a la vez el tema de nvim (y su barra, lualine con theme = "auto") y el de herdr.
#   tema               muestra el tema actual y los disponibles
#   tema gruvbox       cambia los dos; herdr se recarga al instante, nvim al volver a abrirlo
# Edita las dos líneas del repo (colorscheme.lua y config.toml de herdr): queda como cambio sin
# commit en Salchipapa.Dots. Para añadir un tema: una línea "nombre nvim herdr" abajo.
function tema --description 'Cambia el tema de nvim y herdr a la vez'
    # nombre | colorscheme de nvim | tema de herdr
    set -l temas \
        "solarized solarized-osaka solarized" \
        "gruvbox gruvbox gruvbox" \
        "tokyonight tokyonight tokyo-night" \
        "kanagawa kanagawa kanagawa" \
        "rose-pine rose-pine rose-pine" \
        "catppuccin catppuccin catppuccin" \
        "nord nord nord"

    # Los archivos reales del repo (~/.config/nvim y el config.toml de herdr son enlaces)
    set -l nvim_cfg (realpath ~/.config/nvim 2>/dev/null)/lua/plugins/colorscheme.lua
    set -l herdr_cfg (realpath ~/.config/herdr/config.toml 2>/dev/null)
    if not test -f "$nvim_cfg"; or not test -f "$herdr_cfg"
        echo "tema: no encuentro colorscheme.lua de nvim o el config.toml de herdr" >&2
        return 1
    end

    set -l actual_nvim (string match -rg '^\s*colorscheme = "([^"]+)"' < $nvim_cfg)
    set -l actual_herdr (string match -rg '^name = "([^"]+)"' < $herdr_cfg)

    if test (count $argv) -eq 0
        echo "Actual: nvim $actual_nvim · herdr $actual_herdr"
        set -l nombres
        for t in $temas
            set -a nombres (string split ' ' $t)[1]
        end
        echo "Disponibles: $nombres"
        return 0
    end

    for t in $temas
        set -l campos (string split ' ' $t)
        test "$campos[1]" = "$argv[1]"; or continue
        sed -i -E "s/^(\s*colorscheme = )\"[^\"]+\"/\1\"$campos[2]\"/" $nvim_cfg
        sed -i -E "s/^name = \"[^\"]+\"/name = \"$campos[3]\"/" $herdr_cfg
        if type -q herdr; and herdr status server 2>/dev/null | string match -q '*running*'
            herdr server reload-config >/dev/null 2>&1
        end
        echo "Tema: $campos[1] (nvim $campos[2] · herdr $campos[3]). nvim lo toma al volver a abrirlo."
        return 0
    end

    set -l nombres
    for t in $temas
        set -a nombres (string split ' ' $t)[1]
    end
    echo "tema: no conozco «$argv[1]». Disponibles: $nombres" >&2
    return 1
end
