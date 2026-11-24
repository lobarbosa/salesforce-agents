# Design — EPLAST-27: Próxima melhor ação por cliente

**Bloqueio (caso 3 da regra 4):** nenhum. Todas as perguntas de regra de negócio foram resolvidas como premissas
(seção 8), com evidência da org ou do padrão. Os riscos de severidade alta (seção 9) estão no gate do arquiteto
humano para aceitar, e nenhum deles impede o build.

**Org conferida:** `sbx-eplast-dev` (`sf org list` em 2026-11-15: Sandbox, Connected). Só metadata e `COUNT()`;
nenhum registro de negócio lido, nenhuma escrita.
**Insumos:** `01-analise.md` (aprovada em 2026-11-15), `02-recon.md`, `comentarios-do-card.md`, `assessment.md`
(achados 1, 2, 4, 5 e 6), skills `salesforce-doutrina` e `padrao-entrega`. A rodada anterior
(`rodada-anterior/03-design.md`) serviu só de referência; as opções A, B, C e D de lá não são retomadas.

**Estimativa de esforço:** 26–44 h
O que mudou em relação à análise (32–56 h):
- Sai o Apex invocável (+8 a 16 h da análise). A regra cabe num Flow autolançado (seção 1), então não há classe nova
  nem a exigência de 85% de cobertura.
- A3 reaproveita o campo de fórmula `Account.Inactive__c`, que já existe (seção 3), e não precisa de cálculo novo.
- Entra o trabalho de liberar o acesso ao `SFAgent2`, que hoje não tem nenhuma concessão na dev (seção 5), e o de
  criar massa fictícia em QA atravessando a integração Protheus (risco R2).
- Faixa por bloco: Custom Metadata e registro 2–3 h · Flow 6–10 h · ação e tópico do `SFAgent2` 4–8 h · permission set
  e acesso ao agente 2–4 h · verificação na dev com massa fictícia 4–6 h · massa e roteiro de QA 5–8 h · apoio à
  homologação 3–5 h.

---

## 1. Decisão: declarativo (Flow autolançado como ação do `SFAgent2`)

A regra A1 a A3 vira **um Flow autolançado, sem gatilho de registro**, exposto como ação do tópico
`insights_comerciais` do `SFAgent2`. O Flow lê Account, Opportunity e um Custom Metadata, decide a ação por regra
fixa e devolve um texto pronto. O assistente só apresenta esse texto.

Por que não o nível acima (configuração pura):
- Um campo de fórmula em Account não enxerga as Opportunity filhas. A2 ("existe oportunidade aberta parada") exige
  olhar os filhos.
- Levar A2 para um campo de Account exigiria roll-up por Flow ou trigger, gravando em Account. Isso cria automação
  nova num objeto com o achado 1 do assessment (ordem de execução não mapeada) e contraria P6 (não gravar nada).
- As ações padrão do agente que já existem (`ConsultarPedidos`/`queryRecords`, `AgregacaoPedidos`/
  `queryRecordsWithAggregate`) deixam o LLM montar a consulta e escolher a prioridade. O resultado não é
  determinístico, o que contraria P5 e o critério "não inventa ação fora da lista".
- Não há motor de recomendação nativo para configurar: 0 `RecommendationStrategy` (recon, seção 1).

Por que não descer para código (Apex invocável):
- Nenhum dos critérios da doutrina para Apex se aplica: não há rollback, callout, recursão nem volume em lote. A
  consulta é de uma conta por vez, com 3 consultas de no máximo 1 registro cada.
- O achado 2 (cobertura de 10%) pesa contra acrescentar classe sem necessidade.
- O ponto em que o Flow perde para o Apex é o teste unitário determinístico. Isso é compensado pela verificação com
  massa fictícia e pelos cenários de QA (seção 10).

## 2. O que reaproveita e o que cria (regra 3 da conta)

