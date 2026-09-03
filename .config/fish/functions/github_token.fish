function github_token --description "Carrega GITHUB_PERSONAL_ACCESS_TOKEN a partir do item 'GITHUB_PERSONAL_ACCESS_TOKEN' no Bitwarden"
    set -l session (bw_session)
    or return 1

    set -l token (bwcli get item GITHUB_PERSONAL_ACCESS_TOKEN --session $session 2>/dev/null | jq -r '.notes // .login.password // empty')
    if test -z "$token"
        echo "github_token: item 'GITHUB_PERSONAL_ACCESS_TOKEN' não encontrado no cofre (crie um Secure Note ou Login com esse nome)" >&2
        return 1
    end

    set -gx GITHUB_PERSONAL_ACCESS_TOKEN $token
    echo "GITHUB_PERSONAL_ACCESS_TOKEN carregado nesta sessão."
end
