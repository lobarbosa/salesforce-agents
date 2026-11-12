# EPLAST-28 — Testes: alertas de oportunidade parada ou sem acompanhamento

**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

---

## 0. Resumo executivo

Não há nada para testar. Confirmei por conta própria — não apenas lendo os artefatos
anteriores, mas consultando a org e o git diretamente — que **nenhuma metadata desta
demanda foi construída**, em nenhuma sandbox. Esta etapa não pôde homologar nada porque
não existe build. O que segue é o registro do que foi verificado, não um roteiro executado
contra uma solução real.

Isso não é uma falha de QA no sentido de "testei e quebrou". É a ausência do objeto de
teste. Classifico mesmo assim como reprovado porque o veredito desta etapa precisa refletir
que a demanda **não está pronta para homologação nem para release**, e o Squad OS só
distingue aprovado/reprovado — não existe terceiro estado para "não há o que testar".

## 1. O que a análise e o design pediam (para registro, não para execução)

`01-analise.md` (seção 4) define 8 cenários Gherkin para o alerta de oportunidade parada —
geração de alerta ao atingir o prazo, ausência de alerta dentro do prazo, não-repetição do
alerta, zeragem por novo acompanhamento, exclusão de oportunidades fechadas, escalonamento
ao gestor (pendente de confirmação), garantia de não-gravação em Opportunity, e cobertura de
teste Apex ≥ 85% se houver classe nova.

`03-design.md` decidiu a forma (Flow agendado `Opportunity_Scheduled_AlertaParada` +
`CustomNotificationType Oportunidade_Parada`, nível declarativo, com possível descida para
Apex) mas deixou **explícito, na própria seção 0**, que aceitar o design não libera o build:
faltam a decisão contratual da Onda 3 e os 4 parâmetros bloqueantes de negócio (definição de
"parada"/"acompanhamento", prazo, canal/frequência, destinatário/escalonamento).

`04-plano-build.md` registra que o builder **não construiu nada** pelas mesmas 5 lacunas
(seção 11 do design): decisão contratual, itens 1–4 de parâmetros de negócio, volume de
produção, confirmação de `sbx-eplast-qa` conectada, e aprovação da estimativa pelo cliente.
O próprio documento termina com "Esta etapa não avança para `aguardando_gate_build`" — e, no
entanto, o gate foi aprovado e a demanda chegou a `qa` (ver seção 3, alerta de processo).

## 2. O que eu confirmei na org (`sbx-eplast-qa`), agora, nesta sessão

Não aceitei a leitura de `04-plano-build.md` como suficiente — rodei as consultas
novamente, na org conectada a esta sessão.

```
$ sf org list
Alias          Org Id              Status
sbx-eplast-qa  00DHa000006vZtmMAE  Connected
```

Só `sbx-eplast-qa` está conectada nesta sessão (QA, não dev). Username de integração omitido
deste registro de propósito (guardrail #2: formato de e-mail não entra em artefato, mesmo
sendo usuário técnico — a org é identificada pelo alias e pelo Org Id, que bastam).

```
$ sf data query --target-org sbx-eplast-qa \
  --query "SELECT ApiName FROM FlowDefinitionView WHERE ApiName LIKE '%AlertaParada%' OR ApiName LIKE '%StaleAlert%'"
Total number of records retrieved: 0.

$ sf data query --target-org sbx-eplast-qa \
  --query "SELECT DeveloperName FROM CustomNotificationType WHERE DeveloperName LIKE '%Parada%' OR DeveloperName LIKE '%Oportunidade%'"
Total number of records retrieved: 0.
```

Para não confiar só em bater o nome exato, ampliei a busca por qualquer Flow com relação a
Opportunity (em vez de só o nome proposto no design):

```
$ sf data query --target-org sbx-eplast-qa \
  --query "SELECT ApiName, Label FROM FlowDefinitionView WHERE Label LIKE '%Opportunity%'"
Total number of records retrieved: 0.

$ sf data query --target-org sbx-eplast-qa \
  --query "SELECT ApiName, Label FROM FlowDefinitionView WHERE Label LIKE '%Oportunidade%'"
APINAME                   LABEL
Oportunidade_Industria    Oportunidade Indústria
OpportunityFlow           Fluxo Oportunidade
PaymentTermsOpportunity   Condições de Pagamento Oportunidade
ScheduledFlowOpportunity  Fluxo Agendado - Oportunidade
```

Os quatro Flows retornados já são citados em `03-design.md` (seção 5.1) como automações
**existentes** que a demanda explicitamente não toca. Nenhum se chama
`Opportunity_Scheduled_AlertaParada` nem equivalente. Também listei todos os
`CustomNotificationType` da org, sem filtro de nome, para não deixar passar um nome
diferente do proposto:

