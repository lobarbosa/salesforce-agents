# EPLAST-47 — Design: correção do Fluxo Agendado – Oportunidade

**Cliente:** Eplast · **Etapa:** 3 (design, `arquiteto`) · **Data:** 2026-11-14
**Org de referência:** `sbx-eplast-dev` (sandbox, Org ID `00DHa000006vfMLMAY`), a única conectada nesta sessão. Só leitura: nenhum deploy, DML ou anonymous Apex.
**Entradas:** `01-analise.md` (aprovado em `gates.md`, 2026-11-14), `02-recon.md` (2026-11-14), `comentarios-do-card.md` (respostas P2, P3, P4, P7 e saída do alerta do ex-parceiro), `assessment.md` (trechos por Grep), histórico RAG.
**Status:** pronto para o **gate bloqueante do arquiteto humano**. Há 3 decisões que este design não toma sozinho (seção 0).

**Estimativa de esforço:** 26–40 h

O que mudou em relação à análise (30–50 h): P2, P3, P4 e P7 foram respondidas no card, e a regra de negócio atual fica como está (sem período configurável, sem trocar média por soma, sem renomear campo). O alerta do ex-parceiro saiu do escopo. O recon confirmou que não há Apex gravando os 4 campos nas classes lidas e que não há concorrência de escrita em `AveragePurchasesThisYear__c`. Isso tira horas. Ficam dentro da faixa, e seguram o topo dela: o relatório por metadata (achado EPLAST-39 da skill `salesforce-doutrina`) e o dado sintético em QA, que dispara a cadeia do `OpportunityFlow` (Order, Quote, CPQ). Se o gate recusar os custom metadata types (decisão D1), a faixa cai cerca de 3 h.

---

## 0. Decisões que precisam do aceite do arquiteto humano

| # | Decisão | Proposta deste design | Alternativa se recusada |
|---|---|---|---|
| **D1** | **Novos tipos de metadata (custom metadata types)** para faixas e parâmetros. É um tipo de objeto novo na org, não dado de negócio, mas pode ser lido como mudança de modelo de dados: **escalo ao humano, não decido sozinho.** | `RankingRange__mdt` (7 faixas) e `ScheduledFlowOpportunitySetting__mdt` (dia de execução e destinatário da falha). Os dois existentes (`Protheus__mdt`, `TriggerUtility__mdt`) não servem: o segundo só tem `BypassTrigger__c` (confirmado por describe), e o primeiro é da integração. | Faixas fixas em um elemento Decision (7 regras) e destinatário em Custom Label. O critério 12 passa a ser "valores só na Decision nova", e mudar faixa exige nova versão do fluxo. |
| **D2** | **Ativar histórico de campo em `Account.Ranking__c`** para o relatório de mudanças (critério 14). Hoje `IsFieldHistoryTracked = false` (confirmado). Configuração nativa, mas muda o que a org guarda. | Ativar histórico só em `Ranking__c` e criar 1 relatório sobre o tipo padrão de histórico de conta. | Sem histórico, o critério 14 não tem como mostrar "classificação anterior" sem campo novo. Volta a P12 com a Eplast. |
| **D3** | **Critério 7 da análise (período configurável) sai desta demanda.** A diretriz do card de 14/11 diz "a regra de negócio atual não muda; muda a execução por conta, as faixas e o alerta de erro", e P2 manteve `ThisYear__c`. | O período continua sendo `Opportunity.ThisYear__c` (data de criação). O critério 7 não é testado. | Se o gate quiser manter o critério 7, o período vira campo do custom metadata, e a fórmula `ThisYear__c` deixa de ser o filtro. Isso **muda regra** e precisa voltar ao cliente. |

---

## 1. Solução proposta

**Nível: declarativo (Flow), ajustando o `ScheduledFlowOpportunity` existente em uma nova versão.** Sem Apex.

Por que não o nível acima (configuração pura): o cálculo é uma agregação de `Opportunity` sobre `Account` com filtro (`StageName`, `ThisYear__c`), gravada uma vez por mês. Roll-up summary de Account sobre Opportunity existe na plataforma, mas criaria campo novo (modelo de dados) e não faz a classificação nem a checagem do dia. Configuração cobre só parte: picklist, histórico de campo e parâmetros (custom metadata).

