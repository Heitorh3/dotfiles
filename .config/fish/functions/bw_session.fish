function bw_session --description "Retorna uma BW_SESSION válida do Bitwarden, desbloqueando se necessário"
    if set -q BW_SESSION
        set -l current_status (bw status --session $BW_SESSION 2>/dev/null | jq -r '.status' 2>/dev/null)
        if test "$current_status" = "unlocked"
            echo $BW_SESSION
            return 0
        end
    end

    set -l new_session (bw unlock --raw)
    if test -z "$new_session"
        echo "bw_session: falha ao desbloquear o Bitwarden" >&2
        return 1
    end

    set -gx BW_SESSION $new_session
    echo $new_session
end
