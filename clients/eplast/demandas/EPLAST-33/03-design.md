**Solução:** mista
**Org consultada:** `sbx-eplast-dev` (única org em `sf org list` nesta sessão, sandbox `eplast--qa` da Eplast, que é a dev da esteira pela regra 5 da conta)

# EPLAST-33 — Design da solução, rodada 17/11 (ajuste às respostas do cliente)

**Demanda:** EPLAST-33 · **Etapa:** 3, design (`arquiteto`) · **Data:** 2026-11-17 · **Gate:** bloqueante, aceite do arquiteto humano.
**Entradas:** `01-analise.md` (aprovada em 15/11), `02-recon.md` (17/11), respostas da Eplast de 17/11 (registradas no fim do design anterior e no card), `00-preflight.md` (sem bloqueio, nenhuma outra demanda nos mesmos componentes), `assessment.md`, RAG do cliente. O build e o QA da rodada anterior (`rodada-anterior/premissas-assumidas/`, QA **aprovado** em 16/11) são a linha de base: esta rodada muda só o que as respostas pedem.

**Conferido nesta sessão por `sf`, além do recon (só metadata e contagens):**
- `Account.Sector__c` é o segmento da Eplast: os 9 relatórios `SEGMENTO - ...` e os 8 `LEADS - SEGMENTO - ...` da pasta "MARKETING CLOUD" filtram por `Account.Sector__c`, com os mesmos 9 valores da picklist (retrieve dos relatórios para pasta temporária, descartado). Resolve a lacuna 3 do recon.
- `Account.LastPurchase__c` ("Última Compra") é roll-up `MAX(Opportunity.CloseDate)` das oportunidades `Fechado/Ganho`; `Account.Inactive__c` é fórmula `TODAY() - LastPurchase__c > 90`. Os relatórios `SEM COMPRA - 91 A 180 DIAS` (e as outras faixas) filtram por `Account.LastPurchase__c`, com opt-out `EMAIL_OPT_OUT` e `Contact.et4ae5__HasOptedOutOfMobile__c`.
- `Order.EffectiveDate` é gravado com a data do dia pelo Flow `OpportunityFlow` ao criar o pedido e vai ao Protheus como `DtEmissao` (`OrderAdapter`). `Order.IssuanceDate__c` ("Data emissão") é editável no permission set `Protheus` e não é escrito por nenhuma classe ou Flow do repositório; sem descrição.
- Fluxo de status de `Order`: Flow `Order` (after-save) leva a oportunidade a `Fechado/Ganho` quando o pedido chega a `Concluido` e a `Fechado/Perdido` em `Cancelado`. Quem grava `Faturamento`/`Concluido` não está no código do repositório (provavelmente a integração).
- `Product2.QuantityUnitOfMeasure` (padrão) existe. Distribuição `Group__c` × unidade: `PREF` 680 UN; `TAMP` 202 UN; `ALCA` 7 UN; `RESI` 1 UN + 15 KG; `GPET` 2 UN + 3 sem unidade; sem grupo 38 UN + 94 sem unidade. **Uma família (`RESI`) já mistura unidades.** Não há código de grupo para garrafa.
- `CommercialSignal__c`: os 11 campos **têm** descrição (tooling `CustomField`), ao contrário do que o recon registrou. `CommercialSignalSetting__mdt.Default` hoje: 60 dias, 30%, `Industry`, `Faturamento;Concluido`, `Queda;Alta`.
- Nenhum job agendado da demanda na dev (`CronTrigger` com nome `EPLAST33%`: 0; `CommercialSignalScheduler` só aparece como `Aborted` em `AsyncApexJob`). As 9 classes estão em API 67.0, a mesma da org e do projeto.
- `SFAgent2` (`BotDefinition` consultável agora): versões 1 a 15; **v13 ativa**; v14 e v15 inativas, de 16/11. Tópico `insights_comerciais` existe.
- Relatório `CommercialSignals_ByAccount` (resumo por `Type__c`) e tipo `Accounts_with_CommercialSignals` (Account: `Id`, `Name`, `Ranking__c`; sinal: todos os campos atuais).

---

## 1. Solução escolhida

**Decisão:** manter o motor da rodada anterior (Apex Batch agendado que grava `CommercialSignal__c`, parâmetros em `CommercialSignalSetting__mdt`, leitura por relatório) e **ajustá-lo** às respostas. Acrescentar a **consulta pelo `SFAgent2`** como ação Apex de leitura dos sinais já calculados, numa versão nova do agente. Nenhuma escrita em Account, Opportunity, Order ou OrderItem.