Por que não descer para Apex: nenhum critério da doutrina se aplica. Não há callout, rollback complexo nem recursão. O volume é o único ponto, e a mudança **reduz** a carga em relação a hoje (seção 5). Se a medição em QA passar de 70% de um limite (critério de escalonamento da doutrina), o design volta para revisão com a opção Apex (Batch), não antes.

### 1.1 Fluxo novo (versão 2 do `ScheduledFlowOpportunity`)

```
[Agendado: Daily, 15:47 UTC — mantido]  start: Opportunity, IsWon = true  (mantido: mesma população de contas)
 └─ GetSetting      (Get Records ScheduledFlowOpportunitySetting__mdt, registro Default)          [novo]
 └─ CheckDayMonth   DAY(hoje) = GetSetting.RunDayOfMonth__c (registro = 14)                          [alterado: era 14 fixo]
 └─ CheckAccount    $Record.AccountId vazio → fim                                                    [novo]
 └─ GetRepresentativeOpportunity  Opportunity, AccountId = $Record.AccountId, IsWon = true,
                                  ordenado por Id crescente, só o primeiro                           [novo]
 └─ IsRepresentative  GetRepresentativeOpportunity.Id = $Record.Id ? senão → fim                      [novo: execução por conta]
 └─ GetOpportunities  (mantido: AccountId, StageName = Fechado/Ganho, ThisYear__c = true)
 └─ LoopOpportunities → AssignSumValue (mantido: SumAmount += Amount)
 └─ [removidos] QuantityOpportunities/Count (sem uso), GetOpportunities2 (sem filtro de conta, sem uso)
 └─ ClassifyRanking  (sobre $Record.Account.AveragePurchasesThisYear__c — mantido, P3)               [reescrito]
        média vazia → NewRanking = valor atual da conta (não altera; P6, ver seção 7)
        senão: GetRanges (RankingRange__mdt, ordenado por SortOrder__c) e loop com flag:
               primeira faixa com média ≤ UpperLimit__c, ou UpperLimit__c vazio (3G) → NewRanking
 └─ HasChanges  SumAmount ≠ conta.LastMonthPurchaseValue__c  OU  NewRanking ≠ conta.Ranking__c ?   [novo]
        não → fim (não grava)
 └─ UpdateAccount  Account Id = $Record.AccountId:
        LastMonthPurchaseValue__c = SumAmount, Ranking__c = NewRanking   (1 update só)               [substitui 6 updates]
        fault → LogFault                                                                              [novo]
 └─ LogFault   cria IntegrationLog__c (IntegrationAction__c = "ScheduledFlowOpportunity",
               ResponseStatus__c = "Erro", ExecutionDate__c = agora,
               ResponseBody__c = Id da conta + $Flow.FaultMessage)                                    [novo, reaproveita objeto]
        destinatário configurado (GetSetting.FaultRecipient__c não vazio) e P5 = operacional ?
               sim → Send Email (ação padrão) ao destinatário, sem dado de cliente no corpo além do Id
               não → só o log
```

Pontos de desenho:
- **Execução por conta sem gravar estado.** Cada oportunidade ganha continua gerando uma interview (é assim que o gatilho agendado funciona), mas só a da oportunidade ganha de menor Id da conta segue adiante. As demais terminam antes da soma. Resultado: 1 cálculo e no máximo 1 update por conta por execução (critério 4), sem campo novo de controle. A população de contas não muda: segue "contas com pelo menos 1 oportunidade ganha", como hoje.
- **Por que não mudar o objeto de início para `Account`.** Mudaria a população (todas as contas, ou exigiria um filtro que hoje não existe sem campo novo), multiplicaria interviews diárias pelo total de contas, e contas sem venda passariam a ser classificadas. Isso é mudança de regra, que o card proibiu.
- **Por que manter Daily + checagem do dia (P9).** Fluxo agendado só aceita frequência Once, Daily ou Weekly. Mensal não existe. P9 fica respondida pela plataforma: mantém diário com checagem do dia. O dia passa ao custom metadata, o que também permite ao QA rodar em qualquer data (seção 8).
- **Faixas (P7).** Mesma comparação do card: acima do limite anterior, até o limite inclusive. Registros de `RankingRange__mdt`:

