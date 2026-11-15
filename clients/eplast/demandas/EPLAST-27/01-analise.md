# Análise — EPLAST-27: Próxima melhor ação por cliente

**Org conferida:** `sbx-eplast-dev` (confirmada com `sf org list` em 2026-11-15, Status Connected).
Leituras só de metadata e contagens agregadas; nenhuma escrita, DML ou deploy.
**Estado atual da dev:** 0 Account, 0 Opportunity, 0 Order, 0 Task (`COUNT`). Os critérios de aceite
abaixo exigem massa de teste fictícia criada na sandbox de QA; a dev não serve para validar o resultado.
**Base desta versão:** refeita pela regra 4 da conta Eplast (decisão de 2026-11-15). A rodada anterior
(`rodada-anterior/`) foi usada só como referência de levantamento e de perguntas, não como decisão.

---

## 1. Contexto de negócio

A Eplast contratou a Konecta para a implantação de IA no Salesforce Sales e Marketing. Esta demanda,
"sugerir ao vendedor a próxima melhor ação para cada cliente, com base no histórico e na situação
comercial", pertence à Onda 3 · Comercial, que `contrato.md` lista como não contratada. Pela regra 1 da
conta, o escopo não bloqueia: a frente segue análise, desenho e build. Essa observação não é pendência.

Há sobreposição com o que já existe ou está contratado, e isso precisa ser tratado antes do design:

- O agente `SFAgent2` (Bot e GenAiPlannerBundle `SFAgent2_v1` a `v4`) existe na dev, confirmado por
  metadata nesta etapa. O tópico `insights_comerciais` já foi descrito, no recon de 2026-11-10, como
  responsável por "identificar oportunidades paradas, pedidos pendentes e sinais de risco na carteira do
  vendedor" (`[demandas/EPLAST-27/rodada-anterior/02-recon.md]`). Pela regra 3 da conta, "recomendação"
  estende o `SFAgent2`; não cria agente novo.
- A EPLAST-28 trata de alerta proativo de oportunidade parada (`[demandas/EPLAST-28/02-recon.md]`).
- Os entregáveis `eplast-ent-09`, `10` e `11` do contrato (Onda 2) cobrem clientes que precisam de
  acompanhamento, resumo do cliente e clientes sem compra recente (`contrato.md`).

Sem uma regra única, a Eplast acabaria com três "próximas ações" diferentes. A decisão abaixo (P7) evita isso.

## 2. Objetivo

Dado um cliente, o vendedor obtém uma sugestão da próxima ação a tomar, calculada a partir de sinais que a
org já mantém. A sugestão aparece no assistente de IA, é apenas leitura e não grava nem dispara nada no CRM.

## 3. O que a demanda não diz e como foi resolvido

| # | Pergunta do card (2026-11-13) | Como foi resolvida | Onde está |
|---|---|---|---|
| Q1 | Lista de ações e critério de prioridade | Org e padrão: a org não tem motor de recomendação (0 `RecommendationStrategy`, sem metadata). Os sinais que existem (risco, atividade, data da última compra) indicam três ações simples com prioridade fixa | P1, P2 |
| Q2 | Fontes de "histórico e situação comercial" | Org: `Account.LastPurchase__c` é um resumo de MAX sobre Opportunity, ou seja, a org já define "última compra" a partir de Opportunity. Order fica fora da v1 | P3 |
| Q3 | Onde aparece: página do registro ou assistente | Regra 3 da conta: pedido de "recomendação" vai para o `SFAgent2` | P4 |
| Q4 | Regra fixa ou IA generativa | Padrão e LGPD: regra determinística. Usar LLM para decidir exigiria a decisão LGPD ainda aberta (D6 da EPLAST-23) e não é necessário para a v1 | P5 |
| Q5 | Público e frequência | Padrão e assessment: cálculo sob demanda, na leitura, sem gravar nada. Isso evita nova automação em Account, Opportunity e Order | P6 |
| Contrato | Onda 3 não contratada | Regra 1 da conta: não é pendência nem motivo de bloqueio | seção 1 |
| Sobreposição | Com `insights_comerciais`, EPLAST-28 e `eplast-ent-09/10/11` | Regra 3 da conta: estender, não duplicar | P7 |

