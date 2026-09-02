# dotfiles

Arquivos de configuração da minha máquina Linux, para restaurar rapidamente o
ambiente após uma formatação.

## O que tem aqui

- Shell: `.bashrc`, `.profile`, `.config/fish/` (config, functions, completions, conf.d, plugins)
- Git: `.gitconfig`
- Prompt: `.config/starship.toml`
- Versões de ferramentas (asdf): `.tool-versions`
- SSH: `.ssh/config` (apenas o arquivo de configuração — **nenhuma chave privada é versionada**)
- Ferramentas de terminal: `.config/bat`, `.config/btop`, `.config/htop`, `.config/lazygit`, `.config/lazydocker`

## O que **não** está aqui (de propósito)

Chaves SSH/GPG, credenciais AWS/Azure, tokens do `gh`, histórico de shell,
sessões/estado de apps (Discord, Slack, Cursor, VS Code, navegador) e qualquer
outro segredo. Esses arquivos ficam fora de controle de versão por segurança.

O `.config/fish/config.fish` tinha uma variável `HF_TOKEN` (token da Hugging
Face) com o valor real — ela foi substituída por um placeholder
(`SEU_TOKEN_AQUI`). Depois de instalar, edite o arquivo e coloque seu token
pessoal ali (ou, melhor ainda, migre para um gerenciador de segredos).

## Como usar após formatar a máquina

```bash
git clone git@github.com:Heitorh3/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

O script cria **symlinks** de cada arquivo/pasta deste repositório para o
local correspondente em `$HOME`. Se já existir algo no destino, ele faz
backup em `~/.dotfiles-backup-<timestamp>/` antes de sobrescrever.

Depois de rodar o script:

1. Preencha `HF_TOKEN` em `~/.config/fish/config.fish` (ou remova a linha se
   não usar).
2. Gere/restaure suas chaves SSH manualmente em `~/.ssh/` (não incluídas aqui).
3. Instale as ferramentas que os configs esperam (fish, starship, asdf, bat,
   btop, htop, lazygit, lazydocker) via seu gerenciador de pacotes preferido.

## Atualizando o repositório com mudanças locais

Como os arquivos em `$HOME` viram symlinks para dentro deste repo, basta
editar normalmente (ex: `~/.bashrc`) e depois:

```bash
cd ~/dotfiles
git add -A
git commit -m "update: ..."
git push
```