| SortOrder__c | Ranking__c | UpperLimit__c |
|---|---|---|
| 1 | MP | 10.000 |
| 2 | PP | 35.000 |
| 3 | P | 80.000 |
| 4 | M | 160.000 |
| 5 | G | 500.000 |
| 6 | GG | 1.000.000 |
| 7 | 3G | (vazio = sem teto) |

  A ordenação é por `SortOrder__c`, não por `UpperLimit__c`: ordenar por limite poria o vazio (3G) em primeiro.
- **Um update só.** Hoje o fluxo faz 2 updates por interview (valor e depois ranking), cada um disparando a cadeia de Account (seção 4). Passa a 1, e nenhum quando nada mudou.

### 1.2 Achado que o cliente precisa saber antes do QA (não bloqueia)

**A regra PP atual compara com `EqualTo 10000`, não com "até 10.000"** (confirmado no XML da versão ativa). Na prática, hoje toda conta com média **abaixo** de 10.000, ou vazia, cai no resultado padrão e vira **GG**. O card pede "MP até 10.000". Com a correção, essas contas passam de GG para MP. Na primeira execução após a entrega haverá uma troca grande de classificação em contas pequenas, visível no comercial e no Protheus. Isso não é regra nova (o card é explícito), mas o consultor deve avisar a Eplast antes da homologação.

---

## 2. Reaproveita × cria (regra 3 da conta)

| # | Item | Situação na org (confirmado em `sbx-eplast-dev`) | Decisão |
|---|---|---|---|
| 1 | Flow `ScheduledFlowOpportunity` | Existe. Versão ativa 1, Scheduled, `Opportunity`, `IsWon = true`, Daily | **Reaproveita**: nova versão do mesmo fluxo. Mantém API name, agendamento e horário. Não se cria fluxo novo. |
| 2 | `GetOpportunities`, `LoopOpportunities`, `AssignSumValue`, `SumAmount` | Existem | **Reaproveita** sem mudar filtro (P2). |
| 3 | `GetOpportunities2`, `QuantityOpportunities`, variável `Count` | Existem, sem uso (resultado não é lido) | **Remove.** |
| 4 | `ValuePurchasesLastMonth` e os 5 updates `UpdateAccountPP/P/UpdatAccountM/UpdateAccountG/UpdateAccountGG` + `LastMonthPurchaseValue` | Existem | **Substitui** por `ClassifyRanking` + `UpdateAccount` (1 update). |
| 5 | `CheckDayMonth` e fórmula `Day` | Existem (descrição diz "dia 1º", regra usa 14) | **Altera**: compara com o parâmetro. Corrige a descrição. |
| 6 | `Account.Ranking__c` | Existe, picklist **restrita**, 5 valores (PP, P, M, G, GG), descrição vazia | **Altera**: adiciona MP e 3G (ordem MP, PP, P, M, G, GG, 3G). Preenche descrição. |
| 7 | `Account.LastMonthPurchaseValue__c` | Existe, currency, descrição vazia | **Reaproveita** com o mesmo nome (P4). Só preenche descrição dizendo que guarda a soma das ganhas do ano (`ThisYear__c`), apesar do rótulo "Último Mês". |
| 8 | `Account.AveragePurchasesThisYear__c` | Existe; gravado pelo `OpportunityFlow` | **Reaproveita só como leitura** (P3). Não altera o `OpportunityFlow`. |
| 9 | `IntegrationLog__c` | Existe (campos `IntegrationAction__c`, `ResponseStatus__c`, `ResponseBody__c`, `ExecutionDate__c`, entre outros); sem trigger | **Reaproveita** para registrar falha. Não se cria objeto de log. Ressalva: o objeto nasceu para integração HTTP; o uso fica identificado por `IntegrationAction__c = ScheduledFlowOpportunity`. |
| 10 | Custom metadata de faixas e parâmetros | Não existe (só `Protheus__mdt` e `TriggerUtility__mdt`) | **Cria** `RankingRange__mdt` e `ScheduledFlowOpportunitySetting__mdt`, **sujeito a D1**. |
| 11 | Histórico de campo em `Ranking__c` | Desativado (`IsFieldHistoryTracked = false`) | **Ativa**, sujeito a D2. |
| 12 | Relatório de mudança de classificação | Nenhum encontrado por nome entre 379 relatórios (recon). Conteúdo dos relatórios não lido. | **Cria** 1 relatório, salvo se a Eplast apontar um existente (P12). |
| 13 | Ação de e-mail no fluxo | Não existe hoje | **Cria** dentro do caminho de falha, condicionada a P5 (seção 6). |
| 14 | Agente `SFAgent2` | Existe | Não se aplica. Não é alterado. |
| 15 | Apex | Não se cria nem se altera classe ou trigger | n/a |

