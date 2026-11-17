**Solução:** mista
**Org consultada:** `sbx-eplast-dev` (única org conectada em `sf org list` nesta sessão, sandbox, API 68.0)

# EPLAST-33 — Design da solução (cross-sell, volume e recuperação)

**Etapa:** 3 (design, `arquiteto`) · **Data:** 2026-11-15 · **Entradas:** `01-analise.md` (aprovada em 2026-11-15, em lote, com a ressalva no card de que as premissas devem ser conferidas neste gate), `02-recon.md` (2026-11-15), `assessment.md`, RAG do cliente. A rodada anterior (`rodada-anterior/03-design.md`) foi usada só como referência: a opção C dela (Apex agendado + objeto de resultado) é retomada aqui, agora como recomendação e não mais como alternativa condicionada a perguntas abertas.

Confirmado nesta sessão por `sf` (só metadata e contagens): versão ativa de `ScheduledFlowOpportunity` (v2, ativa desde 2026-11-14, EPLAST-47) e seu agendamento diário 15:47 UTC; descrição de `Account.Ranking__c` e `Account.LastMonthPurchaseValue__c`; `Order.OpportunityId`, `EffectiveDate`, `TotalAmount`; lógica do Flow `Order` (pedido `Concluido` → oportunidade `Fechado/Ganho`; `Cancelado` → `Fechado/Perdido`); `Account.Industry` com 32 valores ativos, picklist não restrita; jobs agendados ativos (`OrderScheduledFlow` 06:00 UTC, `Logs_Delete_Records` 02:00 UTC, `CreationPriceBook` 17:36 UTC); ausência de qualquer objeto, CMDT ou classe com nome `CommercialSignal*`; objetos `et4ae5__IndividualEmailResult__c`, `et4ae5__SendDefinition__c`, `et4ae5__Automated_Send__c`; campos `Contact.HasOptedOutOfEmail` e `Contact.et4ae5__HasOptedOutOfMobile__c`; campos de erro das 17 validation rules ativas de Order.

---

## 1. Decisão e porquê

**Decisão:** cálculo em **Apex assíncrono agendado** (Batch + Schedulable), parâmetros em **Custom Metadata Type**, resultado gravado num **objeto custom novo filho de Account** (master-detail), exibido e exportado por **relatório** sobre um tipo de relatório custom. Nenhuma escrita em Account, Opportunity, Order ou OrderItem. `SFAgent2` não é alterado.

Doutrina aplicada (skill `salesforce-doutrina`, ordem configuração → Flow → código):

| Nível | Avaliado para | Por que não basta |
|---|---|---|
| Configuração (relatório, filtro cruzado, roll-up, fórmula) | Recuperação e "Nunca comprou" cabem num relatório de Account com filtro cruzado "sem pedidos" + subfiltro de status e `EffectiveDate` | Resolve 2 dos 5 tipos e sem a métrica "dias sem compra" (RF-2). Queda/alta de volume exigem comparar soma de dois períodos por conta e filtrar pelo percentual: relatório não filtra por fórmula de resumo. Cruzada exige estatística grupo × produto: impossível em relatório. Roll-up de Order em Account não existe (lookup) e criaria escrita em Account. Usar relatório para 2 tipos e outro meio para 3 espalharia os parâmetros em dois lugares (fere RF-5 e CA-17) |
| Declarativo (Flow agendado) | Recalcular os 5 tipos por conta | Flow não agrega (não há GROUP BY nem COUNT DISTINCT em Get Records); a cruzada exigiria laços aninhados conta × pedido × item, com risco de limite de elementos e de CPU no volume de produção (não medido). Os 21 critérios de aceite fixam limites exatos (59/61 dias, 30%/31%, grupo de 4/5): a doutrina manda código quando é preciso "teste unitário determinístico sobre a regra" e há "volume alto com risco de limite" |
| **Código (Apex Batch)** | Os 5 tipos numa passada única, com consultas agregadas por lote | Escolhido. Uma regra só, um lugar de parâmetros, testável a 85% |

