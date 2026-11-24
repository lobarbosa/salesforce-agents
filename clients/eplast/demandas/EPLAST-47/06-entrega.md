# EPLAST-47 — Entrega: classificação da conta ao salvar a oportunidade

**Cliente:** Eplast · **Demanda:** EPLAST-47 · **Etapa:** 6–7 (release e documentação)
**Estado:** entregue na sandbox de QA (`sbx-eplast-qa`), aguardando homologação do cliente e decisão de levar a produção. Produção não foi tocada.

## 1. O que foi entregue (linguagem de negócio)

Antes, a classificação das contas (MP, PP, P, M, G, GG, 3G) e o campo "Valor da última compra" eram recalculados por uma rotina mensal, todo dia 14, para todas as contas de uma vez. Essa rotina tinha faixas erradas (faltavam MP e 3G) e gravava em massa nas contas.

Agora:

- **A classificação acontece quando a oportunidade é salva.** Ao ganhar, perder, criar ou alterar o valor ou a conta de uma oportunidade ganha do ano, só a conta dessa oportunidade é recalculada.
- **"Valor da última compra"** (`LastMonthPurchaseValue__c`) passa a ser a soma das oportunidades "Fechado/Ganho" do ano da conta. Oportunidades perdidas não entram.
- **As faixas** ficam em metadado configurável (`RankingRange__mdt`), com os 7 valores do campo "Classificação" (MP, PP, P, M, G, GG, 3G). As bordas foram provadas na QA: 10.000; 35.000; 80.000; 160.000; 500.000; 1.000.000 e os valores acima de cada uma.
- **Histórico:** cada mudança de classificação fica no histórico do campo, e o relatório `AccountRankingChanges` (pasta `EPLAST47`) lista as mudanças.
- **Falha não barra a venda.** Se a atualização da conta falhar, a oportunidade é salva, a falha vai para o log de integração (`IntegrationLog__c`) e, se houver destinatário configurado, sai um e-mail.
- **A rotina mensal antiga foi desligada, não apagada.** O Flow `ScheduledFlowOpportunity` não tem versão ativa nem agendamento.

O que não mudou: o envio de contas ao ERP (Protheus), as regras de criação de pedido e cotação e o cálculo da média anual feito pelo fluxo existente `OpportunityFlow`.

## 2. Rastreabilidade

| Item | Valor |
|---|---|
| Demanda | `EPLAST-47` |
| Branch | `feature/EPLAST-47` (a partir da `main`) |
| Commits relevantes | `4d7281e8` (build via CI, dev); `6d4b7524` (QA via CI); `ba5fab8d` (pacote sem o Flow agendado); `61f717d8` (registro de decisão) |
| PR | **não localizado.** Os artefatos não trazem número de PR, e o `gh` não tem token neste runner. Preencher antes do merge. |
| Org de build e verificação | `sbx-eplast-dev` (sandbox `eplast--qa`, Org ID `00DHa000006vfMLMAY`) |
| Org de QA e homologação | `sbx-eplast-qa` (sandbox `eplast--qas`, Org ID `00DHa000006vZtmMAE`) |
| Deploy de release na QA (real) | `0AfHa00000ENFCpKAP`, Succeeded, 156 componentes, 0 erros, 2026-11-24T12:16:43Z |
| Dry-run do release | `0AfHa00000ENHePKAX`, Succeeded, 156 componentes, 0 erros |
| Deploy do pacote da rodada 6 de QA | `0AfHa00000EJ46HKAT`, Succeeded, 2026-11-17T09:05Z (`05-deploy-qa.md`) |
| Veredito de QA | `05-testes.md`: aprovado (rodada 6), org `sbx-eplast-qa` |
| Verificação na dev | `04-verificacao.md`: aprovada |
| Homologação | `gates.md` (registro pela esteira, 2026-11-24T12:15Z) |
| Produção | não levada. Deploy de produção é decisão humana com janela e aprovação. |

Deploys da dev (build, verificação e desativação do agendado) estão em `04-plano-build.md` e `04-verificacao.md`, com seus IDs.

## 3. Componentes

Todos os componentes do pacote de release. Nenhum Apex novo, nenhum objeto novo, nenhum campo novo.