Componentes novos com API name:
- `RankingRange__mdt`: `Ranking__c` (Text 3), `UpperLimit__c` (Number 16,2, opcional), `SortOrder__c` (Number 2,0). 7 registros (`MP`, `PP`, `P`, `M`, `G`, `GG`, `X3G`; o nome do registro não pode começar com dígito, o valor do campo é `3G`).
- `ScheduledFlowOpportunitySetting__mdt`: `RunDayOfMonth__c` (Number 2,0), `FaultRecipient__c` (Email, opcional). 1 registro `Default` com dia 14 e destinatário **vazio** até P11.
- Relatório `AccountRankingChanges` (nome provisório), pasta a definir (P12).

Todo componente novo ou alterado nasce com descrição preenchida (assessment: 153 de 223 campos sem descrição em Account/Order/Opportunity/OrderItem). Os dois campos tocados (`Ranking__c`, `LastMonthPurchaseValue__c`) saem desta demanda com descrição.

Nomenclatura: o padrão do squad seria `Opportunity_Scheduled_...`. Mantém-se `ScheduledFlowOpportunity` porque renomear criaria outro fluxo (regra 3). Campos novos seguem o padrão em inglês dos campos da org (o `CLAUDE.md` da conta não define prefixo).

---

## 3. Objetos, campos e automações afetados

| Componente | Tipo | Leitura / escrita nesta demanda | Confirmação |
|---|---|---|---|
| `Opportunity.IsWon`, `AccountId`, `StageName`, `Amount`, `ThisYear__c` | campos | leitura | recon (describe) |
| `Opportunity.LastMonth__c` | fórmula | deixa de ser lido (sai com `GetOpportunities2`) | recon |
| `Account.AveragePurchasesThisYear__c` | currency | leitura | recon + XML |
| `Account.LastMonthPurchaseValue__c` | currency | escrita | recon + XML |
| `Account.Ranking__c` | picklist restrita | escrita + 2 valores novos | describe nesta sessão (`restrictedPicklist = true`) |
| `IntegrationLog__c` | objeto custom | criação, só em falha | describe nesta sessão |
| `Order` | — | **não é lido nem gravado** pelo fluxo | XML |
| Permission sets `Protheus` (leitura e edição nos 4 campos), `AncCrmIntegrationUser` e `sfdc_a360_sfcrm_data_extract` (leitura) | permissão | sem mudança | recon |

**Permissões.** Nenhum perfil ou permission set muda. Valor novo de picklist não exige permissão. O fluxo agendado roda em contexto de sistema e lê custom metadata sem permissão extra. O relatório herda o acesso da pasta (P12). O usuário que vê `Ranking__c` (16 perfis) passa a ver MP e 3G.

---

## 4. Ordem de execução em Account, Opportunity e Order

O fluxo roda no job agendado próprio, não no salvar do usuário. O evento alterado é o **update de `Account` feito pelo fluxo**.