Configuração continua sendo usada onde basta: parâmetros (CMDT), modelo do resultado (objeto + campos), visibilidade (master-detail, "controlado pelo pai"), saída (tipo de relatório + relatório), acesso (permission set).

**Mudança de modelo de dados — decisão de arquitetura sênior, escalada a este gate.** O objeto `CommercialSignal__c` é novo. Pela regra do papel, eu recomendo, mas não decido: o arquiteto humano aprova ou recusa explicitamente. Alternativa sem objeto novo, se recusado: componente LWC que calcula sob demanda para o usuário (sem persistência). Custo dela: a cruzada precisa da base inteira a cada abertura (risco de limite síncrono de 10 s de CPU e 50 mil linhas), não gera relatório exportável para o Marketing Cloud (fere CA-19) e não é idempotente por construção. Por isso não é a recomendação.

## 2. Item a item: o que reaproveita e o que cria

### 2.1 Reaproveita (sem alterar)

| Item | Confirmado | Como entra |
|---|---|---|
| `Order.Status`, `EffectiveDate`, `TotalAmount`, `AccountId`; `OrderItem.Product2Id`, `OrderId` | sim | Fonte da compra (PA-2, PA-3, PA-4) |
| `Account.Industry` | sim (32 valores, não restrita) | Grupo da cruzada (PA-7) |
| `Account.Ranking__c` | sim. Descrição: faixa da média de compras do ano, gravada por `ScheduledFlowOpportunity` | **Só coluna de contexto no relatório.** Não é recalculado nem usado na regra (PA-16) |
| Flow `ScheduledFlowOpportunity` (v2 ativa, EPLAST-47) | sim | **Não é alterado nem duplicado.** Calcula faixa de porte (MP…3G) por média anual de oportunidades ganhas; EPLAST-33 calcula recência, tendência e cruzada. Conceitos diferentes, sem segundo ranking (PA-16) |
| Agente `SFAgent2` (`SFAgent2_v1`–`v4`, ações `ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta`, `QueryRecords`) | existência sim; régua interna não relida | Não alterado na v1 (PA-1). Default de 60 dias e 30% do CMDT alinhado à régua que a recon anterior atribui a ele. Fase 2: nova ação do `SFAgent2` lendo `CommercialSignal__c`, sem agente novo |
| 18 relatórios de pedido/cliente (`PEDIDOS POR CLIENTE` etc.) | nomes sim; filtros não lidos | Não alterados. Nenhum deles pode entregar volume ou cruzada (limite de relatório, seção 1); o novo relatório não os substitui |
| Pacote `et4ae5`, `Campaign`, `CampaignMember` | sim | Não alterados (seção 5) |

### 2.2 Não reaproveita, de propósito

| Item | Por quê |
|---|---|
| `Account.LastMonthPurchaseValue__c` | Descrição na org: soma das ganhas do ano, apesar do rótulo (EPLAST-47). Não serve como base de 3 meses |
| `Account.TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c`, `LastPurchase__c` | Sem descrição (achado 4); quem os grava não foi identificado |
| `RankingRange__mdt`, `ScheduledFlowOpportunitySetting__mdt` | Pertencem ao Flow da EPLAST-47; misturar parâmetros acoplaria as duas demandas |
| `IntegrationLog__c` | Log de integração Protheus; não é log de cálculo |

### 2.3 Cria (nomes propostos; nenhum existe na org — confirmado)

Convenção: o `CLAUDE.md` da Eplast não define prefixo; os campos custom da org seguem inglês sem prefixo (`Ranking__c`, `LastPurchase__c`), e é esse padrão que se segue. Todo componente sai com `Description` preenchida (achado 4).