| Tipo | API name | Ação |
|---|---|---|
| Flow (novo) | `Opportunity_AfterSave_ClassificaConta` | Criado. Flow após salvar, disparado por registro em `Opportunity`, `triggerOrder` 1500. Versão ativa na QA: `301Ha0000177L43IAE`. |
| Flow (desativado) | `ScheduledFlowOpportunity` (`flowDefinitions/` com `activeVersionNumber` 0) | Desativado, não apagado. Sem versão ativa, sem `CronTrigger`. |
| Metadado | `RankingRange__mdt` (7 registros: G, GG, M, MP, P, PP, X3G) | Reaproveitado, sem mudança de faixa. |
| Metadado | `RankingRange__mdt.Ranking__c`, `SortOrder__c`, `UpperLimit__c` | Reaproveitados. |
| Metadado | `ScheduledFlowOpportunitySetting__mdt.Default` | Reaproveitado. `FaultRecipient__c` vazio (sem e-mail de falha). |
| Metadado | `ScheduledFlowOpportunitySetting__mdt.RunDayOfMonth__c` | Descrição alterada para "sem uso". Campo mantido. |
| Campo | `Account.Ranking__c` (picklist MP, PP, P, M, G, GG, 3G; histórico de campo) | Reaproveitado. Campo vigente da classificação. |
| Campo | `Account.LastMonthPurchaseValue__c` | Reaproveitado. Recebe a soma das ganhas do ano. Nome mantido (premissa PA4 do design). |
| Relatório | `AccountRankingChanges` (pasta `EPLAST47`) | Filtro alterado para `Ranking__c`. Pasta provisória. |
| Leitura | `Account.AveragePurchasesThisYear__c`, `Opportunity.ThisYear__c` | Só leitura. |
| Log | `IntegrationLog__c` (ação `ClassificaConta`) | Usado no caminho de falha. |

Não alterados: `OpportunityFlow`, `AccountTrigger`, `AccountTriggerHelper`, `OpportunityTrigger`, `UpdateAccountCompanyInfo`, permission sets (incl. `Protheus`), perfis, relatório `CLASSIFICAÇÃO - CONTAS POR CLASSE`, agente `SFAgent2`, nada no Marketing Cloud.

## 4. Como funciona (fluxo em passos)

Disparo: qualquer save de oportunidade que atenda à condição de entrada.

1. **Entrada.** O Flow roda se a oportunidade tem conta, é do ano corrente (`ThisYear__c`) e: nasce ganha; passa a ganha; deixa de ser ganha; ou muda de valor ou de conta estando ganha. Demais saves e oportunidades de anos anteriores não entram.
2. **Leitura da conta.** Lê `Ranking__c`, `LastMonthPurchaseValue__c` e `AveragePurchasesThisYear__c` da conta. A média é lida depois que o `OpportunityFlow` gravou a média na mesma transação.
3. **Soma.** Soma `Amount` das oportunidades da conta com `StageName` = "Fechado/Ganho" e `ThisYear__c` = verdadeiro. Sem oportunidade, a soma é 0.
4. **Classificação.** Se a média (`AveragePurchasesThisYear__c`) está vazia, mantém a classificação atual, nunca vai para GG. Se está preenchida (inclusive 0), busca a primeira faixa de `RankingRange__mdt`, em ordem de `SortOrder__c`, cujo `UpperLimit__c` seja maior ou igual à média (faixa sem limite = 3G). Média 0 dá MP.
5. **Decisão de gravar.** Só grava se a classificação ou a soma mudou em relação à conta lida. Senão, termina sem tocar na conta.
6. **Gravação.** Update da conta: `Ranking__c` e `LastMonthPurchaseValue__c`. Esse update dispara o histórico de campo e a cadeia de Account existente (`AccountTrigger`, que enfileira um job por conta, para envio ao Protheus ou consulta à BrasilAPI).
7. **Falha.** Se o update falhar, o Flow grava `IntegrationLog__c` e, só se `FaultRecipient__c` estiver preenchido, envia e-mail com o Id da conta e a mensagem de erro (sem dado de cliente). A oportunidade continua salva.

Para a ordem de execução no save, ver `03-design.md`, seção 1.5.

## 5. Configuração pós-deploy

- **Nenhuma ativação extra.** O Flow novo nasce ativo pelo pacote.
- **Nenhum permission set novo.** Nenhum passo de acesso.
- **E-mail de falha (opcional).** `ScheduledFlowOpportunitySetting__mdt.Default.FaultRecipient__c` está vazio por premissa PA6. Para receber e-mail de falha, a Eplast informa o destinatário e alguém preenche o campo. É configuração, não deploy.
- **Produção (quando houver decisão):** antes de levar o pacote, conferir na org de produção `FlowDefinitionView` do `ScheduledFlowOpportunity` (sem versão ativa) e `Opportunity_AfterSave_ClassificaConta` (ativo), e `CronTrigger` sem agendamento do Flow antigo. O release não executa produção.
- **Relatório:** pasta `EPLAST47` é provisória (PA7). Mover para a pasta definitiva é decisão da Eplast.
- **Marketing Cloud (quem opera):** ver item 7.

