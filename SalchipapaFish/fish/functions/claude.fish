function claude --wraps claude --description 'Claude Code con el token de gh para el plugin de GitHub'
    # El plugin github de Claude Code se autentica con GITHUB_PERSONAL_ACCESS_TOKEN. Se toma de
    # la sesion de gh al abrir Claude Code: no se guarda en ningun archivo y siempre es el vigente.
    set -l token
    if not set -q GITHUB_PERSONAL_ACCESS_TOKEN; and type -q gh
        set token (gh auth token 2>/dev/null)
    end
    if test -n "$token"
        GITHUB_PERSONAL_ACCESS_TOKEN=$token command claude $argv
    else
        command claude $argv
    end
end
