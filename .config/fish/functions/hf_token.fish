function hf_token --description "Carrega HF_TOKEN a partir do item 'HF_TOKEN' no Bitwarden"
    set -l session (bw_session)
    or return 1

    set -l token (bwcli get item HF_TOKEN --session $session 2>/dev/null | jq -r '.notes // .login.password // empty')
    if test -z "$token"
        echo "hf_token: item 'HF_TOKEN' não encontrado no cofre (crie um Secure Note ou Login com esse nome)" >&2
        return 1
    end

    set -gx HF_TOKEN $token
    echo "HF_TOKEN carregado nesta sessão."
end