```
$ sf data query --target-org sbx-eplast-qa --query "SELECT DeveloperName, MasterLabel FROM CustomNotificationType"
DEVELOPERNAME  MASTERLABEL
Novo_Pedido    Novo Pedido
```

Só existe um `CustomNotificationType` na org, `Novo_Pedido`, sem relação com esta demanda.

**Conclusão própria, independente da leitura de `04-plano-build.md`:** não há Flow, nem
CustomNotificationType, nem variação de nome razoável desses componentes na org de QA. Nada
do design foi implantado.

## 3. O que eu confirmei no git

```
$ git diff origin/main...feature/EPLAST-28 --stat
CLAUDE.md                                          |   4 +
clients/eplast/demandas/EPLAST-28/01-analise.md    | 247 +++++++++++++++++
clients/eplast/demandas/EPLAST-28/02-recon.md      | 133 +++++++++
clients/eplast/demandas/EPLAST-28/03-design.md     | 304 +++++++++++++++++++++
clients/eplast/demandas/EPLAST-28/04-plano-build.md| 104 +++++++
clients/eplast/demandas/EPLAST-28/gates.md         |  26 ++
clients/eplast/demandas/EPLAST-28/status.yaml      |  38 ++-
.../.../logs/custos_agentes/*.csv (3 arquivos)
src/salesforce_agents/cli.py                       |  11 +-
11 files changed, 871 insertions(+), 6 deletions(-)
```

Nenhum caminho em `force-app/` aparece na branch inteira, desde que ela diverge de `main`.
Os três commits da branch (`40ddcad8` análise, `27a00993` design, `1dfb9a94` build) só tocam
documentação de demanda, `gates.md`, `status.yaml`, logs de custo e uma alteração em
`src/salesforce_agents/cli.py` — nenhum deles cria ou altera metadata Salesforce.

## 4. Casos de teste — não executáveis

Todos os 8 cenários Gherkin de `01-analise.md` §4 dependem de um Flow e uma
CustomNotificationType que não existem na org. Não monto tabela Caso/Passos/Esperado/Obtido
porque "Obtido" seria inventado — não há comportamento para observar.

| Cenário (análise §4) | Testável nesta sessão? | Motivo |
|---|---|---|
| Parada além do prazo gera alerta | Não | Flow `Opportunity_Scheduled_AlertaParada` não existe na org |
| Dentro do prazo não gera alerta | Não | idem |
| Mesma parada não repete alerta | Não | idem |
| Novo acompanhamento zera a parada | Não | idem |
| Oportunidade fechada não gera alerta | Não | idem; também depende de regra de elegibilidade ainda não fechada (design §3, item 6) |
| Escalonamento ao gestor | Não | explicitamente fora de escopo nesta rodada (design R5: 0 usuários com `ManagerId` na sandbox) |
| Verificação não altera a Opportunity | Não | não há verificação implantada para observar |
| Classe Apex nova tem `<Classe>Test` ≥ 85% | Não | nenhuma classe Apex foi criada (forma base é declarativa; caminho Apex nem foi escolhido) |

Não tentei montar dado sintético e simular o comportamento "no vácuo" (por exemplo,
calculando manualmente `TODAY() - LastActivityDate` fora de um Flow): isso não testaria a
solução, testaria uma reimplementação minha das regras do design — que ainda nem estão
fechadas (item 1 e 2 da seção 3 do design seguem pendentes). Seria inventar um resultado
para parecer que algo foi homologado, o que o guardrail #3 proíbe.

## 5. Critérios de aceite não testáveis nesta sandbox, e por quê

- Todos os 8 cenários da seção 4 de `01-analise.md`: não testáveis, nada implantado (seção 4
  acima).