| Item | Situação na org (confirmada) | Decisão |
|---|---|---|
| Agente `SFAgent2` (`BotDefinition`, tipo `InternalCopilot`) | Existe. 4 versões, **todas `Inactive` na dev** | **Reaproveita.** Nenhum agente novo |
| Tópico `insights_comerciais_1790e90ae9fbdc8` ("Insights Comerciais e Acompanhamento"), do planner `SFAgent2_v4` | Existe. É o tópico ligado à versão mais recente (`GenAiPlannerFunctionDef`) | **Altera:** instrução de escopo para "próxima ação" e inclusão da ação nova |
| Ação `IdentificarConta` (`identifyRecordByName`) | Existe | **Reaproveita** para resolver a conta citada pelo vendedor antes de chamar a ação nova |
| Ações `ConsultarPedidos`, `AgregacaoPedidos`, `QueryRecords_17208408f837c47` | Existem | **Não altera.** Continuam atendendo os outros pedidos do tópico |
| Tópicos `insights_comerciais` das versões v1 a v3 (`…17905e3f890225d`, `…179321583de179d`, `…179cc86a5c7a874`) | Existem | **Não altera.** Ver P11 |
| `Account.Inactive__c` (fórmula: `IF((today() - LastPurchase__c) > 90, true, false)`) | Existe | **Reaproveita como regra A3.** É a definição de "inativo" que a org já usa |
| `Account.LastPurchase__c` (roll-up MAX de `Opportunity.CloseDate`, filtro `StageName = 'Fechado/Ganho'`) | Existe | **Reaproveita** como sinal de histórico (dados insuficientes) |
| `Account.Risk__c` (lista A a E, padrão E) | Existe. O `OpportunityFlow` (decisão `ValidateFinancialAnalysis`) já trata `Risk__c = 'E'` como gatilho de análise financeira | **Reaproveita como regra A1**, com o valor "E" vindo do Custom Metadata |
| `Opportunity.IsClosed`, `LastActivityInDays`, `LastActivityDate`, `StageName`, `CreatedDate` | Existem; `LastActivityInDays` é filtrável (`describe`) | **Reaproveita** na regra A2 |
| Flow `ScheduledFlowOpportunity` | Existe. Pela descrição na metadata, calcula `LastMonthPurchaseValue__c` e `Ranking__c` por conta (EPLAST-47). Não trata oportunidade parada | **Não sobrepõe A2.** Não altera |
| `ScheduledFlowOpportunitySetting__mdt`, `RankingRange__mdt` | Existem, com finalidade de ranking | **Não reaproveita:** finalidade diferente. Misturar parâmetros de ranking com os de próxima ação acoplaria duas demandas |
| `PS_Comercial_ResumoClienteAgente` | Existe, 0 atribuições. Pelo design da EPLAST-34, dá acesso só a `CustomerSummaryService` (`[demandas/EPLAST-34/03-design.md]`) | **Não reaproveita.** Ver seção 5 |
| Custom Metadata `NextBestActionSetting__mdt` | Não existe | **Cria** (seção 3) |
| Flow `Account_Agente_ProximaAcao` | Não existe | **Cria** (seção 3) |
| Ação de agente `ProximaAcaoCliente` (`GenAiFunction`, alvo Flow) | Não existe | **Cria** e liga ao tópico da v4 |
| Permission set `PS_Comercial_ProximaAcao` | Não existe | **Cria** (seção 5) |

## 3. Componentes

### 3.1 Custom Metadata `NextBestActionSetting__mdt` (cria)
A org nomeia seus CMDT em inglês com sufixo `Setting` (`ScheduledFlowOpportunitySetting__mdt`), e o `CLAUDE.md`
do cliente não define prefixo. O nome segue a org. Todos os campos saem com `Description` (achado 4).

| Campo | Tipo | Registro `Default` | Uso |
|---|---|---|---|
| `StaleOpportunityDays__c` | Número(4,0) | 30 | Limiar de A2 |
| `RiskValues__c` | Texto(50) | `E` | Valores de `Risk__c` que disparam A1. Lista separada por `;` |
| `RestrictToOwner__c` | Caixa de seleção | verdadeiro | Recorte de carteira (P8) |

Visibilidade pública. Não é mudança de modelo de dados de negócio: nenhum campo novo em Account, Opportunity ou Order.

### 3.2 Flow `Account_Agente_ProximaAcao` (cria)
Autolançado, sem gatilho, API atual (68.0). Entrada: `recordId` (Id da conta). Saídas: `actionCode`
(`A1|A2|A3|NONE|NODATA|NOT_OWNER`) e `message` (texto pronto para o vendedor).

Passos, nesta ordem:
1. **Get Records** `NextBestActionSetting__mdt`, `DeveloperName = 'Default'`.
2. **Get Records** Account por `recordId`, só os campos `Name`, `OwnerId`, `Risk__c`, `LastPurchase__c`,
   `Inactive__c`. Se não encontrar (sem acesso ou Id inválido), devolve `NOT_OWNER` com mensagem neutra.
