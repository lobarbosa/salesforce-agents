# EPLAST-47 — Design (rodada 2): classificação de contas só declarativa, sem gravar em massa em Account

**Cliente:** Eplast · **Etapa:** 3 (design, `arquiteto`) · **Data:** 2026-11-16
**Org de referência:** `sbx-eplast-dev` (sandbox, Org ID `00DHa000006vfMLMAY`), a única conectada em `sf org list`. Só leitura: consultas de metadata, retrieve para pasta temporária, describe de relatório. Nenhum deploy, DML ou anonymous Apex. Nada no Marketing Cloud.
**Entradas:** `01-analise.md` (aprovada em `gates.md`, 14/11), `02-recon.md` (16/11, redesenho), `comentarios-do-card.md` (decisão de 16/11), `05-testes-rodada-3.md` (falha que motivou o redesenho), `00-preflight.md` (sem bloqueios, nenhuma outra demanda nos mesmos componentes), `assessment.md` (trechos por Grep), RAG (EPLAST-27, EPLAST-34).
**Status:** pronto para o **gate bloqueante do arquiteto humano**. Há 3 decisões de arquitetura que este design não toma sozinho (seção 0). Nenhuma pergunta de negócio bloqueia (caso 3 da regra 4: nenhum).

**Estimativa de esforço:** 36–52 h

O que mudou em relação à análise (30–50 h) e ao design anterior (26–40 h): a faixa é o total da demanda. Inclui as horas já gastas no build da rodada 1 (custom metadata, picklist, Flow v2, relatório, 3 rodadas de QA) e soma o retrabalho desta rodada, estimado em 12–16 h: objeto novo com 8 campos e histórico, tipo de relatório, 2 relatórios, permission set, uma alteração de página, Flow v3 trocando o destino da gravação e mais uma rodada de QA sobre a população da QAS. Ficam de fora, e não pesam: Apex, a cadeia Protheus e o Marketing Cloud.

---

## 0. Decisões que precisam do aceite do arquiteto humano

| # | Decisão | Proposta deste design | Se recusada |
|---|---|---|---|
| **D1** | **Mudança de modelo de dados: objeto custom novo `AccountRanking__c` ("Classificação da Conta"), mestre-detalhe com `Account`.** É decisão de arquitetura sênior: **escalo ao humano, não decido sozinho.** A decisão de 16/11 lista essa alternativa, mas não a escolhe. | Um registro vigente por conta, gravado pelo Flow agendado, com histórico de campo. Seções 1 e 2. | Alternativa 1 (fórmula), com as perdas da seção 1.2: muda a cadência de mensal para contínua, perde o histórico (critério 14) e exige recriar `Ranking__c`. Volta ao cliente, porque muda a regra. |
| **D2** | **`Account.Ranking__c` e `Account.LastMonthPurchaseValue__c` deixam de ser atualizados.** Ficam com o último valor gravado, e a classificação mensal vigente passa a ficar em `AccountRanking__c`. É consequência direta da restrição "não gravar em massa em Account". | Congelar. Os dois campos não são apagados nem tirados de página, relatório ou permission set nesta demanda. A descrição e o texto de ajuda passam a dizer que o valor está congelado e onde fica o vigente. A depreciação fica para depois que os consumidores migrarem (seção 7). | Qualquer forma de manter os dois campos atualizados grava em Account, e isso a restrição de 16/11 proíbe. Só a alternativa da fórmula evita (ver D1). |
| **D3** | **Alterar a página `Account_Record_Page`** (FlexiPage na linha de base do repo; hoje mostra `Ranking__c` e `LastMonthPurchaseValue__c` como campo) para incluir a lista relacionada de `AccountRanking__c`. | Acrescentar um componente `force:relatedListSingleContainer` de "Classificação da Conta" ao lado da seção onde está `Ranking__c`. Não remover campo da página. | Sem a lista na página, o usuário só vê a classificação vigente pelos relatórios, e na página continua vendo o valor congelado. |

Já aceitas e mantidas da rodada anterior (card, 14/11): `RankingRange__mdt` e `ScheduledFlowOpportunitySetting__mdt` (D1 antiga), histórico em `Account.Ranking__c` (D2 antiga; continua ligado, sem uso novo), período fixo em `Opportunity.ThisYear__c` (D3 antiga, critério 7 fora).

---

## 1. Solução escolhida

**Nível: configuração + declarativo.** Um objeto custom novo com histórico de campo, campo fórmula e relatórios (configuração). Uma versão nova do Flow `ScheduledFlowOpportunity` (declarativo) passa a gravar nesse objeto, não em `Account`. **Sem Apex novo, sem alterar Apex existente.**

### 1.1 Por que este desenho resolve a falha da rodada 3

A QA reprovou porque o Flow gravava em `Account`. Cada update dispara o `AccountTrigger` (after update), e o `AccountTriggerHelper.updateAccountInfoFromCNPJ` enfileira um `SendAccountToProtheus` por conta, sem filtro de campo (`02-recon.md` §3, mesmo achado em EPLAST-27 e EPLAST-34, pelo RAG). Com 555 contas, isso deu "Too many queueable jobs added to the queue: 51" e 162 erros.