## 4. Evidências da org (confirmadas nesta etapa por `sf`, só metadata)

- `Account.Risk__c`: campo de lista de opções (valores ainda não lidos; ver P1).
- `Account.LastPurchase__c`: "Resumo da totalização (MAX Oportunidade)".
- `Account.TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c`, `LastMonthPurchaseValue__c`,
  `LimitUsed__c`, `Saldo_duplicatas_a_vencer__c`: moeda, existem.
- `Account.AccountHasCheckInTask__c`: caixa de seleção, existe.
- `Opportunity.StageName` (lista), `CloseDate` (data), `LastActivityInDays` e `LastStageChangeInDays`
  (número), existem.
- `Opportunity.IqScore`: número, existe, mas o significado não foi confirmado. Não é usado na v1.
- `RecommendationStrategy`: sem metadata na org. Nenhum motor de recomendação nativo está confirmado.
- Bot `SFAgent2` e GenAiPlannerBundle `SFAgent2_v1` a `v4`: existem. O estado ativo da versão e o texto
  atual do tópico `insights_comerciais` vêm do recon de 2026-11-10 e não foram reabertos aqui. O recon
  desta rodada precisa confirmar antes do design.

## 5. Regra de negócio (v1, com as premissas aplicadas)

Avaliada nesta ordem; a primeira que casar vence:

1. **A1 · Tratar risco da conta.** `Account.Risk__c` está num valor de risco (lista de valores a confirmar no recon).
2. **A2 · Retomar oportunidade parada.** Existe Opportunity aberta da conta com `LastActivityInDays` maior que 30 dias.
3. **A3 · Reativar cliente sem compra recente.** `Account.LastPurchase__c` é anterior a 90 dias da data de consulta.
4. **Nenhuma ação prioritária.** Nenhuma das condições acima casou.
5. **Dados insuficientes.** A conta não tem Opportunity nem `LastPurchase__c` preenchido. Não é erro.

Os limiares (30 e 90 dias) e a lista de ações ficam em Custom Metadata, para mudar sem deploy de código.

## 6. Critérios de aceite (Gherkin)

Todos os cenários são testados em `sbx-eplast-qa`, com registros fictícios. Nenhum dado real de cliente.

```gherkin
Funcionalidade: Próxima ação sugerida no assistente (insights_comerciais)

  Cenário: Conta com risco alto recebe A1 com prioridade sobre A2
    Dado que a conta de teste tem Risk__c num valor de risco
    E que a mesma conta tem uma Opportunity aberta com LastActivityInDays igual a 45
    Quando o vendedor dono da conta pergunta ao assistente a próxima ação para essa conta
    Então a resposta indica "Tratar risco da conta"
    E a resposta não indica "Retomar oportunidade parada"

  Cenário: Conta sem risco e com oportunidade parada recebe A2
    Dado que a conta de teste não tem Risk__c preenchido
    E que tem uma Opportunity aberta com LastActivityInDays igual a 31
    Quando o vendedor dono da conta pergunta ao assistente a próxima ação
    Então a resposta indica "Retomar oportunidade parada" e cita o estágio da oportunidade

  Cenário: Conta sem risco e sem oportunidade parada, com última compra há 91 dias, recebe A3
    Dado que a conta de teste tem LastPurchase__c com data de 91 dias atrás
    E que não tem Opportunity aberta com mais de 30 dias sem atividade
    Quando o vendedor dono da conta pergunta ao assistente a próxima ação
    Então a resposta indica "Reativar cliente sem compra recente"

  Cenário: Conta sem nenhuma condição casada recebe "Nenhuma ação prioritária"
    Dado que a conta de teste não tem risco, tem Opportunity com 5 dias sem atividade e compra há 10 dias
    Quando o vendedor pergunta a próxima ação
    Então a resposta indica "Nenhuma ação prioritária no momento"
    E a resposta não inventa ação fora da lista A1 a A3

  Cenário: Conta nova sem Opportunity nem compra recebe mensagem de dado insuficiente
    Dado que a conta de teste não tem Opportunity e LastPurchase__c está vazio
    Quando o vendedor pergunta a próxima ação
    Então a resposta indica "Dados insuficientes para sugerir ação"
    E nenhuma mensagem de erro técnico é exibida ao usuário

  Cenário: Vendedor não recebe sugestão de conta que não é da sua carteira
    Dado que a conta de teste pertence a outro vendedor
    Quando o vendedor X pergunta a próxima ação dessa conta
    Então a resposta não revela dados da conta
    E o acesso segue o compartilhamento padrão do Salesforce

  Cenário: A consulta não grava nada
    Dado a data e hora de LastModifiedDate de todas as contas e oportunidades de teste
    Quando o vendedor faz 10 consultas de próxima ação
    Então nenhum registro de Account, Opportunity ou Task teve LastModifiedDate alterado
    E nenhum Flow ou trigger de Account, Opportunity ou Order foi executado por essas consultas

  Cenário: A sugestão não dispara comunicação pelo CRM
    Quando a sugestão é apresentada ao vendedor
    Então nenhum e-mail, mensagem ou campanha é enviado pelo CRM
    E o desenho não contém Flow com e-mail alert, Apex de e-mail ou envio fora do Marketing Cloud

  Cenário: A resposta não expõe dado pessoal
    Quando a ação retorna a sugestão
    Então a resposta não contém CPF, e-mail ou telefone de contato da conta
    E os campos usados pela regra são apenas os listados na seção 4

  Cenário: Mudar um limiar altera a sugestão sem deploy de código
    Dado que o limiar de A2 está em 30 dias no Custom Metadata
    Quando o limiar é alterado para 60 dias e a conta de teste tem Opportunity com 45 dias sem atividade
    Então A2 deixa de ser sugerida para essa conta

  Cenário: Mesma regra para os demais consumidores
    Dado que a EPLAST-28 e o entregável eplast-ent-11 consumirem a mesma regra
    Quando A2 e A3 forem calculados para uma mesma conta
    Então os três consumidores recebem o mesmo resultado
```

