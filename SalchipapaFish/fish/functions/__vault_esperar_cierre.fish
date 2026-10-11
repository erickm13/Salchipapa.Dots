function __vault_esperar_cierre --description 'Al cerrar un agente: espera el resumen de la sesion y la subida de la boveda, y lo dice'
    # argv[1]: el resultado que habia antes de abrir el agente (`__vault_esperar_cierre --antes`).
    # Lo usan las funciones claude, codex y copilot.
    # El hook de cierre (vault-session-end.sh) trabaja en segundo plano y deja el resultado en
    # session-end.status. Si el agente no tuvo sesion (claude --version, -p…) no hay nada que esperar.
    set -l dir ~/.cache/salchipapa-dots
    set -l estado $dir/session-end.status
    set -l cola $dir/session-queue
    if test "$argv[1]" = --antes
        # Marca del ultimo resultado (ns), para reconocer luego el de esta sesion
        head -n1 $estado 2>/dev/null; or echo 0
        return 0
    end
    set -l antes $argv[1]
    test -d $cola; or return 0

    set -l avisado 0
    for i in (seq 240) # como mucho 2 minutos
        if test -f $estado; and test (head -n1 $estado) != "$antes"
            test $avisado = 1; and printf '\r\033[K'
            tail -n +2 $estado
            return 0
        end
        # Nada en cola ni procesandose: este agente no cerro una sesion (o ya se informo)
        if test (count $cola/*.json) -eq 0; and flock -n $cola/.lock true 2>/dev/null
            test $avisado = 1; and printf '\r\033[K'
            return 0
        end
        if test $avisado = 0
            printf '⏳ Guardando el resumen de la sesión en la bóveda… (Ctrl+C: que siga en segundo plano)'
            set avisado 1
        end
        sleep 0.5
    end
    printf '\r\033[K⚠ El resumen sigue en segundo plano (detalle: %s/session-log.log)\n' $dir
end
