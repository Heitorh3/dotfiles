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
Face) com o valor real hardcoded — isso foi removido. O token agora vive no
Bitwarden e é carregado sob demanda pela função `hf_token` (veja
[Segredos via Bitwarden](#segredos-via-bitwarden) abaixo).

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

## Segredos via Bitwarden

Em vez de hardcodar tokens em arquivos de config, eles ficam guardados no
cofre do Bitwarden e são carregados sob demanda no terminal, via
`.config/fish/functions/bw_session.fish` e `.config/fish/functions/hf_token.fish`.

Como funciona:

- `bw_session` chama `bw unlock` (pede a master password) só se a sessão
  atual não estiver válida, e guarda o resultado em `$BW_SESSION` pro resto
  do terminal.
- `hf_token` usa `bw_session` pra buscar o item chamado `HF_TOKEN` no cofre
  e exportar `$HF_TOKEN` na sessão atual.

Setup necessário (não versionado, tem que ser feito à mão em cada máquina):

```bash
npm install -g @bitwarden/cli   # instala o `bw`
bw login seu-email@exemplo.com  # login interativo (pede master password/2FA)
```

Depois, crie um item no cofre chamado exatamente `HF_TOKEN` — um *Secure
Note* com o token no campo de notas (ou um item *Login* com o token no campo
de senha). Pode ser pela UI do Bitwarden (app desktop/extensão) ou pela CLI.

Uso diário: sempre que precisar do token, rode `hf_token` no terminal — ele
desbloqueia o cofre (se preciso) e exporta `$HF_TOKEN` só naquela sessão do
shell. Não fica em nenhum arquivo em disco.

Esse mesmo padrão serve pra qualquer outro segredo: crie uma function nova
(`.config/fish/functions/<nome>.fish`) seguindo o modelo de `hf_token.fish`,
trocando o nome do item buscado no `bw get item`.

## Atualizando o repositório com mudanças locais

Como os arquivos em `$HOME` viram symlinks para dentro deste repo, basta
editar normalmente (ex: `~/.bashrc`) e depois:

```bash
cd ~/dotfiles
git add -A
git commit -m "update: ..."
git push
```
