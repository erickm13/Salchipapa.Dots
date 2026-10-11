function codex --wraps codex --description 'codex; al salir dice si se guardaron las notas de la sesion (Obsidian)'
    set -l antes (__vault_esperar_cierre --antes)
    command codex $argv
    set -l rc $status
    __vault_esperar_cierre $antes
    return $rc
end