- Volume de produção (item 8 do design, pré-condição 3 do build): não testável mesmo se
  houvesse build — depende de número que só o cliente pode fornecer; não se consulta
  produção (guardrail #2).
- Teste de carga do design (§5.2: 200+ oportunidades de donos diferentes, 1 dono com 150
  oportunidades): não executável sem o Flow existir para medir consumo de interviews.

## 6. Dado novo desta sessão, relevante para a pré-condição 4 do design (R6)

Hoje (2026-11-12), dentro do ambiente de QA, `sf org list` mostra **só `sbx-eplast-qa`
conectada** (Org Id `00DHa000006vZtmMAE`). `04-plano-build.md` (rodado no ambiente de dev,
em 2026-11-11) tinha visto **só `sbx-eplast-dev` conectada** (Org Id `00DHa000006vfMLMAY`).

Os dois Org Ids são diferentes — isso é evidência de que dev e QA são sandboxes distintas,
o que resolve parte da dúvida levantada pelo achado 6 do assessment e pela pré-condição 4
da seção 11 do design (R6). **Mas resolve só essa dúvida.** As outras quatro pré-condições
(decisão contratual, os 4 parâmetros de negócio, volume de produção, aprovação de estimativa)
continuam sem resposta registrada em `comentarios-do-card.md` — ver seção 7.

---

### FALHA 1 (crítica) — não há nenhuma metadata desta demanda implantada em `sbx-eplast-qa`

A demanda chegou à etapa `qa` sem nenhum componente do design ter sido construído. Nenhum
cenário de aceite é testável. Confirmado de forma independente via `sf data query` (Flow e
CustomNotificationType, seção 2) e via `git diff` contra `origin/main` (seção 3) — nenhuma
metadata Salesforce em `force-app/` em toda a branch `feature/EPLAST-28`.

### FALHA 2 (crítica) — as 5 pré-condições do design (§11) seguem sem resposta

`comentarios-do-card.md` só registra 3 linhas, uma por gate aprovado ("aprovou o gate X").
Nenhuma resposta às perguntas bloqueantes da análise §5 ou às pré-condições do design §11:
(1) decisão contratual da Onda 3 — (a)/(b)/(c); (2) definição de "parada"/"acompanhamento",
prazo, canal/frequência, destinatário; (3) volume de oportunidades abertas em produção; (4)
confirmação dev≠QA — esta, parcialmente resolvida nesta sessão (seção 6), mas as outras 4
não; (5) aprovação da estimativa pelo cliente no Squad OS.

---

## 7. Alerta de processo para o humano (não é achado técnico — é achado de esteira)

A demanda avançou por **três gates aprovados** (`aguardando_gate_analise`,
`aguardando_gate_design`, `aguardando_gate_build`) apesar de:

- `03-design.md` dizer explicitamente, na seção 0, que aceitar o design **não libera o
  build** sem decisão contratual registrada e sem resposta aos 4 parâmetros bloqueantes;
- `04-plano-build.md` dizer explicitamente, na seção 0 e na linha final, que **o build não
  foi executado** e que "esta etapa não avança para `aguardando_gate_build`".

Mesmo assim, `status.yaml` registra a transição `aguardando_gate_build → qa` em
2026-11-12T13:36:34 (autor Carlos Sordi), e a demanda chegou aqui. A explicação mais
provável, e que recomendo investigar: a checagem automática de transição de etapa
(`ArtifactAusenteError` em `demands.py`, guardrail #5) confere **se o arquivo numerado
existe em disco** — `04-plano-build.md` existe, então a checagem passa — mas não lê **o
conteúdo** do arquivo para saber se ele diz "constrooi" ou "não construí nada". Um
documento que relata deliberadamente a ausência de build satisfaz a mesma checagem mecânica
que um documento que relata um build real.

**Recomendação para este caso:**

1. **Não homologar.** Não há o que homologar.
2. **Não liberar release.** Não existe PR com `force-app`, não existe metadata para
   empacotar.
3. Reverter `status.yaml` de volta para `build` (ou para `aguardando_gate_design`, se a
   decisão contratual ainda estiver em aberto) — guardrail #5 permite correção manual para
   trás sem exigir o artefato do estágio abandonado.
4. Antes de qualquer novo avanço, registrar em `comentarios-do-card.md` as respostas às 5
   pré-condições de `03-design.md` §11 — em especial a decisão contratual da análise §6
   ((a) aditivo, (b) volta para backlog, ou (c) autorização explícita para design sem
   build), que é a mais crítica: a Onda 3 segue "não contratada" segundo `contrato.md`
   citado em ambos os artefatos anteriores.
5. Considerar, como melhoria de processo (fora do escopo desta sessão de QA, só registro):
   a checagem de transição de etapa poderia exigir uma linha-sinal nos artefatos (ex.: o
   `ba-discovery`/`arquiteto`/builder declarando "pronto para o próximo gate" vs. "parado,
   aguardando resposta humana") para não tratar "documento existe" como sinônimo de "etapa
   concluída". Não implementei essa mudança — é decisão de quem mantém o fluxo, não do
   agente de QA.

## 8. Testes de UI (`qa_browser_*`)

Não aplicável. Não há tela, Flow ativo nem notificação para abrir — qualquer tentativa de
usar `qa_browser_*` aqui seria testar a Lightning genérica da org, não esta demanda.

---

Testes executados. Preciso da sua homologação para liberar o release.

(Nota: dado o conteúdo acima, a recomendação desta etapa é explicitamente **não** homologar
nem liberar release — a frase de encerramento é o protocolo padrão desta etapa, não uma
sugestão de aprovação.)