3. **Carteira:** se `RestrictToOwner__c` for verdadeiro e `OwnerId` for diferente de `$User.Id`, devolve `NOT_OWNER`
   ("Esta conta não está na sua carteira.") **sem nenhum dado da conta**.
4. **Get Records** Opportunity, primeiro registro só, `AccountId = recordId` e `IsClosed = false`, com filtro
   `LastActivityInDays > StaleOpportunityDays__c` **ou** (`LastActivityDate` vazio e `CreatedDate` anterior a
   hoje menos `StaleOpportunityDays__c`), ordenado por `LastActivityInDays` decrescente. Campos: `StageName`,
   `LastActivityInDays`.
5. **Get Records** Opportunity, primeiro registro só, `AccountId = recordId` (existe alguma?). Campo: `Id`.
6. **Decisão**, a primeira que casar vence:
   1. `NODATA`: passo 5 vazio **e** `LastPurchase__c` vazio. Fica antes de A1 por causa do padrão E (P9).
   2. `A1`: `Risk__c` está em `RiskValues__c`. "Tratar risco da conta: o cadastro está com risco {Risk__c},
      que leva novas oportunidades para análise financeira."
   3. `A2`: passo 4 encontrou registro. "Retomar oportunidade parada: há uma oportunidade em {StageName} sem
      atividade há {n} dias."
   4. `A3`: `Inactive__c` verdadeiro. "Reativar cliente sem compra recente: a última compra ganha foi há mais de
      90 dias."
   5. `NONE`: "Nenhuma ação prioritária no momento."
7. Atribui `actionCode` e `message` às saídas. **Nenhum elemento de criação, atualização, exclusão, envio de e-mail
   ou ação de mensagem.**

Escala e CPU: são sempre 4 consultas com no máximo 1 registro cada, independentemente de quantas oportunidades a conta
tem. Não há loop, então uma conta com centenas de oportunidades não multiplica o custo (lição SOMOSAGILITY-10). Não
há DML, então nenhum trigger ou Flow de Account, Opportunity ou Order roda.

Contexto de execução: `DefaultMode`, com a carteira imposta pelo passo 3. Ver incerteza I2.

### 3.3 Ação `ProximaAcaoCliente` e tópico (altera `SFAgent2_v4`)
- Ação nova `ProximaAcaoCliente` (`GenAiFunction`, tipo Flow, alvo `Account_Agente_ProximaAcao`). Entrada
  `recordId` obrigatória; saída `message` marcada para exibição.
- Tópico `insights_comerciais_1790e90ae9fbdc8`: acrescentar à descrição de escopo "sugerir a próxima ação para um
  cliente". Acrescentar instruções:
  - quando o vendedor pedir a próxima ação, identificar a conta com `IdentificarConta` e chamar `ProximaAcaoCliente`;
  - apresentar a `message` sem acrescentar, trocar nem combinar ações;
  - se o código for `NOT_OWNER`, não consultar a conta por outras ações.
- Nada é alterado nas ações existentes nem nos outros tópicos.

### 3.4 O que **não** é criado
Nenhum trigger, Flow acionado por registro, campo em Account, Opportunity ou Order, classe Apex, LWC, componente de
página, relatório, agente novo, e-mail alert ou ação de envio.

## 4. Ordem de execução nos objetos tocados

| Objeto | Automação existente no mesmo objeto (recon, seção 3) | Evento disparado por esta demanda |
|---|---|---|
| Account | `AccountBefore` (SBQQ), `AccountTrigger`, Flows `AccountTriggered`, `UpdateParentAccountUsedLimit` (after save), `AccountUpdateEconomicGroup` (agendado) | **Nenhum.** Só leitura |
| Opportunity | `OpportunityBefore`, `OpportunityAfter` (SBQQ), `OpportunityTrigger`, Flows `OpportunityFlow`, `Oportunidade_Industria` (after save), `ScheduledFlowOpportunity` (agendado) | **Nenhum.** Só leitura |
| Order | `OrderTrigger` (SBQQ e custom, mesmo nome), Flows `Order`, before save de Id externo, `OrderScheduledFlow` | **Nenhum.** Order fora da v1 (P3) |
| Task | Flow `TaskCreatedOrUpdated` | **Nenhum** |

