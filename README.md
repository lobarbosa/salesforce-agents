# Salesforce Agents

Squad de agentes que constrói soluções Salesforce a partir de **demandas** registradas
por consultores — de forma declarativa (Flow, Validation Rules, Permission Sets) ou em
código (Apex, Lightning Web Components) — com um espaço isolado por cliente e gates
humanos bloqueantes em cada etapa.

## Arquitetura

Dois pedaços que se somam:

1. **Doutrina de delivery** (`CLAUDE.md` + `.claude/`) — subagentes especialistas,
   skills e guardrails, no formato nativo do Claude Code: `ba-discovery`, `arquiteto`
   (gate bloqueante), `builder-declarativo`, `dev-apex`, `qa`, `release` (nunca toca
   produção) e `doc`. É a mesma doutrina que funcionaria com `claude` interativo dentro
   de um repo de cliente — aqui ela é compartilhada por todos os clientes deste
   monorepo e carregada automaticamente pelo Claude Agent SDK a partir do workspace do
   cliente (`setting_sources=["project"]` resolve `CLAUDE.md`/`.claude/` subindo os
   diretórios até a raiz do repo).
2. **Orquestração programática** (`src/salesforce_agents/`) — dispara sessões do
   Claude Agent SDK por demanda, e um modelo de dados de **demanda** que substitui o
   Jira como fonte de "história": cada demanda é um registro em
   `clients/<cliente>/demandas/<DEMAND-ID>/`, com estágio rastreado em `status.yaml`.

Ferramentas custom (`src/salesforce_agents/tools.py`) dão aos agentes acesso a:
- `spec_read` — extrai texto de anexos de uma demanda em `.md`, `.pdf` ou `.docx`.
- `sf_deploy` / `sf_retrieve` / `sf_query` / `sf_org_list` — wrapper sobre a
  Salesforce CLI (`sf`) para deploy, retrieve e SOQL no org do cliente.

Cada cliente tem seu próprio projeto Salesforce DX isolado em
`clients/<nome-do-cliente>/`, com seu próprio `CLAUDE.md` de briefing de conta ("Conhecimento
do Cliente" — veja `clients/README.md` e o template em `clients/_template/CLAUDE.md`).

**Squad OS** — um front-end publicado (artifact) onde a demanda nasce e o briefing de
cada cliente é editado por quem não mexe em terminal. Hoje a ponte para este repositório
é manual (leia a demanda no OS, rode `sfagents demanda nova` com o mesmo texto); ver
`docs/conexoes-e-setup.md` para o runbook completo de conexões e credenciais.

## Setup

```bash
pip install -e .
npm install -g @salesforce/cli   # necessário para sf_deploy/sf_retrieve/sf_query
export ANTHROPIC_API_KEY=...
```

## Uso

1. Crie o workspace do cliente (uma vez por cliente):

   ```bash
   sf project generate --name clients/acme
   cp clients/_template/CLAUDE.md clients/acme/CLAUDE.md   # preencha o briefing da conta
   sf org login web --alias acme
   ```

2. Registre a demanda (o que viria de uma estória de Jira em outros contextos):

   ```bash
   sfagents demanda nova --client acme --titulo "Qualificação de Leads" \
     --texto examples/exemplo_demanda.md
   # -> Demanda criada: ACME-1 (status: backlog)
   ```

3. Acompanhe e avance pelos gates:

   ```bash
   sfagents demanda listar --client acme
   sfagents demanda avancar --client acme ACME-1 analise   # aciona o BA
   # ... aprovação humana ...
   sfagents demanda avancar --client acme ACME-1 design    # aciona o arquiteto (gate bloqueante)
   # ... aprovação humana ...
   sfagents demanda avancar --client acme ACME-1 build     # aciona builder-declarativo / dev-apex
   sfagents demanda avancar --client acme ACME-1 qa
   sfagents demanda avancar --client acme ACME-1 release   # nunca em produção
   ```

O fluxo completo de estágios, guardrails e a estrutura de artefatos por demanda estão
documentados no `CLAUDE.md` da raiz deste repositório.

## Status

Projeto em estágio inicial. Próximos passos sugeridos:
- Validar o fluxo ponta a ponta com um org scratch real, do intake até o deploy em sandbox.
- Construir a camada visual de acompanhamento (board por cliente) sobre o mesmo modelo de
  demanda — hoje é só CLI/arquivo, o board é um produto separado a decidir depois.
- Adicionar um agente de QA/revisão que rode testes Apex e valide o deploy em modo
  `--check-only` antes do deploy real.