Inserir ou atualizar um registro filho em mestre-detalhe **não salva o registro pai**. O pai só passa pelo ciclo de save quando há roll-up summary ou workflow entre objetos (ordem de execução, skill `salesforce-doutrina`). O objeto novo não terá roll-up, e a org tem 0 workflow rule custom: as 17 existentes são do `et4ae5` (assessment). Assim, a execução mensal **não toca `Account`**. Também não acionam o `AccountTrigger`, o `AccountBefore` (SBQQ), os Flows `AccountTriggered` e `UpdateParentAccountUsedLimit` nem as 6 validation rules de Account. Fica 0 enfileiramento para o Protheus.

### 1.2 Alternativas descartadas, com o porquê

| Alternativa | Por que não |
|---|---|
| **1. `Ranking__c` como fórmula** (seria configuração, o nível acima) | (a) `Ranking__c` é picklist restrita com histórico. A plataforma não converte picklist em fórmula no lugar: seria apagar e recriar o campo, perdendo o histórico e quebrando as referências do permission set `Protheus` e do relatório `CLASSIFICACAO_CONTAS_POR_CLASSE`. (b) A fórmula reclassifica a cada mudança da média, que o `OpportunityFlow` grava a cada save de oportunidade. Hoje a classificação é mensal, no dia 14, e o card de 14/11 manda não mudar a regra. (c) Campo fórmula não tem histórico, então o critério 14 cai. (d) O valor de compras (soma das ganhas do ano) não sai em fórmula. Roll-up de Opportunity em Account não aceita filtro por `ThisYear__c`, que usa `NOW()`. A soma continuaria precisando de quem grave. |
| **2b. Um registro por conta por mês (snapshot)** | Funciona, mas o "vigente" depende de filtro por data relativa: antes do dia 14, "este mês" fica vazio. Isso complica o segmento do Marketing Cloud e a lista na página. Um registro vigente por conta, com histórico de campo, dá o mesmo rastro com consulta mais simples (premissa PA9). |
| **Ranking ao vivo dentro do `OpportunityFlow`** (no update de Account que ele já faz) | Exige uma versão nova de um Flow de CPQ com mais de 2.000 linhas. Muda a cadência para contínua. E as contas sem oportunidade salva não seriam reclassificadas pelas faixas novas, o que pediria uma carga em massa em Account. |
| **Gravar em Account em blocos menores que 50, ou usar o bypass `TriggerUtility__mdt.BypassTrigger__c`** | Proibido pela decisão de 16/11. O tamanho de lote de Flow agendado não é configurável (200). O bypass é chave global e desligaria os triggers de Account e Opportunity da org inteira durante o job. |
| **Apex (Batch, ou filtrar campo no `AccountTriggerHelper`)** | Proibido pela decisão de 16/11 ("sem Apex novo", "não mexer na AccountTrigger"). Pela doutrina, também não é necessário: sem callout, sem recursão, sem rollback complexo. |

### 1.3 Fluxo: nova versão do `ScheduledFlowOpportunity`

A dev está com a v2 Active (v1 Obsolete). O build cria a **v3 na dev, implantada como Draft**. A QA está com a v5 Active, e o deploy da esteira lá cria a próxima versão. Ativar é passo separado, depois da verificação (seção 8). A v2 continua ativa até lá.

```
[Agendado: Daily, 15:47 UTC — mantido]  start: Opportunity, IsWon = true  (mantido)
 └─ GetSetting / CheckDayMonth / CheckAccount                      [mantidos da v2]
 └─ GetRepresentativeOpportunity / IsRepresentative                [mantidos: 1 interview segue por conta]
 └─ GetOpportunities / LoopOpportunities / AssignSumValue          [mantidos: soma das ganhas, ThisYear__c]
 └─ ClassifyRanking / GetRanges / LoopRanges / RangeMatches / AssignRanking   [mantidos: faixas do RankingRange__mdt, pela média]
 └─ GetCurrentRanking  Get Records AccountRanking__c, Account__c = $Record.AccountId, só o primeiro   [novo]
 └─ KeepCurrentRanking (média vazia): NewRanking = GetCurrentRanking.Ranking__c,
                       ou $Record.Account.Ranking__c se ainda não há registro   [alterado: nunca GG]
 └─ HasCurrentRanking ?                                                         [novo, substitui HasChanges]
      sim → UpdateRanking  (Update Records no registro encontrado):
              PreviousRanking__c = GetCurrentRanking.Ranking__c
              Ranking__c = NewRanking, PurchaseValue__c = SumAmount (0 se vazio),
              AveragePurchases__c = $Record.Account.AveragePurchasesThisYear__c,
              ReferenceDate__c = hoje                                        fault → LogFault
      não → CreateRanking  (Create Records):
              Account__c = $Record.AccountId, AccountKey__c = $Record.AccountId,
              PreviousRanking__c = $Record.Account.Ranking__c (valor legado),
              demais campos como acima                                        fault → LogFault
 └─ LogFault / HasRecipient / SendFaultEmail                       [mantidos da v2; ResponseBody__c = Id da conta + $Flow.FaultMessage]
 └─ [removidos] UpdateAccount, HasChanges
```

