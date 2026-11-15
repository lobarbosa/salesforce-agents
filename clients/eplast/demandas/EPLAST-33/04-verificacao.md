**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast, Org Id 00DHa000006vfMLMAY, única org em `sf org list`, Connected; regra 5 da conta)

# EPLAST-33 — Reverificação do build

Aprovada com ressalvas. Reexecutei a suíte Apex na dev e consultei a metadata. Não criei dado de teste próprio: a dev tem 0 contas e 0 pedidos, e criar Account dispara `AccountTrigger` (CNPJ e consulta externa à BrasilAPI). A suíte do builder usa fixture com contorno oficial (`TriggerUtility.bypassTrigger`) e limpa os próprios dados. Nada saiu da org por minha ação.

## Evidência executada

- Rodada paralela das 4 classes (`--code-coverage`), Test Run Id `707Ha00001E0T6X`: 38 testes, 37 passaram, 1 falhou (`CommercialSignalBatchTest.doesNotWriteToCommercialObjects`, `UNABLE_TO_LOCK_ROW` no insert de Account da fábrica). É o intermitente que o plano (4.6) já registra: concorrência entre classes de teste na mesma org, fora da lógica da entrega (o batch não escreve em Account).
- Reteste em série (`--synchronous`), classe a classe: `CommercialSignalBatchTest` 12/12, `CommercialSignalServiceTest` 15/15, `CommercialSignalGroupStatsBatchTest` 8/8, `CommercialSignalSchedulerTest` 3/3 = 38/38 (100%). O teste que falhou, rodado isolado, passou.
- Cobertura: `CommercialSignalService` 99%, `CommercialSignalGroupStatsBatch` 98%, `CommercialSignalBatch` 97%, `CommercialSignalScheduler` 100%.
- `CommercialSignal__c`: 0 registros; Account: 0 (nada ficou das suítes).
- `ApexTrigger` com nome contendo "Signal" ou "Commercial" em Account, Order, OrderItem e Opportunity: 0. Triggers preexistentes (Account 2, Opportunity 3, Order 2, OrderItem 1) não são da entrega.
- `FlowDefinition` com "Signal" ou "EPLAST33" no nome: 0.
- `CustomField` de `CommercialSignal__c` com nome tipo e-mail, telefone ou CPF: 0.
- Relatório `CommercialSignals_ByAccount`: 1 registro em `Report`. Colunas conferidas no `.report-meta.xml` do repositório: Account Id, nome, `Ranking__c`, e os campos de sinal (tipo, produto, datas, valores, variação, motivo). Nenhum campo de contato.
- Job agendado: `CronTrigger` "EPLAST33 Sinais Comerciais" estava `0 0 1 * * ?`, WAITING, próxima execução 2026-11-16 04:00 UTC (agendamento provado). Depois disso abortei o job na dev (`System.abortJob`; consulta posterior: 0 jobs EPLAST33), para não travar o deploy e a validação do PR (achado EPLAST-33). A esteira reagenda na QA, em duas sessões.

## Automação concorrente (assessment)

A entrega não escreve em Account, Opportunity, Order nem OrderItem e não cria trigger nem Flow neles. Não entra na ordem de execução do `AccountTrigger`, do `OrderTrigger`, do CPQ (SBQQ) nem dos Flows existentes. A única contenção observada foi o `UNABLE_TO_LOCK_ROW` nas fixtures de teste em execução paralela, que desaparece em série.

## Tabela por critério

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V-01 | CA-01, CA-02 | Testes do serviço e do lote (61, 60, 59 dias), em série | 61 entra; 60 e 59 não | Passaram | passou |
| V-02 | CA-03, CA-04 | Conta sem pedido; pedido cancelado e em processo | "Nunca comprou" gerado; pedidos inválidos não contam | Passaram | passou |
| V-03 | CA-05, CA-06, CA-07 | 30% exato, 31%, queda, alta, base zero | Só acima de 30% classifica; sem base não classifica | Passaram | passou |
| V-04 | CA-08 a CA-11 | Cruzada: 4 de 10, 2 de 10, compra recente, sem Industry, grupo de 4 | Só as regras do design geram sinal | Passaram | passou |
| V-05 | CA-12 | Contagens e `LastModifiedDate` de objetos comerciais antes e depois; sem `EmailMessage` | Nenhuma escrita comercial | Teste passou, após reteste em série da rodada com lock | passou |
| V-06 | CA-13 | Teste de permissão (sem permission set não lê; com ele lê e não cria) | Acesso só pelo permission set | Passou; visibilidade por conta não provável na dev (OWD de Account ReadWrite) | passou em parte |
| V-07 | CA-14 | Consulta de campos de contato no objeto e colunas do relatório | Nenhum campo de contato | 0 campos; colunas sem contato | passou |
| V-08 | CA-15, CA-16 | Reexecução; pedido novo entre execuções | Sem duplicata; recuperação removida | Passaram | passou |
| V-09 | CA-17 | Parâmetro de 90 dias no CMDT | Classificação muda sem alterar código | Passou | passou |
| V-10 | CA-20 | Cobertura e nomenclatura | 85% ou mais por classe | 97% a 100%; 4 classes `*Test` | passou |
| V-11 | CA-21 | Triggers e Flows novos em objetos comerciais | Nenhum | 0 triggers, 0 Flows | passou |
| V-12 | Agendamento | `CronTrigger` antes de abortar | Diário às 04:00 UTC | `0 0 1 * * ?` (America/Sao_Paulo), próxima 2026-11-16 04:00 UTC; job abortado depois | passou |
| V-13 | CA-19 | Metadata: sem envio, Flow ou Campaign no build | Nada dispara pelo CRM | Sem componente de envio; público é a lista | passou |
| V-14 | CA-18 | Amostra do Comercial contra o Protheus | Lista bate | Critério de homologação | não executado |

## O que pode ter saído da org

Nada. Não criei registros que disparassem automação. A suíte não chama sistema externo (bypass do `AccountTrigger`, envio ao Protheus evitado pelo usuário `integracao*` de teste).

## O que ficou sem prova

1. **CA-18**: validação de negócio pelo Comercial contra o Protheus (homologação).
2. **CA-13, visibilidade por conta**: exige compartilhamento real, na QA.
3. **Relatório aberto com dados**: a dev está vazia; foi conferido só como existente e pelas colunas do metadata. Abrir na QA depois de agendar o job e conferir.
4. **Volume sintético** (1 conta com 5 mil itens; 1.000 contas em 3 grupos): não medido. Criar contas na dev exige bypass do trigger fora de teste; ficou para a QA.
5. **Intermitência** `UNABLE_TO_LOCK_ROW`: se a QA rodar a suíte em paralelo, pode reaparecer; rodar em série.