**Achado 1 do assessment (alta).** Não se aplica ao componente: a solução não grava nada, então não entra na ordem de
execução e não precisa do mapeamento triggers × CPQ × Flows. **Aplica-se à massa de teste:** criar contas e
oportunidades fictícias na dev e na QA atravessa toda a cadeia acima, inclusive a integração Protheus (risco R2). A
condição que invalida esta decisão é qualquer mudança futura que grave em Account, Opportunity ou Task. Nesse caso,
o mapeamento completo do achado 1 vira pré-requisito.

## 5. Permissões

- **Cria `PS_Comercial_ProximaAcao`**, com:
  - acesso ao agente `SFAgent2` (concessão de agente no permission set);
  - leitura de Account e Opportunity e FLS de leitura em `Risk__c`, `LastPurchase__c`, `Inactive__c`;
  - acesso ao Flow `Account_Agente_ProximaAcao`, se a org restringir execução de Flow por permissão.
- **Nenhum perfil é alterado** (perfis comerciais duplicados no assessment).
- **Por que não reaproveitar `PS_Comercial_ResumoClienteAgente`:** ele pertence a outra entrega (`CustomerSummaryService`)
  e tem 0 atribuições. Juntar as duas funções num permission set amarraria a liberação de uma à outra. Um permission
  set group comercial pode reunir os dois depois.
- **Achado da org:** hoje **nenhum** permission set ou perfil tem concessão ao `SFAgent2` na dev (`SetupEntityAccess`
  com `SetupEntityId` do Bot: 0 linhas). Ou seja, nenhum vendedor usa o agente hoje na dev. A licença ou PSL de
  Agentforce que o usuário precisa não foi confirmada (I3).
- Quem recebe o PS: os vendedores de teste na QA. Os usuários reais são definidos na homologação (P10).

## 6. Marketing Cloud (regra 2 da conta)

Nada é enviado. A sugestão é só texto no assistente. Nenhum Flow `MCC_*` é tocado. Se a Eplast quiser, mais tarde,
usar a próxima ação para segmentar público no Marketing Cloud, o CRM precisaria gravar o código da ação em campo. Isso
contraria P6 e reabre o achado 1, então fica fora desta demanda. Seria um passo de quem opera o Marketing Cloud, sobre
um dado que o CRM passaria a fornecer.

## 7. Critérios de aceite ajustados pelo design

A análise foi aprovada com os cenários abaixo escritos de um jeito que a org não sustenta. O QA testa com este texto:

- **"Conta sem risco":** como `Risk__c` tem padrão `E`, nenhuma conta nasce "sem risco". Leia "Risk__c com valor
  fora de `RiskValues__c`" (por exemplo, `A`).
- **"Vendedor não recebe sugestão de conta que não é da sua carteira":** com OWD de Account `ReadWrite`, o
  compartilhamento padrão não esconde a conta. O recorte vem de `RestrictToOwner__c` (P8). Então a resposta é "Esta
  conta não está na sua carteira", sem nenhum dado da conta. A frase "o acesso segue o compartilhamento padrão" sai do
  critério.
- **"Mudar um limiar altera a sugestão":** vale para `StaleOpportunityDays__c` (A2) e para `RiskValues__c` (A1). O
  limiar de A3 está na fórmula de `Inactive__c` (P2).
- **"Mesma regra para os demais consumidores":** EPLAST-28 e `eplast-ent-11` estão em backlog. O cenário vira
  orientação de design para essas demandas (chamar `Account_Agente_ProximaAcao` ou ler `NextBestActionSetting__mdt`)
  e não é testável nesta entrega.

## 8. Premissas assumidas (validar na homologação)

Herdadas da análise (P1 a P7) com o que o design fixou, e novas (P8 a P12).

- [x] **P1 · Lista de ações e prioridade.**
  - Decisão: `NODATA` → A1 → A2 → A3 → `NONE`, fixa no Flow. Os textos ficam no Flow.
  - Evidência: análise P1. A prioridade fica no Flow, e não em Custom Metadata como a análise sugeria, porque
    tornar a ordem configurável exigiria laço e ordenação dinâmica no Flow, que são mais complexos de manter do que a
    regra. É o padrão mais simples (doutrina).
  - Como mudar: trocar a ordem ou o texto é uma nova versão do Flow, sem código.
