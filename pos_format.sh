#!/usr/bin/env bash
#
# post_install.sh — script de pós-instalação para Linux Mint (base Ubuntu Noble).
#
# Reinstala os apps do dia a dia que rodam nesta máquina (Chrome, VS Code, Docker,
# kubectl, Slack, Spotify, Insync, AnyDesk, Azure CLI, Warp, DBeaver, Discord, ...),
# as ferramentas de terminal usadas pelo ~/dotfiles (fish, starship, asdf, eza,
# zoxide, bat, btop, lazygit, lazydocker, fisher) e no final clona/aplica o
# ~/dotfiles. Baseado originalmente no tutorial de Fernando Souza
# (https://www.youtube.com/@fernandosuporte/).
#
# Uso: ./post_install.sh
# Pode ser rodado mais de uma vez — cada passo checa se já foi feito antes de agir.

set -uo pipefail

# ----------------------------- CORES / LOG ----------------------------- #
c_ok="\e[1;32m"; c_err="\e[1;31m"; c_info="\e[1;34m"; c_reset="\e[0m"

log_info() { echo -e "${c_info}[INFO]${c_reset} $*"; }
log_ok()   { echo -e "${c_ok}[OK]${c_reset} $*"; }
log_err()  { echo -e "${c_err}[ERRO]${c_reset} $*" >&2; }

# Roda um passo "opcional": avisa e segue em frente se falhar, em vez de
# derrubar o script inteiro (rede instável, URL de terceiro fora do ar, etc.).
run_optional() {
  local desc="$1"; shift
  if "$@"; then
    log_ok "$desc"
  else
    log_err "$desc — falhou, pulando (rode manualmente depois se precisar)."
  fi
}

clear

# ----------------------------- REQUISITOS ----------------------------- #
for cmd in dpkg apt wget curl git ping gpg flatpak; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_err "Comando obrigatório não encontrado: $cmd"
    exit 1
  fi
done

log_info "Verificando o acesso à internet..."
if ping -c 3 -W 2 www.google.com.br >/dev/null 2>&1; then
  log_ok "Conexão com a internet funcionando normalmente."
else
  log_err "Sem conexão com a internet. Verifique a rede antes de continuar."
  exit 1
fi

# Pede a senha do sudo uma vez só e mantém viva durante o script.
sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null & )

# ----------------------------- VARIÁVEIS ----------------------------- #
DIRETORIO_DOWNLOADS="$HOME/Downloads/programas"
KEYRINGS_DIR="/etc/apt/keyrings"
DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_REPO="git@github.com:Heitorh3/dotfiles.git"
# Fallback para quando a chave SSH ainda não está disponível (ex: máquina
# recém-formatada, antes de abrir o Bitwarden e habilitar o SSH Agent).
DOTFILES_REPO_HTTPS="https://github.com/Heitorh3/dotfiles.git"

URL_GOOGLE_CHROME="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
URL_VSCODE="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
URL_DISCORD="https://discord.com/api/download?platform=linux&format=deb"
URL_DBEAVER_CE="https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb"
# Verifique se este link ainda é válido antes de rodar; o site costuma mudar o
# padrão de nome. Baixe manualmente em https://www.4kdownload.com/downloads se falhar.
URL_4K_VIDEO_DOWNLOADER="https://dl.4kdownload.com/app/4kvideodownloaderplus_amd64.deb"

# Pacotes comuns via apt (sem repositório extra, universe/multiverse já bastam)
PACOTES_APT_BASE=(
  fish
  bat
  btop
  htop
  fzf
  silversearcher-ag
  flameshot
  7zip
  gh
)

# Pacotes que dependem de repositórios de terceiros adicionados abaixo
PACOTES_APT_TERCEIROS=(
  eza
  docker-ce
  docker-ce-cli
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
  kubectl
  azure-cli
  warp-terminal
  ulauncher
  copyq
  insync
  insync-nemo
  spotify-client
  slack-desktop
  anydesk
  warpinator
  zoxide
)
# ---------------------------------------------------------------------- #