**Account (único objeto gravado).** A cada update, na ordem da plataforma (skill `salesforce-doutrina`):
1. Before-save flows de Account: nenhum ativo entre os 9 flows de Account/Opportunity lidos no recon.
2. Before triggers: `AccountBefore` (pacote SBQQ, não lido) e `AccountTrigger` (custom, valida CNPJ). **A ordem entre os dois não é garantida pela plataforma** (assessment, achado de automação concorrente).
3. Validation rules de Account (6 ativas, nomes confirmados nesta sessão): `Celular`, `Contato_Fiscal`, `Telefone`, `WhatsApp`, `CheckUserCanSetLimitDueDate`, `CheckUserCanSetRisk`. Fórmulas não lidas.
4. After triggers: `AccountTrigger` after update (`updateAccountCNPJInfo`). Não li o helper; não sei se faz callout sempre ou só quando o CNPJ muda.
5. Workflow field updates: 2 em Account+Opportunity (contagem do recon; campos não verificados).
6. After-save flows `AccountTriggered` e `UpdateParentAccountUsedLimit`, **ambos sem critério de entrada** (confirmado no XML): rodam em todo update. O segundo atualiza a conta pai, que dispara a mesma cadeia de novo na conta pai.

**Como a mudança lida com isso:**
- Não acrescenta automação em Account e não depende da ordem acima. Os campos gravados não são lidos por nenhum desses componentes, até onde o recon leu (5 classes, 2 triggers custom, 9 flows). Os triggers do SBQQ não foram lidos: essa é a incerteza que fica.
- **Reduz** o número de vezes que a cadeia roda: de 2 updates por oportunidade ganha para no máximo 1 por conta, e nenhum quando os valores não mudaram (`HasChanges`). É a melhor mitigação disponível sem tocar em código de outra demanda.
- Falha de qualquer elo da cadeia (validation rule de telefone em conta antiga, erro do helper de CNPJ, trava na conta pai) cai no caminho de falha e vira log, em vez de falha silenciosa da interview.
- Não usa `TriggerUtility__mdt.BypassTrigger__c`: é chave global e desligaria triggers da org inteira durante o job.

**Opportunity.** O fluxo só lê `Opportunity`. Nenhum trigger (`OpportunityTrigger`, `OpportunityBefore`, `OpportunityAfter`) ou flow de Opportunity é disparado pela mudança. Não se aplica.

**Order.** Não se aplica: o fluxo não lê nem grava `Order`. A colisão do `OrderTrigger` custom com o do SBQQ e as 23 validation rules de Order não são tocadas nem agravadas pelo fluxo. **Exceção no teste:** criar oportunidade ganha sintética em QA dispara o `OpportunityFlow`, que cria `Order`, `Quote`, chama `CreateQuoteCPQController` e envia aprovação (`submit`) (confirmado no XML). Ver risco R5.

---

## 5. Limites de governador e escala

Volume real: desconhecido. A dev tem 0 contas e 0 oportunidades. Produção não pode ser consultada. P10 aberta.

| Cenário | Hoje (versão 1) | Depois (versão 2) |
|---|---|---|
| Interviews por dia | 1 por oportunidade ganha, todo dia (terminam na checagem do dia fora do dia 14) | Igual. Limite da plataforma para interviews agendadas em 24 h: o maior entre 250.000 e 200 × licenças (documentação Salesforce; a confirmar pelo volume de P10). |
| Conta com N oportunidades ganhas (o "pai com muitos filhos" do achado SOMOSAGILITY-10) | N interviews, cada uma lê as N oportunidades (N² linhas) e faz 6 elementos de update possíveis, 2 executados | N interviews leem 1 linha cada (`GetRepresentativeOpportunity`); só 1 lê as N e faz no máximo 1 update |
| `GetOpportunities2` | Sem filtro de conta: cada interview lê **todas** as oportunidades `LastMonth__c` da org. Risco real de passar de 50.000 linhas no lote. | Removido |
| DML por lote de 200 interviews | até 400 updates de Account, cada um com a cadeia da seção 4 | até 200, tipicamente menos (`HasChanges`) |
| Custom metadata | n/a | Get Records em custom metadata não conta no limite de SOQL |

A plataforma agrupa Get Records e Update Records das interviews do mesmo lote. A medição do QA confirma (seção 8). Critério de escalonamento: CPU ou SOQL acima de 70% do limite no lote de volume volta o design para revisão, com a opção Apex Batch.