| Tipo | API name | Conteúdo |
|---|---|---|
| Objeto custom | `CommercialSignal__c` ("Sinal Comercial") | Sharing "Controlado pelo pai". Sem trigger, Flow, validation rule ou roll-up. Nome automático `SC-{000000}` |
| Campo master-detail | `CommercialSignal__c.Account__c` → Account | Visibilidade herdada da conta (CA-13); exclusão em cascata com a conta |
| Picklist restrita | `CommercialSignal__c.Type__c` | `Recuperacao`, `NuncaComprou`, `QuedaVolume`, `AltaVolume`, `Cruzada` |
| Lookup | `CommercialSignal__c.Product__c` → Product2 | Só na Cruzada |
| Date | `LastPurchaseDate__c` | Última compra válida |
| Number(6,0) | `DaysWithoutPurchase__c` | Recuperação |
| Currency | `BasePeriodAmount__c`, `CurrentPeriodAmount__c` | Volume (somas dos dois períodos) |
| Percent(5,1) | `VariationPercent__c` | Volume: variação; Cruzada: % do grupo que comprou o produto |
| Text(255) | `Reason__c` | Motivo legível: métrica, janela, data de referência, valor de comparação (RF-2) |
| Date | `CalculationDate__c` | Data da execução |
| Text(120), External ID, único | `SignalKey__c` | `AccountId-Type-Product2Id`: chave de upsert (CA-15) |
| Custom Metadata Type | `CommercialSignalSetting__mdt`, registro `Default` | `RecoveryDays__c` 60; `PurchaseStatuses__c` "Faturamento;Concluido"; `VolumeWindowMonths__c` 3; `VolumeThresholdPercent__c` 30; `VolumeDirections__c` "Queda;Alta"; `CrossSellGroupField__c` "Industry"; `CrossSellLookbackMonths__c` 12; `CrossSellRecentDays__c` 180; `CrossSellMinSharePercent__c` 30; `CrossSellMinGroupSize__c` 5; `CrossSellMaxPerAccount__c` 10; `BatchSize__c` 100; `IncludeNeverPurchased__c` true |
| Classe Apex | `CommercialSignalService` | Regras puras (classificação, limites estritos), sem SOQL; recebe agregados e parâmetros. `with sharing` não se aplica (sem consulta) |
| Classe Apex | `CommercialSignalGroupStatsBatch` | Fase 1: por lote de contas com grupo preenchido, conta contas distintas por (grupo, produto) nos últimos 12 meses e o tamanho de cada grupo. `Database.Stateful`; no `finish`, encadeia a fase 2 passando o mapa |
| Classe Apex | `CommercialSignalBatch` | Fase 2: por lote de contas, calcula os 5 tipos com consultas agregadas por lote, faz upsert por `SignalKey__c` e apaga os sinais da conta que não se repetiram (CA-15, CA-16). `without sharing` declarado e justificado: a cruzada precisa da base inteira; a visibilidade é aplicada na leitura (PA-17) |
| Classe Apex | `CommercialSignalScheduler` | `Schedulable`; dispara a fase 1 |
| Testes | `CommercialSignalServiceTest`, `CommercialSignalGroupStatsBatchTest`, `CommercialSignalBatchTest`, `CommercialSignalSchedulerTest` | 85% por classe (CA-20); um método por CA-01 a CA-17 e CA-21 (inventário); fixture preenchendo os campos das validation rules ativas de Order e Account (ver 4.3) |
| Tipo de relatório | `Accounts_with_CommercialSignals` | Account (primário) com `CommercialSignal__c` (obrigatório) |
| Pasta de relatório | `EPLAST33_SinaisComerciais` | Compartilhada com quem tem o permission set (via grupo público) |
| Relatório | `CommercialSignals_ByAccount` ("Sinais Comerciais por Conta") | Resumo agrupado por `Type__c`; colunas: Account ID, nome da conta, `Ranking__c`, tipo, produto, `DaysWithoutPurchase__c`, somas, `VariationPercent__c`, `LastPurchaseDate__c`, `Reason__c`, `CalculationDate__c`. **Nenhum campo de contato** (CA-14). Formato copiado de um relatório existente da org (doutrina, achado EPLAST-39) |
| Permission set | `PS_Comercial_SinaisComerciais` | Leitura de `CommercialSignal__c` e FLS dos campos; aba opcional. Sem create/edit/delete. Atribuído ao Comercial e a quem exporta para o Marketing Cloud |
| Grupo público | `EPLAST33_SinaisComerciais` | Acesso à pasta |