# ----------------------------- APT: destravar e atualizar ----------------------------- #
if sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; then
  log_err "apt/dpkg parece estar em uso por outro processo — não vou remover os locks."
else
  sudo rm -f /var/lib/dpkg/lock-frontend /var/cache/apt/archives/lock
fi
sudo dpkg --configure -a

sudo apt update -y
sudo mkdir -p "$KEYRINGS_DIR"

# ----------------------------- REPOSITÓRIOS DE TERCEIROS ----------------------------- #
# Cada bloco só adiciona o repositório se ele ainda não existir (idempotente).

add_keyed_repo() {
  # add_keyed_repo <arquivo.list> <linha deb completa> <url da chave> <arquivo da chave>
  local list_file="/etc/apt/sources.list.d/$1"
  local deb_line="$2" key_url="$3" keyring="$4"

  if [ -f "$list_file" ]; then
    log_ok "Repositório já presente: $1"
    return 0
  fi

  curl -fsSL "$key_url" | sudo gpg --dearmor -o "$keyring" || return 1
  echo "$deb_line" | sudo tee "$list_file" >/dev/null
}

run_optional "Repositório Docker CE" add_keyed_repo \
  "docker.list" \
  "deb [arch=amd64 signed-by=$KEYRINGS_DIR/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  "https://download.docker.com/linux/ubuntu/gpg" \
  "$KEYRINGS_DIR/docker.gpg"

run_optional "Repositório Kubernetes (kubectl)" add_keyed_repo \
  "kubernetes.list" \
  "deb [signed-by=$KEYRINGS_DIR/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" \
  "https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key" \
  "$KEYRINGS_DIR/kubernetes-apt-keyring.gpg"

run_optional "Repositório eza" add_keyed_repo \
  "gierens.list" \
  "deb [arch=amd64 signed-by=$KEYRINGS_DIR/gierens.gpg] http://deb.gierens.de stable main" \
  "https://raw.githubusercontent.com/eza-community/eza/main/deb.asc" \
  "$KEYRINGS_DIR/gierens.gpg"

run_optional "Repositório Insync" add_keyed_repo \
  "insync.list" \
  "deb [signed-by=$KEYRINGS_DIR/insync.gpg] http://apt.insync.io/mint xia non-free contrib" \
  "https://d2t3ff60b2tol4.cloudfront.net/DEB-GPG-KEY-INSYNC" \
  "$KEYRINGS_DIR/insync.gpg"

run_optional "Repositório Spotify" add_keyed_repo \
  "spotify.list" \
  "deb https://repository.spotify.com stable non-free" \
  "https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg" \
  "$KEYRINGS_DIR/spotify.gpg"

run_optional "Repositório Slack" add_keyed_repo \
  "slack.list" \
  "deb https://packagecloud.io/slacktechnologies/slack/debian/ jessie main" \
  "https://packagecloud.io/slacktechnologies/slack/gpgkey" \
  "$KEYRINGS_DIR/slack.gpg"

run_optional "Repositório AnyDesk" add_keyed_repo \
  "anydesk-stable.list" \
  "deb [signed-by=$KEYRINGS_DIR/anydesk.gpg] http://deb.anydesk.com/ all main" \
  "https://keys.anydesk.com/repos/DEB-GPG-KEY" \
  "$KEYRINGS_DIR/anydesk.gpg"

run_optional "Repositório Warp terminal" add_keyed_repo \
  "warpdotdev.list" \
  "deb [arch=amd64 signed-by=$KEYRINGS_DIR/warpdotdev.gpg] https://releases.warp.dev/linux/deb stable main" \
  "https://releases.warp.dev/linux/keys/warp.asc" \
  "$KEYRINGS_DIR/warpdotdev.gpg"

if [ ! -f /etc/apt/sources.list.d/azure-cli.sources ]; then
  run_optional "Repositório Azure CLI" bash -c '
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg
    echo "Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: $(lsb_release -cs)
Components: main
Architectures: amd64
Signed-by: /etc/apt/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/azure-cli.sources >/dev/null
  '