- [x] **P2 · Limiares: 30 dias (A2) e 90 dias (A3).**
  - Decisão: A2 em `StaleOpportunityDays__c` = 30. A3 reaproveita `Account.Inactive__c`, que já usa 90 dias.
  - Evidência: a org já define "inativo" como mais de 90 dias desde a última compra ganha (fórmula de `Inactive__c`).
    Criar outro limiar de 90 dias daria à Eplast duas definições de inativo que podem divergir (regra 3).
  - Como mudar: A2 no registro de Custom Metadata. A3 na fórmula de `Inactive__c`, que vale para toda a org.
    Se a Eplast quiser um limiar só da próxima ação, acrescenta-se um campo ao CMDT.
- [x] **P3 · Fontes: Account e Opportunity.** Order fica fora. `AccountHasCheckInTask__c` não entra: não há
  evidência de quem o preenche (recon), e a dev não tem dados.
  - Como mudar: incluir numa demanda futura.
- [x] **P4 · Canal: só o assistente** (tópico da v4 do `SFAgent2`).
  - Como mudar: um componente de página pode chamar o mesmo Flow depois.
- [x] **P5 · Regra determinística.** O LLM só apresenta o texto. A instrução do tópico proíbe acrescentar ação.
- [x] **P6 · Sob demanda, sem gravar.** Nenhum DML (seção 3.2).
- [x] **P7 · Regra única.** EPLAST-28 e `eplast-ent-11` reaproveitam o Flow e o CMDT (seção 7).
- [x] **P8 · Recorte de carteira = dono da conta.**
  - Pergunta: como cumprir "vendedor não vê conta de outro" com OWD de Account `ReadWrite`?
  - Decisão: o Flow só responde para o dono (`OwnerId = $User.Id`), com flag `RestrictToOwner__c` ligada.
  - Evidência: OWD Account `ReadWrite` e Opportunity `Read` (recon, seção 5). A análise P6 definiu o público como
    "vendedor dono da conta". Não há regra de compartilhamento confirmada que restrinja a carteira.
  - Como mudar: desligar a flag para seguir só o compartilhamento. Membros de equipe de conta ou gestores exigem
    ajuste no Flow.
- [x] **P9 · Valor de risco = `E`, e "dados insuficientes" vem antes de A1.**
  - Pergunta: qual valor de `Risk__c` significa risco?
  - Decisão: `E`, em `RiskValues__c`. `NODATA` é avaliado antes de A1.
  - Evidência: o `OpportunityFlow` ativo manda a oportunidade para análise financeira quando
    `Account.Risk__c = 'E'` (decisão `ValidateFinancialAnalysis`). `Risk__c` vem do Protheus
    (`AccountUtility`, `AccountAdapter`) e só pode ser alterado pelos perfis integração, administrador e Financeiro
    (validation rule `CheckUserCanSetRisk`). Como `E` é o valor padrão, uma conta recém-criada sem histórico cairia
    em A1. Por isso `NODATA` vem primeiro.
  - Como mudar: editar `RiskValues__c` (por exemplo `D;E`). Para A1 vencer `NODATA`, é uma nova versão do Flow.
- [x] **P10 · Público do permission set.** Na QA, só os vendedores de teste. A lista de usuários reais sai da
  homologação. Muda só a atribuição.
- [x] **P11 · Versão do agente.** Altera só o planner `SFAgent2_v4`, que é a versão mais recente.
  - Evidência: as 4 versões estão `Inactive` na dev, a v4 é a de maior número e usa o tópico "Insights Comerciais
    e Acompanhamento", cuja descrição já cobre oportunidades paradas. Versão inativa pode ser editada sem criar outra.
  - Como mudar: se a Eplast tiver outra versão em uso, a ação e a instrução são copiadas para ela. A EPLAST-29
    (backlog, mesmo agente) parte da v4 deixada por esta demanda.
- [x] **P12 · Oportunidade aberta sem nenhuma atividade conta como parada** quando foi criada há mais dias que o
  limiar.
  - Evidência: padrão. `LastActivityInDays` fica vazio sem atividade, e ignorar esses registros esconderia
    exatamente as oportunidades mais abandonadas.
  - Como mudar: retirar a segunda condição do filtro do passo 4.