### 2.4 Altera / deprecia

Nada. Nenhum perfil é alterado (achado 8: perfis comerciais duplicados).

### 2.5 Passo pós-deploy (sandbox, não metadata)

Agendar `CommercialSignalScheduler` diariamente às 04:00 UTC (01:00 em Brasília) pela tela "Agendar Apex" ou por `System.schedule` na sandbox. Na QA, quem agenda e roda é a esteira/QA conforme o fluxo (agendamento testado em duas sessões).

## 3. Ordem de execução e concorrência

**Account, Order e Opportunity têm trigger próprio, trigger do CPQ (`SBQQ`) e Flows record-triggered after-save no mesmo evento (achado 1, reconfirmado no recon §3). Order tem dois triggers chamados `OrderTrigger` (CPQ e próprio). A ordem entre eles não foi mapeada nem testada.**

Como a solução fica fora dessa cadeia:
- O batch só **lê** Account, Order, OrderItem e Product2. Leitura não dispara trigger, Flow nem validation rule.
- A única escrita é em `CommercialSignal__c`, objeto novo sem automação. Ele não terá roll-up summary em Account: sem roll-up, inserir o filho não salva o pai, então os triggers e Flows de Account não rodam e o `LastModifiedDate` da conta não muda (CA-12 prova isso na QA).
- Os 14 Flows `MCC_*` são `AutoLaunched` (recon), não record-triggered: não reagem à gravação do objeto novo.
- **Bloqueio de linha:** inserir/excluir filho master-detail trava a conta-pai durante a transação. Se a integração Protheus ou um Flow agendado gravar a mesma conta ao mesmo tempo, um dos dois pode receber `UNABLE_TO_LOCK_ROW`. Mitigação: horário 04:00 UTC, longe de `OrderScheduledFlow` (06:00), `ScheduledFlowOpportunity` (15:47), `CreationPriceBook` (17:36) e `Logs_Delete_Records` (02:00); DML com `allOrNone=false`, falhas contadas e expostas no status do job; a execução seguinte recompõe (idempotente). O horário da integração Protheus não foi medido (incerteza I-10).
- Não cria trigger, Flow nem validation rule em Account, Opportunity ou Order (CA-21).

## 4. Governador, escala e CPU

Volume de produção não medido (dev vazia; produção proibida). Desenho para dois cenários (doutrina, achado SOMOSAGILITY-10):

| Cenário | Desenho | Ponto de atenção |
|---|---|---|
| Muitas contas | Batch assíncrono (60 s CPU, 12 MB heap, 50 mil linhas por `execute`). Por lote: ~5 SOQL agregadas (última compra, soma por período, produtos dos últimos 180 dias, sinais existentes, estatística do grupo vinda da fase 1) e 2 DML. Nada por conta dentro de laço | Fase 1 guarda só pares (grupo, produto) com compra: teto teórico 32 × 1.042 ≈ 33 mil, real bem menor |
| Uma conta com muitos pedidos/itens | Consultas agregadas (`GROUP BY AccountId, Product2Id`) devolvem poucas linhas, mas **cada linha de origem conta para as 50 mil** | Conta com dezenas de milhares de itens em 12 meses aproxima o limite sozinha. Mitigação: `BatchSize__c` (100 → menor) e janela da cruzada, ambos no CMDT |
| Explosão de sinais | Cruzada limitada a `CrossSellMaxPerAccount__c` (10) por conta, ordenada pelo % do grupo | Evita milhares de linhas por conta e excesso de armazenamento |

Critério de escalonamento: o verificador e o QA medem com fixture sintética (ex.: 1 conta com 5 mil itens; 1.000 contas em 3 grupos). Se passar de ~70% de qualquer limite, o design volta ao gate.

