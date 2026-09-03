set -U fish_greeting

if status is-interactive
# Commands to run in interactive sessions can go here
end

set SPACEFISH_PROMPT_ADD_NEWLINE true

# set PATH /home/heitor/.local/share/pnpm $PATH
# set PATH $PATH $HOME/.nvm/versions/node/v20.0.11/bin
# set PATH STARSHIP_CACHE=~/.starship/cache $PATH	

set -U fish_user_paths $fish_user_paths $HOME/.local/share/pnpm
# set -U fish_user_paths $fish_user_paths $HOME/.local/share/nvm/v22.15.1/bin
set -U fish_user_paths $fish_user_paths $HOME/.local/share/nvm/v24.1.0/bin
set -U fish_user_paths $fish_user_paths $HOME/.starship/cache

# n 
#set PATH $PATH/usr/local/n

set -x ASDF_DATA_DIR $HOME/.asdf $PATH
#set PATH $PATH/usr/local/bin/go/bin/

#hugginface — carregado sob demanda do Bitwarden, rode `hf_token` quando precisar
# (evita pedir a master password em todo terminal novo)

starship init fish | source

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
set -gx PATH /usr/local/go/bin $PATH

# SSH Agent: usa o agent do Bitwarden Desktop (SSH Agent habilitado em
# Configurações > SSH Agent no app) — a chave privada fica só no cofre,
# nunca em disco. Se o Bitwarden não estiver rodando, cai pro agent do
# sistema (gnome-keyring/ssh-agent) e não faz nada.
set -l bw_ssh_sock "$HOME/.bitwarden-ssh-agent.sock"
if test -S "$bw_ssh_sock"
    set -x SSH_AUTH_SOCK $bw_ssh_sock
end

# Aliases
alias ccm="git diff | cody chat --stdin -m 'Write a commit message for this diff'"
alias ocm="git diff | ollama run llama3.1 'Write a commit message for this diff'"
alias kubectl="minikube kubectl "

alias rodou-start="minikube kubectl -- -n airflow-rodou port-forward service/rodou-ro-dou-airflow-api-server 8080:8080"

# alias cloudBeaver="kubectl port-forward -n cloudbeaver deployment/dbeaver 8978:8978 &"
#alias vault="kubectl port-forward -n vault vault-0 8200:8200 &"

#alias cat="bat --theme=\$(read -globalDomain AppleInterfaceStyle &> /dev/null && echo default || echo GitHub)"
alias cat="bat --theme=\$(read -globalDomain AppleInterfaceStyle &> /dev/null && echo default || echo Dracula)"

alias l="ls -la"
alias ls="eza --color=always --long --git --icons=always"
#alias cd="z"
alias bat="batcat"
alias batdiff="git diff --name-only --relative --diff-filter=d | xargs batcat --diff"

zoxide init fish | source

export FZF_CTRL_T_OPTS="
  --style full
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

function fish_greeting
    echo 💻 The time is (set_color yellow)(date +%T)(set_color normal) and this machine is called $hostname
end

function cloudBeaver
    kubectl port-forward -n cloudbeaver deployment/dbeaver 8978:8978 &
    echo "🛢️ cloudBeaver is running on port 8978!" 
end

function jupyter
    kubectl port-forward -n airflow-dev $(kubectl get pods -n airflow-dev --no-headers -o custom-columns=":metadata.name" | grep "jupyter") 8888:8888 & 
    echo "🚀 Jupyter is running on port 8888!"    
end

function vault
    kubectl port-forward -n vault vault-0 8200:8200 & 
    echo "🚀 Vault is running on port 8200!"
end

function airflow
    kubectl port-forward svc/airflow-dev-web 8080:8080 -n airflow-dev & 
    echo "🚀 Airflow dev is running on port 8080!"
end

function nas
    mount -t nfs 192.168.100.43:/backup /home/heitor/netgear/ -o rw,hard,intr & 
    mount -t nfs 192.168.100.43:/pessoal /home/heitor/netgear/ -o rw,hard,intr &
    mount -t nfs 192.168.100.43:/cginf /home/heitor/netgear/ -o rw,hard,intr &
    echo "🛢️ units assembled successfully!"    
end

# ASDF configuration code
# if test -z $ASDF_DATA_DIR
#     set _asdf_shims "$HOME/.asdf/shims"
# else
#     set _asdf_shims "$ASDF_DATA_DIR/shims"
# end

# Do not use fish_add_path (added in Fish 3.2) because it
# potentially changes the order of items in PATH
# if not contains $_asdf_shims $PATH
#     set -gx --prepend PATH $_asdf_shims
# end

set --erase _asdf_shims

# Plugins
# EZA
# https://github.com/eza-community/eza/blob/main/INSTALL.md

# FZF
# https://github.com/junegunn/fzf?tab=readme-ov-file#linux-packages

# BAT
# https://github.com/sharkdp/bat

# ZOXIDE
# https://github.com/ajeetdsouza/zoxide

# Silver Searcher
# https://github.com/ggreer/the_silver_searcher

# Verificar se é necessário instalar o plugin ou se a função acima já resolve o problema da chave ssh
# Instalar o Fisher (gerenciador de plugins do Fish) se não tiver
#curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# Instalar o plugin ssh-agent
#fisher install danhper/fish-ssh-agent

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/heitor/miniconda3/bin/conda
    eval /home/heitor/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/home/heitor/miniconda3/etc/fish/conf.d/conda.fish"
        . "/home/heitor/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/heitor/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)"