## 9. Riscos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **O agente não está ativo nem liberado para ninguém na dev** (4 versões `Inactive`, 0 concessões). Testar exige ativar a v4 e dar acesso. A licença de Agentforce para os usuários de teste não está confirmada | **Alta** | Ativar a v4 e atribuir `PS_Comercial_ProximaAcao` é passo manual pós-deploy (dev e QA). Se faltar licença, a verificação sai `inconclusiva` dizendo isso, e o Flow é verificado sozinho |
| R2 | **Massa de teste atravessa a cadeia Protheus.** Criar Account e Opportunity fictícias dispara `AccountTrigger` e `OpportunityTrigger` (achado 1) e pode chamar `SendAccountToProtheus` (achado 2, sem teste) | **Alta** | Antes de criar a massa, o builder confere o desvio de integração existente (`TriggerUtility__mdt`, não lido) e registra no plano. Massa mínima, com nomes claramente fictícios. Sem DML se o envio ao ERP não puder ser contido |
| R3 | Dev e QA podem ser a mesma org (achado 6: o alias de dev aponta para `eplast--qa`) | Média | Fora do alcance do design. A esteira confirma antes do deploy de QA. Se forem a mesma org, a QA deixa de provar o deploy |
| R4 | `Risk__c = 'E'` pode ser o valor da maioria das contas reais (é o padrão), e A1 dominaria as respostas | Média | Na homologação, medir com `SELECT Risk__c, COUNT(Id) FROM Account GROUP BY Risk__c` (agregado, sem dado pessoal). Se dominar, trocar `RiskValues__c` |
| R5 | Saída do Flow passa pelo LLM do agente sem a decisão LGPD D6 (EPLAST-23) | Média | A saída leva só o código, o texto fixo, o estágio e o número de dias. Nada de CPF, e-mail, telefone, valor ou nome de contato. O agente já lê pedidos hoje. O arquiteto humano decide no gate se aceita |
| R6 | O LLM reescrever ou completar a sugestão | Média | Instrução do tópico + cenário de QA "não inventa ação" com perguntas variadas |
| R7 | Validation rules (Account 6, Opportunity 16) recusarem a massa. `Risk__c` só é editável por administrador, Financeiro ou integração | Baixa | Massa criada por administrador. O QA ajusta `Risk__c` com esse perfil |

## 10. O que o QA deve testar onde o assessment aponta fragilidade

1. **Não grava nada (achado 1):** `LastModifiedDate` de contas e oportunidades de teste igual antes e depois de 10
   consultas, e log de depuração do vendedor sem execução de `AccountTrigger`, `OpportunityTrigger`, `AccountTriggered`
   ou `OpportunityFlow`.
2. **Uma conta com muitas oportunidades:** 150 oportunidades abertas numa conta. A resposta sai sem erro de CPU ou
   limite (lição SOMOSAGILITY-10).
3. **Carteira:** vendedor B pergunta pela conta do vendedor A e recebe só "não está na sua carteira".
4. **Precedência:** conta nova com `Risk__c` padrão `E` e sem histórico recebe `NODATA`. Conta com histórico e `E`
   recebe A1, mesmo com oportunidade parada.
5. **A2 por limiar:** com 31 dias sem atividade, A2 aparece. Com o CMDT em 60 e 45 dias sem atividade, não aparece.
   Oportunidade aberta sem nenhuma atividade criada há mais de 30 dias também dispara A2 (P12).
6. **A3:** `LastPurchase__c` há 91 dias (oportunidade `Fechado/Ganho` com `CloseDate` há 91 dias) e nenhuma
   oportunidade parada dá A3.
7. **Sem dado pessoal e sem envio:** a resposta não contém CPF, e-mail, telefone ou valor. Nenhum e-mail sai do CRM.
8. **Massa (R2):** confirmar e registrar que a criação da massa não gerou envio ao Protheus (`IntegrationLog__c`
   por contagem).

## 11. O que **não** será feito nesta demanda

- Order e OrderItem como sinal (P3).
- Visão de gestor, cálculo em lote ou gravação da sugestão em campo (P6).
- Componente de página do registro (P4).
- Texto gerado por IA ou modelo preditivo (P5).
- Público ou campanha no Marketing Cloud (seção 6).
- Alteração das versões v1 a v3 do `SFAgent2` ou das ações existentes.
- Mapeamento completo da ordem de execução do achado 1 e consolidação de triggers. Não é necessário para uma solução
  só de leitura.
- Ativação do `SFAgent2` em produção.

## 12. Incertezas declaradas

- **I1.** Não li a instrução completa do tópico `insights_comerciais_1790e90ae9fbdc8`, só a descrição (cortada). O
  builder lê o planner da v4 antes de editar e preserva o que existe.
