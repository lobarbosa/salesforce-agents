**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-33 — Testes na QA, fase 2 (conferência)

Org confirmada por `sf org list`: `sbx-eplast-qa` (QAS da Eplast, Org Id 00DHa000006vZtmMAE, usuário de execução `005bJ00000piKAaQAM`). Escopo: o do gate de 17/11 (sem a consulta pelo assistente). Os CA-* de `01-analise.md` são da rodada anterior (61 dias, 30%) e foram lidos contra os valores aprovados no design de 17/11 (90 dias, 20%, por família, histórico insuficiente, cruzada por `Sector__c`). Deploy conferido em `05-deploy-qa.md` (0AfHa00000EJKsbKAH, Succeeded). Esta é a primeira rodada reprovável: não há `05-testes-rodada-<n>.md` anterior; o `05-testes.md` que existia era a fase 1 (aguardando execução).

## Falhas (nenhuma bloqueia o aceite)

### FALHA 1 (branda) — o job agendado falha se quem agenda não tem o permission set `PS_Comercial_SinaisComerciais`
- Reproduzir: usuário sem o permission set agenda `CommercialSignalScheduler` (foi o caso do arme das 14:41 UTC, porque a fase 1 removeu a atribuição do usuário de execução ao terminar, como a regra da esteira exige).
- Obtido: `CronTrigger` 08eHa00000XthL2IAJ disparou às 14:41:00 UTC (`TimesTriggered` 1); `CommercialSignalGroupStatsBatch` Completed sem erro; `CommercialSignalBatch` 707Ha00001EGLEcIAP terminou com 13 de 13 lotes com erro (`ExtendedStatus`: "No such column 'SignalKey__c' on entity 'CommercialSignal__c'"). Nenhum sinal foi gravado (contagem seguiu 1358, `ProductFamily__c` preenchido 0).
- Reexecução com o permission set atribuído ao mesmo usuário (`new CommercialSignalScheduler().execute(null)`, 14:59 UTC): 0 erros em 13 lotes, sinais gravados (casos abaixo). Portanto a causa é a falta de permissão de campo de quem executa o job (o `upsert` por `SignalKey__c` roda com a permissão de campo do usuário do agendamento), não a lógica.
- Esperado: o job rodar com quem a Eplast agendar. Sugestão ao builder, sem bloquear: registrar no design/roteiro que o usuário que agenda tenha o permission set (ou administrador), ou gravar em modo sistema.
- Não bloqueia: com o permission set o job funciona; a produção agenda com um administrador. Registrado no roteiro do cliente.

### Observação (sem prova de defeito) — jobs em dobro
Em cada execução, `AsyncApexJob` mostra duas linhas de `CommercialSignalGroupStatsBatch` (12/12 lotes) e duas de `CommercialSignalBatch` (13/13), tanto no disparo agendado quanto na execução manual. O código do `finish` encadeia uma só execução; não consegui explicar a duplicidade. O efeito é inofensivo (gravação por chave, 0 duplicatas de `SignalKey__c`), mas vale o builder conferir.

## Casos executados