| Nível | O que resolveria | Por que não basta / onde é usado |
|---|---|---|
| Configuração | Recuperação (90 dias) e "Nunca comprou" num relatório de Account com filtro cruzado | Não resolve volume por família com mês fechado contra média de 3 meses, nem cruzada por segmento (estatística grupo × família), nem histórico insuficiente. O CRM já tem um "sem compra" por configuração (`LastPurchase__c`/`Inactive__c`), mas pela oportunidade ganha, que o cliente disse que **não** conta. **Usada** para: parâmetros (CMDT), novos campos, picklist, relatório, permission set, tópico do agente |
| Declarativo (Flow) | Ação do agente lendo `CommercialSignal__c` com Get Records | Para o cálculo: Flow não agrega (sem GROUP BY, sem soma por mês e família); seria laço conta × pedido × item. Para a ação do agente: a consulta tem filtros opcionais combinados (conta, tipo, segmento, UF), limite e precisa garantir a visão do usuário (`WITH USER_MODE`); em Flow isso vira várias decisões e o contexto de execução de Flow autolançado chamado pelo agente não é determinístico para o critério CA-13 |
| **Código (Apex)** | Cálculo (já existente, ajustado) e ação de leitura do agente | Escolhido. Mesma regra num lugar só, parâmetros fora do código, teste determinístico a 85% (doutrina: volume com risco de limite e teste unitário sobre a regra) |

**Mudança de modelo de dados — escalada a este gate.** Não há objeto novo (o `CommercialSignal__c` já foi aprovado em 15/11 e está construído), mas a rodada **acrescenta campos e um valor de picklist** ao objeto e campos ao CMDT (seção 2.3). Pela regra do papel, eu recomendo e o arquiteto humano decide.

**Versões e ativação (doutrina "Alterar o que já existe"):**
- Classes `CommercialSignal*`: **editadas no lugar**, com justificativa: a demanda ainda não foi entregue, nenhuma classe é chamada por trigger, Flow, ação de agente ou job (0 jobs `EPLAST33` na dev, conferido); não há comportamento em uso a preservar. Condição para o build e para o passo de deploy da QA: confirmar 0 jobs agendados de `CommercialSignalScheduler` na org antes de implantar (achado da QA de 15/11: a validação recusa reimplantar classe com job agendado). Se houver, quem implanta desagenda antes e reagenda depois, e registra.
- `SFAgent2`: **versão nova, inativa**. Parte da última versão (v15), como manda a doutrina; antes, o builder confere (RAG/`gates.md` das outras demandas) quem criou v14 e v15 e se ainda serão ativadas. Se v15 for trabalho abandonado, parte da v13 (ativa) e registra. A versão nova é implantada inativa; ativação é passo separado: na dev, depois da verificação; na QA, pelo `qa` (autorizado), registrando qual entrou e qual saiu. Desfazer: reativar a v13.
- Relatório e tipo de relatório: metadata sem versão; alterados no lugar (são desta demanda).

## 2. Reaproveita vs cria (regra 3)

### 2.1 Reaproveita

| Item | Confirmado | Como entra |
|---|---|---|
| `CommercialSignal__c` e seus 11 campos | sim | Mantidos. Mudam descrições de `BasePeriodAmount__c` (passa a ser média mensal da base), `CurrentPeriodAmount__c` (último mês fechado), `VariationPercent__c` e `SignalKey__c` (chave inclui família) |
| `CommercialSignalSetting__mdt`, registro `Default` | sim | Reaproveitado; valores alterados conforme o cliente (seção 2.4). `VolumeWindowMonths__c` passa a significar "meses completos da base" (3) |
| `CommercialSignalBatch`, `CommercialSignalGroupStatsBatch`, `CommercialSignalService`, `CommercialSignalScheduler` + 4 `<Classe>Test` + `CommercialSignalTestFactory` | sim, 9 ativas, API 67.0 | Ajustadas (seção 2.4). Upsert idempotente, exclusão de sinais que não se repetem, `allOrNone=false`, contadores e encadeamento das fases ficam como estão |
| Relatório `CommercialSignals_ByAccount`, pasta `EPLAST33_SinaisComerciais`, tipo `Accounts_with_CommercialSignals` | sim | Recebem as colunas novas; nenhum relatório novo |
| `PS_Comercial_SinaisComerciais`, `PS_Marketing_SugestaoCampanha` | sim | Recebem FLS dos campos novos; o primeiro recebe acesso à classe da ação do agente |
| `Account.Sector__c` | sim; é o segmento usado nos relatórios do Marketing Cloud | Grupo da cruzada, só por configuração (`CrossSellGroupField__c`; `resolveGroupField` já aceita) |
| `Product2.Group__c` | sim, 5 códigos | Família de produto (parâmetro novo, seção 2.3) |
| `Product2.QuantityUnitOfMeasure` | sim | Unidade da quantidade, para não somar unidades diferentes |
| `Account.BillingState` | sim (padrão) | "Região" como filtro complementar no relatório e na ação do agente |
| `SFAgent2`, tópico `insights_comerciais`, ação `IdentificarConta` | sim (v13 ativa) | Estende o tópico com uma ação; `IdentificarConta` resolve nome → conta. Não cria agente nem tópico |
| Relatórios `SEM COMPRA - ...` e `SEGMENTO - ...` (pasta MARKETING CLOUD), `Account.LastPurchase__c`, `Account.Inactive__c` | sim | **Não alterados** (são do Marketing Cloud e de outra régua). O corte de 90 dias da nova régua coincide com o de `Inactive__c` e com a faixa "91 a 180" (seção 4) |