Pontos de desenho:
- **Sempre grava o registro filho**, mesmo sem mudança. É o que zera `RankingChanged__c` (fórmula: anterior ≠ atual) no mês seguinte e marca `ReferenceDate__c`. O objeto não tem automação, então gravar sempre não custa nada além do DML do lote.
- **`AccountKey__c` único (External ID)** garante 1 registro por conta. Uma criação em duplicidade falha, cai no `LogFault` e não gera um segundo registro. Também serve a um upsert futuro por integração.
- **Faixas e comparação**: sem mudança desde a rodada 1. A faixa é acima do limite anterior e até o limite inclusive, ordenada por `SortOrder__c`, e `X3G` não tem teto. O XML não carrega nenhum limite fixo (critério 12).
- **O Flow só lê `Account`** (`AveragePurchasesThisYear__c` e `Ranking__c`, pelo `$Record.Account`), não grava.

---

## 2. Reaproveita × cria × altera (regra 3 da conta)

Todos os itens marcados como existentes foram conferidos em `sbx-eplast-dev` no recon ou nesta sessão.

| # | Item | Situação na org | Decisão |
|---|---|---|---|
| 1 | Flow `ScheduledFlowOpportunity` | v2 Active, v1 Obsolete na dev. O repo difere da v2 só em ordem de elementos e `versionSegment` (diff nesta sessão) | **Altera por versão nova**: v3 Draft na dev, ativação em passo separado. Mantém API name, agendamento e horário. |
| 2 | Elementos da v2: `GetSetting`, `CheckDayMonth`, `CheckAccount`, `GetRepresentativeOpportunity`, `IsRepresentative`, `GetOpportunities`, `LoopOpportunities`, `AssignSumValue`, `ClassifyRanking`, `GetRanges`, `LoopRanges`, `RangeMatches`, `AssignRanking`, `LogFault`, `HasRecipient`, `SendFaultEmail` | Existem na v2 (lista de elementos conferida nesta sessão) | **Reaproveita** sem mudar a lógica. |
| 3 | `KeepCurrentRanking` | Existe na v2 | **Altera**: lê a classificação do registro filho, e não a da conta (seção 1.3). |
| 4 | `UpdateAccount`, `HasChanges` | Existem na v2 | **Remove** da v3. |
| 5 | `GetCurrentRanking`, `HasCurrentRanking`, `UpdateRanking`, `CreateRanking` | Não existem | **Cria** na v3. |
| 6 | `RankingRange__mdt` (7 registros) | Existe | **Reaproveita** sem mudança. |
| 7 | `ScheduledFlowOpportunitySetting__mdt` (`Default`: dia 14, `FaultRecipient__c`) | Existe | **Reaproveita** sem mudança. |
| 8 | `AccountRanking__c` e campos (seção 2.1) | Não existe. Nenhum objeto com "Ranking" ou "Classifica" no nome, além do `RankingRange` (consulta nesta sessão) | **Cria** (sujeito a D1). |
| 9 | Tipo de relatório `AccountWithRanking` (Contas com Classificação da Conta) | Não existe | **Cria**, com Account como objeto principal e `AccountRanking__c` (B) obrigatório. Traz os campos de Account que o relatório do Marketing Cloud usa. |
| 10 | Relatório `AccountRankingChanges` (pasta `EPLAST47`, provisória) | Existe. Tipo `AccountAuditHistory`, **sem filtro** (describe nesta sessão): mostra qualquer histórico de conta, não só o de Ranking | **Altera**: passa para o tipo `AccountWithRanking`, com filtro `RankingChanged__c = true` e colunas conta, classificação anterior, classificação atual, data de referência e valor de compras. Mantém o API name. Se o deploy recusar a troca de tipo de relatório, o builder remove e recria com o mesmo nome, e registra isso no plano. |
| 11 | Relatório `AccountRankingByClass` ("Classificação Mensal - Contas por Classe") | Não existe | **Cria** na pasta `EPLAST47`, agrupado por `AccountRanking__c.Ranking__c`. É a fonte para o Marketing Cloud (seção 6). Não se altera o `CLASSIFICACAO_CONTAS_POR_CLASSE`, que o Marketing Cloud consome hoje (seção 6). |
| 12 | Permission set `PS_Comercial_ClassificacaoConta` | Não existe. Há outros `PS_Comercial_*` na dev | **Cria**: leitura em `AccountRanking__c` e nos campos, sem edição (só o Flow grava). |
| 13 | `Account_Record_Page` (FlexiPage) | Existe no repo, mostra `Record.Ranking__c` e `Record.LastMonthPurchaseValue__c`, tem 7 `relatedListSingleContainer` | **Altera** (sujeito a D3): acrescenta 1 lista relacionada. Parte da versão do repo, com diff restrito ao componente novo. |
| 14 | `Account.Ranking__c` | Picklist restrita, 7 valores, histórico ligado | **Altera só descrição e texto de ajuda** (D2): "Valor congelado desde EPLAST-47. Classificação mensal vigente em Classificação da Conta". Valores e histórico ficam como estão. |
| 15 | `Account.LastMonthPurchaseValue__c` | Currency, tem descrição | **Altera só descrição e texto de ajuda** (D2), na mesma linha. |
| 16 | `Account.AveragePurchasesThisYear__c` | Gravado pelo `OpportunityFlow` (`TotalPurchasesThisYear__c / Count`, XML conferido nesta sessão) | **Reaproveita só como leitura.** |
| 17 | `IntegrationLog__c` | Existe, já usado pelo `LogFault` da v2 | **Reaproveita.** |
| 18 | Layouts `Account Layout` e `CPQ Account Layout` | Existem | **Não altera.** A página Lightning (item 13) basta. Mexer no layout acrescentaria risco de sobrescrever dev e QA sem ganho. |
| 19 | `AccountTrigger`, `AccountTriggerHelper`, `TriggerUtility__mdt`, `OpportunityFlow`, triggers SBQQ | Existem | **Não altera** (decisão de 16/11). |
| 20 | Agente `SFAgent2` | Existe (v13 é a mais recente na dev) | **Não se aplica.** A demanda não é de assistente. Não é alterado. |

