**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast, Org Id 00DHa000006vfMLMAY, confirmada em `sf org list`, única org conectada)

# EPLAST-33 — Verificação do build

Aprovada com ressalvas. Os critérios de regra (CA-01 a CA-17, CA-20, CA-21) foram exercitados pela suíte Apex do builder, que eu reexecuti na dev. Não criei dado de teste próprio: a dev tem 0 contas e 0 pedidos, e criar Account dispara `AccountTrigger` (CNPJ e BrasilAPI), que é callout externo. A suíte usa fixture com contorno oficial (`TriggerUtility.bypassTrigger`) e remove os dados no próprio teste. Nada ficou na org: `CommercialSignal__c` tem 0 registros e Account tem 0.

## Evidência executada

- `sf apex run test -o sbx-eplast-dev` nas 4 classes de teste (`--code-coverage`), Test Run Id `707Ha00001DzdKU`: Outcome Passed, 38 testes, 100%.
- Cobertura por classe: `CommercialSignalService` 99%, `CommercialSignalGroupStatsBatch` 98%, `CommercialSignalBatch` 97%, `CommercialSignalScheduler` 100%. Todas ≥ 85%.
- `ApexClass` com nome `CommercialSignal%`: 9 classes, todas Active (4 de produção, 4 de teste, 1 fábrica).
- `CronTrigger` "EPLAST33 Sinais Comerciais": `0 0 1 * * ?`, estado WAITING, `NextFireTime` 2026-11-16T04:00:00Z (04:00 UTC, como no design). Os 3 `AsyncApexJob` abortados da classe são jobs criados pelos testes.
- `FieldDefinition` de `CommercialSignal__c`: os 11 campos do plano existem (`Account__c`, `Type__c`, `Product__c`, `LastPurchaseDate__c`, `DaysWithoutPurchase__c`, `BasePeriodAmount__c`, `CurrentPeriodAmount__c`, `VariationPercent__c`, `Reason__c`, `CalculationDate__c`, `SignalKey__c`).
- Relatório `CommercialSignals_ByAccount`: 1 registro em `Report`. Permission set `PS_Comercial_SinaisComerciais`: 1. `ApexTrigger` com "Signal" em Account, Order, OrderItem ou Opportunity: 0 (CA-21).

## Tabela por critério

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V-01 | CA-01, CA-02 | Testes do serviço e do lote com última compra a 61, 60 e 59 dias | 61 entra; 60 e 59 não | Testes passaram (38/38) | passou |
| V-02 | CA-03, CA-04 | Conta sem pedido; pedido cancelado e em processo | "Nunca comprou" gerado; pedidos inválidos não contam | Testes passaram | passou |
| V-03 | CA-05, CA-06, CA-07 | Variação 30% exato, 31%, queda, alta, base zero | Só acima de 30% classifica; sem base não classifica | Testes passaram | passou |
| V-04 | CA-08 a CA-11 | Cruzada com 4 de 10, 2 de 10, compra recente, sem Industry, grupo de 4 | Só as regras do design geram sinal | Testes passaram | passou |
| V-05 | CA-12 | Contagens e maior `LastModifiedDate` de Account, Order, OrderItem e Opportunity antes e depois da execução; nenhum `EmailMessage` | Nenhuma escrita em objetos comerciais | Teste passou; código sem DML fora de `CommercialSignal__c` | passou |
| V-06 | CA-13 | Teste de permissão: sem o permission set não lê; com ele lê e não cria | Acesso só pelo permission set | Teste passou. A visibilidade por conta não foi provada (OWD de Account é ReadWrite) | passou em parte |
| V-07 | CA-14 | Conferência da lista de campos do relatório no plano e do objeto | Nenhum campo de contato | Nenhum campo de contato nos 11 campos do objeto; o relatório foi conferido só pelo plano | passou em parte |
| V-08 | CA-15, CA-16 | Reexecução; pedido novo entre execuções | Sem duplicata, mesmos Ids; recuperação removida | Testes passaram | passou |
| V-09 | CA-17 | Parâmetro de 90 dias no CMDT sobre a fixture do CA-01 | Classificação muda sem alterar código | Teste passou | passou |
| V-10 | CA-20 | Cobertura e nomenclatura `<Classe>Test` | ≥ 85% por classe | 97% a 100%; 4 classes `*Test` | passou |
| V-11 | CA-21 | Consulta de triggers em Account, Order, OrderItem e Opportunity | Nenhum trigger novo | 0 | passou |
| V-12 | Agendamento | Consulta de `CronTrigger` | Job diário às 04:00 UTC | `0 0 1 * * ?` em America/Sao_Paulo, WAITING, próxima execução 2026-11-16 04:00 UTC | passou |
| V-13 | CA-19 | Conferência por metadata: sem Flow, e-mail ou Campaign no build | Nada dispara pelo CRM; público identificável | Sem componente de envio. O público é a lista (relatório e objeto), conforme o design | passou |
| V-14 | CA-18 | Amostra validada pelo Comercial contra o Protheus | Lista bate | Critério de homologação, não exercitável na dev | não executado |

## O que ficou sem prova

1. **CA-18**: validação de negócio pelo Comercial contra o Protheus. É feita na homologação.
2. **CA-13, visibilidade por conta**: exige compartilhamento real, na QA. Na dev só se provou a permissão por objeto.
3. **Relatório aberto com dados** (CA-14 na saída real): a dev está vazia, então o relatório foi confirmado só como existente. Alguém precisa abri-lo na QA depois de agendar o job e conferir que não há campo de contato. O builder já avisou que o formato foi escrito à mão.
4. **Consumo de limites com volume** (1 conta com 5 mil itens; 1.000 contas em 3 grupos), pendente no design seção 4. Não medi: exigiria criar contas em massa na dev, passando por `AccountTrigger` e BrasilAPI, sem contorno fora do teste. Medir na QA ou com fixture dedicada.
5. **Execução real do job agendado**: só foi provado o agendamento. A primeira execução está prevista para 2026-11-16 04:00 UTC.

## Observações

- Falhas de gravação do batch só vão para `System.debug`, não para o status do job (desvio 4 do plano). Não impede o critério.
- `UNABLE_TO_LOCK_ROW` intermitente em execução paralela, relatado pelo builder. Na minha rodada (4 classes juntas) não ocorreu.
- Cobertura global da org: 43% (`Org Wide Coverage`).

## O que pode ter saído da org

Nada. Não disparei automação com callout. Não criei registros.