### 2.2 Não reaproveita, de propósito

| Item | Por quê |
|---|---|
| `Account.LastPurchase__c` / `Inactive__c` como fonte | Medem a última oportunidade ganha; o cliente disse que "oportunidade ganha sem faturamento não conta". Mudá-los alteraria os públicos do Marketing Cloud e gravaria em Account |
| `Product2.Family` | Picklist só com `None` |
| `SalesReturn__c` | Cliente pediu devoluções fora até a integração ser corrigida |
| Ações `ConsultarPedidos`/`QueryRecords` (`queryRecords` padrão) | Fazer o LLM montar consulta sobre um objeto novo não garante "os mesmos critérios" nem a visão do usuário; a ação dedicada devolve exatamente os sinais calculados |

### 2.3 Cria (nomes propostos; nenhum existe na org — conferido)

| Tipo | API name | Conteúdo |
|---|---|---|
| Campo Text(40) | `CommercialSignal__c.ProductFamily__c` | Família (`Group__c`) do sinal de volume, histórico insuficiente e cruzada por família |
| Campo Number(16,2) | `CommercialSignal__c.CurrentPeriodQuantity__c` | Quantidade no último mês fechado (só quando a família tem uma única unidade no período) |
| Campo Number(16,2) | `CommercialSignal__c.BasePeriodQuantity__c` | Média mensal de quantidade nos meses da base (mesma condição) |
| Campo Text(20) | `CommercialSignal__c.UnitOfMeasure__c` | Unidade da quantidade (`UN`, `KG`...) ou `MISTA` quando a família mistura unidades (quantidade não é somada) |
| Valor de picklist | `CommercialSignal__c.Type__c` = `HistoricoInsuficiente` | Sinaliza conta × família sem base suficiente para comparar volume |
| Campo CMDT Text | `PurchaseDateField__c` | Campo de data da compra em `Order`. Lista permitida no código: `EffectiveDate`, `IssuanceDate__c`, `ActivatedDate`. Valor: `EffectiveDate` (PA-23) |
| Campo CMDT Text | `FamilyField__c` | Campo de família em `Product2`. Permitidos: `Group__c`, `Family`. Valor: `Group__c` |
| Campo CMDT Number | `VolumeMinBaseMonths__c` | Mínimo de meses da base com compra da família para comparar. Valor: 2 (PA-26) |
| Campo CMDT Text | `VolumeMetric__c` | `Valor`, `Quantidade` ou `ValorOuQuantidade`. Valor: `Valor` (PA-25) |
| Campo CMDT Text | `CrossSellLevel__c` | `Familia` ou `Produto`. Valor: `Familia` (PA-28) |
| Campo CMDT Text | `CrossSellExcludedFamilies__c` | Famílias que nunca são sugeridas (separadas por `;`). Valor: vazio |
| Classe Apex | `CommercialSignalAgentAction` | `@InvocableMethod`, `with sharing`, consultas `WITH USER_MODE`. Entradas opcionais: `accountId`, `signalType`, `sector`, `state` (UF), `maxResults` (padrão 20, teto 50). Devolve linhas de texto com conta, tipo, família/produto, métrica, motivo e data do cálculo. Sem dado de contato. Só leitura |
| Classe de teste | `CommercialSignalAgentActionTest` | 85%; roda como usuário de teste criado no próprio teste com `PS_Comercial_SinaisComerciais` atribuído (lição da QA de 15/11); prova que conta sem acesso não aparece |
| Ação do agente | `ConsultarSinaisComerciais_EPLAST33` no tópico `insights_comerciais`, na versão nova do `SFAgent2` | Instrução do tópico: para cliente sem compra, queda de volume, histórico insuficiente ou venda cruzada, chamar esta ação (com `IdentificarConta` quando vier nome); nunca recalcular a partir de pedidos; sempre citar a data do cálculo; não sugerir item específico quando o sinal for de família |

