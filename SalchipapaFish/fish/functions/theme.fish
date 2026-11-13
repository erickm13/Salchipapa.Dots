# theme: aplica un tema de Salchipapa-Shell, lo mismo que elegirlo con Super+T: colores de la
# shell, terminal, nvim (también los abiertos), herdr, fish, starship, fzf, bat, eza, yazi, btop,
# lazygit… Cada app toma lo que trae shell/themes/<tema>/ del repo de la shell.
#   theme              muestra el tema actual y los disponibles
#   theme gruvbox      lo aplica (rose-pine vale como rosepine)
#   theme gruvbox soft con variante, si el tema tiene varias
# No toca los dotfiles: lo que cambia queda en ~/.local/state/salchipapa-shell/.
function theme --description 'Aplica un tema de Salchipapa-Shell (lo mismo que Super+T)'
    set -l shell_dir (realpath ~/.config/hypr 2>/dev/null)
    set -l apply $shell_dir/scripts/apply-colors.sh
    set -l schemes $shell_dir/shell/themes/schemes.json
    if not test -x "$apply"; or not test -f "$schemes"
        echo "theme: no encuentro Salchipapa-Shell (~/.config/hypr)" >&2
        return 1
    end

    set -l names (jq -r 'keys[]' $schemes | string match -v dynamic)
    if test (count $argv) -eq 0
        echo "Actual: "(cat ~/.local/state/salchipapa-shell/scheme 2>/dev/null; or echo "ninguno")
        echo "Disponibles: $names"
        return 0
    end

    set -l name (string replace -- rose-pine rosepine $argv[1])
    if not contains -- $name $names
        echo "theme: no conozco «$argv[1]». Disponibles: $names" >&2
        return 1
    end
    $apply scheme $name $argv[2..]
    and echo "Tema: $name"
end