### 2.1 `AccountRanking__c`: definição

- Label "Classificação da Conta" / "Classificações da Conta". `Name`: numeração automática `CLA-{000000}`. Compartilhamento `ControlledByParent`. `allowReports` = true, `enableHistory` = true, sem atividades e sem busca. Descrição do objeto: "Classificação mensal vigente da conta, gravada pelo Flow ScheduledFlowOpportunity (EPLAST-47). Não criar roll-up para Account: reabriria o update em massa de Account."
- Campos, todos com descrição (achado 4 do assessment):

| API name | Tipo | Histórico | Conteúdo |
|---|---|---|---|
| `Account__c` | Mestre-detalhe(Account), `AccountRankings`, sem reparenting | — | conta |
| `AccountKey__c` | Texto(18), único, External ID | — | Id da conta. Garante 1 registro por conta |
| `Ranking__c` | Picklist restrita: MP, PP, P, M, G, GG, 3G | sim | classificação vigente |
| `PreviousRanking__c` | Picklist restrita, mesmos valores | — | classificação antes da última execução. Na primeira, o valor legado de `Account.Ranking__c` |
| `RankingChanged__c` | Fórmula (caixa de seleção): `TEXT(Ranking__c) <> TEXT(PreviousRanking__c)` | — | mudou na última execução |
| `PurchaseValue__c` | Moeda(16,2) | sim | soma das ganhas do ano (`ThisYear__c`), a mesma regra que ia para `LastMonthPurchaseValue__c` |
| `AveragePurchases__c` | Moeda(16,2) | — | média usada na classificação (cópia de `Account.AveragePurchasesThisYear__c` na execução) |
| `ReferenceDate__c` | Data | — | data da última execução |

Os valores da picklist repetem os de `Account.Ranking__c`, que é lista local, não conjunto global. Se uma faixa nova entrar no `RankingRange__mdt`, as duas listas precisam do valor novo, e isso vai na descrição dos dois campos.

---

## 3. Objetos, automações e ordem de execução

| Objeto | O que a solução faz | Automação que dispara |
|---|---|---|
| `Opportunity` | Só leitura (start do Flow e `GetOpportunities`) | Nenhuma |
| `Account` | **Só leitura** na execução. Deploy de metadata: descrição e texto de ajuda de 2 campos | Nenhuma em runtime |
| `AccountRanking__c` | Criação e atualização em lote pelo Flow | Nenhuma: objeto novo, sem trigger, Flow, validation rule ou roll-up |
| `IntegrationLog__c` | Criação só em falha | Sem trigger (recon da rodada 1) |
| `Order` | Não lê, não grava | Nenhuma |

**Ordem de execução no save de `AccountRanking__c`:** validação de sistema (unicidade de `AccountKey__c`, valor de picklist restrita), gravação, histórico de campo, commit. Sem before ou after de nenhum tipo. No pai, o mestre-detalhe só trava a linha de `Account` durante o DML. Não há save do pai.

**Os 3 pontos que o recon deixou abertos:**

1. **`AccountTriggerHelper` enfileira `SendAccountToProtheus` em todo update sem mudança de CNPJ.** O desenho **não agrava, elimina a exposição desta demanda**: a execução mensal faz 0 update em Account, contra 1 por conta na v2. A causa de fundo, o filtro por campo no helper, continua. Ela afeta qualquer gravação em massa em Account, e é a mesma achada em EPLAST-27 e EPLAST-34. Fica recomendada como demanda própria de Apex (seção 9), fora deste escopo pela decisão de 16/11. Confirmado nesta sessão: o payload do Protheus (`AccountAdapter.toProtheus`, chamado por `ProtheusAPI.sendClientToProtheus`) **não referencia** `Ranking__c` nem os campos de compra. Então congelar os campos em Account não muda o que o ERP recebe.
2. **Bypass global em `TriggerUtility__mdt`.** Não é usado, nem na solução nem no teste. Desligaria os triggers de Account e Opportunity da org inteira.
3. **`OpportunityFlow` v2 com `AccountTrigger` nos campos de compra.** O `OpportunityFlow` continua gravando `AveragePurchasesThisYear__c` e `TotalPurchasesThisYear__c` em Account a cada save de oportunidade, como hoje: um registro por vez, iniciado pelo usuário. A solução só **lê** a média e deixa de ser um segundo escritor de Account. Isso remove a concorrência de escrita. Resta uma corrida de leitura: uma oportunidade salva durante o job muda a média entre a leitura e o fim do lote, e a conta é classificada com o valor do momento da leitura. Severidade baixa. A execução seguinte corrige.
4. **SBQQ em Account, Opportunity e Order.** Não são acionados: não há gravação nesses objetos. O `OrderTrigger` duplicado (custom e SBQQ) e as 23 validation rules de Order não são tocados. **Exceção, só no teste:** criar oportunidade ganha sintética dispara o `OpportunityFlow`, que cria cotação e pedido via CPQ e pode chegar ao Protheus. Está autorizado em 15/11, nas condições do card (seção 8).