### 2.4 Altera

| Componente | Mudança |
|---|---|
| `CommercialSignalSetting__mdt.Default` | `RecoveryDays__c` 60 → **90**; `VolumeThresholdPercent__c` 30 → **20**; `VolumeDirections__c` → **`Queda`**; `CrossSellGroupField__c` `Industry` → **`Sector__c`**; `VolumeWindowMonths__c` 3 (novo significado); campos novos com os valores da 2.3. `PurchaseStatuses__c` continua `Faturamento;Concluido` (PA-24) |
| `CommercialSignalService` | Recuperação: `dias > RecoveryDays__c` (estrito). Volume: compara **último mês completo** com a **média dos N meses completos anteriores** por conta × família; alerta de queda com variação **≥ limiar** (inclusivo, resposta do cliente); classificação `HistoricoInsuficiente`; cruzada por família ou produto conforme `CrossSellLevel__c`, respeitando `CrossSellExcludedFamilies__c`. Volume não é calculado para conta já em `Recuperacao` ou `NuncaComprou` (PA-27) |
| `CommercialSignalBatch` | Consultas dinâmicas com campo de data e de família vindos do CMDT, **validados contra a lista permitida** (sem concatenação de texto livre). Agregado de `OrderItem` por conta, família, unidade e mês (`SUM(TotalPrice)`, `SUM(Quantity)`) na janela [1º dia do mês M−(N+1), último dia do mês M−1]. Chave `SignalKey__c` = `AccountId-Type-<Product2Id ou família>` |
| `CommercialSignalGroupStatsBatch` | Estatística do grupo por (segmento, família) ou (segmento, produto), conforme `CrossSellLevel__c` |
| 4 classes de teste + `CommercialSignalTestFactory` | Fixtures dos novos limites: 90/91 dias; queda 19,9% / 20,0%; histórico com 1 e 2 meses da base; família com unidades mistas; cruzada por família no segmento; família excluída; troca de `PurchaseDateField__c` muda o resultado sem deploy |
| `Accounts_with_CommercialSignals` | Acrescenta `Account.Sector__c`, `Account.BillingState` e os 4 campos novos do sinal |
| `CommercialSignals_ByAccount` | Acrescenta colunas `Sector__c`, `BillingState`, `ProductFamily__c`, quantidades e unidade. Formato copiado do XML atual (doutrina, EPLAST-39). Filtro por segmento e UF fica a cargo do usuário na tela (filtro do relatório), sem relatório novo |
| `PS_Comercial_SinaisComerciais`, `PS_Marketing_SugestaoCampanha` | FLS de leitura dos 4 campos novos; o primeiro ganha `classAccess` de `CommercialSignalAgentAction` |
| `SFAgent2` | Versão nova inativa com a ação e a instrução (seção 1) |

Nada é depreciado. Nenhum perfil é alterado.

## 3. Impacto e ordem de execução

**Account, Order e OrderItem têm trigger próprio, trigger do CPQ (`SBQQ`) e Flows no mesmo evento (achado 1 do assessment, reconfirmado no recon): `Order` com dois `OrderTrigger` (CPQ e próprio) + Flow before-save + Flow after-save `Order` + 17 validation rules; `Account` com `AccountBefore` (SBQQ), `AccountTrigger` (enfileira Protheus por conta) e Flows `AccountTriggered`/`UpdateParentAccountUsedLimit`. A ordem entre eles não foi mapeada nem testada.**

Como a solução fica fora dessa cadeia (nada nesta rodada muda isso):
- Batch e ação do agente só **leem** Account, Order, OrderItem e Product2. Leitura não dispara trigger, Flow nem validation rule.
- A única escrita é em `CommercialSignal__c` (sem trigger, Flow, validation rule nem roll-up). Sem roll-up, gravar o filho não salva a conta: `AccountTrigger` e o envio ao Protheus não rodam (CA-12 continua provando).
- **Bloqueio de linha:** upsert/exclusão de filho master-detail trava a conta-pai na transação; concorrência com a integração Protheus pode dar `UNABLE_TO_LOCK_ROW`. Mitigação mantida: horário 04:00 UTC, `allOrNone=false`, reexecução idempotente.
- Opportunity não é lida nem escrita.

