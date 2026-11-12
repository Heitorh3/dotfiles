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
  ".config/Code/User/settings.json"
  ".config/Code/User/keybindings.json"
  ".local/bin/ai-memory-project"
  ".local/bin/ai-memory-continue-bridge"
  ".local/bin/filezilla-bitwarden"
  ".local/share/applications/filezilla.desktop"
  ".continue/config.yaml"
  ".claude/settings.json"
  ".claude/skills/usar-prompt"
)

link_one() {
  local rel="$1"
  local src="$DOTFILES_DIR/$rel"
  local dest="$HOME/$rel"

  # Evita criar symlink quebrado se o arquivo não existir no repositório.
  if [ ! -e "$src" ]; then
    echo "aviso: $rel não existe em $DOTFILES_DIR (pulando)"
    return
  fi

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

if command -v ollama-symlinks >/dev/null 2>&1; then
  echo "ok (já instalado): ollama-symlinks"
else
  echo "Instalando ollama-symlinks..."
  curl -fsSL https://raw.githubusercontent.com/qaribhaider/ollama-to-lmstudio-symlinks/main/install.sh | bash \
    || echo "aviso: falha ao instalar ollama-symlinks (seguindo em frente)"
fi

# copilot-cli (comando `ms`): instala só se faltar e loga só se a conta
# ainda não estiver no cache. Falhas aqui não interrompem o restante.
install_copilot_cli() {
  local account="heitor.neto@gestao.gov.br"

  if command -v ms >/dev/null 2>&1; then
    echo "ok (já instalado): copilot-cli"
  elif command -v npm >/dev/null 2>&1; then
    echo "Instalando copilot-cli..."
    npm install -g @microsoft/managed-apps-cli \
      || { echo "aviso: falha ao instalar o copilot-cli (seguindo em frente)"; return; }
  else
    echo "aviso: npm não encontrado; instale o Node e rode ./install.sh de novo para instalar o copilot-cli"
    return
  fi

  if ms auth status 2>/dev/null | grep -qiF "$account"; then
    echo "ok (já logado): copilot-cli como $account"
  else
    echo "Logando no copilot-cli..."
    ms auth login --account "$account" \
      || echo "aviso: falha no login do copilot-cli (rode 'ms auth login' depois)"
  fi
}

install_copilot_cli

# Plugins do Claude Code: a lista versionada fica em .claude/settings.json
# (enabledPlugins e extraKnownMarketplaces); os arquivos são baixados aqui.
install_claude_plugins() {
  local settings="$DOTFILES_DIR/.claude/settings.json"
  local name source plugin marketplaces installed

  if ! command -v claude >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "aviso: claude ou jq não encontrado; instale-os e rode ./install.sh de novo para restaurar os plugins"
    return
  fi

  # Consulta cada lista uma vez só, em vez de chamar o claude a cada item.
  marketplaces="$(claude plugin marketplace list </dev/null 2>/dev/null || true)"
  installed="$(claude plugin list </dev/null 2>/dev/null || true)"

  while IFS=$'\t' read -r name source; do
    if grep -qF -- "$name" <<<"$marketplaces"; then
      echo "ok (já adicionado): marketplace $name"
    else
      echo "Adicionando marketplace $name..."
      claude plugin marketplace add "$source" --scope user </dev/null \
        || echo "aviso: falha ao adicionar o marketplace $name (seguindo em frente)"
    fi
  done < <(jq -r '.extraKnownMarketplaces // {} | to_entries[]
    | [.key, (.value.source | .repo // .url // .path)] | @tsv' "$settings")

  while IFS= read -r plugin; do
    if grep -qF -- "$plugin" <<<"$installed"; then
      echo "ok (já instalado): plugin $plugin"
    else
      echo "Instalando plugin $plugin..."
      claude plugin install "$plugin" --scope user </dev/null \
        || echo "aviso: falha ao instalar o plugin $plugin (seguindo em frente)"
    fi
  done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$settings")
}

install_claude_plugins

echo ""
echo "Concluído. Backups (se houve) em: $BACKUP_DIR"
echo ""
echo "Lembrete: HF_TOKEN e outros segredos não ficam mais em arquivo — eles vêm"
echo "do Bitwarden. Instale a CLI (npm install -g @bitwarden/cli), rode"
echo "'bwcli login', crie o item 'HF_TOKEN' no cofre e depois use o comando"
echo "'hf_token' no fish sempre que precisar. Veja o README.md, seção"
echo "'Segredos via Bitwarden'."
