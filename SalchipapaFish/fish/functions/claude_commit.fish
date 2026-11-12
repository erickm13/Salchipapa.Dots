function claude_commit --description 'Claude escribe el mensaje y hace commit de lo que está en stage (tecla C en lazygit)'
    # Basado en craftzdog/dotfiles. Solo commitea lo que ya está en stage: no puede hacer git add ni push.
    if git diff --cached --quiet
        echo "No hay nada en stage: añade los archivos primero (espacio en lazygit)."
        return 1
    end

    # Los commits que escribe un agente firman como Padawan-Salchipapa (ver la bóveda, hub de IA)
    set -lx GIT_AUTHOR_NAME Padawan-Salchipapa
    set -lx GIT_AUTHOR_EMAIL 346263417+Padawan-Salchipapa@users.noreply.github.com
    set -lx GIT_COMMITTER_NAME $GIT_AUTHOR_NAME
    set -lx GIT_COMMITTER_EMAIL $GIT_AUTHOR_EMAIL

    set -l prompt 'Haz un commit de los cambios que están en stage en este repo. No saludes ni hagas resúmenes de sesión: solo el commit.
1. Mira `git diff --cached` y `git log -10 --oneline` para seguir el estilo de mensajes del repo (idioma, conventional commits, etc.).
2. Escribe un mensaje conciso: título de una línea y, si hace falta, un cuerpo corto que explique el porqué.
3. Ejecuta `git commit -m ...` (sin trailer Co-Authored-By ni firma de Claude). No hagas git add, ni push, ni amend.
4. Termina con una sola línea: el título del commit.'

    set -l progress_filter '
        if .type == "system" and .subtype == "init" then "● Claude Code empezó"
        elif .type == "assistant" then
            .message.content[]
            | if .type == "thinking" then "● Pensando…"
              elif .type == "tool_use" then "$ " + (.input.command // .name)
              elif .type == "text" then "\n" + .text
              else empty end
        elif .type == "user" then
            .message.content[]?
            | select(.type == "tool_result")
            | .content
            | if type == "array" then map(.text // "") | join("\n") else tostring end
        else empty end'

    # `command claude` salta el wrapper de fish (espera el cierre de la bóveda);
    # disableAllHooks evita que cada commit abra/cierre una sesión en la nota diaria.
    command claude -p $prompt \
        --settings '{"disableAllHooks": true}' \
        --allowedTools "Bash(git diff:*)" "Bash(git log:*)" "Bash(git status:*)" "Bash(git commit:*)" \
        --output-format stream-json --verbose </dev/null \
        | jq --unbuffered -r $progress_filter
end
