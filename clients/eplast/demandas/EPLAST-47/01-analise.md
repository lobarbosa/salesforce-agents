# EPLAST-47 — Análise: correção do Fluxo Agendado – Oportunidade

**Cliente:** Eplast · **Etapa:** 1 (análise, `ba-discovery`) · **Data:** 2026-11-14
**Org conectada e confirmada:** `sbx-eplast-dev` (sandbox, Org ID `00DHa000006vfMLMAY`, `IsSandbox` na org de dev). Única org conectada nesta sessão. Nenhuma ação de escrita foi feita.
**Entrada:** `demanda.md` (história do consultor, baseline de 17/10). Os pontos do baseline foram reconfirmados na org de dev hoje, conforme indicado no próprio card.
**Status:** pronta para o gate humano de análise. Não aprova gate; não aciona o arquiteto.

---

## 1. Contexto de negócio

O fluxo agendado `ScheduledFlowOpportunity` ("Fluxo Agendado - Oportunidade") calcula, todo dia 14, o valor de compras do último mês e a classificação (ranking) de cada conta. Esses valores alimentam a área comercial e a integração com o Protheus (o permission set `Protheus` lê `Account.Ranking__c`, `Account.AveragePurchasesThisYear__c` e `Account.LastMonthPurchaseValue__c`).

Hoje o fluxo tem problemas de desenho que afetam o resultado e a operação:
- roda uma vez por oportunidade ganha, não por conta;
- grava a soma anual no campo de "último mês";
- classifica pela média, não pela soma que ele mesmo grava;
- tem faixas erradas e não cobre 2 das 7 classificações previstas;
- tem uma consulta sem filtro de conta que não tem uso;
- tem um e-mail de alerta para um ex-parceiro que não está no fluxo (ver seção 4).

## 2. Objetivo

Corrigir o fluxo para que: (a) processe por conta, uma vez por execução; (b) calcule o valor de compras por regra configurável; (c) classifique as contas por faixas configuráveis cobrindo as 7 classificações; (d) remova o alerta obsoleto e trate falhas com destinatário configurável; (e) fique testado na sandbox de QA com evidência por cenário.

Fora de escopo desta análise: promoção para QAS e produção (card EPLAST-48); definição das respostas de negócio (cabe ao cliente).

## 3. Análise funcional

### 3.1 Comportamento atual (confirmado na org de dev, versão ativa 1, `LastModifiedDate` 2024-07-04)

| Ponto | Comportamento confirmado | Evidência |
|---|---|---|
| Gatilho | Agendado, objeto `Opportunity`, filtro `IsWon = true`, frequência diária | metadata da org (flow retrieved) |
| Dia 14 | Decisão `CheckDayMonth` com `numberValue 14`, dentro do caminho diário | metadata da org |
| Soma | `AssignSumValue` soma `Amount` das oportunidades de `GetOpportunities` (filtro `AccountId`, `StageName = Fechado/Ganho`, `ThisYear__c = true`) | metadata da org |
| Gravação | `LastMonthPurchaseValue` grava em `Account.LastMonthPurchaseValue__c` (campo de "último mês") | metadata da org |
| Classificação | Faixas lidas de `Account.AveragePurchasesThisYear__c`, não da soma gravada | repo e org (mesma estrutura) |
| Faixas | PP `= 10.000`; P `> 10.000 e ≤ 70.000`; M `> 70.000 e ≤ 150.000`; G `> 150.000 e ≤ 500.000`; resultado padrão = GG | metadata da org |
| Consulta órfã | `GetOpportunities2` filtra só `LastMonth__c = true`, sem conta; é o `noMoreValuesConnector` do loop e nenhum elemento lê seu resultado | metadata da org (única referência é o conector) |
| Alertas | Não há ação de e-mail (`emailSimple`/`emailAlert`) no fluxo da org | metadata da org |

### 3.2 Os 4 pontos do diagnóstico (H1)

1. **Execução por oportunidade — confirmado.** O gatilho é o objeto `Opportunity`, e a atualização de `Account` ocorre por oportunidade ganha. A correção por conta exige mudar o ponto de entrada do fluxo (ou o agrupamento), o que é desenho do arquiteto.
2. **Soma anual gravada no campo de último mês — confirmado.** `AssignSumValue` soma o ano (`ThisYear__c`), e o resultado vai para `LastMonthPurchaseValue__c`.
3. **Consulta sem filtro de conta — confirmado.** `GetOpportunities2` só filtra `LastMonth__c`, e seu resultado não é usado.
4. **Alertas para ex-parceiro — refutado no fluxo, não localizado na org.** O fluxo não tem e-mail. Não é possível dizer, com o que foi lido, onde o alerta está. A org tem 11 `WorkflowAlert` no total, mas a consulta não permite filtrar por objeto (campo não existe no tooling); `WorkflowRule` sobre `Opportunity` e `Account` = 0. Ficou como incerteza (seção 5).