Ponto que não consigo medir: a cadeia de Account (seção 4) com conta pai. Se várias contas filhas do mesmo grupo caem no mesmo lote, `UpdateParentAccountUsedLimit` atualiza a mesma pai várias vezes, com risco de `UNABLE_TO_LOCK_ROW` (critério 6). Isso já acontece hoje, em dobro.

---

## 6. Caminho de falha e Marketing Cloud (regra 2 da conta)

- O aviso de falha é **operacional** (erro técnico de um job), não comunicação com cliente nem campanha. O design o trata assim, mas **P5 continua aberta** e trava só a promoção para QAS (card de 14/11).
- Se a Eplast responder P5 como **operacional**: fica a ação padrão Send Email do Flow, só para `FaultRecipient__c`, com o Id da conta e a mensagem de erro, sem dado de cliente.
- Se responder **marketing**: o build remove a ação de e-mail e fica só o `IntegrationLog__c`. O disparo vira **passo de quem opera o Marketing Cloud** (fora da esteira, que só conecta as sandboxes do CRM): ler os registros de log de `IntegrationAction__c = ScheduledFlowOpportunity` e montar o envio lá. O CRM entrega só o dado.
- Destinatário vazio (P11 ainda sem endereço): o fluxo não envia e só registra o log (critério 16).
- Nenhum outro passo de Marketing Cloud nesta demanda.

---

## 7. Perguntas de regra de negócio

**Bloqueantes para o build: nenhuma.** P2, P3, P4 e P7 foram respondidas no card. As que seguem abertas não impedem construir, porque o desenho deixa o ponto parametrizado ou isolado:

| # | Pergunta | Como o design segue sem a resposta | Bloqueia |
|---|---|---|---|
| P1 | Premissa anual, só ganhas (Tatiana) | Mantém a regra atual (`StageName = Fechado/Ganho`, `ThisYear__c`) | Promoção a QAS |
| P5 | Alerta operacional ou de marketing | Seção 6: e-mail condicionado, log sempre | Promoção a QAS |
| **P6** | Conta sem compra: zero ou vazio? E **conta com média vazia: qual classificação?** | Valor: mantém o comportamento atual (variável sem valor padrão; o QA registra se grava vazio ou zero). Classificação com média vazia: **não altera `Ranking__c`** (hoje vira GG pelo erro da seção 1.2; o critério 11 proíbe GG). Média zero cai em MP ("até 10.000"). **Pedir confirmação da Eplast antes da homologação.** | Homologação |
| P8 | Protheus aceita MP e 3G? `Ranking__c` é restrita, e o permission set `Protheus` tem edição: se o ERP gravar valor fora da lista, o update dele falha | Nada no CRM depende disso | Promoção a QAS |
| P9 | Diário com dia 14 ou mensal | Respondida pela plataforma (seção 1.1). Informar a Eplast. | — |
| P10 | Números do teste de volume | Seção 8 usa 50 contas (critério 6) como mínimo | Critério 18 |
| P11 | Endereço do destinatário | Registro `Default` sai com destinatário vazio | Promoção a QAS |
| P12 | Pasta do relatório ou relatório existente | Builder cria em pasta provisória e registra a pendência no plano de build | Critério 14 em QAS |

Nova, sem bloquear: a soma filtra `StageName = Fechado/Ganho`, e a população filtra `IsWon = true`. Se a org tiver outra fase ganha, as duas divergem. Mantido como está (regra atual). Vale uma linha ao cliente junto com P1.

---

## 8. Estratégia de teste para o QA

Org: **`sbx-eplast-qa`**. Antes de qualquer caso, o QA confirma com `sf org display` que o Org ID é o da QA e diferente do da dev (`00DHa000006vfMLMAY`). Assessment, achado 6: o alias de dev aponta para uma sandbox cuja instância e cujo usuário de conexão se identificam como "qa". Evidência na dev não vale para o aceite.