## 6. Plano de rollback

1. **Classificador:** desativar `Opportunity_AfterSave_ClassificaConta` (Setup > Flows) ou reimplantar a versão anterior pela `main`. As contas já classificadas mantêm o `Ranking__c` gravado. Reverter valores só com decisão do cliente; o relatório `AccountRankingChanges` lista as mudanças.
2. **Agendado:** para voltar ao comportamento antigo, reimplantar `ScheduledFlowOpportunity.flowDefinition` com `activeVersionNumber` da versão a restaurar e reagendar. Antes, desativar o Flow novo: os dois ativos juntos duplicam a classificação. **Ponto não confirmado:** a versão de referência na dev é a v2 (`04-plano-build.md`); na QA, as versões existentes são v7 e v8 (`05-testes-rodada-5.md`). Conferir qual corresponde à v2 antes de reativar.
3. **Relatório, faixas e descrições:** reimplantar os arquivos da `main`. Campos e objetos novos não são apagados por deploy comum; não há remoção prevista.

## 7. Limitações conhecidas e dívida técnica

**Limitações da entrega**

- **Critério 16 (falha forçada) não exercitado.** Na QA, a regra `CheckAccountOwnerHasProtheusSellerId` barra a oportunidade antes do Flow novo, e na dev as validation rules não deixam criar conta inválida. O caminho de falha está provado só por leitura do Flow. Fica para a homologação (`05-roteiro-cliente.md`, teste 6), sem reprovar.
- **Teste 5 do roteiro (falha) depende do time técnico** para provocar a falha.
- **Envio ao Protheus a cada classificação.** Cada update de conta dispara a cadeia existente, que pode enviar a conta ao ERP. O responsável aceitou isso para teste com dado sintético (R8). Em produção, é decisão a confirmar. O ERP não recebe `Ranking__c` (`AccountAdapter`, `ProtheusAPI` e `UpdateAccountWithProtheusInfo` sem referência), mas a configuração do lado do ERP não é visível pelo CRM.
- **Média não atualizada em alguns casos (comportamento existente).** Ganha sem cotação aprovada não atualiza a média. Na baixa de ganha para perdida, o `OpportunityFlow` grava a média com o total anterior, e com contagem 0 divide por zero. A classificação segue o campo gravado (PA12). Nesta demanda não foi corrigido.
- **Troca de conta:** só a conta nova é recalculada (PA8). A antiga mantém a classificação até o próximo evento ou o recálculo da EPLAST-48.
- **Exclusão e restauração** de oportunidade não recalculam (PA9).
- **Recálculo das contas existentes** não está nesta demanda. Contas sem nenhum evento novo ficam com a classificação antiga até o card EPLAST-48.
- **Carga em massa:** o `AccountTrigger` enfileira um job por conta, e o limite de 50 jobs por transação já existe hoje. O Flow novo adiciona até um job por conta. Com cotação aprovada, o máximo de contas distintas por transação cai de cerca de 25 para cerca de 16 (`03-design.md`, 3.2). Não testado com carga real (decisão do responsável: sem teste de volume).
- **Nenhum teste Apex.** Não há Apex novo; a cobertura do squad (85%) não se aplica a este pacote.

**Dívida técnica identificada (não é desta demanda)**

- **Defeito em `UpdateAccountCompanyInfo`:** grava a conta (linha 31) e chama `SendAccountToProtheus.execute` na mesma transação (linha 34). A plataforma recusa a chamada externa depois da gravação, e o envio ao Protheus falha quando a conta tem os campos exigidos. Correção sugerida à Eplast: voltar a enfileirar o envio com `System.enqueueJob`. Não corrigido.
- **Raiz do limite de jobs:** a `AccountTrigger` enfileira um job por conta, sem filtro de campo. Qualquer atualização em massa de `Account` envia contas ao ERP. Solução nova não grava em massa em `Account`.
- **Dependência de ordem:** o Flow novo depende de o `OpportunityFlow` não ter `triggerOrder` acima de 1500. Se alguém der a ele ordem maior, o Flow novo lê a média antiga. Está escrito na descrição do Flow.
- **Reentrada do save:** o `OpportunityFlow` atualiza o próprio registro, e isso pode reexecutar o save. Não confirmado se o Flow novo roda de novo; o `HasChanges` evita gravação repetida.
- **Relatório provisório:** `AccountRankingChanges` está na pasta `EPLAST47`, e o filtro de `Ranking__c` não foi conferido com dado real pela Analytics API (só 0 linhas na dev sem histórico).
- **Campo sem uso:** `RunDayOfMonth__c` ficou sem uso (descrição atualizada). Remover exige mudança de modelo de dados.
- **Flow agendado desativado, não apagado:** `ScheduledFlowOpportunity` e suas versões ficam no org. Apagar é decisão posterior.
- **Consumidores de `Ranking__c` no Marketing Cloud:** não visíveis pelo CRM. Não confirmado se alguma extração ou público lê o campo.
- **Incertezas do design não confirmadas:** contexto de execução do caminho assíncrono do Flow; como o update agrupado trata Id repetido de conta (caso V5 da verificação); se `SFAgent2` referencia os campos de compra (não verificado; a demanda não o altera).