### 4.3 Fixture e validation rules
17 regras ativas em Order; os campos que elas apontam como erro são, pelo rótulo: Contratado, Nome da conta, Cliente de Entrega, Data de entrega, Filial de Despacho, Data de emissão, Data previsão de vendas, Tipo de Operação, Transportadora, Espécie 1, Tipo de Frete, Volume 1, Status e duas no topo da página (fórmulas não lidas). A fixture de teste e a de QA preenchem todos (doutrina, `ValidaJOB`). As 6 regras de Account e 4 de OrderItem também. O builder lê as fórmulas antes de escrever a fixture.

## 5. Riscos do assessment aplicáveis

| Achado | Objeto/automação | Tratamento |
|---|---|---|
| 1. Automação própria concorre com a do CPQ no mesmo evento (alta) | Account, Order, Opportunity, OrderItem | Não se aplica à escrita: só leitura nesses objetos; objeto novo sem automação; sem roll-up em Account (seção 3) |
| 2. Cobertura Apex 10% (alta) | Classes novas | 4 classes de teste dedicadas, 85% cada. Não eleva a cobertura global; o risco de deploy em produção (75% da org) é do release humano e fica registrado (R-5) |
| 3. Validation rules em Order (média; 23, 17 ativas) | Fixture | Seção 4.3 |
| 4. Campos sem descrição (média; 153) | Account | Não usa campos sem descrição; todo componente novo com `Description` |
| 5. Nomenclatura de teste | Testes | `<Classe>Test` |
| 6. Dev e QA possivelmente a mesma org (média) | Ambiente | Reconfirmado: o alias de dev aponta para instância e usuário que se identificam como `qa`; a QA não está conectada. **Condição de ambiente para o build** (não é pergunta de negócio): confirmar que `sbx-eplast-dev` e `sbx-eplast-qa` são orgs distintas antes de construir |
| 7/8. Perfis | Acesso | Só permission set novo; perfis intocados |
| 10. `OrderTrigger` duplicado | Apex | Nenhuma classe nova com nome de Order; prefixo `CommercialSignal` sem colisão (confirmado) |

### 5.1 Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R-1 | `UNABLE_TO_LOCK_ROW` em Account no upsert/delete dos filhos | média | Horário, `allOrNone=false`, reexecução idempotente |
| R-2 | Volume de produção estoura 50 mil linhas num lote | média | `BatchSize__c`, janela, medição na QA com critério de 70% |
| R-3 | `Industry` vazio ou com valores soltos (picklist não restrita) esvazia a cruzada | média | Conta sem grupo fica fora da cruzada (CA-10); grupo mínimo de 5 (CA-11); campo de grupo configurável |
| R-4 | Status `Faturamento` conta como compra aqui, mas só `Concluido` vira oportunidade ganha no ranking da EPLAST-47 | baixa | Documentado (PA-16); parâmetro de status |
| R-5 | Deploy em produção com cobertura org-wide baixa | alta (release) | Fora da esteira; registrado para o release humano |
| R-6 | Concorrência de demandas no `SFAgent2` (fase 2) | baixa na v1 | v1 não toca o agente |
| R-7 | `OrderScheduledFlow` filtra `Liberação Financeira`, valor que não existe na picklist (`Liberacao Financeiro`) — o Flow provavelmente nunca encontra registros | baixa para esta demanda | Não afeta EPLAST-33 (status de processo não conta como compra). Registrado como achado para demanda própria; não é corrigido aqui |

## 6. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca recuperação e relacionamento (regra 2 da conta). A esteira não faz nada no Marketing Cloud.