**Governador e CPU** (volume de produção não medido; dev vazia):

| Cenário | Desenho | Atenção |
|---|---|---|
| Muitas contas | Batch de `BatchSize__c` (100) contas; ~5 SOQL agregadas por lote, 2 DML; nada por conta em laço | Assíncrono: 60 s CPU, 50 mil linhas |
| Conta com muitos pedidos/itens (achado SOMOSAGILITY-10) | Agregação feita no banco (`GROUP BY` conta, família, unidade, mês): poucas linhas devolvidas, CPU baixa; mas cada `OrderItem` de origem conta para as 50 mil linhas | A janela de volume caiu de 6 para 4 meses, reduzindo linhas. Mitigação: `BatchSize__c` menor. Verificador mede com 1 conta e 5 mil itens; acima de 70% de qualquer limite, volta ao gate |
| Estatística do grupo | Por família: 9 segmentos × ~6 famílias; por produto (se ligado): teto 9 × 1.042 | Bem abaixo do heap |
| Ação do agente | Síncrona, 1 SOQL com `LIMIT` ≤ 50 sobre `CommercialSignal__c` | Sem risco de limite |

## 4. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca recuperação, segmentação e relacionamento (regra 2). A esteira não faz nada no Marketing Cloud.

1. **Dados que o Marketing Cloud lê e onde ficam:** `CommercialSignal__c` (`Account__c`, `Type__c`, `ProductFamily__c`, `Product__c`, `DaysWithoutPurchase__c`, `VariationPercent__c`, `CalculationDate__c`); segmento em `Account.Sector__c` (o mesmo dos relatórios `SEGMENTO - ...` do Marketing Cloud); UF em `Account.BillingState`; pessoa por `Contact.AccountId`. O sinal não guarda contato (CA-14).
2. **Como o público fica identificável no CRM:** relatório `CommercialSignals_ByAccount`, filtrável por tipo, família, segmento e UF, exportável com o ID da conta (CA-19). Recalculado diariamente; `CalculationDate__c` marca a foto. Não se cria campanha nem membro de campanha (membro exige contato ou lead; montar público por pessoa é do Marketing Cloud).
3. **Duas réguas de "sem compra" convivem, de propósito:** os relatórios `SEM COMPRA - ...` do Marketing Cloud usam `LastPurchase__c` (última oportunidade ganha); o sinal `Recuperacao` usa pedido faturado, como o cliente definiu. O corte é o mesmo (mais de 90 dias, faixa "91 a 180"), mas a base difere: uma conta com oportunidade ganha e pedido ainda não faturado aparece no sinal e não no relatório do Marketing Cloud. Não alteramos os relatórios deles. Recomendação para quem opera o Marketing Cloud: usar o sinal quando o critério for "faturado"; alinhar as duas réguas é decisão da Eplast e, se pedida, demanda própria.
4. **O que o Marketing Cloud devolve e onde é gravado:** o retorno de envio continua onde o conector grava (`et4ae5__IndividualEmailResult__c`, `et4ae5__SendDefinition__c`). Nada novo no sinal nem em Account.
5. **Consentimento e opt-out:** em `Contact.HasOptedOutOfEmail` e `Contact.et4ae5__HasOptedOutOfMobile__c` — os mesmos filtros que os relatórios do Marketing Cloud já usam — e no status de assinante do Marketing Cloud. O sinal é de conta, não é consentimento.
6. **Fica para quem opera o Marketing Cloud:** importar o relatório (ou sincronizar `CommercialSignal__c`, se a edição do conector permitir — não verificado), cruzar conta → contatos elegíveis, aplicar opt-out, criar e disparar a jornada.

## 5. Premissas assumidas (validar na homologação)

**Decidido pelo cliente em 17/11 (não são premissas):** compra = pedido faturado, sem cancelados; oportunidade ganha sem faturamento não conta; 90 dias, configurável; "nunca comprou" separado; volume por família, valor e quantidade sem somar unidades diferentes; último mês completo × média dos 3 completos anteriores; queda ≥ 20%; sinalizar histórico insuficiente; cruzada por segmento com região como filtro; relatório + assistente com os mesmos critérios; devoluções fora.

**Mantidas da rodada anterior:** PA-13 (saída sem contato), PA-14 (diário), PA-15 (sem notificação), PA-17 (cálculo em modo sistema, visibilidade pelo pai), PA-19 (até 10 cruzadas por conta), PA-21 (todas as contas; "Nunca comprou" desligável), PA-22 (04:00 UTC). **Substituídas:** PA-5 (60 → 90), PA-6 e PA-20 (janela móvel e 30% → mês fechado e 20%), PA-7 (`Industry` → `Sector__c`; produto → família), PA-1/PA-12 (assistente entra nesta rodada).

