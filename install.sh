#!/usr/bin/env bash
#
# install.sh — cria symlinks dos arquivos deste repositório para o $HOME,
# fazendo backup de qualquer arquivo/pasta existente antes de sobrescrever.
#
# Uso:
#   git clone git@github.com:Heitorh3/dotfiles.git ~/dotfiles
#   cd ~/dotfiles
#   ./install.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Lista de caminhos (relativos a este repo / relativos a $HOME) a linkar.
TARGETS=(
  ".bashrc"
  ".profile"
  ".gitconfig"
  ".tool-versions"
  ".ssh/config"
  ".config/fish/config.fish"
  ".config/fish/fish_plugins"
  ".config/fish/functions"
  ".config/fish/completions"
  ".config/fish/conf.d"
  ".config/starship.toml"
  ".config/bat/config"
  ".config/btop/btop.conf"
  ".config/htop/htoprc"
  ".config/lazygit/config.yml"
  ".config/lazydocker/config.yml"
)

link_one() {
  local rel="$1"
  local src="$DOTFILES_DIR/$rel"
  local dest="$HOME/$rel"

  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$(readlink -f "$dest" 2>/dev/null || true)" = "$(readlink -f "$src")" ]; then
      echo "ok (já linkado): $rel"
      return
    fi
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    mv "$dest" "$BACKUP_DIR/$rel"
    echo "backup: $rel -> $BACKUP_DIR/$rel"
  fi

  ln -s "$src" "$dest"
  echo "linkado: $rel"
}

echo "Instalando dotfiles de $DOTFILES_DIR"
for t in "${TARGETS[@]}"; do
  link_one "$t"
done

echo ""
echo "Concluído. Backups (se houve) em: $BACKUP_DIR"
echo ""
echo "Lembrete: HF_TOKEN e outros segredos não ficam mais em arquivo — eles vêm"
echo "do Bitwarden. Instale a CLI (npm install -g @bitwarden/cli), rode"
echo "'bw login', crie o item 'HF_TOKEN' no cofre e depois use o comando"
echo "'hf_token' no fish sempre que precisar. Veja o README.md, seção"
echo "'Segredos via Bitwarden'."