---

## 4. Limites de governador e escala

Lote de Flow agendado: 200 interviews por transação. Volume conhecido só na QAS: 555 contas elegíveis e 1.217 contas (rodada 3 e card). A dev não tem dado. Produção não se consulta.

| Recurso por lote de 200 | v2 (reprovada) | v3 |
|---|---|---|
| Update em Account | até 200, cada um com toda a cadeia de Account | **0** |
| `enqueueJob` (limite 50) | 1 por conta atualizada: estoura com 51 | **0** |
| DML | 1 update de Account em lote | 1 create e 1 update de `AccountRanking__c` em lote, sem automação |
| SOQL | Flow agrupa os Get Records das interviews no mesmo elemento | +1 consulta agrupada (`GetCurrentRanking`). Custom metadata não conta |
| Linhas (50.000) | `GetOpportunities` lê as ganhas do ano de cada conta representante | Igual. **Risco**: um lote com várias contas de muitas oportunidades soma as linhas (R3) |
| CPU (pai com muitos filhos, achado SOMOSAGILITY-10) | loop de soma por conta + cadeia de Account | Só o loop de soma e de 7 faixas. A cadeia de Account sai, que era o custo dominante |

O fluxo de N oportunidades da mesma conta não é N²: as N interviews leem 1 linha cada no `GetRepresentativeOpportunity`, e só uma faz a soma.

Critério de escalonamento (doutrina): CPU, SOQL ou linhas acima de 70% do limite no lote medido na QA devolve o design para revisão. A saída então seria trocar a soma pelo `TotalPurchasesThisYear__c` que o `OpportunityFlow` já mantém, o que pede confirmação de regra, ou Apex Batch, que pede nova decisão do responsável.

---

## 5. Permissões

- **`PS_Comercial_ClassificacaoConta`** (novo): leitura no objeto e em todos os campos. Sem criar, editar ou apagar. Quem recebe é premissa PA10.
- O Flow agendado roda em contexto de sistema (Automated Process) e não precisa de permissão.
- Compartilhamento: `ControlledByParent`. Quem vê a conta vê a classificação, desde que tenha o permission set.
- **Sem mudança** em perfis, no permission set `Protheus` (o ERP não lê o objeto novo, PA4), em `AncCrmIntegrationUser` ou em `sfdc_a360_sfcrm_data_extract`.
- Relatórios: herdam o acesso da pasta `EPLAST47` (PA8).

---

## 6. Preparação do Sales Cloud para o Marketing Cloud (regra 2 da conta)

A classificação é dado de segmentação: o relatório `CLASSIFICACAO_CONTAS_POR_CLASSE`, da pasta "MARKETING CLOUD", tem `Account.Ranking__c` como coluna (describe nesta sessão). A esteira **não faz nada no Marketing Cloud**.

- **Dados que o Marketing Cloud vai precisar ler e onde ficam:** `AccountRanking__c.Ranking__c` (classificação vigente), `PreviousRanking__c`, `RankingChanged__c`, `PurchaseValue__c` e `ReferenceDate__c`, ligados à conta por `Account__c`, com chave estável em `AccountKey__c` (Id da conta).
- **Como o segmento fica identificável no CRM:** relatório `AccountRankingByClass` (contas por classificação vigente) e `AccountRankingChanges` (contas que mudaram na última execução), os dois no tipo `AccountWithRanking`. Também por filtro direto no objeto.
- **O que muda para o Marketing Cloud:** a coluna `Account.Ranking__c` do relatório atual fica congelada (D2). **O relatório `CLASSIFICACAO_CONTAS_POR_CLASSE` não é alterado** por esta demanda: trocar o tipo dele mudaria o que o Marketing Cloud importa sem quem o opera decidir.
- **O que o Marketing Cloud devolve e onde é gravado:** nada nesta demanda. Nenhum campo de retorno é criado.
- **Consentimento e opt-out:** não muda. A classificação é atributo da conta, não canal de contato. Continuam valendo os campos e o tratamento que o Marketing Cloud Connect (`et4ae5`) já usa, sem alteração.
- **Fica para quem opera o Marketing Cloud:** decidir se o segmento por classificação passa a ler `AccountRankingByClass`, ou o objeto `AccountRanking__c` como fonte sincronizada, em vez da coluna congelada. Depois disso, avisar para que `Account.Ranking__c` possa sair do relatório antigo em demanda futura.
- O aviso de falha do Flow é operacional, não marketing (PA2). Não passa pelo Marketing Cloud.