**Como rodar o fluxo em qualquer dia:** no registro `Default` de `ScheduledFlowOpportunitySetting__mdt` da QA, `RunDayOfMonth__c` = dia do teste. O job diário das 15:47 UTC processa. Depois do teste, o QA volta o valor para 14 e registra isso. Casos de uma conta só podem usar o Debug do Flow Builder sobre um registro escolhido.

**Dado de teste: sintético, criado e apagado pelo QA.** A dev não tem registro. Fixture preenche todo campo exigido pelas validation rules de Account e de Opportunity (10 de Opportunity listadas no recon, entre elas `CheckAccountOwnerHasProtheusSellerId`, `CheckOppHasBranch`, `CheckOppHasPaymentTermId`), não só os desta demanda (achado SOMOSAGILITY-10 da doutrina). Para os casos de faixa, o QA pode gravar `AveragePurchasesThisYear__c` direto na conta depois de criar a oportunidade, porque o campo é editável e o `OpportunityFlow` o recalcula a cada save de oportunidade.

| # | Cenário | Critério |
|---|---|---|
| 1 | Conta A com 3 ganhas, conta B com 1: cada conta recebe 1 update (debug log com trace flag no usuário do processo automatizado; contar o update por conta) | 4 |
| 2 | XML final: nenhum Get Records de Opportunity sem filtro de `AccountId`; `GetOpportunities2` ausente | 5 |
| 3 | Lote de 50 contas, várias com conta pai em comum: 0 `UNABLE_TO_LOCK_ROW`, 0 logs de falha não explicados; anotar CPU e SOQL do lote (escala se > 70%) | 6 |
| 4 | Ganhas de 3.000 e 2.000 + perdida de 9.000 → valor 5.000 | 8 |
| 5 | Conta só com ganha de ano anterior → valor gravado conforme comportamento atual; registrar vazio ou zero (P6) | 9 |
| 6–17 | Média = 10.000 / 10.000,01 / 35.000 / 35.000,01 / 80.000 / 80.000,01 / 160.000 / 160.000,01 / 500.000 / 500.000,01 / 1.000.000 / 1.000.000,01 → MP / PP / PP / P / P / M / M / G / G / GG / GG / 3G | 10 |
| 18 | Média 0 → MP; média vazia → `Ranking__c` não muda (nunca GG) | 11 |
| 19 | Mudar `UpperLimit__c` de uma faixa no custom metadata, sem nova versão do fluxo → classificação acompanha; XML sem limites antigos (70.000, 150.000) | 12 |
| 20 | Picklist `Ranking__c` ativa = MP, PP, P, M, G, GG, 3G | 13 |
| 21 | Relatório de mudanças mostra N contas com valor anterior e novo, após uma execução que muda N | 14 |
| 22 | Falha forçada em 1 conta (ex.: dado que viola a validation rule `Telefone`, montado na fixture sintética): as outras contas do lote gravam; `IntegrationLog__c` criado; com destinatário vazio não envia | 16 |
| 23 | Com destinatário de teste preenchido: envio registrado. Conferir a entregabilidade de e-mail da QA, já que sandbox costuma vir com "só e-mail do sistema" | 16 |
| 24 | Execução sem mudança de valores → nenhum update (`LastModifiedDate` da conta inalterado) | regressão |
| 25 | Regressão de Account: atualizar conta pelo fluxo não altera dado de CNPJ nem quebra `AccountTriggered`/`UpdateParentAccountUsedLimit` | assessment |

Fragilidades do assessment que o QA cobre: a dúvida dev × qa (pré-checagem do Org ID); a automação concorrente em Account (casos 3, 22, 25); a cadeia Protheus (ver R5; o assessment pede priorizar teste dessa cadeia). A cobertura Apex de 10% não se aplica, porque não há Apex nesta demanda.

---