- [x] **PA-23. Qual campo é a "data de faturamento".**
  Pergunta: a org não tem campo de data de faturamento; qual data usar?
  Decisão: `Order.EffectiveDate` ("Data de emissão"), restrita a pedidos em status faturado (PA-24).
  Evidência: `EffectiveDate` é obrigatório (regra `CheckOrderHasEffectiveDate`) e sempre preenchido; é a data do pedido enviada ao Protheus (`OrderAdapter`). `IssuanceDate__c` é gravável só pela integração (permission set `Protheus`) e pode ser a data da nota, mas o preenchimento não foi confirmado (dev sem pedidos); escolher um campo possivelmente vazio jogaria toda conta em "Nunca comprou".
  Como mudar: `PurchaseDateField__c` = `IssuanceDate__c` (sem deploy). O QA mede na QAS, só por contagem (`SELECT COUNT() FROM Order WHERE Status IN (...) AND IssuanceDate__c != null` contra o total), e registra o percentual para a Eplast decidir na homologação.

- [x] **PA-24. Quais status significam "faturado".**
  Decisão: `Faturamento` e `Concluido`; `Cancelado` e os status de processo (`Revisao de Pedido`, `Liberacao Financeiro`, `Liberacao Estoque`) não contam.
  Evidência: a sequência da picklist põe `Faturamento` depois das liberações; o Flow `Order` trata `Concluido` como venda ganha. Nenhum valor tem descrição.
  Como mudar: `PurchaseStatuses__c` = `Concluido` se `Faturamento` significar "em faturamento" e não "faturado".

- [x] **PA-25. Faturamento líquido e métrica do alerta.**
  Decisão: valor = `SUM(OrderItem.TotalPrice)` (preço praticado × quantidade, sem imposto e sem devolução); o alerta de queda dispara pelo valor. A quantidade é mostrada ao lado quando a família tem uma só unidade no período; família com unidades mistas (hoje `RESI`: UN e KG; `GPET` com produto sem unidade) mostra `MISTA` e não soma.
  Evidência: `OrderItem` não tem campo de valor líquido de imposto; `SBQQ__TaxAmount__c` é estimativa do CPQ. Distribuição de unidade por `Group__c` conferida.
  Como mudar: `VolumeMetric__c` = `Quantidade` ou `ValorOuQuantidade`. Devoluções entram quando a integração de `SalesReturn__c` for corrigida (demanda própria).

- [x] **PA-26. Família de produto e histórico insuficiente.**
  Decisão: família = `Product2.Group__c` (`PREF`, `TAMP`, `RESI`, `ALCA`, `GPET`); produto sem grupo entra como família "Sem família". Histórico insuficiente = a conta comprou a família em menos de 2 dos 3 meses da base; nesse caso grava `HistoricoInsuficiente` e não compara.
  Evidência: `Family` está vazia; `Group__c` é o único agrupador preenchido (1042 produtos, 910 com grupo). O significado dos códigos é inferido pelo nome. Exigir 2 de 3 meses evita comparar com média de um mês isolado.
  Como mudar: `FamilyField__c`; `VolumeMinBaseMonths__c` (1 a 3).

- [x] **PA-27. Sinais sobrepostos.**
  Decisão: conta em `Recuperacao` ou `NuncaComprou` não recebe sinal de volume (seria queda de 100% em toda família, repetindo o mesmo alerta).
  Evidência: padrão de minimização do squad. Como mudar: ajuste pontual no serviço.

- [x] **PA-28. Venda cruzada sem compatibilidade técnica na org.**
  Pergunta: como avaliar pré-forma, tampa e garrafa "com compatibilidade técnica" e não sugerir combinação incompatível?
  Decisão: a cruzada sugere **família**, não item: "o segmento compra a família X (≥ 30% das contas do segmento em 12 meses) e esta conta não comprou X em 180 dias". Como não há item, não há combinação incompatível sugerida; o vendedor escolhe o item compatível. A família sugerida é sempre diferente das que a conta compra (complementar).
  Evidência: busca por campo de compatibilidade (gargalo, rosca, diâmetro, tipo) em `Product2`: nenhum (recon). Não há código de grupo para garrafa. O próprio cliente cita uma tabela de compatibilidade que não está na org.
  Como mudar: `CrossSellLevel__c` = `Produto` volta à sugestão por item (sem garantia de compatibilidade); `CrossSellExcludedFamilies__c` tira famílias (ex.: `RESI`). Sugestão por item compatível depende de a Eplast fornecer a tabela, em demanda própria.