1. **Dados que o Marketing Cloud lê e onde ficam:** `CommercialSignal__c` (`Account__c`, `Type__c`, `Product__c`, `DaysWithoutPurchase__c`, `VariationPercent__c`, `CalculationDate__c`) e, para chegar à pessoa, `Contact.AccountId`. Os sinais não guardam dado de contato (minimização, CA-14).
2. **Como o público fica identificável no CRM:** pelo `Type__c` (e produto, na cruzada) no relatório `CommercialSignals_ByAccount`, exportável com Account ID e tipo (CA-19). Os registros são recalculados diariamente; `CalculationDate__c` marca a foto.
3. **O que o Marketing Cloud devolve e onde é gravado:** o retorno de envio continua onde o conector já grava (`et4ae5__IndividualEmailResult__c`, `et4ae5__SendDefinition__c`, existentes). A v1 não cria campo de retorno nos sinais nem em Account.
4. **Consentimento e opt-out:** ficam nos campos existentes de Contato/Lead (`HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c`) e no status de assinante do próprio Marketing Cloud. O sinal é de conta, não é consentimento; quem opera o Marketing Cloud filtra o opt-out ao montar o público.
5. **O que fica para quem opera o Marketing Cloud:** importar o relatório (ou, se a edição do conector permitir, sincronizar `CommercialSignal__c` como fonte de dados — não verificado pela esteira); cruzar conta → contatos elegíveis; aplicar opt-out; criar e disparar jornada. `Campaign`/`CampaignMember` (existentes e vazios) não são usados na v1: membro de campanha exige contato ou lead, e montar público por pessoa é passo do Marketing Cloud.

## 7. Premissas assumidas (validar na homologação)

Herdadas da análise, mantidas como decididas: **PA-1** (v1 é relatório/lista, sem IA; `SFAgent2` na fase 2), **PA-2** (compra = `Order`; reforçada em PA-16), **PA-3** (status `Faturamento`, `Concluido`; parâmetro), **PA-4** (`EffectiveDate`; parâmetro no código de seleção, não no CMDT), **PA-5** (60 dias; "Nunca comprou" separado), **PA-6** (soma de `TotalAmount`, 3 meses × 3 anteriores, > 30% estrito, queda e alta), **PA-7** (grupo `Industry`, histórico de `OrderItem`, ≥ 30% do grupo em 12 meses, não comprou em 180 dias, grupo ≥ 5), **PA-9** (somente leitura nos objetos comerciais — a escrita em objeto novo é a decisão do gate, seção 1), **PA-10** (envio pelo Marketing Cloud), **PA-11** (qualidade Protheus validada na amostra), **PA-12** (entrega própria, régua alinhada ao `SFAgent2`), **PA-13** (aceite por fixture + amostra; saída sem contato), **PA-14** (diário), **PA-15** (sem notificação, sem IA). **PA-8 é ajustada pela PA-17.**

Acrescentadas neste design:

- [x] **PA-16. Fonte da compra frente ao ranking existente.**
  Pergunta: usar `Order` cria um segundo ranking divergente do `ScheduledFlowOpportunity`?
  Decisão: não há segundo ranking. EPLAST-33 não calcula faixa de porte nem grava `Ranking__c`/`LastMonthPurchaseValue__c`; mostra `Ranking__c` como coluna de contexto. A fonte é `Order` porque só `OrderItem` tem o produto (cruzada) e porque o Flow `Order` já transforma pedido `Concluido` em oportunidade `Fechado/Ganho`: a população é a mesma do ranking, mais os pedidos em `Faturamento`.
  Evidência: descrição de `Ranking__c` (faixa da média anual de ganhas); lógica do Flow `Order`; EPLAST-47 é dona do Flow agendado `[RAG: demandas/EPLAST-47/04-plano-build.md]`.
  Como mudar: `PurchaseStatuses__c` = "Concluido" alinha 100% à base do ranking.

- [x] **PA-17. Cálculo em modo sistema, visibilidade na leitura.**
  Pergunta: como cumprir "carteira do usuário" (PA-8) se a cruzada precisa de todas as contas do grupo?
  Decisão: o batch calcula sobre toda a base; cada usuário só vê sinais das contas que já vê, porque `CommercialSignal__c` é "controlado pelo pai". O % do grupo é agregado, sem expor dado de outra conta.
  Evidência: padrão master-detail da plataforma; OWD de Account interno ReadWrite (recon §5).
  Como mudar: visão por gestor/papel é questão de compartilhamento de Account, sem tocar no cálculo.

