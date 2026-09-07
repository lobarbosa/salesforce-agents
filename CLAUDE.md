# Delivery Salesforce com Agentes

Squad de agentes que constrói soluções Salesforce a partir de **demandas** registradas por
consultores — o papel que uma estória de Jira teria em outros contextos, aqui é um registro
de demanda dentro deste repositório (veja `sfagents demanda --help`). Modelo: **humano +
agente em co-construção**. Agente nunca entrega sozinho.

## Regra de ouro
Toda demanda passa por **gates humanos bloqueantes**. O agente para e espera aprovação
explícita. Não existe "vou seguindo e depois você revisa".

## Fluxo canônico

| # | Etapa | Agente | Gate |
|---|-------|--------|------|
| 1 | Ler a demanda, refinar critérios de aceite | `ba-discovery` | Humano aprova o refinamento |
| 2 | Recon da org (o que já existe) | `org-recon` (skill) | — |
| 3 | Desenho da solução (declarativo vs código) | `arquiteto` | **BLOQUEANTE** — arquiteto humano aprova |
| 4 | Build em branch + sandbox | `builder-declarativo` / `dev-apex` | PR obrigatório |
| 5 | Testes em sandbox | `qa` | Humano homologa |
| 6 | Empacotamento e deploy sandbox/UAT | `release` | **Prod: proibido ao agente** |
| 7 | Documentação de entrega | `doc` | Spot check |

O orquestrador (sessão principal) roteia entre agentes. Nunca pula etapa.

## Guardrails inegociáveis

1. **Produção é proibida.** Nenhum agente executa deploy, DML ou anonymous Apex em org
   de produção. Aliases contendo `prod`, `prd` ou `production` são bloqueados por hook.
2. **Dados reais não entram no contexto.** Nunca rodar SOQL que retorne dados de cliente
   (CPF, e-mail, telefone, valores). Só metadata e contagens agregadas. LGPD.
3. **Não invente metadata.** Antes de referenciar qualquer objeto, campo, Flow ou classe,
   confirme via `sf` CLI contra a org. Se não confirmou, declare a incerteza.
4. **Git é obrigatório.** Todo build acontece em branch `feature/<DEMAND-ID>`. Nada é
   commitado direto na main. Todo merge passa por PR com revisor humano — `main` é
   protegida (push direto bloqueado) e exige os checks de CI abaixo passando:
   - `ci-python.yml` — testes do orquestrador (`src/salesforce_agents/`)
   - `ci-squad-os.yml` — lint + build do Squad OS (`apps/squad-os/`)
   - `ci-salesforce-validate.yml` — `sf project deploy validate` (check-only, nunca
     deploy de verdade) contra a sandbox do cliente cujo `force-app` mudou no PR
5. **Estado em disco.** Cada demanda gera `clients/<cliente>/demandas/<DEMAND-ID>/` com os
   artefatos numerados. Se a sessão cair, o próximo agente lê a pasta e retoma de onde parou.
   `sfagents demanda avancar` **recusa avançar** um estágio de execução pra frente se o
   artefato que aquele estágio deveria ter produzido não existir em disco (`demands.py`,
   `ArtifactAusenteError`) — status.yaml não pode mais declarar um estágio que não aconteceu.
   Corrigir manualmente pra trás (reverter um status errado) sempre é permitido, sem exigir
   o artefato do estágio abandonado.
6. **Uma demanda por vez, por cliente.** Não paralelize builds na mesma sandbox sem alinhar
   com o humano.
7. **Nunca misture clientes.** Cada cliente vive isolado em `clients/<cliente>/`, com seu
   próprio org, seu próprio `CLAUDE.md` de briefing e seu próprio histórico de demandas.

## Convenções

- Branch: `feature/<DEMAND-ID>-descricao-curta`
- Commit: `<DEMAND-ID>: verbo no imperativo`
- Cobertura mínima de teste Apex: 85% por classe
- Toda classe tem classe de teste dedicada `<Classe>Test`
- Nomenclatura de campo/Flow/classe: ver skill `padrao-entrega` (convenção específica de
  cada cliente pode sobrepor a convenção padrão — confira o `CLAUDE.md` do cliente primeiro)

## Seleção de modelo por agente

