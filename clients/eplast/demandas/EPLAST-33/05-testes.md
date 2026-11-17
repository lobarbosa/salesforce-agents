**Veredito:** aguardando execução
**Org de teste:** `sbx-eplast-qa`
**Conferir depois de:** 2026-11-17 14:51 UTC (disparo armado 14:41 UTC + 10 min)

# EPLAST-33 — Testes na QA, fase 1 (armar)

Org conectada confirmada por `sf org list`: `sbx-eplast-qa` (QAS da Eplast, Org Id 00DHa000006vZtmMAE, usuário de execução `005bJ00000piKAaQAM`). Escopo: o do gate de 17/11 (sem a consulta pelo assistente). Os CA-* de `01-analise.md` são da rodada anterior (61 dias, 30%); foram lidos contra os valores aprovados no design de 17/11 (90 dias, 20%, por família, histórico insuficiente, cruzada por `Sector__c`).

## O que já foi comprovado nesta sessão

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| Q1 Componentes do `05-deploy-qa.md` na org | `sf data query` em `ApexClass`; `FieldDefinition` (Tooling) de `CommercialSignal__c` e do CMDT | 9 classes; 4 campos novos no sinal; 6 campos novos no CMDT | 9 classes Active (API 67); `ProductFamily__c`, `UnitOfMeasure__c`, `BasePeriodQuantity__c`, `CurrentPeriodQuantity__c` presentes; 6 campos novos do CMDT presentes | passou |
| Q2 Parâmetros `Default` (CA-17: parâmetro sem código) | query em `CommercialSignalSetting__mdt` | 90 dias; 20; `Queda`; `Sector__c`; `EffectiveDate`; `Group__c`; base mínima 2; `Familia`; `Faturamento;Concluido` | Valores idênticos (1 registro) | passou |
| Q3 Suíte Apex na QA (CA-20, e regras de limite 91/90/89 dias, 20%, histórico, família, segmento < 5, bulk, idempotência, sem escrita em objetos comerciais) | `sf apex run test` das 4 classes `CommercialSignal*Test` na QA; resultado lido em `ApexTestResult` | Todos passam, cobertura >= 85% | 0 falhas (a suíte rodou duas vezes por timeout da primeira chamada: 132 resultados `Pass`, 66 testes por rodada). Cobertura (`ApexCodeCoverageAggregate`): Service 273/273, Scheduler 5/5, Batch 109/111, GroupStatsBatch 52/54 | passou |

## Fase 1 — estado de antes (só contagens agregadas)

- `CommercialSignal__c`: 1358 registros, da rodada anterior (regras antigas): NuncaComprou 637, Recuperacao 530, QuedaVolume 169, AltaVolume 22, Cruzada 0. Nenhum tem `ProductFamily__c` (0). Última criação: 2026-11-16 01:20 UTC.
- Objetos comerciais (para CA-12): Account 1223, maior LastModifiedDate 2026-11-17T13:15:54Z; Order 10321, 2026-11-16T01:48:10Z; OrderItem 10008, 2026-11-13T19:06:52Z; Opportunity 9341, 2026-11-17T11:06:24Z. Account e Opportunity têm uso humano na QAS; mudança de data nesses dois só vale como defeito se vier da execução (ver `LastModifiedBy`).
- Job agendado `EPLAST33%` antes de armar: nenhum ativo (o da rodada anterior foi cancelado pela esteira antes do deploy, ver `05-deploy-qa.md`).

## O que foi alterado para armar

- `System.schedule('EPLAST33 QA arme 1117', '0 41 11 17 11 ? 2026', new CommercialSignalScheduler())` por Apex anônimo na QA. Fuso da org America/Sao_Paulo; `CronTrigger` 08eHa00000XthL2IAJ com `NextFireTime` 2026-11-17T14:41:00Z, estado WAITING (conferido).
- Nome tentado primeiro ("EPLAST33 QA arme") foi recusado por resíduo de nome; usei o sufixo 1117.
- Permission set `PS_Comercial_SinaisComerciais` atribuído ao usuário de execução para ler os campos novos (atribuição `0PaHa00000EM1ghKAD`), e **removido** ao fim desta sessão. Na fase 2 atribuir de novo para ler `ProductFamily__c` e desfazer ao final.
- Nada commitado. Desfazer o arme: abortar o `CronTrigger` 08eHa00000XthL2IAJ.

## Esperado depois da execução (fase 2 confere)

1. `CronTrigger` 08eHa00000XthL2IAJ com `PreviousFireTime` 14:41 UTC e `TimesTriggered` 1; `AsyncApexJob` de `CommercialSignalGroupStatsBatch` e `CommercialSignalBatch` Completed, sem falha.
2. `AltaVolume` = 0 (o `Default` só liga queda). Surgem `HistoricoInsuficiente` e, se o dado permitir, `Cruzada` com `ProductFamily__c` preenchido. `QuedaVolume` e `AltaVolume` antigos (sem família) somem; os novos têm `ProductFamily__c` e `BasePeriodQuantity__c`/`UnitOfMeasure__c` coerentes.
3. `Recuperacao` só com `DaysWithoutPurchase__c` > 90; nenhuma conta em Recuperacao/NuncaComprou com sinal de volume (PA-27); `Cruzada` nunca com família "Sem familia".
4. Sem duplicata de `SignalKey__c` (CA-15) e contagem `Cruzada` por conta <= 3.
5. Account, Order, OrderItem, Opportunity: contagens e maiores LastModifiedDate iguais aos de antes (CA-12), nenhum `EmailMessage` novo originado do job (CA-19).
6. Relatório `CommercialSignals_ByAccount` com as colunas novas (CA-14: só ID, nome, tipo, métrica, datas; sem e-mail, telefone, CPF).
7. CA-13 (carteira por compartilhamento) e CA-18 (amostra contra o Protheus): fase 2 com o usuário de teste `005bJ00000hBJmYQAW` (conta Konecta `.eplast.qas`, acesso negado) e roteiro do cliente.

## O que pode ter saído da org

Nenhum e-mail nem chamada externa: o job só lê Order/OrderItem/Account e grava `CommercialSignal__c`. A conferência da fase 2 registra o resultado.