- [x] **PA-29. Região.**
  Decisão: região = UF de cobrança (`Account.BillingState`), usada como filtro no relatório e na ação do agente; não entra no cálculo do percentual do segmento.
  Evidência: não há campo de região em Account; `Territory2` não é suportado na org. "Filtro complementar" na resposta do cliente.
  Como mudar: trocar a coluna/filtro por outro campo quando a Eplast indicar um.

- [x] **PA-30. 90 dias, estrito.**
  Decisão: recuperação a partir de 91 dias sem compra faturada.
  Evidência: `Account.Inactive__c` usa `> 90`; o relatório do Marketing Cloud começa em 91 dias. Como mudar: `RecoveryDays__c`.

- [x] **PA-31. Assistente lê, não calcula.**
  Decisão: o `SFAgent2` responde só com os sinais já gravados (data do último cálculo), na visão do usuário da conversa; não recalcula na hora.
  Evidência: diretriz do responsável ("se couber como leitura dos sinais já calculados"); garante os mesmos critérios do relatório. Como mudar: recálculo sob demanda seria demanda própria.

## 6. Riscos do assessment tratados

| Achado | Toca? | Tratamento |
|---|---|---|
| 1. Automação concorrente em Account/Opportunity/Order (alta) | Leitura só | Seção 3: nenhuma escrita nesses objetos; objeto de saída sem automação e sem roll-up |
| 2. Cobertura Apex ~10% (alta) | Classes da demanda | 6 classes de teste dedicadas, 85% cada (CA-20). Não muda a cobertura geral; deploy em produção é decisão do release humano (`RunSpecifiedTests`) |
| 3. Validation rules de Order (média; 17 ativas) | Fixture | Fixture preenche os campos de todas as regras ativas de Order (17), Account e OrderItem (4); o builder lê as fórmulas antes. Não alteramos as regras nem as 6 inativas de status |
| 4. Campos sem descrição (média) | Campos novos | Todo campo, CMDT e classe novos com `Description`; descrições dos campos reaproveitados atualizadas ao novo significado. Usamos `Sector__c`, `Group__c`, `EffectiveDate` sem descrição na org: o significado assumido está nas PA-23/26 |
| 5. Nome de classe de teste | Testes | `<Classe>Test` para todas |
| 6. Dev com "qa" no nome | — | Resolvido pela regra 5 da conta; não se aplica |
| 7/8. Perfis | Acesso | Só permission sets existentes da demanda; nenhum perfil alterado |
| 9. API version atrasada | Classes | As classes da demanda já estão em 67.0 (versão da org); classe nova nasce em 67.0. Classes antigas da org não são tocadas |
| 10. `OrderTrigger` duplicado | — | Não tocado; prefixo `CommercialSignal` sem colisão |

**Riscos técnicos**

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R-1 | `UNABLE_TO_LOCK_ROW` na conta-pai | média | Horário, `allOrNone=false`, reexecução idempotente |
| R-2 | 50 mil linhas num lote em conta muito grande | média | Janela menor (4 meses), `BatchSize__c`, medição com critério de 70% |
| R-3 | `PurchaseDateField__c` ou `FamilyField__c` com valor inválido no CMDT | média | Lista permitida no código; valor fora dela usa o padrão e registra no `Reason__c`/log do job; teste cobre |
| R-4 | **Versões v14/v15 do `SFAgent2` inativas, de outra frente, sem dono identificado nesta sessão.** Se outra demanda ativar uma versão que não tenha a ação desta, a consulta some | média | Builder identifica o dono antes de criar a versão nova (seção 1) e registra no plano qual versão base usou; a demanda seguinte parte da versão deixada por esta |
| R-5 | Duas réguas de "sem compra" (oportunidade ganha × pedido faturado) confundem o usuário | média | Seção 4, item 3; explicado no roteiro do cliente |
| R-6 | Agente responde fora da ação (monta consulta própria em pedidos), como visto na EPLAST-27 | média | Instrução com prioridade no tópico; o verificador testa perguntas variadas |
| R-7 | Job agendado na QA impede reimplantar as classes | baixa | Conferir 0 jobs antes do deploy (seção 1) |

## 7. Pendências que bloqueiam

Nenhuma (caso 3 da regra 4). Toda pergunta de negócio desta rodada tem resposta do cliente ou premissa com evidência, e muda por parâmetro.

