# Salesforce Agents

Squad de agentes que constrói soluções Salesforce a partir de **demandas** registradas por
consultores no Squad OS, de forma declarativa (Flow, validation rule, permission set) ou em
código (Apex, Lightning Web Component), com um espaço isolado por cliente e gates humanos
bloqueantes em cada etapa. O agente nunca entrega sozinho e nunca toca produção.

As regras estão em `CLAUDE.md`. O porquê de cada uma e os achados que as motivaram estão em
`docs/doutrina-detalhada.md`.

## Como as peças se encaixam

```
Squad OS (apps/squad-os)  ──materializa e dispara──▶  GitHub Actions (.github/workflows)
        ▲                                                      │
        │                                                      ▼
        └──────────── estado, artefatos, custo ◀──── esteira (src/salesforce_agents)
                                                               │
                                                               ▼
                                              agentes e skills (.claude/) + sf CLI
                                                               │
                                                               ▼
                                         sandboxes do cliente: sbx-<cliente>-dev e -qa
```

| Peça | Onde | O que faz |
|---|---|---|
| **Squad OS** | `apps/squad-os/` | Portal (Next.js na Vercel, Postgres no Supabase). Demanda, briefing, gates, homologação, contrato, horas, financeiro. Materializa a demanda no repositório e dispara a esteira; recebe o estado de volta pelas rotas `/api/sync/*`. |
| **Workflows** | `.github/workflows/` | `run-demand.yml` roda uma etapa por execução, no GitHub Environment do cliente e do ambiente (`<cliente>-dev` ou `<cliente>-qa`). Os demais: assessment, planejamento, teste de conexão, validação de PR, varredura de demandas paradas, promoção de QA para dev. |
| **Esteira** | `src/salesforce_agents/` | CLI `sfagents`. Decide a etapa, abre a sessão do Claude Agent SDK, confere o artefato, lê o veredito e avança até o próximo gate (`fluxo.py`). Estado da demanda em disco (`demands.py`), ambiente por etapa (`ambientes.py`), guarda de produção (`guarda.py`). |
| **Agentes e skills** | `.claude/agents/`, `.claude/skills/` | Um agente por papel (`ba-discovery`, `recon`, `arquiteto`, `builder-declarativo`, `dev-apex`, `verificador`, `qa`, `release`, `doc`, mais `org-assessment`, `planejador` e `devops`). As skills são arquivos que o agente abre com Read. |
| **Scripts** | `scripts/` | Passos determinísticos dos workflows: pacote da demanda, deploy em QA, varredura de dado pessoal, comparação de orgs. |
| **Clientes** | `clients/<cliente>/` | Projeto Salesforce DX do cliente, `CLAUDE.md` de briefing, `assessment.md`, fixtures de teste e `demandas/<DEMAND-ID>/` com os artefatos de cada demanda. |

Os agentes chamam o `sf` pelo Bash; o hook `.claude/hooks/guard-prod.sh` e a conferência de
sandbox em `guarda.py` recusam qualquer org fora das duas sandboxes do cliente. As
ferramentas próprias (`src/salesforce_agents/tools.py`) são só duas famílias: `spec_read`
(anexo em PDF ou DOCX) e `qa_browser_*` (navegador para o teste de tela do QA).

## O fluxo de uma demanda

Análise → gate → recon e design → **gate do arquiteto** → build e verificação na sandbox de
dev → gate de PR → deploy e testes na sandbox de QA → homologação do cliente → release e
documentação. Uma etapa por execução; a esteira para em cada gate e só segue quando uma
pessoa aprova no card. A tabela completa, com agente, artefato e gate de cada etapa, está
no `CLAUDE.md`.

Subir em produção é trabalho do consultor, fora da esteira (skill `subir-producao`).

## Rodar localmente

```bash
pip install -e . pytest
PYTHONPATH=src python3 -m pytest          # testes da esteira

cd apps/squad-os
npm install
npm test && npx tsc --noEmit && npx eslint .   # testes do portal
```

Para ver o portal com banco descartável e login simulado, use a skill `portal-local`.

A esteira em si roda no GitHub Actions, disparada pelo Squad OS; não é para ser rodada da
máquina de alguém contra a org de um cliente. A CLI existe para os workflows e para
inspeção:

```bash
sfagents demanda listar --client <cliente>
sfagents demanda status-json --client <cliente> <DEMAND-ID>
sfagents demanda conferir-gates --client <cliente> <DEMAND-ID>
```

## Onde ler mais

| Assunto | Documento |
|---|---|
| Regras da esteira | `CLAUDE.md` |
| Motivo de cada regra, achados e funcionamento do Squad OS | `docs/doutrina-detalhada.md` |
| Conexões, credenciais e ordem de montagem de um cliente | `docs/conexoes-e-setup.md`, `docs/credenciais.md` |
| O que só uma pessoa pode configurar (Supabase, Vercel, GitHub) | `docs/ativacao.md` |
| Portal: arquitetura, banco, deploy | `apps/squad-os/README.md` |
| Workspace de cliente | `clients/README.md` |
| Operar a esteira, conferir gate, homologar, subir em produção | skills em `.claude/skills/` |
