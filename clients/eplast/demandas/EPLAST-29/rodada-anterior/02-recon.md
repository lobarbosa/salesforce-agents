# EPLAST-29 · Recon da org — Ações por linguagem natural no assistente de IA

**Cliente:** Eplast · **Org:** `sbx-eplast-dev` (sandbox confirmada via `Organization.IsSandbox = true`,
Org Id `00DHa000006vfMLMAY`) · **Coleta:** 2026-11-11T15:09Z · **Autor:** org-recon (skill, rodado pelo
orquestrador da sessão)

Tudo abaixo foi confirmado via `sf` contra a org nesta data — nada aqui vem de memória, do
`assessment.md` ou da análise sem reconfirmação (guardrail #3). Onde o achado só repete o
assessment, é porque o `sf` confirmou de novo, não porque foi copiado.

---

## 0. Achado que muda a leitura de Q1 (plataforma do assistente)

A análise levantou como pendente **se existe um assistente de IA já ativado** e qual é a
relação com EPLAST-29. Confirmado via metadata:

- Existe **um** Agentforce Employee Agent na org: `Bot` **SFAgent2**
  (`agentType = AgentforceEmployeeAgent`, `type = InternalCopilot`), com 4 versões de
  `GenAiPlannerBundle` (`SFAgent2_v1` a `_v4`). Nenhum outro `Bot`/agente de IA existe na org.
- O `agentScript` da versão ativa (`SFAgent2_v4`) define um roteador (`agent_router`) com 3
  subagentes: `off_topic`, `ambiguous_question` e **`insights_comerciais`**. Este último é
  claramente os entregáveis `eplast-ent-09`/`eplast-ent-10` citados na análise ("Quais
  clientes precisam de acompanhamento hoje?", "Resumo completo de um cliente") — as
  instruções do subagente citam esses dois cenários literalmente.
- **Todas as ações hoje configuradas no agente são de leitura.** `insights_comerciais` usa
  3 ações, todas mapeadas para ações padrão (`standardInvocableAction://`), nenhuma
  Apex custom:
  - `identifyRecordByName` (busca registro por nome)
  - `queryRecords` (consulta SOQL)
  - `queryRecordsWithAggregate` (consulta agregada)

  Não existe `GenAiPlugin` nem `GenAiFunction` na org (0 de cada) — ou seja, nenhuma
  ação/tópico customizado via Apex foi publicado como metadata até hoje; tudo roda em cima
  de duas ações padrão do próprio Agentforce.

**Conclusão de recon (não é decisão de design):** existe evidência direta de que EPLAST-29
seria **extensão do SFAgent2** (novo subagente de escrita ao lado de `insights_comerciais`),
não um assistente novo — mas isso é decisão do arquiteto, não deste recon. Vale registrar
também que a plataforma expõe ações padrão com um campo `require_user_confirmation`
(boolean, hoje `False` nas 3 ações existentes porque são leitura) — ponto relevante para
RN-1 (confirmação antes de gravar) no design, a confirmar se cobre os cenários Gherkin.
Existe também o permission set `PS_Comercial_ResumoClienteAgente`, já ligado a este agente,
mas com **0 atribuições diretas** nesta sandbox hoje (`PermissionSetAssignment` — pode estar
via grupo, não confirmado).

## 1. Objetos candidatos (Q2) — automação existente por objeto

| Objeto | Trigger Apex ativo | Flow record-triggered ativo | Validation Rules ativas | OWD (confirmado) |
|---|---|---|---|---|
| **Account** | `AccountBefore` (ns `SBQQ`, v57) + `AccountTrigger` (custom, v58) | `AccountTriggered` (RecordAfterSave), `SetPaymentTermsChangesinAccount` (RecordAfterSave), `UpdateParentAccountUsedLimit` (RecordAfterSave) | 6 (`Celular`, `CheckUserCanSetLimitDueDate`, `CheckUserCanSetRisk`, `Contato_Fiscal`, `Telefone`, `WhatsApp`) | `ReadWrite` (interno) / `Private` (externo) |
| **Opportunity** | `OpportunityAfter` + `OpportunityBefore` (ns `SBQQ`, v57) + `OpportunityTrigger` (custom, v59) | `CPQQuoteFlow`, `Oportunidade_Industria`, `OpportunityFlow` (todos RecordAfterSave) | 16 ativas (lista completa em metadata, ex.: `CheckAccountHasCNAE`, `CheckHasAccount`, `PriceBook`, `TaxAnalysis`) | `Read` (interno) / `Private` (externo) |
| **Order** | `OrderTrigger` (ns `SBQQ`, v57) **e** `OrderTrigger` (custom, v59) — **mesmo nome, dois triggers ativos distintos** | `Order` (RecordAfterSave, label "Pedido" — atualiza `StageName`/status da Opportunity pai e dispara aprovação financeira), `Acionado_por_registro_Antes_de_atualizar_Pedido...` (RecordBeforeSave) | 23 no metadata, **17 ativas** / 6 inativas | `ControlledByParent` (de Account) |
| **Task** | nenhum trigger Apex ativo encontrado | **`TaskCreatedOrUpdated`** (RecordAfterSave, `recordTriggerType = CreateAndUpdate`) — verifica se a Task é de "Check-In" e, se relacionada a uma Account, atualiza o campo `Account.AccountHasCheckInTask__c` | 0 (describe retornou 0 validation rules e 0 campos obrigatórios sem default além dos padrão) | sharing de Activity segue o registro relacionado (`WhatId`/`WhoId`), não tem `sharingModel` próprio |

Achados que **corrigem/detalham** a análise (seção 7 de `01-analise.md`):

- **Risco #1 do assessment (automação concorrente) confirmado de novo em Order**: dois
  triggers ativos chamados `OrderTrigger` — um do pacote `SBQQ` (CPQ) e um custom — coexistem
  no mesmo objeto/evento. Isso é exatamente o achado #10 do assessment, reconfirmado hoje via
  `ApexTrigger.NamespacePrefix`.
- **Task não está livre de automação** como a análise supôs ("Criar Task... não aparece no
  inventário do assessment; a presença de automação concorrente em Task não foi verificada").
  Existe sim um Flow ativo em Task (`TaskCreatedOrUpdated`) — de baixo risco aparente (só lê
  `Subject`/relacionamento e atualiza um campo de Account), mas precisa entrar no design: toda
  Task criada pelo assistente passa por ele.
- **Task, isoladamente, tem superfície de risco baixa para criação**: nenhuma validation
  rule, nenhum campo obrigatório customizado sem default, nenhum trigger Apex. Isso sustenta
  a premissa P2 da análise (escopo mínimo viável = Task) como caminho de menor risco.
- **Order segue sendo o objeto de maior risco** caso Q2 o inclua: 2 triggers concorrentes,
  Flow que atualiza a Opportunity pai e dispara aprovação financeira, 17 validation rules
  ativas, e integração com Protheus (ver seção 2).

## 2. Integração com ERP Protheus (risco #2 do assessment)

Classes Apex confirmadas na org (todas `Status = Active`, API v59, sem namespace):
`SendAccountToProtheus`, `SendOrderToProtheus`, `AccountTriggerHandler`,
`OpportunityTriggerHandler`, `OrderTriggerHandler`. Existência confirmada via
`ApexClass` — conteúdo não lido linha a linha neste recon (ficaria para o design/build, se
Order ou Account entrarem em escopo). Cobertura de teste dessas classes especificamente
**não pôde ser medida** nesta sessão: `ApexCodeCoverageAggregate` não é consultável via
`sf data query` (API REST recusa o objeto); medir exigiria Tooling API dedicada — registrar
como pendência para quem for tocar essas classes, não bloqueia o recon de hoje porque o
número agregado (10%) já está no assessment e esta demanda só herda o risco se Q2 incluir
Account/Order.

## 3. Confirmação do achado #6 do assessment — dev e qa podem não ser ambientes distintos

Esta sessão só tem **uma** org conectada (`sf org list`): `sbx-eplast-dev`. Não há alias
`sbx-eplast-qa` disponível neste job para comparar. Confirmado desta sandbox:

- `instanceUrl`: contém `--qa.sandbox` no domínio (a sandbox em si se identifica como "qa"
  internamente, embora o alias da esteira seja `sbx-eplast-dev`).
- `IsSandbox = true` (guardrail #1 ok — não é produção), mas o nome interno reforça a dúvida
  do assessment.

**Isto bloqueia a seção "rastreabilidade/homologação" dos critérios de aceite de EPLAST-29**:
os cenários Gherkin da análise pressupõem que o roteiro de QA (etapa 5) roda num ambiente
distinto de onde o build acontece (etapa 4). Enquanto não for confirmado que `sbx-eplast-dev`
e `sbx-eplast-qa` são sandboxes fisicamente diferentes, a homologação desta demanda corre o
risco de testar no mesmo lugar onde foi construído. Não é um bloqueio para o **design**
seguir (o design não depende de qual sandbox é qual), mas precisa ser resolvido por um humano
antes da etapa de QA — não é algo que este recon ou o arquiteto podem decidir sozinhos.

## 4. Perfis comerciais (Q5) e licença (P6)

- Perfis confirmados: `Comercial`, `Comercial Padrão`, `Comercial - Analista`,
  `Comercial - Analistas` — os 4 citados no assessment (achado #8), ainda existem todos hoje,
  nenhum foi consolidado.
- Licença `Salesforce`: **14/14 em uso** — confirma o achado do assessment. Não há licença
  Salesforce livre para criar usuário de teste adicional na sandbox sem liberar uma
  existente; relevante para o roteiro de QA (etapa 5), que provavelmente vai precisar rodar
  com um usuário já existente em vez de um usuário de teste dedicado.
- Licença `Einstein Agent`: 0/601 em uso e `External Einstein Agent`: 0/401 em uso — há
  capacidade de licença/crédito de Agentforce disponível por este contador, mas o número
  "0 em uso" com um agente ativo em produção-piloto é estranho o suficiente para não
  confiar nele como medida de consumo real; registrar como "não totalmente confiável",
  não como "sem risco de crédito".

## 5. O que fica como pendência explícita para o design

1. Confirmar com o humano (Q1–Q3, seção 6 da análise) antes de o arquiteto fechar o desenho:
   este recon só reúne evidência técnica, não substitui a resposta de negócio.
2. Cobertura de teste específica das classes de integração Protheus — não medida aqui
   (ver seção 2); medir antes de qualquer alteração nelas, se Q2 incluir Account/Order.
3. Divergência dev/qa (seção 3) — resolver antes da etapa de QA, não antes do design.
4. `require_user_confirmation` e o catálogo de ações padrão disponíveis (ex.: se existe uma
   ação padrão de criação de registro equivalente a `queryRecords` para escrita) não foram
   enumerados a fundo aqui — é trabalho de design, citado só como pista.