---

## 7. Riscos do assessment que tocam o escopo

| Achado do assessment | Como este design lida |
|---|---|
| **1. Automação concorrente em Account/Opportunity/Order (alta)** | **Evitada por construção.** A solução não grava em nenhum dos três. A ordem de execução entre `AccountTrigger`, `AccountBefore` (SBQQ) e os Flows after-save deixa de importar para esta demanda. Fica o mesmo aviso de EPLAST-27 (RAG): se o gate pedir para voltar a gravar em Account, o design perde a validade. |
| **2. Cobertura Apex de ~10%, cadeia Protheus sem teste (alta)** | Não se aplica: nenhuma classe criada ou alterada. A solução tira esta demanda da cadeia Protheus (0 enfileiramento). A recomendação do assessment, priorizar teste da cadeia, vira a demanda sugerida na seção 9. |
| **3. Validation rules de Order (23)** | Não se aplica: não grava em Order. Só o dado sintético do teste passa por elas, via `OpportunityFlow`. |
| **4. Campos sem descrição (153 de 223)** | Todo campo novo nasce com descrição. Os 2 de Account tocados ganham descrição atualizada. |
| **6. Dúvida dev × qa** | Resolvida pela regra 5 da conta. O QA confere o Org ID da QA como sempre. |

Consumidores de `Account.Ranking__c` e `LastMonthPurchaseValue__c` afetados pelo congelamento (D2), conforme o que foi confirmado:
- a página `Account_Record_Page`, mitigada por D3;
- o relatório `CLASSIFICACAO_CONTAS_POR_CLASSE`, mitigado pela seção 6;
- o permission set `Protheus`, que tem leitura e edição, mas cujo payload de saída não leva os campos (PA4).

Não foram varridos: outros relatórios, layouts de outros perfis e classes Apex fora das lidas. Fica como incerteza (seção 10).

---

## 8. Plano de teste (para verificador e QA)

**Ativação:** na dev, o verificador ativa a v3 depois do teste por Debug sobre dado sintético, e registra no `04-verificacao.md` que entra a v3 e sai a v2. Na QA, a esteira implanta e o QA ativa a versão nova, registrando a que entra e a que sai em `05-testes.md`. **Desfazer:** reativar a versão anterior. O objeto pode ficar, porque não tem efeito colateral.

**Estado herdado na QA:** o card de 15/11 deixou `RunDayOfMonth__c` = 15 e o início às 17:10 do fuso da org. A esteira reimplanta o build, e o QA confere e devolve o dia 14 e as 15:47 UTC ao final.

**Linha de base, antes da execução (só contagens agregadas):**
- `Account` com `LastModifiedDate` na janela;
- `AsyncApexJob` de `SendAccountToProtheus` na janela;
- `IntegrationLog__c` por `IntegrationAction__c`;
- `AccountRanking__c` = 0;
- distribuição de `Account.Ranking__c` por valor.

| # | Cenário | Critério | Onde o assessment indica fragilidade |
|---|---|---|---|
| 1 | **Execução sobre a população da QAS** (autorizada pelo card de 15/11, regra 5): `AccountRanking__c` criados = contas distintas com ganha (`COUNT_DISTINCT(AccountId)` de `Opportunity` com `IsWon = true`) | 4, 18 | — |
| 2 | **0 update em Account pela execução:** `Account` alterada pelo usuário do processo automatizado na janela = 0; `AsyncApexJob` `SendAccountToProtheus` novo atribuível à execução = 0; `IntegrationLog__c` de erro da ação `ScheduledFlowOpportunity` novo = 0. **É a prova da falha da rodada 3** | 6 e regressão | Achado 1 (Account) e cadeia Protheus |
| 3 | Distribuição de `AccountRanking__c.Ranking__c` = distribuição esperada, calculada por `COUNT()` de Account em cada faixa de `AveragePurchasesThisYear__c` (os mesmos números da rodada 3: MP 207, PP 138, P 107, M 73, G 30, GG 0, 3G 0, a reconferir na data) | 10, 11 | — |
| 4 | Segunda execução no mesmo mês: nenhum registro duplicado (contagem igual). `RankingChanged__c` = falso onde nada mudou | 4 | — |
| 5 | Sintético "TESTE EPLAST-47": ganhas de 3.000 e 2.000 e perdida de 9.000 → `PurchaseValue__c` = 5.000 | 8 | `OpportunityFlow` e CPQ disparam na criação: listar o que saiu (card de 15/11) |
| 6 | Conta sintética só com ganha de ano anterior → `PurchaseValue__c` = 0 (PA3) | 9 | idem |
| 7–18 | Média 10.000 / 10.000,01 / 35.000 / 35.000,01 / 80.000 / 80.000,01 / 160.000 / 160.000,01 / 500.000 / 500.000,01 / 1.000.000 / 1.000.000,01 → MP / PP / PP / P / P / M / M / G / G / GG / GG / 3G. Pode usar Debug do Flow sobre a conta sintética, com a média gravada direto nela (1 update individual, autorizado) | 10 | — |
| 19 | Média 0 → MP. Média vazia → mantém a classificação anterior, nunca GG | 11 | — |
| 20 | XML da v3 sem limite fixo. Trocar `UpperLimit__c` de uma faixa no custom metadata muda a classificação sem nova versão | 12 | — |
| 21 | Picklists `Account.Ranking__c` e `AccountRanking__c.Ranking__c` = MP, PP, P, M, G, GG, 3G | 13 | — |
| 22 | `AccountRankingChanges` mostra N linhas = `COUNT()` de `RankingChanged__c = true`, com anterior e atual. Na primeira execução, o anterior é o legado | 14 | — |
| 23 | **Falha forçada:** registro sintético de `AccountRanking__c` com `AccountKey__c` = Id da conta sintética B, mas `Account__c` = conta sintética A. Na execução, a criação para B falha por duplicidade → `IntegrationLog__c` criado e as outras contas gravam. Com destinatário vazio, não envia | 16 | — |
| 24 | Com `FaultRecipient__c` de teste: envio registrado. Conferir a entregabilidade de e-mail da sandbox | 16 | — |
| 25 | **CPU e linhas:** debug log do usuário do processo automatizado no lote que contém a conta com mais oportunidades ganhas (achada por `COUNT()` agrupado por `AccountId`, sem nome). Anotar CPU, SOQL e linhas. Acima de 70%, escala | 6 e escala | Achado SOMOSAGILITY-10 |
| 26 | Página da conta mostra a lista "Classificação da Conta". Usuário com `PS_Comercial_ClassificacaoConta` lê e não edita | D3, permissões | — |
| 27 | Regressão: `Account.Ranking__c` e `LastMonthPurchaseValue__c` com distribuição igual à da linha de base (congelados) | D2 | — |