else
  log_ok "Repositório Azure CLI já presente"
fi

if ! apt-cache policy ulauncher 2>/dev/null | grep -q ppa.launchpadcontent.net/agornostal; then
  run_optional "PPA do ulauncher" sudo add-apt-repository -y ppa:agornostal/ulauncher
else
  log_ok "PPA do ulauncher já presente"
fi

if ! apt-cache policy copyq 2>/dev/null | grep -q ppa.launchpadcontent.net/hluk; then
  run_optional "PPA do copyq" sudo add-apt-repository -y ppa:hluk/copyq
else
  log_ok "PPA do copyq já presente"
fi

sudo apt update -y

# ----------------------------- INSTALAÇÃO DE PACOTES ----------------------------- #
instalar_pacotes_apt() {
  for pacote in "$@"; do
    if dpkg -s "$pacote" >/dev/null 2>&1; then
      log_ok "já instalado: $pacote"
    else
      sudo apt install -y "$pacote" || log_err "falha ao instalar: $pacote"
    fi
  done
}

instalar_pacotes_apt "${PACOTES_APT_BASE[@]}"
instalar_pacotes_apt "${PACOTES_APT_TERCEIROS[@]}"

# ----------------------------- PACOTES .DEB AVULSOS ----------------------------- #
mkdir -p "$DIRETORIO_DOWNLOADS"

baixar_e_instalar_deb() {
  local nome="$1" url="$2"
  local destino="$DIRETORIO_DOWNLOADS/$nome.deb"

  if wget -q --user-agent="Mozilla/5.0" -O "$destino" "$url"; then
    sudo dpkg -i "$destino" || sudo apt-get install -f -y
    log_ok "$nome instalado/atualizado"
  else
    rm -f "$destino"
    log_err "não consegui baixar $nome de $url — instale manualmente."
  fi
}

run_optional "Google Chrome"        baixar_e_instalar_deb "google-chrome" "$URL_GOOGLE_CHROME"
run_optional "Visual Studio Code"   baixar_e_instalar_deb "vscode" "$URL_VSCODE"
run_optional "Discord"              baixar_e_instalar_deb "discord" "$URL_DISCORD"
run_optional "DBeaver CE"           baixar_e_instalar_deb "dbeaver-ce" "$URL_DBEAVER_CE"
run_optional "4K Video Downloader+" baixar_e_instalar_deb "4kvideodownloaderplus" "$URL_4K_VIDEO_DOWNLOADER"

# ----------------------------- FLATPAK ----------------------------- #
run_optional "Bitwarden (flatpak)" flatpak install -y --noninteractive flathub com.bitwarden.desktop
run_optional "Telegram (flatpak)"  flatpak install -y --noninteractive flathub org.telegram.desktop
run_optional "OBS Studio (flatpak)" flatpak install -y --noninteractive flathub com.obsproject.Studio

# ----------------------------- DOCKER: pós-instalação ----------------------------- #
if command -v docker >/dev/null 2>&1; then
  sudo systemctl enable --now docker || true
  if ! groups "$USER" | grep -q '\bdocker\b'; then
    sudo usermod -aG docker "$USER"
    log_info "Usuário adicionado ao grupo docker — é preciso relogar (ou 'newgrp docker') para valer."
  fi
fi

# ----------------------------- FERRAMENTAS DE TERMINAL (dotfiles) ----------------------------- #
if ! command -v brew >/dev/null 2>&1; then
  run_optional "Homebrew" bash -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
else
  log_ok "Homebrew já instalado"
fi
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true

if command -v brew >/dev/null 2>&1 && ! command -v asdf >/dev/null 2>&1; then
  run_optional "asdf (via brew)" brew install asdf
fi

if ! command -v starship >/dev/null 2>&1; then
  run_optional "Starship" bash -c 'curl -fsSL https://starship.rs/install.sh | sh -s -- -y'
fi

if ! command -v zoxide >/dev/null 2>&1; then
  run_optional "zoxide" bash -c 'curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash'
fi

