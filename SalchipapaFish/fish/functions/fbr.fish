# fbr [búsqueda]: cambiar de rama de git con fzf. Ramas locales y remotas, las más recientes primero;
# vista previa con sus últimos commits. Una remota (origin/x) se cambia a la local x (git la crea
# siguiendo a la remota si no existe).
function fbr --description "Cambiar de rama de git con fzf (vista previa: últimos commits)"
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "fbr: no estás dentro de un repo de git" >&2
        return 1
    end
    # %(symref) vacío = no es un alias como origin/HEAD
    set -l branch (git for-each-ref --sort=-committerdate \
        --format='%(if)%(symref)%(then)%(else)%(refname:short)%(end)' refs/heads refs/remotes |
        string match -v '' |
        SHELL=/bin/sh fzf --prompt='branch> ' --query="$argv" \
            --preview='git log --oneline --graph --color=always -20 {}' \
            --border-label=' Enter: cambiar de rama ' --border-label-pos=-2:bottom)
    or return
    for remote in (git remote)
        if string match -q -- "$remote/*" $branch
            set branch (string replace -- "$remote/" '' $branch)
            break
        end
    end
    git switch $branch
end