- [x] **PA-18. Persistir o resultado em objeto próprio.** Ver seção 1: recomendação, sujeita à aprovação explícita do arquiteto humano (mudança de modelo de dados). Evidência: CA-15, CA-19 e limites síncronos. Como mudar: alternativa LWC sob demanda, perdendo exportação.

- [x] **PA-19. Teto de cruzadas por conta.**
  Pergunta: quantas sugestões de produto por conta?
  Decisão: até 10, as de maior % no grupo.
  Evidência: padrão de minimização do squad; 1.042 produtos na org poderiam gerar centenas por conta.
  Como mudar: `CrossSellMaxPerAccount__c`.

- [x] **PA-20. Períodos de volume.**
  Pergunta: "3 meses" é calendário ou móvel?
  Decisão: móvel pela data da execução: atual = (hoje − 3 meses, hoje]; base = os 3 meses anteriores a esse. Comparação estrita sobre o valor não arredondado; exibe uma casa decimal.
  Evidência: opção mais simples e coerente com os CA-05/06; não há definição na org.
  Como mudar: `VolumeWindowMonths__c`; troca para mês fechado é ajuste pontual no serviço.

- [x] **PA-21. Universo de contas e "Nunca comprou".**
  Pergunta: toda conta sem compra entra, inclusive prospects?
  Decisão: sim, todas as contas; o tipo `NuncaComprou` fica separado e pode ser desligado.
  Evidência: CA-03; sem filtro de tipo de conta definido na org para esse fim.
  Como mudar: `IncludeNeverPurchased__c` = false, ou filtro de tipo de conta em versão seguinte.

- [x] **PA-22. Horário do recálculo.**
  Decisão: 04:00 UTC diário. Evidência: jobs agendados da org (seção 3). Como mudar: reagendar o `CommercialSignalScheduler`.

## 8. Bloqueios (caso 3)

Nenhum. Todas as perguntas de negócio têm evidência na org ou padrão, e mudam por parâmetro.

Duas coisas, porém, precisam do humano neste gate, e não são perguntas de negócio:
- **Aprovação explícita do objeto novo `CommercialSignal__c`** (mudança de modelo de dados, seção 1).
- **Condição de ambiente para o build:** confirmar que dev e QA são orgs distintas (achado 6).

## 9. O que NÃO será feito

Escrita em Account, Opportunity, Order, OrderItem; trigger, Flow ou validation rule nesses objetos; alteração de `ScheduledFlowOpportunity`, `RankingRange__mdt` ou dos campos de compra de Account; extensão do `SFAgent2`; notificação ao vendedor; qualquer envio pelo CRM ou configuração no Marketing Cloud; uso de `Campaign`/`CampaignMember`; correção do filtro do `OrderScheduledFlow` (R-7); cruzada pelo catálogo CPQ; integração nova com Protheus; alteração de perfis.

## 10. Incertezas declaradas

- I-1. Significado de `Order.Status` inferido pelo nome (PA-3), embora o Flow `Order` confirme `Concluido` = ganho.
- I-2. Dev vazia: nenhuma regra exercitada com dado real; limiares são defaults.
- I-3. Régua do `SFAgent2` (60 dias, 30%) não relida no metadata do agente.
- I-4. Preenchimento e distribuição de `Industry` desconhecidos.
- I-5. Fórmulas das 17 validation rules de Order não lidas (só os campos de erro).
- I-6. Volume de produção (contas, pedidos, itens) não medido.
- I-7. Dev e QA podem ser a mesma org.
- I-8. Que inserir filho master-detail sem roll-up não altera o `LastModifiedDate` da conta é comportamento esperado da plataforma, não testado nesta org: CA-12 prova na QA.
- I-9. Se a edição do conector permite sincronizar objeto custom no Marketing Cloud não foi verificado.
- I-10. Horário de gravação da integração Protheus em Account não medido (R-1).

## 11. Estimativa de esforço

**Estimativa de esforço:** 56–96 h