No gate, o arquiteto humano decide (não é pergunta de negócio): os campos novos em `CommercialSignal__c` e no CMDT (mudança de modelo de dados, seção 2.3) e a versão base do `SFAgent2` (R-4).

## 8. O que NÃO será feito

Escrita em Account, Opportunity, Order ou OrderItem; trigger, Flow ou validation rule nesses objetos; alteração de `LastPurchase__c`, `Inactive__c` ou dos relatórios da pasta MARKETING CLOUD; tratamento de devoluções (`SalesReturn__c`) e correção da sua integração; regra de compatibilidade técnica item a item; campo ou cálculo de região; recálculo sob demanda pelo agente; agente ou tópico novo; notificação ao vendedor; qualquer envio pelo CRM ou configuração no Marketing Cloud; campanha/membro de campanha; alteração de perfis; correção do filtro do `OrderScheduledFlow` (R-7 da rodada anterior).

## 9. Entregas para o builder

1. Confirmar 0 jobs `CommercialSignalScheduler` agendados; não deixar job agendado na dev.
2. Campos novos em `CommercialSignal__c` (4) e valor `HistoricoInsuficiente`; campos novos no CMDT (6) e valores do `Default` (seção 2.4), todos com descrição.
3. Ajustar `CommercialSignalService`, `CommercialSignalBatch`, `CommercialSignalGroupStatsBatch` e testes/factory (seção 2.4), com fixtures nos limites novos e nas 17 regras de Order.
4. Criar `CommercialSignalAgentAction` + `CommercialSignalAgentActionTest` (teste como usuário com o permission set).
5. Versão nova inativa do `SFAgent2` com a ação no tópico `insights_comerciais`; seção "Versões e ativação" no plano (base, entra, sai, desfazer).
6. Tipo de relatório e relatório com as colunas novas; FLS e `classAccess` nos permission sets.
7. QA: medir na QAS, por contagem, o preenchimento de `IssuanceDate__c` em pedidos faturados (PA-23) e repetir as premissas no roteiro do cliente.

## 10. Estimativa de esforço

**Estimativa de esforço:** 40–68 h

O que mudou em relação à análise (60–110 h) e ao design anterior (56–96 h): o recon mostrou que objeto, CMDT, 4 classes com testes, relatório e permission sets já existem e passaram no QA; a rodada é de ajuste. Composição: campos, CMDT, picklist, relatório, tipo de relatório e permission sets (5–8 h); ajuste das 3 classes de cálculo e dos testes aos novos limites, família, mês fechado e histórico insuficiente (16–26 h); ação do agente, teste e versão nova do `SFAgent2` (8–14 h); verificação de volume/CPU, QA agendado em duas sessões e roteiro (8–14 h); homologação e ajuste de parâmetro (3–6 h). Não inclui compatibilidade técnica item a item, devoluções nem trabalho no Marketing Cloud.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

## Decisão do responsável no gate (2026-11-17): aprovado sem a consulta pelo assistente

Decidido por Leonardo Barbosa em 17/11. O desenho desta rodada está aprovado **com um
corte de escopo**. Vale acima do que as seções anteriores dizem sobre o `SFAgent2`.

**Fica fora desta rodada (não construir):**
- a classe `CommercialSignalAgentAction` e o teste `CommercialSignalAgentActionTest`;
- a ação `ConsultarSinaisComerciais_EPLAST33` e qualquer versão nova do `SFAgent2`
  (o agente não é tocado; a pendência R-4 da versão base deixa de existir);
- o `classAccess` dessa classe nos permission sets e os casos de teste da consulta pelo
  assistente.

A consulta pelo assistente volta a ser fase seguinte, como na rodada anterior (PA-1). O
roteiro do cliente diz isso em "O que assumimos e você precisa confirmar": o canal desta
entrega é o relatório; o assistente fica para uma próxima etapa.

**Aprovado como desenhado:**
- os 4 campos novos e o valor `HistoricoInsuficiente` em `CommercialSignal__c`, e os 6
  campos novos em `CommercialSignalSetting__mdt` (seção 2.3);
- o ajuste das classes de cálculo e dos testes: 90 dias, último mês fechado contra a média
  dos três anteriores, queda de 20%, por família, histórico insuficiente, venda cruzada por
  segmento (`Sector__c`) com região como filtro;
- tipo de relatório, relatório e permission sets com as colunas novas;
- as premissas da seção 5 e o que a seção 8 deixa de fora (compatibilidade técnica item a
  item, devoluções, data de faturamento pela data do pedido até o QA medir `IssuanceDate__c`).

Estimativa com o corte: a faixa de 40–68 h cai pela parte da ação do agente (8–14 h).
