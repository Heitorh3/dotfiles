function bwcli --description "Bitwarden CLI (nome próprio para não colidir com o /bin/bw do sistema)"
    set -l candidates \
        $HOME/.local/share/nvm/*/bin/bw \
        $HOME/.nvm/versions/node/*/bin/bw

    set -l real_bw
    for c in $candidates
        if test -x $c
            set real_bw $c
        end
    end

    if test -z "$real_bw"
        echo "bwcli: Bitwarden CLI não encontrado. Rode: npm install -g @bitwarden/cli" >&2
        return 127
    end

    command $real_bw $argv
end
