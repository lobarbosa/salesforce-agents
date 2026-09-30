# Obsidian como curadoria do RAG (uso local, opcional)

`.mcp.json` na raiz do repo declara um servidor MCP (`mcp-obsidian`, via
[`Local REST API`](https://github.com/coddingtonbear/obsidian-local-rest-api))
que dá ao Claude Code acesso de leitura/escrita a um vault Obsidian — pra
quem quer navegar, revisar ou editar visualmente o mesmo corpus que o RAG
interno ingere (`clients/<cliente>/**/*.md` — ver CLAUDE.md guardrail #2 e
`docs/conexoes-e-setup.md`).

**Só funciona rodando Claude Code local, na sua máquina.** Uma sessão remota
(nuvem) não alcança `127.0.0.1` do seu computador — o Obsidian e o Claude
Code precisam estar na mesma máquina. Não tem relação nenhuma com o pipeline
de agentes em CI (`run-demand.yml` etc.): aquele nunca teve, e não vai ter,
acesso a Obsidian nenhum — é ferramenta de gente, não de agente automático.

## Setup (uma vez, na sua máquina)

1. Instale o [Obsidian](https://obsidian.md/) e abra `clients/` (ou o repo
   inteiro) como vault.
2. Instale e ative o plugin comunitário **Local REST API**
   (`Settings → Community plugins → Browse → "Local REST API"`).
3. Copie a API key que o plugin gera (`Settings → Local REST API`).
4. Exporte `OBSIDIAN_API_KEY` no shell antes de abrir o Claude Code neste
   repo (nunca commite a chave — `.mcp.json` só referencia a variável):
   ```
   export OBSIDIAN_API_KEY="a-chave-que-o-plugin-gerou"
   ```
5. Precisa de `uv`/`uvx` instalado (`pipx install uv` ou
   `curl -LsSf https://astral.sh/uv/install.sh | sh`) — é quem baixa e roda
   o `mcp-obsidian` sob demanda, sem precisar instalar nada global.

Host e porta assumem o padrão do plugin (`127.0.0.1:27124`). Se o seu
Obsidian estiver noutra porta, adicione `OBSIDIAN_HOST`/`OBSIDIAN_PORT` ao
bloco `env` de `.mcp.json` localmente (não precisa virar commit, é ajuste de
máquina).

## O que a ferramenta dá pra fazer

`list_files_in_vault`, `list_files_in_dir`, `get_file_contents`, `search`,
`patch_content`, `append_content`, `delete_file` — ver o próprio
[README do `mcp-obsidian`](https://github.com/MarkusPfundstein/mcp-obsidian)
pra detalhe de cada uma.

Editar um arquivo por aqui edita o arquivo de verdade em
`clients/<cliente>/...` — os mesmos guardrails de sempre continuam valendo
(guardrail #2: nunca escrever dado real de cliente nesses arquivos; nunca
misturar clientes). A próxima reingestão do RAG (`run-demand.yml`, depois do
commit) pega a mudança normalmente — nada aqui fura o fluxo de PR/gate
humano, é só outro jeito de editar o mesmo markdown antes de commitar.
