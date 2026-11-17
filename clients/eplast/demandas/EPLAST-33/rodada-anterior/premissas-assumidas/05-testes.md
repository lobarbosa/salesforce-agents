**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa` (sandbox `eplast--qas`, Partial Copy; usuário de execução `005bJ00000piKAaQAM`)

# EPLAST-33 — Testes na QA, fase 2 (conferência) — veredito final

Org confirmada por `sf org list` (só `sbx-eplast-qa` conectada). Conferência feita em 2026-11-16T01:38Z, depois de `Conferir depois de` (01:35Z). A org estava como armada na fase 1. Nenhuma falha. Ressalvas de cobertura (não são falhas) na seção final.

## Execução agendada (arme da fase 1)
- CronTrigger `08eHa00000Xr7aEIAR`: `PreviousFireTime` 2026-11-16T01:20:00Z, `TimesTriggered` 1 (estado DELETED por ser disparo único, como previsto).
- `AsyncApexJob`: `CommercialSignalGroupStatsBatch` Completed, 8/8 lotes, 0 erros (01:20:02Z); `CommercialSignalBatch` Completed, 13/13 lotes, 0 erros (01:20:15Z).

## Casos (evidência de antes e depois, só contagens agregadas)
| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| CA-03/04 Nunca comprou | `SELECT Type__c, COUNT(Id) FROM CommercialSignal__c GROUP BY Type__c` | 637 (1.220 contas − 583 com pedido válido); pedido cancelado/em processo não conta | NuncaComprou = 637; 0 desses com `LastPurchaseDate__c` preenchido | aprovado |
| CA-01/02 Recuperação (>60 dias) | Mesma contagem + MIN/MAX de `DaysWithoutPurchase__c` | 530 (ou 533 se a data virasse 16/11); todos > 60 | Recuperacao = 530; dias mín. 61, máx. 807 | aprovado |
| CA-05/06 Queda e Alta (>30% estrito) | MIN/MAX de `VariationPercent__c` e MIN de `BasePeriodAmount__c` por tipo | Só variação > 30 e base > 0 | QuedaVolume = 169 (variação 30,7 a 100); AltaVolume = 22 (30,4 a 210,8); base mínima 10,6 (> 0) | aprovado |
| CA-07 Sem base não entra em volume | Base mínima > 0 (acima) | Nenhum sinal de volume com base 0 | Base mínima 10,6 | aprovado |
| CA-08/09/11 Cruzada (resultado real) | Apex anônimo somente leitura (agregado por Setor e produto, 12 meses, status Faturamento/Concluido, grupo ≥ 5) | Nenhum sinal se nenhum produto chega a 30% do grupo | Cruzada = 0 sinais. Conferência independente: 0 combinações setor-produto com ≥ 30% das contas do grupo; maior participação 10,3% (28 de 272, Bebidas). Zero é o resultado correto na base da QAS | aprovado (regras de 30%/31%, 4 de 10 e 2 de 10, grupo 4/5 e 180 dias provadas por teste Apex, ver CA-20; ponta a ponta com sinal gerado não ocorreu por falta de dado que atinja 30%) |
| CA-10 Conta sem Setor | Contagem de Recuperacao+NuncaComprou com Industry nulo; Cruzada = 0 | Fica nos outros tipos, fora da cruzada | 437 sinais Recuperacao/NuncaComprou em contas sem Setor; 0 Cruzada | aprovado |
| CA-12 Não escreve em objetos comerciais | Contagens e maior `LastModifiedDate` depois | Iguais ao antes | Account 1.220 (igual); Order 10.320 (igual), máx. 2026-11-13T19:08:09Z (igual); OrderItem 10.008 (igual), máx. 2026-11-13T19:06:52Z (igual); Opportunity 9.332 (igual), máx. 2026-11-15T23:30:14Z (igual ao antes); Account máx. 2026-11-15T23:30:14Z (igual); EmailMessage 805 (igual) | aprovado |
| CA-15 Idempotência / unicidade | `GROUP BY SignalKey__c HAVING COUNT(Id) > 1` | 0 duplicatas | 0 linhas; total 1.358 = 637+530+169+22; todas com `CalculationDate__c` 2026-11-15 | aprovado |
| CA-14 Sem dado de contato | `sf project retrieve` do relatório `CommercialSignals_ByAccount` na QA e leitura das colunas | Sem e-mail/telefone/CPF | Colunas: Id e Nome da conta, Ranking, Produto, Dias sem compra, valores base/atual, variação, última compra, motivo, data de cálculo, tipo. Nenhum campo de contato | aprovado (metadados); abertura com dados na tela: não executada, ver abaixo |
| CA-13 parte permissão | Antes de atribuir o permission set a mim: `SELECT COUNT() FROM CommercialSignal__c WHERE SignalKey__c != null` | Sem acesso ao campo | `No such column 'SignalKey__c'` | aprovado |
| CA-16/17 Pedido novo / parâmetro | Suíte Apex da QA | Asserts passam | Passam (Run `707Ha00001E4Kfo`) | aprovado (teste Apex) |
| CA-20 Cobertura e nomenclatura | `sf apex run test -o sbx-eplast-qa`, 4 classes, com cobertura | 85% por classe | 41/41 passam. Service 99%, GroupStatsBatch 98%, Batch 97%, Scheduler 100% | aprovado |
| CA-21 Sem Flow/trigger/validation novo em objetos comerciais | Leitura de `05-deploy-qa.md` | Nenhum | 0 itens de flow, trigger ou validationRule na lista de componentes | aprovado |
| Componentes do deploy na org | Objeto `CommercialSignal__c`, CMDT (1 registro `Default`), permission set, relatório (`00OHa000002zH7dMAE`), classes | Existem | Todos encontrados | aprovado |

## Não executados / sem prova pela tela
- **CA-18 (amostra do Comercial) e CA-19 (Marketing Cloud):** não executáveis na esteira (validação de negócio e Marketing Cloud, fora do escopo). Ficam para a homologação, no roteiro do cliente.
- **CA-13 visibilidade por conta (usuário A não vê conta de B):** só a parte de permissão foi provada; o compartilhamento depende do objeto "controlado pelo pai" (design PA-17) e de um segundo usuário com compartilhamento real. O usuário de teste da conta (`005bJ00000hBJmYQAW`) está inativo na QAS; o `005bJ00000piKAaQAM` (usuário de execução) é outra conta de serviço Administrador. Fica no roteiro do cliente.
- **Abertura do relatório pela UI:** a sessão `qa_browser` abriu a Lightning, mas o relatório só mostra contas reais da Partial Copy; não foi capturado (guardrail de dados reais). Verificado por metadados.

## O que foi alterado e desfeito
1. Permission set `PS_Comercial_SinaisComerciais` atribuído ao usuário `005bJ00000piKAaQAM` (antes: 0 atribuições). **Desfeito:** `PermissionSetAssignment` `0PaHa00000EJfLyKAL` removido; contagem de atribuições do PS = 0.
2. Job de uma vez só `EPLAST33 QA arme` (`08eHa00000Xr7aEIAR`): já executado e removido pela plataforma; nada a abortar.
3. **Agendamento do design:** por Apex anônimo, `CommercialSignalScheduler.scheduleDaily(JOB_NAME)` criou o job `EPLAST33 Sinais Comerciais` (`08eHa00000Xr4SZIAZ`), diário 04:00 UTC, `NextFireTime` 2026-11-16T04:00:00Z, WAITING (design PA-22). Não commitado.
4. Nenhum perfil, papel, outro permission set ou usuário alterado. Nenhum campo de usuário alterado.

## O que pode ter saído da org
Registros criados: 1.358 `CommercialSignal__c` (resultado da própria solução, contados acima). Nenhum e-mail, callout ou integração disparada (EmailMessage 805, igual). Nenhum dado de teste persistido meu em Account/Order/OrderItem (`fixtures/` não existe no cliente).

## Observação para o time
Os 1.358 sinais gerados ficam na QAS. A próxima execução do job diário recalcula e atualiza por `SignalKey__c`, sem duplicar.
