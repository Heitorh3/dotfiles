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
- Editor: `.config/Code/User/settings.json`, `.config/Code/User/keybindings.json`
  (preferências apenas — extensões são reinstaladas pela lista em
  `pos_format.sh`, não versionadas aqui; ver nota sobre o token do GitHub
  abaixo)

## O que **não** está aqui (de propósito)

Chaves SSH/GPG, credenciais AWS/Azure, tokens do `gh`, histórico de shell,
sessões/estado de apps (Discord, Slack, Cursor, navegador) — e qualquer outro
segredo, incluindo o resto da pasta `.config/Code/User/` (histórico,
workspaceStorage, globalStorage, sync/, etc.). Esses arquivos ficam fora de
controle de versão por segurança.

O `.config/fish/config.fish` tinha uma variável `HF_TOKEN` (token da Hugging
Face) com o valor real hardcoded — isso foi removido. O token agora vive no
Bitwarden e é carregado sob demanda pela função `hf_token` (veja
[Segredos via Bitwarden](#segredos-via-bitwarden) abaixo).

O `.config/Code/User/settings.json` tinha, na configuração `cody.mcpServers`,
um GitHub Personal Access Token hardcoded em texto puro (duas vezes). Como
esse repositório é **público**, isso teria vazado o token assim que o arquivo
fosse versionado. O token foi removido e trocado por `${env:GITHUB_PERSONAL_ACCESS_TOKEN}`
— o mesmo padrão do `HF_TOKEN`, carregado sob demanda pela função
`github_token` (Bitwarden). **Se você reconhece esse token, revogue-o em
https://github.com/settings/tokens — ele ficou exposto em disco em texto
puro.**

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
2. Restaure suas chaves SSH manualmente em `~/.ssh/` (veja
   [Restaurando as chaves SSH](#restaurando-as-chaves-ssh) abaixo — não são
   versionadas aqui).
3. Instale as ferramentas que os configs esperam (fish, starship, asdf, bat,
   btop, htop, lazygit, lazydocker) via seu gerenciador de pacotes preferido.

## Restaurando as chaves SSH

O `.ssh/config` deste repositório espera uma chave em `~/.ssh/id_ed25519`
(`IdentityFile ~/.ssh/id_ed25519`). Chaves privadas nunca são versionadas
aqui — escolha um dos caminhos abaixo depois de formatar a máquina.

### Opção recomendada: Bitwarden SSH Agent

A chave fica só dentro do cofre do Bitwarden (nunca em disco em
`~/.ssh/`), servida por um agent que o app desktop expõe em
`~/.bitwarden-ssh-agent.sock`. O `.config/fish/config.fish` deste repo já
aponta `$SSH_AUTH_SOCK` pra esse socket automaticamente quando ele existe
(veja o trecho perto do início do arquivo).

1. Instale/abra o **Bitwarden Desktop** e faça login.
2. Em Configurações → SSH Agent, habilite o agent.
3. No cofre, confira se existe um item do tipo **SSH key** com a chave
   `id_ed25519` (se for a primeira vez, importe a chave existente ou gere
   uma nova direto ali).
4. Rode `./install.sh` para linkar o `config.fish`, abra um terminal novo e
   teste:
   ```bash
   ssh-add -l          # deve listar a chave servida pelo Bitwarden
   ssh -T git@github.com
   ```

Se o Bitwarden não estiver rodando, o `config.fish` simplesmente não mexe
em `$SSH_AUTH_SOCK` e o sistema cai no agent padrão (gnome-keyring), sem
travar nada.

### Alternativa: arquivo de chave em disco

Caso prefira não depender do Bitwarden para SSH (ou ele não esteja
disponível no momento):

**Tenho um backup da chave**

1. Copie `id_ed25519` e `id_ed25519.pub` para `~/.ssh/`.
2. Ajuste as permissões (o SSH recusa a chave se estiverem erradas):
   ```bash
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_ed25519
   chmod 644 ~/.ssh/id_ed25519.pub
   ```
3. Rode `./install.sh` (ou rode de novo) para linkar o `.ssh/config`.
4. Adicione a chave ao agent e teste o acesso ao GitHub:
   ```bash
   ssh-add ~/.ssh/id_ed25519
   ssh -T git@github.com
   ```

**Não tenho backup (chave perdida)**

1. Gere um par novo:
   ```bash
   ssh-keygen -t ed25519 -C "seu-email@exemplo.com" -f ~/.ssh/id_ed25519
   ```
2. Copie a chave pública e cadastre em cada serviço que usava a chave antiga
   (GitHub → Settings → SSH and GPG keys, e qualquer servidor próprio):
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
3. Revogue/remova a chave antiga desses mesmos serviços, já que ela ficou
   para trás na máquina formatada.
4. Rode `./install.sh` para linkar o `.ssh/config`, depois `ssh-add
   ~/.ssh/id_ed25519` e teste com `ssh -T git@github.com`.

## Segredos via Bitwarden

Em vez de hardcodar tokens em arquivos de config, eles ficam guardados no
cofre do Bitwarden e são carregados sob demanda no terminal, via
`.config/fish/functions/bw_session.fish` e `.config/fish/functions/hf_token.fish`.

Como funciona:

- `bwcli` é uma function que chama o binário `bw` do Bitwarden CLI direto
  pelo caminho instalado via npm — existe pra não colidir com um `/bin/bw`
  do sistema (outro programa, nada a ver com Bitwarden) que pode vir na
  frente no `$PATH`.
- `bw_session` chama `bwcli unlock` (pede a master password) só se a sessão
  atual não estiver válida, e guarda o resultado em `$BW_SESSION` pro resto
  do terminal.
- `hf_token` usa `bw_session` pra buscar o item chamado `HF_TOKEN` no cofre
  e exportar `$HF_TOKEN` na sessão atual.
- `github_token` funciona igual, mas busca o item `GITHUB_PERSONAL_ACCESS_TOKEN`
  e exporta `$GITHUB_PERSONAL_ACCESS_TOKEN` — é o valor que o
  `cody.mcpServers` do VS Code (`.config/Code/User/settings.json`) espera via
  `${env:GITHUB_PERSONAL_ACCESS_TOKEN}`.

Setup necessário (não versionado, tem que ser feito à mão em cada máquina):

```bash
npm install -g @bitwarden/cli     # instala o `bw`
bwcli login seu-email@exemplo.com # login interativo (pede master password/2FA)
```

Depois, crie um item no cofre chamado exatamente `HF_TOKEN` — um *Secure
Note* com o token no campo de notas (ou um item *Login* com o token no campo
de senha). Pode ser pela UI do Bitwarden (app desktop/extensão) ou pela CLI.
Repita o mesmo para um item chamado `GITHUB_PERSONAL_ACCESS_TOKEN`.

Uso diário: sempre que precisar do token, rode `hf_token` (ou `github_token`)
no terminal — ele desbloqueia o cofre (se preciso) e exporta a variável só
naquela sessão do shell. Não fica em nenhum arquivo em disco.

Importante para o `github_token`: como o valor vem de `${env:...}`, o
VS Code só enxerga a variável se for **aberto a partir de um terminal** onde
`github_token` já rodou antes (ex: `github_token; code .`) — abrir pelo ícone
do launcher/desktop não herda a variável.

Esse mesmo padrão serve pra qualquer outro segredo: crie uma function nova
(`.config/fish/functions/<nome>.fish`) seguindo o modelo de `hf_token.fish`,
trocando o nome do item buscado no `bwcli get item`.

## Atualizando o repositório com mudanças locais

Como os arquivos em `$HOME` viram symlinks para dentro deste repo, basta
editar normalmente (ex: `~/.bashrc`) e depois:

```bash
cd ~/dotfiles
git add -A
git commit -m "update: ..."
git push
```