if ! command -v lazydocker >/dev/null 2>&1; then
  run_optional "lazydocker" bash -c 'curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash'
fi

if ! command -v lazygit >/dev/null 2>&1; then
  run_optional "lazygit" bash -c '
    set -e
    LAZYGIT_VERSION=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po "\"tag_name\": \"v\K[^\"]*")
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar -xf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
    sudo install "$tmp/lazygit" /usr/local/bin
    rm -rf "$tmp"
  '
fi

if [ ! -d "$HOME/.nvm" ]; then
  run_optional "nvm" bash -c 'curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash'
fi
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

if command -v nvm >/dev/null 2>&1; then
  nvm install --lts >/dev/null 2>&1 || true
  command -v pnpm >/dev/null 2>&1 || run_optional "pnpm" npm install -g pnpm
  command -v bun  >/dev/null 2>&1 || run_optional "bun"  npm install -g bun
  command -v bw   >/dev/null 2>&1 || run_optional "Bitwarden CLI" npm install -g @bitwarden/cli
fi

if [ ! -d /usr/local/go ]; then
  run_optional "Go" bash -c '
    set -e
    GO_VERSION=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1)
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/go.tar.gz" "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$tmp/go.tar.gz"
    rm -rf "$tmp"
  '
fi

if [ ! -d "$HOME/miniconda3" ]; then
  run_optional "Miniconda" bash -c '
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/miniconda.sh" https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash "$tmp/miniconda.sh" -b -p "$HOME/miniconda3"
    rm -rf "$tmp"
  '
fi

if command -v fish >/dev/null 2>&1 && ! fish -c "functions -q fisher" 2>/dev/null; then
  run_optional "Fisher + plugins do fish" fish -c '
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher edc/bass jorgebucaran/nvm.fish danhper/fish-ssh-agent
  '
fi

if command -v fish >/dev/null 2>&1 && [ "$SHELL" != "$(command -v fish)" ]; then
  run_optional "fish como shell padrão" sudo chsh -s "$(command -v fish)" "$USER"
fi

# ----------------------------- DOTFILES ----------------------------- #
if [ -d "$DOTFILES_DIR/.git" ]; then
  run_optional "Atualizar ~/dotfiles" git -C "$DOTFILES_DIR" pull --ff-only
elif git clone "$DOTFILES_REPO" "$DOTFILES_DIR" 2>/dev/null; then
  log_ok "Clonar ~/dotfiles (SSH)"
else
  log_err "Clonar ~/dotfiles via SSH falhou (chave ainda não disponível? veja o Bitwarden SSH Agent no README) — tentando via HTTPS."
  run_optional "Clonar ~/dotfiles (HTTPS)" git clone "$DOTFILES_REPO_HTTPS" "$DOTFILES_DIR"
fi

if [ -x "$DOTFILES_DIR/install.sh" ]; then
  "$DOTFILES_DIR/install.sh"
elif [ -f "$DOTFILES_DIR/install.sh" ]; then
  bash "$DOTFILES_DIR/install.sh"
else
  log_err "~/dotfiles/install.sh não encontrado — os symlinks não foram criados. Resolva o acesso ao repositório e rode '~/dotfiles/install.sh' manualmente."
fi

# minikube via asdf, na versão fixada em .tool-versions do dotfiles
if command -v asdf >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/.tool-versions" ]; then
  asdf plugin add minikube >/dev/null 2>&1 || true
  run_optional "minikube (via asdf)" bash -c "cd '$DOTFILES_DIR' && asdf install minikube"
fi

# ----------------------------- FINALIZAÇÃO ----------------------------- #
sudo apt update && sudo apt dist-upgrade -y
flatpak update -y || true
sudo apt autoclean
sudo apt autoremove -y

log_ok "Pós-instalação concluída."
log_info "Pendências manuais: abrir o Bitwarden Desktop e habilitar o SSH Agent (a chave id_ed25519 é servida pelo cofre, ver README do dotfiles), 'bwcli login' + item HF_TOKEN, e relogar para o grupo docker/shell fish valerem."