### 3.3 Outros achados confirmados

- `Opportunity.ThisYear__c` é fórmula `IF(YEAR(DATEVALUE(CreatedDate)) = YEAR(DATEVALUE(NOW())), true, false)`. Usa **data de criação**, não de fechamento. A demanda já aponta isso.
- `Account.Ranking__c` (lista de opções) tem **5 valores ativos: PP, P, M, G, GG**. Faltam **MP** e **3G**. Confirmado via `sobject describe`.
- A org tem **2 fluxos** gravando campos de compra em `Account`: `ScheduledFlowOpportunity` (grava `LastMonthPurchaseValue__c` e lê `AveragePurchasesThisYear__c`) e `OpportunityFlow` (grava `AveragePurchasesThisYear__c` e `TotalPurchasesThisYear__c`, no repo). Os dois escrevem em `AveragePurchasesThisYear__c`. Isso é concorrência de dado, não só de ordem (ver seção 6).

### 3.4 Regras de negócio que a demanda define (texto do cliente, não inventado)

**Faixas (H4).** Cada faixa começa "acima de" o limite da anterior; o limite superior é "até".

| Classificação | Faixa (valor de compras) | Intervalo proposto (a validar, ver P7) |
|---|---|---|
| MP | até 10.000 | 0 < v ≤ 10.000 |
| PP | até 35.000 | 10.000 < v ≤ 35.000 |
| P | até 80.000 | 35.000 < v ≤ 80.000 |
| M | até 160.000 | 80.000 < v ≤ 160.000 |
| G | até 500.000 | 160.000 < v ≤ 500.000 |
| GG | até 1.000.000 | 500.000 < v ≤ 1.000.000 |
| 3G | acima de 1.000.000 | v > 1.000.000 |

Faixas antigas (10.000 / 70.000 / 150.000 / 500.000) saem do fluxo.

**Cálculo (H3).** Período lido de configuração. Premissa provisória do cliente: base anual, só oportunidades ganhas (`IsWon`). Conta sem compra recebe zero ou vazio, configurável.

**Alerta (H5).** Remover o e-mail do ex-parceiro. Caminho de falha com destinatário configurável. O endereço será informado pela Eplast.

## 4. Critérios de aceite (testáveis)

Escritos como Gherkin. Os exemplos de valor são os limites do item 3.4 e devem ser executados na sandbox de QA.

**H1 — Análise de impacto**
1. Dado o documento de análise de impacto, então ele lista, para cada campo lido ou gravado, o nome de API, quem lê e quem grava (fluxo, relatório, permission set, layout, página, integração). Evidência: tabela no `02-recon.md` ou no design.
2. Dado os 4 pontos do diagnóstico, então cada um está marcado como confirmado ou refutado com evidência de metadata. O ponto 4 (alerta) fica como "não localizado" até que a origem do alerta seja identificada.
3. Dado `Account.Ranking__c`, então a análise declara a lista ativa (5 valores hoje) e a lista desejada (7 valores).

**H2 — Execução por conta**
4. Dado 3 oportunidades ganhas da conta A e 1 da conta B no dia 14, quando o fluxo roda, então `Account A` é atualizada 1 vez e `Account B` 1 vez, não 4 vezes.
5. Dado o fluxo em execução, então nenhuma consulta de `Opportunity` no loop é feita sem filtro de `AccountId` (conferido no debug log ou no XML final).
6. Dado uma execução com 50 contas no lote de QA, então o número de erros `UNABLE_TO_LOCK_ROW` nos logs é 0.

**H3 — Cálculo do valor de compras**
7. Dado que o período está na configuração X, quando o período muda para Y sem alterar código, então o valor calculado muda conforme Y.
8. Dado uma conta com oportunidades ganhas de 3.000 e 2.000 no período e uma oportunidade perdida de 9.000, então o valor de compras é 5.000 (perdida não entra).
9. Dado uma conta sem oportunidade ganha no período, então o valor gravado é o valor configurado (zero ou vazio). Pelo menos um dos dois testado com a configuração escolhida.