Cada agente em `.claude/agents/*.md` declara `model:` no frontmatter — não roda mais tudo
no mesmo modelo default por acidente. Heurística aplicada (council de 2026-09-07, ver
`gates.md`/histórico de sessão — não repita a análise, ela já foi feita):

- **haiku** — `ba-discovery`, `doc`: extração e formatação de texto, sem decisão de risco.
- **sonnet** — `builder-declarativo`, `dev-apex`, `devops`, `qa`, `release`: trabalho
  estruturado com julgamento, mas revisado por PR ou gate antes de valer. Cavalo de batalha.
- **opus** — só `arquiteto`, e só pela decisão declarativo-vs-código em si: é o único gate
  humano bloqueante da doutrina, erro ali compõe nos 6 clientes, e já paga a latência de
  revisão humana de qualquer forma.

**Isso é hipótese reversível, não doutrina validada.** Ninguém tem sinal empírico de
custo/latência/taxa-de-retrabalho por agente ainda — nenhuma demanda completou o ciclo
inteiro. Antes de tratar esta tabela como padrão para os outros 5 clientes, rode pelo menos
um ciclo completo real (ACXYA-1) e confira se algum agente errou por estar num modelo
barato demais ou custou caro demais num modelo caro demais para o que fez. Ajuste com dado,
não com a heurística sozinha.

### Telemetria de custo

Segundo council de otimização de custo (2026-09-07): a variável que domina o custo deste
pipeline não é qual modelo cada agente usa — é o reprocessamento de `CLAUDE.md`/skills sem
cache em 7 etapas × 6 clientes × ciclo indefinido. Antes de mexer em cache, model routing ou
Batch API, é preciso medir. `src/salesforce_agents/orchestrator.py` agora loga cada sessão
de agente (`src/salesforce_agents/costs.py`) em `logs/custos_agentes.csv` — modelo, tokens
de input/output/cache, custo em USD, etapa, cliente, demanda. Só metadata e contagens, nunca
conteúdo da demanda (guardrail #2). Esse log é o pré-requisito pra qualquer decisão futura de
caching ou de revisão da tabela de modelo acima — sem ele, qualquer ajuste continua sendo
achismo.

## Estrutura de artefatos por demanda

```
clients/<cliente>/demandas/<DEMAND-ID>/
  demanda.md         # a história enviada pelo consultor — entrada, não editar
  status.yaml        # estágio atual e histórico de transições (mantido pela CLI sfagents)
  01-analise.md      # BA: contexto, critérios de aceite, dúvidas
  02-recon.md        # o que já existe na org e será impactado
  03-design.md       # decisão declarativo vs código + justificativa
  04-plano-build.md  # passo a passo do que será criado/alterado
  05-testes.md       # roteiro + resultado
  06-entrega.md      # documentação final
  gates.md           # log de aprovações humanas (quem, quando, o quê)
```

## Escopo duplo: projeto e sustentação

- **Projeto (greenfield):** fluxo completo, etapas 1→7.
- **Sustentação (bug/melhoria):** etapas 1, 2, 3 (design enxuto), 4, 5, 7. Bug crítico
  ainda passa pelo gate do arquiteto — reduzido, mas existe.

## Antes de qualquer coisa

1. Confirme com `sf org list` qual org está conectada e **diga ao humano qual é** antes de
   tocar em qualquer coisa. Org errada é o erro mais caro dessa operação.
2. Confirme qual cliente e qual demanda está sendo tratada. O `CLAUDE.md` deste cliente
   (na raiz do workspace atual) é o briefing de conta — leia-o antes de desenhar qualquer
   solução, ele é fonte de verdade sobre quem é o cliente e como trabalhar por ele.

## Nota sobre permissões em execução headless

O orquestrador roda sessões sem humano para responder prompt de permissão, então
concede ferramentas inteiras (`Bash` incluído) via `allowed_tools` no próprio SDK —
isso torna a lista `allow` de `.claude/settings.json` redundante nesse modo, e o aviso
de "workspace não confiável" do Claude Code é sobre exatamente essa lista, nada além.
A rede de segurança real não depende dela: a lista `deny` (`git merge*`, `git push
--force*`, `sf org delete*`) e o hook `guard-prod.sh` continuam bloqueando
normalmente independente de o workspace estar marcado como confiável — verificado
empiricamente. Não "resolva" esse aviso afrouxando permissão; ele não protege nada
que já não esteja protegido por hook ou pela lista `deny`.