Métrica sem critério de aceite (registrada, não reprova): latência da resposta do assistente. A Eplast
precisa definir o limite antes da homologação.

## 7. Premissas assumidas (validar na homologação)

- [x] **P1 · Lista de ações e prioridade (Q1).**
  - Decisão: A1, A2, A3 e "nenhuma" na ordem da seção 5.
  - Evidência: não há motor de recomendação nativo na org (0 `RecommendationStrategy`). Os campos que a org já
  mantém (`Risk__c`, `LastActivityInDays`, `LastPurchase__c`) indicam as três ações. A ordem é a mais simples
  de explicar.
  - Como mudar: lista e prioridade em Custom Metadata. O valor da picklist `Risk__c` que conta como risco
  deve ser confirmado com `sf` no recon.

- [x] **P2 · Limiares (30 dias sem atividade em oportunidade, 90 dias sem compra).**
  - Decisão: 30 e 90 dias como valor de partida.
  - Evidência: não há parâmetro de negócio na org nem no contrato. São valores iniciais de uso simples, não
  um padrão comprovado. Por isso ficam em Custom Metadata.
  - Como mudar: alterar o registro de Custom Metadata. Não exige deploy de código.

- [x] **P3 · Fontes (Q2).**
  - Decisão: Account e Opportunity. Order e OrderItem ficam fora da v1. Task entra só pelo campo
  `AccountHasCheckInTask__c`, se o recon confirmar que ele é preenchido.
  - Evidência: `LastPurchase__c` já é derivado de Opportunity na org. A dev tem 0 Order, e o contrato registra
  risco de qualidade dos pedidos vindos do Protheus (eplast-ent-11). Order é o objeto mais exposto ao achado 1
  do assessment.
  - Como mudar: incluir Order numa demanda futura, depois de validar a qualidade dos dados com o Comercial.

- [x] **P4 · Canal (Q3).**
  - Decisão: a sugestão aparece no assistente, como cenário do tópico `insights_comerciais` do `SFAgent2`.
  Não cria agente novo nem componente novo na página do registro.
  - Evidência: regra 3 da conta (pedido de recomendação estende o `SFAgent2`). O tópico já cobre a carteira do vendedor.
  - Como mudar: se a Eplast quiser o aviso na página do registro, é um canal novo. Pode ser feito depois, lendo a
  mesma regra (P7), sem reescrever a lógica.

