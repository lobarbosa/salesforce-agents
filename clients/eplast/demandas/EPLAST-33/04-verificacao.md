**Verificação:** aprovada
**Org de teste:** sbx-eplast-dev (alias `sbx-eplast-dev`, Org Id 00DHa000006vfMLMAY, conferida com `sf org list`; única org conectada)

# EPLAST-33 — Verificação do build (rodada 17/11)

Escopo: o do gate de 2026-11-17. A consulta pelo assistente (`CommercialSignalAgentAction`, `SFAgent2`) está fora e não foi verificada.
Os CA-* de `01-analise.md` são da rodada anterior (61 dias, 30%). Os critérios foram lidos contra os valores aprovados no design de 17/11 (90 dias, 20%, por família, histórico insuficiente, cruzada por `Sector__c`).

## Resultado resumido
A metadata está presente e correta, e os 66 testes Apex passam com cobertura acima de 85% em todas as classes. Dois pontos não foram exercitados com dado fora do teste Apex: volume/CPU e o acesso por usuário com permission set. Estão em "Sem prova".

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | Parâmetros do `Default` | `sf data query` em `CommercialSignalSetting__mdt` | 90 dias; 20%; `Queda`; `Sector__c`; janela 3; `EffectiveDate`; `Group__c`; base mínima 2; `Valor`; `Familia`; excluídas vazio; `Faturamento;Concluido` | Valores idênticos aos previstos (1 registro) | passou |
| 2 | Campos novos em `CommercialSignal__c` | `FieldDefinition` (Tooling) | `ProductFamily__c` Text(40), `UnitOfMeasure__c` Text(20), 2 quantidades Number(16,2) | 4 campos presentes com esses tipos | passou |
| 3 | Campos novos no CMDT | `FieldDefinition` | 6 campos | `PurchaseDateField__c`, `FamilyField__c`, `VolumeMinBaseMonths__c`, `VolumeMetric__c`, `CrossSellLevel__c`, `CrossSellExcludedFamilies__c` presentes | passou |
| 4 | Valor `HistoricoInsuficiente` no tipo | Retrieve de `CommercialSignal__c.Type__c` e grep | Valor presente | Presente | passou |
| 5 | Tipo de relatório com colunas novas | Retrieve de `Accounts_with_CommercialSignals` | `Sector__c`, `BillingState`, `ProductFamily__c`, 2 quantidades, unidade | Os 6 presentes | passou |
| 6 | Relatório com colunas novas | Retrieve de `CommercialSignals_ByAccount` (pasta `EPLAST33_SinaisComerciais`); existe na dev com Id `00OHa000002zFx3MAE` | Mesmas 6 colunas | Os 6 presentes | passou |
| 7 | FLS no permission set | Retrieve de `PS_Comercial_SinaisComerciais` | 4 campos novos, só leitura | `readable=true`, `editable=false` nos 4 | passou |
| 8 | Regras de negócio (91/90/89 dias; 20,0% entra e 19,99% não; média com mês sem compra; histórico de 1 e 2 meses; `MISTA`; cruzada por família e segmento < 5; troca de `PurchaseDateField__c` sem deploy; bulk de 200; idempotência; sem escrita em Account/Order/OrderItem/Opportunity) | `sf apex run test` das 4 classes `CommercialSignal*Test`, rodado por mim na dev | Todos passam | 66 testes, 100% de aprovação, 0 falha | passou |
| 9 | Cobertura ≥ 85% por classe | `--code-coverage` | ≥ 85% | Service 100%, Scheduler 100%, Batch 98% (linhas 85, 94), GroupStatsBatch 96% (linhas 21, 22) | passou |
| 10 | Sem job agendado na dev | Contagem de `CronTrigger` com nome `EPLAST33%` e de `AsyncApexJob` pendente das classes `CommercialSignal*` | 0 | 0 e 0 | passou |
| 11 | Sem escrita no Marketing Cloud, sem Flow/agente alterado | Leitura do plano e dos nomes dos componentes; sem Flow nem versão de agente no plano | Nenhum | Nenhum no plano. Não conferi por diff de metadata | passou (por declaração do plano) |

## Premissas conferidas
PA-23 a PA-30 (do design) estão refletidas no `Default` (data = `EffectiveDate`, status `Faturamento;Concluido`, família = `Group__c`, base mínima 2, 91 dias, `BillingState` só como coluna de relatório). Nenhuma foi tratada como motivo de reprovação (regra 4 da conta).

## Dados de teste e limpeza
- Nenhum dado criado por mim. Os testes Apex criam e descartam os próprios dados na transação do teste.
- Não existe `clients/eplast/fixtures/` neste checkout, então não havia fixture de Order/OrderItem. A dev está sem pedidos, segundo o plano.
- Nenhuma alteração no meu usuário de execução. Nenhum permission set atribuído. Nenhum job criado.
- Os arquivos retrieved ficaram em `/tmp` e foram descartados.

## O que pode ter saído da org
Nada. Nenhum registro foi criado fora de testes Apex e não houve chamada externa.

## Sem prova (o que uma pessoa precisa fazer)
1. **Volume/CPU** (design, seção 3: 1 conta com ~5 mil itens; voltar ao gate se algum limite passar de 70%). Não medido. A dev não tem pedidos e os testes usam poucos registros. Medir na QAS, rodando o job sobre o dado existente (autorizado pela regra 5 da conta).
2. **Execução do batch encadeado com dados em registros reais**, **Order/OrderItem de verdade** e **execução agendada**. Não exercitados. O que prova o comportamento são os testes Apex do builder, que passaram na minha execução, mas eles usam dados da `CommercialSignalTestFactory`.
3. **Abertura do relatório e acesso por usuário.** Confirmei as colunas e o FLS por metadata, mas não abri o relatório pela tela nem testei um usuário com e sem `PS_Comercial_SinaisComerciais`. O teste Apex só cobre "permission set só leitura".
4. **Aceite de negócio** (amostra do Comercial, CA-18) e a validação das premissas ficam para a homologação.

## Observações sobre a org
- Cobertura geral da org: o plano cita 48% e não a recalculei. Pelas classes desta demanda ficou 96% a 100%.
- Concorrência com CPQ em `Order`/`Opportunity`: a solução não escreve nesses objetos (teste `doesNotWriteToCommercialObjects` passou). Não observei conflito.
- Desvio registrado pelo builder: `PS_Marketing_SugestaoCampanha` não foi alterado (é da EPLAST-46). Não é defeito desta construção.
- Dívida já registrada: `CommercialSignalBatch` e `CommercialSignalGroupStatsBatch` são `without sharing`, com justificativa no cabeçalho.
