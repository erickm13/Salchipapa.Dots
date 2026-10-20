function codex --wraps codex --description 'codex; al salir dice si se guardaron las notas de la sesion (Obsidian)'
    # Marca de esta ventana: el hook de cierre deja aqui el resultado de esta sesion, no el de otra
    set -l antes (__vault_esperar_cierre --antes)
    set -lx VAULT_SESSION_TOKEN $antes
    command codex $argv
    set -l rc $status
    __vault_esperar_cierre $antes
    return $rc
end
