# Salesforce Agents

Agentes especialistas que leem specs de requisitos de clientes e implementam
a solução no Salesforce — de forma declarativa (Flow, Validation Rules,
Permission Sets) ou em código (Apex, Lightning Web Components) — de acordo
com a demanda de cada cliente.

## Arquitetura

Construído com o [Claude Agent SDK](https://docs.claude.com/en/api/agent-sdk).
Um orquestrador lê a spec do cliente e delega o trabalho a subagentes
especialistas:

- **solution-architect** — analisa a spec e decide o plano: data model,
  declarativo vs. código, riscos.
- **declarative-builder** — Flow, Validation Rules, Permission Sets, Page
  Layouts, Record Types.
- **apex-developer** — classes, triggers, testes, integrações via Apex.
- **lwc-developer** — Lightning Web Components.

Ferramentas custom (`src/salesforce_agents/tools.py`) dão aos agentes acesso a:

- `spec_read` — extrai texto de specs em `.md`, `.pdf` ou `.docx`.
- `sf_deploy` / `sf_retrieve` / `sf_query` / `sf_org_list` — wrapper sobre a
  Salesforce CLI (`sf`) para deploy, retrieve e SOQL no org do cliente.

Cada cliente tem seu próprio projeto Salesforce DX isolado em
`clients/<nome-do-cliente>/` (veja `clients/README.md`).

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
   sf org login web --alias acme
   ```

2. Coloque a spec de requisitos em algum lugar (veja `examples/sample_spec.md`
   para o formato esperado).

3. Rode os agentes:

   ```bash
   sfagents run --client acme --spec examples/sample_spec.md
   # ou, para já fazer deploy no org do cliente:
   sfagents run --client acme --spec examples/sample_spec.md --deploy
   ```

O orquestrador lê a spec inteira, aciona o `solution-architect` para montar
o plano, e delega a implementação a cada especialista conforme necessário.

## Status

Projeto em estágio inicial (scaffold). Próximos passos sugeridos:
- Validar o fluxo ponta a ponta com um org scratch real.
- Adicionar um agente de QA/revisão que rode testes Apex e valide o deploy
  em modo `--check-only` antes do deploy real.
- Decidir convenção de versionamento por cliente (branch por cliente? repo
  separado por cliente com este framework como dependência?).