## 9. Riscos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Ordem de execução não garantida entre `AccountBefore` (SBQQ) e `AccountTrigger`, mais 2 flows after-save sem critério de entrada em Account, no mesmo update que o fluxo faz** | **Alta** | A mudança não depende da ordem e reduz o número de updates (seção 4). Triggers do SBQQ não lidos: incerteza declarada. Casos 3, 22 e 25. |
| R2 | Troca em massa de classificação na primeira execução (erro `EqualTo` atual + faixas novas), visível no comercial e no Protheus | Alta (negócio) | Seção 1.2: avisar a Eplast antes da homologação. O relatório (D2) mostra quem mudou. |
| R3 | `Ranking__c` é picklist restrita: se o fluxo for para a org antes dos valores MP/3G, ou se o Protheus enviar valor fora da lista, o update falha | Média | Ordem de deploy: picklist → custom metadata e registros → fluxo. P8 antes de QAS. |
| R4 | Volume de produção desconhecido (P10); limite diário de interviews e CPU da cadeia de Account | Média | A versão 2 é estritamente mais leve que a 1. Medição no caso 3; escala acima de 70%. |
| R5 | **Dado sintético em QA dispara o `OpportunityFlow`** (cria Order e Quote, chama CPQ, envia aprovação): validation rules de Order, `OrderTrigger` duplicado e possível envio ao Protheus a partir da QA | **Alta (teste)** | Antes de criar dado, o QA confirma para onde aponta a integração Protheus na QA (credencial ou endpoint, só metadata). Se apontar para ERP real, para e devolve ao humano. Limpar Order e Quote sintéticos ao fim. |
| R6 | Histórico de campo só registra a partir da ativação; não há passado | Baixa | Ativar no deploy, antes da primeira execução no dia 14. |
| R7 | Ordenação de Get Records por `Id` não oferecida no Flow Builder da versão da org | Baixa | Se não houver, usar `CreatedDate` + `Id` como desempate, ou parar e devolver ao design. Não usar ordenação não determinística. |
| R8 | `IntegrationLog__c` é usado para algo que não é integração HTTP; pode haver limpeza automática (`Logs_Delete_Records`, não lido) | Baixa | Identificação por `IntegrationAction__c`. O builder confere se `Logs_Delete_Records` apaga esse objeto e em quanto tempo, e registra no plano. |
| R9 | Validation rules de telefone em contas legadas fazem o update falhar (hoje falha silenciosa) | Média | Passa a gerar log. Não se corrige dado nesta demanda. |

**Rollback:** reativar a versão 1 do `ScheduledFlowOpportunity`. Os valores MP e 3G da picklist podem ficar (inativos não quebram nada), mas as contas já classificadas como MP ou 3G mantêm o valor até a próxima execução da versão 1, que hoje não grava MP nem 3G. Desativar histórico de campo apaga o rastro: não fazer no rollback.

---

## 10. O que NÃO será feito nesta demanda

- Período configurável (critério 7), sujeito a D3. Troca de `ThisYear__c` para `CloseDate` (P2) e classificação pela soma (P3).
- Renomear `LastMonthPurchaseValue__c` ou mudar o rótulo (P4).
- Procurar ou alterar o alerta do ex-parceiro (resolvido, card de 14/11).
- Alterar `OpportunityFlow`, `AccountTriggered`, `UpdateParentAccountUsedLimit`, triggers custom ou do SBQQ, `OrderTrigger`, validation rules ou dado de conta legado.
- Qualquer envio de marketing; qualquer passo dentro do Marketing Cloud.
- Mapeamento de MP/3G na integração Protheus (P8) e qualquer mudança no ERP.
- Promoção para QAS ou produção (EPLAST-48).
- Alterar o agente `SFAgent2`.

## 11. Incertezas que ficam

- Triggers do SBQQ (`AccountBefore`) e helper do `AccountTrigger` não lidos. A ausência de leitura dos 4 campos foi confirmada só nas 5 classes e nos 9 flows do recon.
- Relatórios, painéis, layouts e páginas que usam os 4 campos: o retrieve do recon não retornou (critério 1 da análise segue parcial).
- Agendamento ativo do job na dev (`CronTrigger` sem linha no recon). O builder confere após ativar.
- Divergência de metadata dev × QA: não comparada. O builder retrieve o fluxo da QA antes do deploy e compara com a versão 1 da dev.
- Fórmulas das 6 validation rules de Account e as 2 workflow field updates: não lidas.

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o build.