- [x] **P5 · Regra determinística, sem LLM na decisão (Q4).**
  - Decisão: A1 a A3 são calculados por regra. O texto da sugestão é um modelo fixo, e o assistente apenas o apresenta.
  - Evidência: padrão (regra simples e auditável, sem modelo). Usar LLM para decidir exigiria a decisão LGPD
  pendente (D6 da EPLAST-23), e a Eplast não pediu IA generativa neste item.
  - Como mudar: texto gerado por IA ou modelo preditivo viram demanda própria, com decisão LGPD e levantamento
  de licença e de dado de treino.

- [x] **P6 · Público e frequência (Q5).**
  - Decisão: a sugestão é calculada sob demanda, na consulta, e não é gravada. Quem vê é o vendedor dono da conta
  (carteira). Gestores não entram na v1.
  - Evidência: o assessment recomenda não criar automação nova em Account, Opportunity e Order. A carteira já é o
  recorte do tópico `insights_comerciais`.
  - Como mudar: cálculo em lote ou visão de gestor são decisões posteriores. Gravar a sugestão em campo exige
  mapear antes a ordem de execução de Account e Opportunity.

- [x] **P7 · Sobreposição com o que já existe (B1).**
  - Decisão: a regra da seção 5 é a única. Entra como cenário do `insights_comerciais`. EPLAST-28 e
  `eplast-ent-11` devem consumir a mesma regra, e não criar outra.
  - Evidência: regra 3 da conta; o `insights_comerciais` já descreve oportunidades paradas e sinais de risco;
  o contrato lista `eplast-ent-09/10/11` na Onda 2.
  - Como mudar: se a Eplast preferir separar, a EPLAST-28 ou o `eplast-ent-11` podem ter regra própria. Isso
  precisa ser decidido antes do design, para não ter duas "próximas ações".

## 8. Pendências

Nenhuma pendência de caso 3 (errar é caro ou difícil de desfazer, e nem a org nem o padrão indicam caminho).
Todas as perguntas de regra de negócio foram resolvidas como premissas acima, com evidência e como mudar.

## 9. Riscos do assessment que tocam esta demanda

- **Achado 1 (automação concorrente em Account, Opportunity e Order), alta.** A v1 só lê. Não cria trigger,
  Flow nem campo gravado nesses objetos, então não entra na ordem de execução não mapeada. Se algum
  componente exigir escrita nesses objetos, a análise volta ao gate.
- **Achado 2 (cobertura Apex de 10%), alta.** Se o design precisar de Apex invocável, a classe nova deve ser
  `<Classe>Test` com cobertura de 85% pelo menos, e não pode tocar a cadeia de envio ao Protheus.
- **Achado 6 (sbx-eplast-dev aponta para instância "qa"), média.** Confirmar a separação dev e QA antes da
  sessão de QA. A QA é o único lugar onde os cenários da seção 6 são validados.
- **Achado de campos sem descrição (153 campos em Account, Order, Opportunity e OrderItem), média.** Qualquer
  campo ou metadata novo sai com descrição.
- **Validation rules de Opportunity (16 ativas, `[demandas/EPLAST-28/02-recon.md]`).** A massa de teste em QA
  precisa satisfazê-las.

## 10. Complexidade e estimativa

**Complexidade: M.** Não há objeto novo nem automação nova nos objetos sensíveis, e a ambiguidade foi
resolvida por premissas. O peso vem de tocar o agente existente (nova versão do `SFAgent2`) e de criar massa de
teste fictícia em QA.

**Estimativa de esforço:** 32–56 h
Premissas que mais pesam na faixa:
- Lógica expressa em tópico e ações declarativas do `SFAgent2`. Se não couber, Apex invocável com teste dedicado (+8 a 16 h).
- Regra em Custom Metadata, sem objeto novo.
- Nova versão do `SFAgent2` coordenada com a EPLAST-29 (decisão de versão, D3 do design anterior).
- Massa de teste fictícia criada em QA; a dev está vazia.
- Duas rodadas de homologação com key users. Order não entra na v1.

O arquiteto refina a faixa no design.

## 11. Encerramento

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