**H4 — Classificação por faixas**
10. Dado os valores 10.000 / 10.000,01 / 35.000 / 35.000,01 / 80.000 / 80.000,01 / 160.000 / 160.000,01 / 500.000 / 500.000,01 / 1.000.000 / 1.000.000,01 (todos na moeda da org), então as classificações são MP / PP / PP / P / P / M / M / G / G / GG / GG / 3G, nessa ordem. Ajustar conforme P7.
11. Dado valor zero e valor vazio, então a classificação segue o que a configuração definir (P6), sem cair em GG por padrão.
12. Dado o XML final do fluxo, então não existe nenhum valor de faixa antiga (10.000, 70.000, 150.000 ou 500.000 como limite do fluxo antigo) fora da nova configuração.
13. Dado o picklist `Account.Ranking__c`, então os valores ativos são exatamente MP, PP, P, M, G, GG, 3G.
14. Dado uma execução que muda a classificação de N contas, então o relatório de mudanças mostra N contas, com a classificação anterior e a nova (o relatório ainda precisa de local, ver P12).

**H5 — Alertas**
15. Dado o fluxo final, então nenhum e-mail ou endereço fixo do ex-parceiro existe nele.
16. Dado uma falha forçada numa atualização de conta na QA, então o caminho de falha envia o aviso ao destinatário configurado. Dado que o destinatário não está configurado, então o fluxo não envia e registra a falha.

**H6 — Testes (QA)**
17. Dado os cenários de borda das faixas (limites, +0,01, zero e vazio) e a lista de 15 cenários definida no design, então cada cenário tem evidência (valor de entrada, saída esperada, saída obtida) em `05-testes.md`, executada na sandbox de QA, não na de dev.
18. Dado o teste de volume, então o critério só é testável com número de contas e de oportunidades informado (ver P10). Sem esses números, este critério é uma intenção, não um aceite.

## 5. Dependências e incertezas

- A demanda diz "Sem Apex". Não foi confirmada, nesta análise, a inexistência de Apex que chame o fluxo ou que atualize os mesmos campos. O repo tem `AccountTrigger`, `OpportunityTrigger` e `OrderTrigger` (`force-app/main/default/triggers`). Para o H1 é necessário mapear se algum deles atualiza `LastMonthPurchaseValue__c`, `AveragePurchasesThisYear__c` ou `Ranking__c`.
- Relatórios e painéis que usam esses campos **não estão no repo**. Não foram localizados nesta sessão. A demanda já pede que o recon os encontre. Incerteza: quais existem e quais estão ativos.
- Integração Protheus: o permission set `Protheus` lê os campos. Não se confirmou se o ERP recebe `Ranking__c` e se aceita `MP` e `3G`. Incerteza que pesa diretamente em P8.
- Origem do alerta para o ex-parceiro: não está no fluxo. Pode estar em outra automação ou em alerta de workflow. Não localizado.
- QA: o Org ID da sandbox de QA usado como referência (`00DHa000006vZtmMAE`) vem do histórico do RAG (`EPLAST-31/05-testes.md`). Não foi reconfirmado nesta sessão, pois só a dev está conectada. O assessment (achado 6) registra dúvida sobre dev × qa; os Org IDs diferentes indicam sandboxes distintas, mas a confirmação por `sf org display` na QA fica para a etapa de QA.

## 6. Riscos do assessment que tocam esta demanda

Fonte: `clients/eplast/assessment.md` (resumo no briefing da conta, saúde vermelha, foto de 2026-09-30). Nenhum trecho foi aberto integralmente.

- **Automação concorrente em Account/Opportunity** (CPQ, Marketing Cloud Connect, pacotes gerenciados e automação própria no mesmo evento). A demanda toca Opportunity e Account. Antes do desenho, mapear a ordem de execução entre `ScheduledFlowOpportunity`, `OpportunityFlow`, `OpportunityTrigger`, `AccountTrigger` e o CPQ. Risco alto: `AveragePurchasesThisYear__c` é escrito por dois fluxos. Consta também que a org tem trigger `OrderTrigger` colidindo em nome com o do pacote SBQQ.
- **Cobertura Apex de 10%**. Se o build não tocar Apex, o mínimo de 75% de deploy não se aplica diretamente. Se o arquiteto optar por classe Apex para o cálculo, a classe precisa de `<Classe>Test` e de cobertura mínima de 85%, e entra no escopo de integração com o Protheus, que o assessment prioriza.
- **Campos sem descrição** (153 em Account/Order/Opportunity/OrderItem). Os campos novos ou alterados (ex.: período de configuração e destinatário, se forem campos) devem nascer com descrição.
- **Dúvida dev × qa**. Afeta diretamente o H6: a evidência de teste tem que vir da sandbox de QA. Ver seção 5.
- **Validation rules de Order** (23). Não se aplica se a demanda não gravar em Order. Confirmar no desenho que não grava.

## 7. Marketing Cloud (regra 2 do cliente)