- **I2.** O contexto de execução de um Flow autolançado chamado como ação de agente não foi confirmado na
  documentação nesta etapa. A carteira não depende disso (passo 3 explícito). Se o modo padrão não respeitar FLS, o
  builder fixa `SystemModeWithSharing` e registra no plano.
- **I3.** Licença ou PSL de Agentforce dos usuários de teste e forma exata de conceder o agente no permission set.
  Não confirmadas (seção 5).
- **I4.** Flow Test declarativo pode não cobrir Flow autolançado sem gatilho. A evidência vem da execução com massa
  fictícia e dos cenários da seção 10.
- **I5.** O que `TriggerUtility__mdt` faz e se permite desviar a integração na criação da massa (R2). Não lido.
- **I6.** Se QA e dev são orgs distintas (achado 6).

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

## Decisão do responsável (2026-11-16): corrigir a instrução do agente numa versão nova

Decidido por Leonardo Barbosa depois da rodada 3 de QA. Vale acima do que este desenho diz
sobre versões do `SFAgent2`.

- **Defeito (rodada 3, v10 ativa na QA):** o assistente chama `ProximaAcaoCliente`, a ação
  devolve a mensagem certa (campo `result`), mas a resposta ao usuário sai só como "Próxima
  ação para a conta X.", sem a mensagem. Na pergunta seguinte, inventa ação fora da lista
  A1 a A3 ("contato inicial").
- **Correção:** criar a **v14 a partir da v13** (a mais nova na dev e a ativa na QA; tem as
  ações e instruções de 27, 29, 34 e 46 e a correção de confirmação de tarefa da 29). Nada
  das outras demandas é removido nem editado. Única mudança, no tópico de insights
  comerciais, na instrução da EPLAST-27:
  1. depois de chamar `ProximaAcaoCliente`, **apresentar sempre, na íntegra, a mensagem
     devolvida pela ação** (inclusive "Dados insuficientes: ..."), sem resumir a uma frase
     de título;
  2. **nunca recomendar ação fora do que a ação devolveu**; se a ação diz que não há dados
     suficientes, dizer isso e parar, sem sugerir "contato inicial" nem outra ação;
  3. em pergunta de continuação ("e então, qual é a ação?"), repetir a mensagem da ação ou
     chamá-la de novo, nunca improvisar.
- **Pacote:** só a v14 (`genAiPlannerBundles/SFAgent2_v14` e `bots/SFAgent2/v14.botVersion`).
  Tirar a v10 da branch: ela já está na QA.
- **Verificação e QA:** conversar com o agente sem tela (`sf agent preview start` / `send` /
  `end`), pedindo pelo nome da conta, pelo menos 3 vezes por cenário, e conferir que a
  resposta traz a mensagem da ação.

## Decisão do responsável (2026-11-16, rodada 4): a ação aceita o nome da conta

Decidido por Leonardo Barbosa depois da rodada 4 de QA (v14). Vale acima das decisões
anteriores deste desenho no que conflitar.

- **Achado (rodada 4):** pelo Id da conta, 10 de 10 respostas trazem a mensagem certa. Pelo
  **nome**, que é como o vendedor pergunta, falha com frequência ("Please select one option."
  ou só a frase de abertura). A instrução (v14) não bastou: o problema é o encadeamento de
  `IdentificarConta` (por nome) com `ProximaAcaoCliente`, que nem sempre acontece.
- **Correção, declarativa (sem Apex):**
  1. **Flow `Account_Agente_ProximaAcao`, versão nova:** passa a aceitar também o **nome da
     conta** como entrada (texto, opcional), além do Id. Com o nome: busca as contas que o
     usuário enxerga cujo nome contém o texto (respeitando o compartilhamento, como hoje);
     **uma** conta: segue e devolve a mensagem de sempre; **várias**: devolve em `message` a
     lista dos nomes encontrados (no máximo 5) pedindo para o usuário dizer qual, sem
     recomendar nada; **nenhuma**: devolve "Não encontrei conta com esse nome que você possa
     ver". Com o Id, o comportamento atual não muda. O Flow continua sem gravar nada.
  2. **Ação `ProximaAcaoCliente` na versão nova do agente:** ganha a entrada do nome da
     conta, com descrição que diga ao planner para passar o nome quando o usuário não der o
     Id, **sem precisar chamar `IdentificarConta` antes**.
  3. **Instrução da EPLAST-27** no tópico de insights: para "próxima ação" de uma conta,
     chamar `ProximaAcaoCliente` direto, com o Id (se estiver no contexto do registro) ou
     com o nome dito pelo usuário; apresentar na íntegra a `message` devolvida; em pergunta
     de continuação ("e então, qual é a ação?"), **chamar a ação de novo** com a mesma
     conta e repetir a mensagem; nunca recomendar ação fora da devolvida.
