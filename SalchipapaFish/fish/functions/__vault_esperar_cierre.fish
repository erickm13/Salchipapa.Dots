function __vault_esperar_cierre --description 'Al cerrar un agente: espera el resumen de su sesion y la subida de la boveda, y lo dice'
    # Lo usan las funciones claude, codex y copilot:
    #   set -l marca (__vault_esperar_cierre --antes)   # marca unica de esta ventana
    #   set -lx VAULT_SESSION_TOKEN $marca               # el agente (y su hook de cierre) la heredan
    #   command claude …; __vault_esperar_cierre $marca
    # El hook de cierre (vault-session-end.sh) trabaja en segundo plano y deja el resultado de ESTA
    # sesion en session-end/<marca>: otras ventanas o sesiones vacias no lo tapan. Si el agente no
    # tuvo sesion (claude --version, -p…) no hay nada que esperar.
    set -l dir ~/.cache/salchipapa-dots
    set -l cola $dir/session-queue
    if test "$argv[1]" = --antes
        echo (random)(random)-(date +%s%N)
        return 0
    end
    set -l marca $argv[1]
    set -l hecho $dir/session-end/$marca
    test -n "$marca"; and test -d $cola; or return 0

    set -l avisado 0
    for i in (seq 240) # como mucho 2 minutos
        if test -f $hecho
            test $avisado = 1; and printf '\r\033[K'
            cat $hecho
            rm -f $hecho
            return 0
        end
        # Ni en cola ni procesandose: este agente no cerro una sesion
        set -l marcas $cola/*.token # sin coincidencias: lista vacia (en un comando, fish daria error)
        if begin; test (count $marcas) -eq 0; or not grep -qxF -- $marca $marcas; end; and flock -n $cola/.lock true 2>/dev/null
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