O que mudou em relação à análise (60–110 h) e por quê: o recon mostrou que não há nada a reaproveitar para a regra (nenhuma classe, nenhum relatório que calcule volume ou cruzada), mas também que a solução não precisa tocar o `ScheduledFlowOpportunity` nem o `SFAgent2`, nem mapear a ordem de execução de Order (só leitura), o que corta a ponta alta. Composição: objeto, campos, CMDT, tipo de relatório, relatório, permission set (8–12 h); 4 classes + 4 testes a 85% com os 21 CAs (24–40 h); fixture contra 17+6+4 validation rules (8–16 h); verificação de volume/CPU e QA agendado em duas sessões (8–14 h); homologação com amostra do Comercial e ajuste de limiar (8–14 h). Não inclui fase 2 do `SFAgent2`, a resolução do achado 6 nem o trabalho no Marketing Cloud.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

## Respostas do cliente (2026-11-17) — valem acima das premissas assumidas deste desenho

A Eplast respondeu por escrito ("Respostas Konecta/Eplast", recebido em 17/11) aos pontos que
este desenho tinha resolvido como premissa assumida. Registrado por Leonardo Barbosa, que
mandou redesenhar com as respostas. **Onde a resposta abaixo diverge de uma premissa deste
arquivo, vale a resposta.** O que o cliente marcou como "a validar" continua premissa, a
repetir no roteiro em "O que assumimos e você precisa confirmar". Os parâmetros ficam
configuráveis (pedido do cliente), sem deploy para ajustar. Reaproveite o que já foi
construído e passou no QA; mude só o que a resposta pede. Os artefatos de build e QA da
rodada anterior estão em `rodada-anterior/premissas-assumidas/` para consulta.

**Resposta do cliente (EPLAST-33 — cross-sell, volume e recuperação):**
- Escopo: extensão do entregável "clientes há mais tempo sem comprar", com queda de volume
  e venda cruzada.
- Canal: relatório para gestão e priorização da carteira, com consulta e recomendação no
  assistente usando os mesmos critérios.
- Compra: pedido efetivamente **faturado**, pela **data de faturamento**, excluindo
  cancelamentos; devoluções conforme a fonte oficial (a integração de devoluções precisa de
  correção, fora desta demanda). Oportunidade ganha sem faturamento não conta.
- Inatividade: **90 dias** sem compra, configurável. Quem nunca comprou aparece separado.
- Volume: faturamento líquido e quantidade **por família de produto**, sem somar unidades de
  produtos diferentes. **Último mês completo contra a média dos três meses completos
  anteriores**, alerta com queda **igual ou superior a 20%**. Sinalizar histórico
  insuficiente.
- Venda cruzada: **segmento** como referência principal e região como filtro complementar.
  Avaliar pré-formas, tampas e garrafas com compatibilidade técnica; priorizar itens
  complementares aos já comprados; não sugerir combinações incompatíveis.

**O que muda neste desenho:**
1. `RecoveryDays__c` de 60 para **90**.
2. Volume: janela de mês fechado (último mês completo × média dos 3 anteriores), limiar
   **20%**, só **queda** como alerta, por família de produto; marcar "histórico insuficiente".
3. Compra: confirmar na org qual campo de `Order` é a data de faturamento e qual status
   significa faturado; se não houver campo de data de faturamento, usar o que existe e
   declarar como premissa a validar.
4. Venda cruzada: agrupar por **segmento** (`Sector__c`, o campo de segmento da Eplast) no
   lugar de `Industry`; região como filtro. Compatibilidade técnica: só se a org tiver campo
   que a represente; se não, declarar que a regra depende de tabela da Eplast e limitar a
   itens complementares por família. Não inventar regra de compatibilidade.
5. Assistente: a consulta pelo `SFAgent2` com os mesmos critérios entra nesta rodada se
   couber como leitura dos sinais já calculados; se exigir mais que isso, declarar como
   fase seguinte.
6. Devoluções: fora. Registrar no roteiro que o faturamento líquido não as trata até a
   integração ser corrigida.