Usuário de teste (regra 6): a conta de serviço da Konecta ativa na org do job, conferida pelo Id. Na dev, o recon achou `005bJ00000piKAaQAM`. Ela tem perfil de administrador, então não serve para o caso de acesso negado. O caso 26 fica restrito a "lê e não edita" pelo permission set, sem prova de negação.

---

## 9. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Consumidores de `Account.Ranking__c` e `LastMonthPurchaseValue__c` passam a ver valor congelado** (página, relatório do Marketing Cloud, eventual leitura do Protheus por API) | **Alta (negócio)** | D2 e D3, seção 6, texto de ajuda nos campos. Avisar a Eplast antes da homologação. |
| R2 | **A causa de fundo continua: qualquer gravação em massa em Account estoura 50 queueables e reenvia contas ao Protheus** (`AccountTriggerHelper` sem filtro de campo) | **Alta (fora do escopo)** | Esta demanda deixa de gravar em Account. **Recomendação ao responsável:** abrir demanda de Apex para filtrar o enfileiramento por campos que o Protheus usa, com `<Classe>Test` e cobertura de 85%, como o assessment prioriza. Hipótese, sem como confirmar sem tocar produção: a v1 em produção grava em Account por oportunidade e pode já falhar do mesmo jeito. |
| R3 | Lote com várias contas de muitas oportunidades passa de 50.000 linhas ou do CPU | Média | Caso 25 mede. Acima de 70%, volta ao design (seção 4). |
| R4 | Alguém cria roll-up de `AccountRanking__c` em Account no futuro e reabre o update em massa | Média | Aviso na descrição do objeto e do campo mestre-detalhe. |
| R5 | A FlexiPage do repo diverge da que está na QA, e o deploy sobrescreve | Média | O builder parte da versão do repo e limita o diff ao componente novo, registrando o diff no plano. Se o gate recusar D3, o item sai. |
| R6 | A troca de tipo do relatório `AccountRankingChanges` é recusada no deploy | Baixa | Remover e recriar com o mesmo API name (item 10). |
| R7 | Duas listas de picklist com os mesmos 7 valores (`Account` e objeto novo) | Baixa | Descrição nos dois campos. Faixa nova exige os dois. |
| R8 | Dado sintético na QA dispara `OpportunityFlow`, CPQ, pedido e possível envio ao Protheus | Alta (teste) | Autorizado em 15/11, nas condições do card: só "TESTE EPLAST-47", o menor volume, e lista do que saiu ao final. |
| R9 | A primeira execução cria registro para toda conta elegível da QAS (cerca de 555) | Baixa | São registros da própria solução (regra 5). Nenhum DML do agente sobre registro existente. |

---

## 10. O que NÃO será feito nesta demanda