- O alerta de falha (H5) é operacional, não marketing. Se a Eplast entender que é mensagem de marketing, a regra 2 manda o envio ao Marketing Cloud, e o CRM fica só com o dado. Isso é decisão do cliente (P5), não é escolhido aqui.
- Nenhum passo de disparo de marketing foi identificado nesta demanda. Se o desenho exigir, ele vai como passo de quem opera o Marketing Cloud, fora da esteira.

## 8. Reaproveitamento (regra 3 do cliente)

- Nenhum agente Agentforce é necessário. A demanda é de automação (Flow agendado), não de assistente.
- O componente existente é `ScheduledFlowOpportunity`. A regra manda ajustar o existente, não criar fluxo novo para o mesmo cálculo. Pelo mesmo motivo, o relatório de mudança de classificação (H4) deve primeiro conferir se já existe relatório que atende; a busca não foi feita nesta sessão (ver P12).
- Campos `LastMonthPurchaseValue__c`, `AveragePurchasesThisYear__c`, `TotalPurchasesThisYear__c`, `Ranking__c` já existem. Reutilizar; não criar campo novo para o mesmo dado sem justificativa no design.

## 9. Perguntas de negócio pendentes

Perguntas de regra de negócio sem resposta. Não foram respondidas nem assumidas. Marcadas por impacto.

| # | Pergunta | Quem responde | Impacto |
|---|---|---|---|
| **P1** | **Premissa do cálculo: base anual e só oportunidades ganhas?** Provisória. Aguarda a Tatiana. | Tatiana (Eplast) | Bloqueia H3 em QAS. Build configurável pode seguir se o gate aceitar a premissa provisória. |
| **P2** | **Qual data define a compra?** `ThisYear__c` usa `CreatedDate`. A regra usa data de criação ou de fechamento (`CloseDate`)? | Eplast | Bloqueia H2/H3. |
| **P3** | **A classificação usa a soma do período ou a média?** Hoje o fluxo classifica pela média e grava a soma. As faixas são sobre o valor total? | Eplast | Bloqueia H4. |
| **P4** | **O campo `LastMonthPurchaseValue__c` deve continuar com esse nome se passar a guardar o valor do período?** Renomear ou manter e mudar o uso? | Eplast + arquiteto | Bloqueia H3 (afeta permission set, layout, página e Protheus). |
| **P5** | **O alerta de falha é operacional ou de marketing?** Se marketing, vai ao Marketing Cloud (regra 2). | Eplast | Bloqueia H5. |
| **P6** | **Conta sem compra: zero ou vazio?** | Eplast | Configurável; decide o padrão. |
| **P7** | **Limite superior é inclusivo?** A tabela do item 3.4 assume (anterior, atual]: 10.000 vira MP, 10.000,01 vira PP. Confirmar. | Eplast | Bloqueia H4 (critérios 10 e 11). |
| **P8** | **MP e 3G são aceitos pelo Protheus?** Se o ERP lê `Ranking__c`, precisa de mapeamento para os 2 novos valores. | Eplast + integração Protheus | Bloqueia H4 em QAS. |
| **P9** | **O fluxo continua agendado diariamente com checagem do dia 14, ou passa a agendado mensal?** | Eplast + arquiteto | Afeta H2. |
| **P10** | **Números do teste de volume** (contas e oportunidades). | Eplast | Critério 18 não é testável sem eles. |
| **P11** | **Quem é o destinatário do alerta de falha?** O endereço é da Eplast. Não será inventado. | Eplast | Bloqueia H5 em QAS. Build configurável pode seguir. |
| **P12** | **Onde fica o relatório de contas que mudam de classificação?** Existe relatório que já atende? | Eplast + recon | Afeta H4 (critério 14). |

**Bloqueantes para o desenho (antes do arquiteto):** P2, P3, P4 e P7. Sem essas respostas, o desenho de H2 a H4 vira suposição.
**Bloqueantes para promoção a QAS:** P1, P5, P8 e P11, conforme a demanda.

## 10. Complexidade e esforço

**Complexidade: G.** Reescrita de fluxo com mudança de ponto de entrada, configuração por metadado, 7 valores de picklist, caminho de falha, relatório novo, mapeamento de concorrência em Account/Opportunity e teste de QA com evidência por cenário.

**Estimativa de esforço:** 30–50 h
Premissas que mais pesam na faixa:
- respostas de P2, P3 e P4 chegam antes do design (sem elas a faixa sobe para o topo);
- o mapeamento de concorrência com OpportunityFlow, triggers e CPQ fica dentro das horas e não vira projeto à parte;
- Apex não é necessário (se o arquiteto optar por Apex, a faixa sobe);
- o alerta de falha fica em caminho simples, com destinatário configurável (P11);
- a integração Protheus não exige mudança fora do CRM (P8).

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