| Caso | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|
| Q1 Componentes do `05-deploy-qa.md` na org | `ApexClass`, `FieldDefinition` (Tooling) | 9 classes; 4 campos novos no sinal; 6 no CMDT | Fase 1: 9 classes Active; campos presentes | passou |
| Q2 CA-17 parâmetros no `Default` | query no CMDT | 90 dias, 20, Queda, `Sector__c`, `EffectiveDate`, `Group__c`, base mínima 2, `Faturamento;Concluido` | 1 registro com os valores | passou |
| Q3 CA-20 suíte Apex (91/90/89 dias, 20,0%/19,99%, histórico, família, segmento < 5, bulk 200, idempotência, sem escrita comercial) | `sf apex run test` na QA | 0 falhas, cobertura >= 85% | 66 testes, 0 falhas; cobertura Service 273/273, Scheduler 5/5, Batch 109/111, GroupStats 52/54 | passou |
| Q4 Job agendado dispara no horário | `CronTrigger` 08eHa00000XthL2IAJ | `PreviousFireTime` 14:41 UTC, `TimesTriggered` 1 | PreviousFireTime 2026-11-17T14:41:00Z, TimesTriggered 1, estado DELETED (encerrou) | passou (o disparo); a gravação falhou, ver FALHA 1 |
| Q5 Execução com a permissão correta grava os sinais | execução do mesmo ponto de entrada, 14:59 UTC | jobs sem erro | GroupStats 12/12 e Batch 13/13, `NumberOfErrors` 0 | passou |
| Q6 Tipos de sinal depois da execução | `COUNT` por `Type__c` | Alta = 0; surgem Histórico insuficiente e Cruzada | Cruzada 581; NuncaComprou 640; HistoricoInsuficiente 41; Recuperacao 432; QuedaVolume 136; AltaVolume 0 (total 1830, antes 1358) | passou |
| Q7 Recuperação > 90 dias (PA-30) | `Recuperacao` com `DaysWithoutPurchase__c` <= 90; mínimo | 0; mínimo 91 | 0 registros; mínimo 91 | passou |
| Q8 Queda por família, mês fechado, >= 20% | QuedaVolume sem família; variação < 20 | 0 | 0 sem família; 0 com variação < 20. Todas as 136 têm variação 100%, coerente com a QAS: 0 pedidos faturados em outubro/2026 (último pedido faturado 2026-09-23) e 944 em jul-set | passou (limites 20%/19,99% provados pela suíte Apex; a QAS só exerce 100%) |
| Q9 Histórico insuficiente | `HistoricoInsuficiente` com família nula | 0 sem família | 41 com família preenchida | passou |
| Q10 Unidade de medida e mistura (PA-25) | QuedaVolume por `UnitOfMeasure__c` | `MISTA` sem somar | UN 130, MISTA 3, SEMUNIDADE 3 | passou |
| Q11 PA-27 sem sobreposição | Apex anônimo só com contagens: contas com volume x contas Recuperação/NuncaComprou | 0 | sobreposição 0 (151 contas com volume, 1072 em recuperação/nunca comprou) | passou |
| Q12 Cruzada: sem "Sem familia" e <= 3 por conta | contagens | 0 e 0 | 0 com "Sem familia"; nenhuma conta com mais de 3 | passou |
| Q13 CA-15 sem duplicata | `GROUP BY SignalKey__c HAVING COUNT > 1` | vazio | vazio | passou |
| Q14 CA-12 não escreve em objetos comerciais | contagem e maior `LastModifiedDate` depois | iguais às de antes | Order 10321 / 2026-11-16T01:48:10Z; OrderItem 10008 / 2026-11-13T19:06:52Z; Account 1223 / 2026-11-17T13:15:54Z; Opportunity 9341 / 2026-11-17T11:06:24Z; todos idênticos aos da fase 1 e anteriores ao job | passou |
| Q15 CA-19 sem e-mail | `EmailMessage` criados desde 14:40 UTC | 0 | 0 | passou |
| Q16 CA-14 relatório (colunas) | retrieve do relatório `CommercialSignals_ByAccount` da QA | colunas novas, sem dado pessoal | Id, nome, Ranking, `Sector__c`, `BillingState`, família, produto, dias, valores e quantidades atual/base, unidade, variação, datas, motivo, tipo; sem e-mail, telefone ou CPF | passou |
| Q17 PA-23 data de faturamento | contagem de pedidos faturados com `IssuanceDate__c` preenchido | decidir campo | 0 de 8095 com `IssuanceDate__c`; `EffectiveDate` está certo como padrão | passou (dado para a homologação) |
| Q18 Sinais por conta com segmento | `Account.Sector__c` preenchido | informativo | 1182 de 1223 contas | informativo |
| CA-13 carteira por compartilhamento (acesso negado) | usuário de teste `005bJ00000hBJmYQAW` | sem acesso ao objeto/sinais | **sem prova**: o usuário está inativo na QAS (perfil Administrador do sistema, que já lê o objeto); não consigo simular. Fica no roteiro do cliente | sem prova |
| CA-18 amostra contra o Protheus | conferência com o ERP | amostra bate | **sem prova**: depende de pessoa da Eplast; fica no roteiro | sem prova |
| Volume/CPU (design, seção 3) | execução sobre 1223 contas | sem estouro | 13 lotes sem erro de limite nas duas execuções com a permissão; não medi CPU nem linhas | informativo |

Telas: não abri a Lightning (QA via CLI e consultas agregadas; nenhuma tela de registro de teste necessária). Sem capturas em `evidencias/`.

Contagem: 16 passaram, 0 reprovaram, 2 sem prova (CA-13 e CA-18, ambos de acesso/ERP, tratados no roteiro do cliente), 1 falha branda (FALHA 1) e 1 observação. O aceite principal (cálculo, limites, parâmetros, sem escrita, relatório) foi executado e comprovado, por isso `aprovado`.

## Mudanças no meu usuário de execução (QA)

- Permission set `PS_Comercial_SinaisComerciais`: fase 1 atribuí e removi; fase 2 atribuí (0PaHa00000EMANHKA5) e **removi** (consulta confirma 0 atribuição). Perfil, papel e outros permission sets intocados. Usuário de teste `005bJ00000hBJmYQAW` intocado.

## O que pode ter saído da org

Nenhum e-mail (0 `EmailMessage` novo) nem chamada externa: o job lê Order/OrderItem/Account e grava `CommercialSignal__c` (1830 sinais depois da execução). Nada no Marketing Cloud. Estado deixado na QA: sinais recalculados pela execução das 14:59 UTC; o `CronTrigger` do arme já encerrou (nada a abortar). A esteira reimplanta o build original depois da sessão; o job oficial (`0 0 1 * * ?`) não está agendado na QA (foi cancelado antes do deploy) e deve ser agendado por quem tem o permission set.