- Gravar em `Account`, em massa ou por conta, na execução mensal. Fazer carga ou backfill de `Account.Ranking__c`.
- Criar ou alterar Apex. Alterar `AccountTrigger`, `AccountTriggerHelper`, `SendAccountToProtheus` ou `TriggerUtility__mdt`, ou usar o bypass.
- Alterar `OpportunityFlow`, `AccountTriggered`, `UpdateParentAccountUsedLimit`, triggers do SBQQ, `OrderTrigger` ou validation rules.
- Apagar, renomear ou tirar de página, relatório ou permission set os campos `Account.Ranking__c` e `LastMonthPurchaseValue__c`. A depreciação é demanda futura.
- Alterar o relatório `CLASSIFICACAO_CONTAS_POR_CLASSE` ou qualquer item da pasta "MARKETING CLOUD". Qualquer passo no Marketing Cloud.
- Alterar layouts de página (`Account Layout`, `CPQ Account Layout`).
- Período configurável (critério 7), troca para `CloseDate` ou classificação pela soma: a regra fica como hoje (card de 14/11).
- Mudança no Protheus ou mapeamento de MP e 3G no ERP. Promoção para QAS final ou produção (EPLAST-48).
- Alterar o agente `SFAgent2`.

**Incertezas que ficam:** outros relatórios, layouts e classes que leem os 2 campos de Account (só foram varridos Flows, as 2 páginas, o `Account Layout`, o permission set `Protheus` e as classes do envio ao Protheus); se o Protheus lê `Ranking__c` por API de entrada; os critérios de entrada de `AccountTriggered` e `UpdateParentAccountUsedLimit`, que deixam de importar porque não há update em Account.

---

## 11. Premissas assumidas (validar na homologação)

Regra 4 da conta. Nenhuma se enquadra no caso 3.

- [x] **PA1 (P1). Base anual, só oportunidades ganhas?** Decisão: mantém a regra atual, soma das ganhas com `ThisYear__c`. Evidência: v1 e v2 do Flow na org e a diretriz do card de 14/11 ("a regra de negócio atual não muda"). Para mudar: filtro do `GetOpportunities` em nova versão do Flow.
- [x] **PA2 (P5). O aviso de falha é operacional ou de marketing?** Decisão: operacional. Usa a ação padrão de e-mail do Flow, só para `FaultRecipient__c`, com o Id da conta e a mensagem de erro, sem dado de cliente. Evidência: é erro técnico de job, não comunicação com cliente, e a regra 2 trata de e-mail, campanha e jornada a clientes. Para mudar: deixar `FaultRecipient__c` vazio (só log) e o operador do Marketing Cloud ler `IntegrationLog__c`.
- [x] **PA3 (P6). Conta sem compra no ano: zero ou vazio? Média vazia classifica como?** Decisão: `PurchaseValue__c` = 0. Média vazia mantém a classificação anterior, do registro ou o legado, nunca GG. Média 0 vira MP. Evidência: a soma de nada é 0 (padrão), e o critério 11 proíbe cair em GG. Para mudar: uma atribuição na nova versão do Flow.
- [x] **PA4 (P8). O Protheus aceita MP e 3G?** Decisão: a solução não muda o que vai ao Protheus. Evidência: `AccountAdapter.toProtheus` não referencia `Ranking__c` (conferido nesta sessão), e `Account.Ranking__c` fica congelado com os valores atuais. O permission set `Protheus` não muda. Para mudar: se o ERP ler a classificação, dar a ele leitura em `AccountRanking__c` (demanda de integração).
- [x] **PA5 (P9). Diário com dia 14 ou mensal?** Decisão: diário com checagem do dia configurável. Evidência: Flow agendado só aceita Once, Daily ou Weekly (plataforma).
- [x] **PA6 (P10). Volume do teste?** Decisão: a população real da QAS (cerca de 555 contas elegíveis, 1.217 contas). Evidência: autorização do card de 15/11 e regra 5. Para mudar: o cliente informa outro número, e o QA repete o caso 1.
- [x] **PA7 (P11). Destinatário da falha?** Decisão: `FaultRecipient__c` vazio até a Eplast informar. Sem destinatário, só log. Evidência: configuração já existente. Para mudar: preencher o registro `Default`, sem nova versão.
- [x] **PA8 (P12). Onde ficam os relatórios?** Decisão: pasta `EPLAST47`, que já existe e é provisória. Evidência: é onde está o `AccountRankingChanges` hoje. Para mudar: mover os 2 relatórios de pasta, sem deploy de lógica.
- [x] **PA9 (nova). Um registro por mês ou um registro vigente por conta?** Decisão: um vigente por conta, com histórico de campo em `Ranking__c` e `PurchaseValue__c` para o rastro mês a mês. Evidência: padrão mais simples para segmento e página (seção 1.2). Para mudar: tirar a unicidade de `AccountKey__c` e criar sempre, em nova versão do Flow.
- [x] **PA10 (nova). Quem vê a classificação nova?** Decisão: os mesmos usuários que veem `Account.Ranking__c` hoje, pelo permission set `PS_Comercial_ClassificacaoConta`. A atribuição é passo do administrador da Eplast depois do deploy. A esteira não atribui a usuário real. Evidência: padrão de permission set do squad e a família `PS_Comercial_*` da org. Para mudar: atribuir a outro grupo.
- [x] **PA11 (nova). Classificação anterior na primeira execução?** Decisão: o valor legado de `Account.Ranking__c`, para que o relatório de mudanças já mostre a primeira troca. Evidência: é o único valor anterior que a org tem. Para mudar: deixar vazio no `CreateRanking`.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