- **Versão do agente:** **v15 a partir da v14** (a mais nova na dev e a ativa na QA). Nada
  das outras demandas (29, 34, 46) é removido nem editado. Pacote: só a v15 e a versão nova
  do Flow; tirar a v14 da branch.
- **Verificação e QA:** conversa sem tela (`sf agent preview start` / `send` / `end`), por
  **nome** e por Id, 3 tentativas por cenário em sessões novas (A1, A2, A3, NONE, NODATA,
  nome ambíguo, nome inexistente, conta de outro dono) e a pergunta de continuação. O
  critério é a resposta trazer a mensagem do Flow em todas.

## Decisão do responsável (2026-11-16, rodada 5): limitação conhecida na pergunta de continuação

Decidido por Leonardo Barbosa depois da rodada 5 de QA (v15). O build não muda.

- **O que a rodada 5 provou:** a pergunta direta, por nome e por Id, traz a mensagem da ação
  (a correção da v15 funcionou).
- **O que sobrou (falha média):** numa conta sem dados, na **pergunta de continuação** ("E
  então, qual é a ação?"), o assistente às vezes improvisa uma recomendação fora da lista
  ("iniciar um contato...").
- **Decisão:** isso fica como **limitação conhecida**, a observar na homologação, e **não
  reprova o QA**. O critério "a resposta não inventa ação fora da lista" vale para a
  resposta à pergunta de próxima ação; a pergunta de continuação entra no roteiro do
  cliente, na seção "O que assumimos e você precisa confirmar", dizendo o que foi observado
  e que a correção (instrução mais estrita) entra numa próxima rodada se a Eplast pedir.
- O QA registra o caso em `05-testes.md` como "limitação conhecida (decisão de 16/11)", com
  o que o assistente respondeu, e mantém os demais casos como estão.

---

## Decisão do responsável (2026-11-23, Leonardo Barbosa): a ação aceita o código da conta no lugar do Id

**Achado (sandbox, 17/11, 1 ocorrência):** o Flow `Account_Agente_ProximaAcao` recebeu em `recordId` o código da conta (`000682`) em vez de um Id do Salesforce. O `GetAccount` filtra `Id = recordId`, e um valor que não é Id faz a consulta falhar. É ajuste interno, a corrigir antes de subir.

**Correção, numa versão nova do Flow (v4), sem editar a v3 no lugar e sem mudar a assinatura da ação do agente (mesmas entradas `recordId` e `accountName`, logo sem versão nova do SFAgent2 por causa disto):**

1. Antes de `GetAccount`, o Flow decide se `recordId` tem forma de Id de Conta: 15 ou 18 caracteres e começa por `001`. Só nesse caso segue pelo caminho atual (`GetAccount` por Id).
2. Se `recordId` veio preenchido e **não** tem forma de Id, o Flow o trata como **código da conta** e busca a Conta por esse código. Campo candidato: `Account.ProtheusId__c` ("ID da Conta no Protheus", Text, External Id, não único; existe no repositório). **O builder confirma na org de dev, por metadata e contagem agregada, que é esse o campo que guarda o código no formato de 6 dígitos; se não for, não inventa: registra `**Resultado do build:** bloqueado` com a pergunta.** A comparação é por igualdade.
3. O resultado da busca por código reaproveita o tratamento que já existe para a busca por nome: nenhuma conta → mensagem de não encontrada; uma conta → segue com ela (inclusive a regra de dono, `RestrictToOwner__c`); várias (mesmo código em lojas diferentes) → devolve a lista para o agente pedir que a pessoa escolha, sem escolher sozinho.
4. Nenhum caminho pode terminar em falha não tratada: toda consulta nova tem `faultConnector` para uma saída com mensagem.

**Testes que a verificação e o QA acrescentam (dados sintéticos, contas `TESTE EPLAST-27`):** `recordId` com Id válido (regressão); com código que casa uma conta; com código que casa duas; com código inexistente; com texto qualquer que não é Id nem código; vazio com `accountName` (regressão do caminho por nome). Em todos, o Flow termina sem erro e com a mensagem certa.

As decisões anteriores desta demanda (rodadas 4 e 5) continuam valendo.