## 8. Premissas assumidas (validar na homologação)

Lista completa e evidências em `03-design.md`, seção 10. Resumo:

| Id | Premissa | Como mudar |
|---|---|---|
| PA1 | Soma só de oportunidades "Fechado/Ganho" do ano (`ThisYear__c`), como na rotina antiga | Filtro de `GetOpportunities` |
| PA2 | Aviso de falha é operacional, por e-mail só com destinatário | Preencher ou esvaziar `FaultRecipient__c` |
| PA3 | Conta sem compra: soma 0; média vazia mantém a classificação; média 0 vira MP | Atribuição em versão nova |
| PA4 | Protheus não muda: a solução não altera o que vai ao ERP | Demanda de integração, se o ERP passar a ler a classificação |
| PA5 | Sem teste de volume (critério 18 retirado em 17/11) | Cenário de carga vira caso de teste |
| PA6 | Destinatário de falha vazio: só log | Preencher o registro `Default` |
| PA7 | Relatório segue na pasta provisória `EPLAST47` | Mover de pasta |
| PA8 | Troca de conta recalcula só a conta nova | Segundo update para a conta anterior, em versão nova |
| PA9 | Exclusão e restauração não recalculam | Flow before delete próprio |
| PA10 | Fase ganha é `Fechado/Ganho` | Trocar por `IsWon` em versão nova |
| PA11 | Oportunidade de ano anterior não dispara o Flow | Tirar a condição |
| PA12 | Classifica pelo campo de média como gravado, mesmo quando o `OpportunityFlow` não o atualiza | Calcular a média no Flow novo, em versão nova |
| PA13 | Falha da classificação não barra a venda | Tirar o caminho de falha |
| PA14 | Agendado desativado e não apagado; `RunDayOfMonth__c` sem uso | Reativar a versão anterior |

## 9. Cronologia de versões e validações (referência)

- Análise aprovada em 2026-11-14; design rodada 3 em 2026-11-17, com decisões do responsável de 17/11 (desativar o agendado no pacote; critério 16 para a homologação).
- Verificação na dev: aprovada (`04-verificacao.md`).
- QA: rodadas 1 a 5 com falhas corrigidas; rodada 6 aprovada (`05-testes.md`, veredito aprovado, org `sbx-eplast-qa`).
- Release na QA em 2026-11-24, sem erro (deploy `0AfHa00000ENFCpKAP`).

## 10. Próximos passos

1. Cliente homologa com `05-roteiro-cliente.md`, incluindo as premissas da seção "O que assumimos e você precisa confirmar" e o teste 5 (falha), com apoio do time técnico.
2. Abrir ou localizar o PR de `feature/EPLAST-47` e registrar o número neste arquivo.
3. Decisão humana sobre produção: janela, aprovação registrada e revisão deste rollback. Conferir o estado do agendado em produção depois do deploy.
4. Card EPLAST-48: recálculo das contas existentes, em lotes pequenos, executado por uma pessoa.
5. Para a Eplast: informar o destinatário de falha (opcional), confirmar o uso de `Ranking__c` no Marketing Cloud e no ERP, e decidir sobre a correção de `UpdateAccountCompanyInfo`.

## 11. Para quem opera o Marketing Cloud (regra 2 da conta)

A esteira não fez nada no Marketing Cloud. Para quem opera:

- Dado que pode ser lido: `Account.Ranking__c` e `Account.LastMonthPurchaseValue__c`. Nenhum campo novo.
- Se algum público ou filtro usa `Ranking__c`, incluir MP e 3G e rever as faixas antigas.
- A classificação agora muda a cada oportunidade ganha ou perdida, não uma vez por mês. Público montado por data pode ver mudanças no meio do mês.
- O segmento aparece no CRM pelo valor de `Ranking__c`, já usado no relatório `CLASSIFICAÇÃO - CONTAS POR CLASSE` (pasta MARKETING CLOUD).
