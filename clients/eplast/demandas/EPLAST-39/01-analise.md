# EPLAST-39 — Análise: Origem dos leads e retorno das campanhas

**Data:** 2026-11-15 · **Etapa:** analise (refeita pela regra 4 da conta, por decisão do Leonardo em 15/11)
**Org conectada (sf):** alias `sbx-eplast-dev`, instância `https://eplast--qa.sandbox.my.salesforce.com`, usuário com sufixo de QA (identificação omitida por LGPD), `sf org list` = Sandbox, Connected.
**Atenção:** o alias de dev aponta para a instância `eplast--qa`. Ver risco R6 e a pré-condição PC-1.

---

## 1. Situação e motivo do retorno

A análise anterior (`rodada-anterior/01-analise.md`) travou a demanda em perguntas de negócio. O card (2026-11-15 02:13) mandou refazê-la pela regra 4: decidir pela org, depois pelo padrão, registrar cada decisão como premissa assumida e levar à homologação. O que já foi construído e reprovado na QA (`rodada-anterior/05-testes-rodada-1.md`) serve de referência para os critérios; o veredito anterior não é decisão.

Falhas da QA que esta análise endereça:
- **F1 (crítica):** o painel não exibe dado nos 5 componentes. Causa provável: um componente usa relatório em formato que o painel não aceita (relatório de lista, sem agrupamento de resumo). Vira o CA-07.
- **F2:** o grupo de origem vazia aparece como "-", não "Sem origem". Vira CA-02 e premissa P1.
- **F3:** valores de `LeadSource` fora da lista não caem em "Fora da lista". Vira CA-03 e premissa P2.

## 2. Contexto de negócio e objetivo

A Eplast quer medir de onde vêm os leads, quanto cada campanha retorna e quais origens convertem em oportunidade. Hoje não há leitura confiável dessa relação no CRM.

**Objetivo:** entregar um painel com relatórios de origem de lead e de retorno de campanha, sobre dados do CRM, que mostre volume por origem, conversão lead→oportunidade e retorno por campanha, com o rótulo "Sem origem" e "Fora da lista" tratados explicitamente.

Histórico: RAG, `demandas/EPLAST-39/demanda.md` e recon da rodada anterior (`rodada-anterior/02-recon.md`) confirmam o escopo. [demandas/EPLAST-39/demanda.md]

## 3. Escopo

**Dentro:**
- Relatórios de origem de lead (leads criados no período por origem × mês) e de conversão por origem.
- Relatório de campanha: custo, receita e retorno por campanha.
- Dashboard que reúne esses relatórios, com todos os componentes exibindo dado.
- Permission set de leitura para a equipe de Marketing.

**Fora:**
- Envio de qualquer comunicação. Marketing sai pelo Marketing Cloud (regra 2). No CRM fica só o que alimenta o MC.
- Alteração ou exclusão dos 380 relatórios e 20 dashboards já existentes (regra 3).
- Correção em massa de `LeadSource` (ver P3).
- Automação nova em Lead, Campaign, Account, Opportunity ou Order.
- Métricas de envio do Marketing Cloud (aberturas, cliques). Não existem no CRM (ver P10).

**Onda:** a demanda pertence à Onda 4 (Marketing), que não está em `contrato.md`. Pela regra 1 da conta, isso não é pendência nem bloqueio. Segue normalmente.

## 4. Regras de negócio (decididas, com evidência)

| Regra | Decisão | Evidência |
|---|---|---|
| Origem do lead | `Lead.LeadSource` | Campo padrão, picklist não restrita, 13 valores ativos (sf) |
| Lista de origens | As 13 ativas: Campanha, WhatsApp, Indicação, Evento, Google Ads, Google Orgânico, Instagram, Facebook, Prospecção ativa, Prospecção passiva, Econodata, E-mail MKT, SDR | `sobject describe` do Lead (sf) |
| Origem vazia | Linha "Sem origem" | Card, F2; P1 |
| Origem fora da lista | Linha única "Fora da lista", com contagem por valor disponível | Picklist não restrita (sf), F3; P2 |
| Conversão | Leads convertidos (`IsConverted`) sobre total de leads, por origem | Padrão de relatório de conversão |
| Retorno de campanha | Receita de oportunidades ganhas com `CampaignId` ÷ `Campaign.ActualCost` | Campos padrão confirmados (sf); P7 |
| Campanha sem custo | Retorno exibido como "n/a", sem divisão por zero | Regra de consistência |

## 5. Critérios de aceite

Todos testáveis em sandbox de QA com massa sintética ou contagens agregadas. Nenhum critério exige ler dado pessoal.

**Funcionalidade: Origem dos leads**

CA-01. Soma por origem igual ao total
```gherkin
Cenário: soma dos grupos de origem fecha com o total de leads do período
  Dado que existem leads criados no período selecionado
  Quando eu abro o relatório MKT_Leads_por_Origem com esse período
  Então a soma dos grupos (13 origens + "Sem origem" + "Fora da lista") é igual ao total de leads criados no período
  E o total é igual à contagem agregada de Lead no mesmo intervalo
```

CA-02. Origem vazia com rótulo correto
```gherkin
Cenário: lead sem LeadSource aparece como "Sem origem"
  Dado um lead de teste com LeadSource vazio no período
  Quando eu abro o relatório de origem
  Então existe uma linha com o rótulo "Sem origem" com contagem igual ao número de leads com LeadSource vazio
  E nenhuma linha aparece com o rótulo "-"
```

CA-03. Fora da lista agrupada
```gherkin
Cenário: valor de LeadSource fora das 13 origens cai em "Fora da lista"
  Dado um lead de teste com um valor de LeadSource que não está entre as 13 origens ativas
  Quando eu abro o relatório de origem
  Então o lead é contado na linha "Fora da lista"
  E o valor não aparece como linha própria no grupo principal
```

CA-04. Lista de buckets igual à picklist
```gherkin
Cenário: a lista de origens do relatório é a lista ativa da picklist
  Dado a picklist LeadSource consultada por sf describe com 13 valores ativos
  Quando eu comparo com os buckets configurados no relatório
  Então os 13 valores estão presentes, sem valor a mais nem a menos
```

CA-05. Período parametrizável
```gherkin
Cenário: o filtro de período recalcula os totais
  Dado o painel aberto
  Quando eu altero o intervalo de data de criação do lead
  Então todos os componentes recalculam sobre o novo intervalo
  E a soma por origem continua igual ao total do intervalo
```

**Funcionalidade: Conversão**

CA-06. Conversão por origem bate com a contagem
```gherkin
Cenário: taxa de conversão por origem igual a convertidos ÷ total
  Dado uma massa de teste com leads de origens conhecidas, parte convertida (IsConverted = true)
  Quando eu abro o relatório de conversão por origem
  Então a taxa de cada origem é igual a convertidos ÷ total daquela origem
  E a soma dos convertidos é igual à contagem agregada de IsConverted = true no intervalo
```

**Funcionalidade: Retorno de campanha**

CA-07. Dashboard exibe dado em todos os componentes
```gherkin
Cenário: o painel renderiza todos os componentes com dado
  Dado a massa de teste carregada na sandbox de QA
  Quando eu abro o dashboard
  Então todos os componentes exibem dado, sem erro de formato de relatório
  E todo relatório usado em componente é de resumo ou matriz, não de lista
```

CA-08. Retorno por campanha
```gherkin
Cenário: retorno = receita ganha ÷ custo real
  Dado uma campanha de teste com ActualCost > 0 e oportunidades ganhas vinculadas por CampaignId
  Quando eu abro o relatório de campanha
  Então o retorno exibido é igual à soma de Opportunity.Amount ganha ÷ Campaign.ActualCost
```

CA-09. Campanha sem custo
```gherkin
Cenário: campanha sem custo não quebra o relatório
  Dado uma campanha de teste com ActualCost = 0 ou vazio
  Quando eu abro o relatório de campanha
  Então o retorno dessa campanha aparece como "n/a"
  E o relatório não exibe erro de divisão
```

**Funcionalidade: Segurança, escopo e não sobreposição**

CA-10. Nada existente foi alterado
```gherkin
Cenário: relatórios e dashboards existentes ficam intactos
  Dado os 380 relatórios e 20 dashboards da org antes do build
  Quando o build é concluído
  Então o diff de metadata fora da pasta Marketing_Origem_Retorno (e do permission set PS_Marketing_AnaliseCampanhas) é zero
```

CA-11. Permissão somente leitura
```gherkin
Cenário: usuário com o permission set não consegue editar Lead nem Campaign
  Dado um usuário de teste com PS_Marketing_AnaliseCampanhas e sem outras permissões de edição
  Quando ele tenta editar um Lead e uma Campaign
  Então a edição é negada
  E ele consegue ver os relatórios da pasta Marketing_Origem_Retorno
```

CA-12. Sem envio e sem automação nova no CRM
```gherkin
Cenário: o pacote não contém componente de envio nem automação nova em objetos de vendas
  Dado o pacote gerado pelo build
  Quando eu inspeciono os componentes
  Então não há EmailTemplate, EmailAlert, Apex de envio de e-mail nem Flow novo de disparo
  E não há Flow ou trigger novos em Account, Opportunity ou Order
```

CA-13. Relatório de origem sem dado pessoal
```gherkin
Cenário: o relatório de origem é agregado
  Dado o relatório MKT_Leads_por_Origem
  Quando eu confiro as colunas do relatório
  Então não há colunas de nome, e-mail, telefone ou CPF
  E o relatório é de resumo, sem linhas de detalhe de lead
```

CA-14. Pré-condição de ambiente
```gherkin
Cenário: a sandbox de dev é distinta da de QA antes do build
  Dado o alias sbx-eplast-dev
  Quando eu consulto sf org display
  Então a instanceUrl do alias de dev é diferente da instanceUrl do alias sbx-eplast-qa
  E o build não começa enquanto essa diferença não for confirmada
```

## 6. Riscos do assessment que tocam a demanda

Assessment: `clients/eplast/assessment.md`. Saúde geral: vermelho.

- **R1 — Automação concorrente em Account, Opportunity e Order (achado 1).** Não se aplica a escrita: a demanda não cria trigger, Flow nem Apex nesses objetos (CA-12). Aplica-se a leitura: os relatórios de conversão e de campanha leem Opportunity. Leitura não dispara automação. Confirmado por sf: não há trigger em Lead nem Campaign (0 `ApexTrigger`). Não reconfirmei os Flows de Opportunity citados no assessment (`Oportunidade_Industria`, `OpportunityFlow`); fica como premissa de que não são alterados.
- **R2 — Cobertura Apex de ~10% (achado 2).** Se o build não tiver Apex, não se aplica. Se precisar de Apex, a regra do squad (85% por classe e `<Classe>Test`) vale.
- **R3 — Validation rules de Order (achado 3).** Não se aplica: não há escrita em Order.
- **R4 — Campos custom sem descrição (achado 4).** Aplica-se parcialmente. Os campos usados são padrão (`LeadSource`, `ActualCost`, `Amount`, `CampaignId`, `IsConverted`). Campo novo, se o build criar algum, sai com `Description` preenchida.
- **R5 — Nome de trigger duplicado com SBQQ (achado 10).** Não se aplica: nenhuma trigger nova.
- **R6 — Alias de dev apontando para sandbox de QA (achado 6).** **Aplica-se e é o risco que mais pesa.** Confirmei por sf: `sbx-eplast-dev` tem instância `eplast--qa.sandbox.my.salesforce.com` e usuário com sufixo `.qa`. Ou o alias foi conectado à sandbox errada, ou dev e QA são a mesma org. Build ou massa de teste na org errada contamina a QA e fere o guardrail de ambientes. Por isso a pré-condição PC-1.
- **R7 — Sandbox de dev sem registros (achado de volume).** Aplica-se: Lead, Campaign e Opportunity estão em 0 na dev (sf, contagem agregada). Os critérios precisam de massa de teste (P11).

## 7. Premissas assumidas (validar na homologação)

Cada item tem pergunta, decisão, evidência e como mudar. Todos resolvidos (`[x]`) pela regra 4.

- [x] **P1 — Rótulo da origem vazia.** Pergunta (card, item 1): aceitar "-" ou usar "Sem origem"?
  Decisão: "Sem origem".
  Evidência: a QA reprovou o "-" (F2); o campo `LeadSource` não é obrigatório (describe).
  Como mudar: trocar o rótulo do bucket no relatório. Mudança de um texto.

- [x] **P2 — Origens fora da lista.** Pergunta (card, item 2): cada uma em sua linha, ou agrupadas?
  Decisão: agrupadas em "Fora da lista", com contagem por valor disponível em relatório de detalhe agregado, sem dado pessoal.
  Evidência: a picklist não é restrita (describe), então valores fora da lista podem existir; a QA reprovou a ausência do agrupamento (F3).
  Como mudar: trocar o bucket por linha por valor. Mudança de configuração do relatório.

- [x] **P3 — Qualidade do dado `LeadSource`.** Pergunta (card, item 3): quem cuida?
  Decisão: esta demanda não corrige dado. O painel mostra o volume de "Sem origem" como indicador. O dono da correção é a Eplast (processo comercial ou SDR), a ser definido na homologação.
  Evidência: correção em massa de dado de cliente sem decisão do dono é difícil de desfazer; a dev não tem dado para medir (R7); o padrão do squad é não alterar dado de produção por demanda de relatório.
  Como mudar: abrir demanda própria de higienização, com regra do dono.

- [x] **P4 — Fonte de verdade da origem.** Pergunta (rodada anterior, item 3): só `LeadSource`, ou também UTM e integrações?
  Decisão: `Lead.LeadSource` para leads e `Opportunity.LeadSource` para conversão. Sem UTM e sem integração.
  Evidência: campos padrão confirmados (sf). Não verifiquei se há campo UTM custom na org. Incerteza declarada.
  Como mudar: trocar o campo de bucket, se a Eplast definir outra fonte.

- [x] **P5 — Período.** Pergunta (rodada anterior, item 2): mensal, trimestral ou histórico?
  Decisão: filtro de intervalo de data de criação, selecionável no painel, sem período fixo.
  Evidência: padrão de relatório Salesforce; cobre todas as opções sem escolher uma.
  Como mudar: definir um intervalo padrão no painel.

- [x] **P6 — Atribuição.** Pergunta (rodada anterior, item 5): primeiro toque, último toque ou multi-toque?
  Decisão: primeiro toque, com a origem do lead. Sem Campaign Influence nem multi-toque.
  Evidência: padrão mais simples; não verifiquei disponibilidade de Campaign Influence na org. Incerteza declarada.
  Como mudar: passar a ler CampaignInfluence, se a Eplast licenciar e pedir.

- [x] **P7 — Fórmula de retorno.** Pergunta (rodada anterior, item 6): qual fórmula e qual custo?
  Decisão: retorno = receita de oportunidades ganhas com `CampaignId` ÷ `Campaign.ActualCost`. Campanha sem custo mostra "n/a".
  Evidência: `ActualCost`, `BudgetedCost`, `ExpectedRevenue`, `Amount` e `IsWon` existem na org (sf). Padrão mais simples de retorno de campanha.
  Como mudar: trocar o custo para `BudgetedCost` ou a fórmula para margem. Alteração de fórmula no relatório.

- [x] **P8 — Público.** Pergunta (rodada anterior, item 7): quem usa e qual nível de detalhe?
  Decisão: equipe de Marketing da Eplast, com visão agregada, sem linhas de lead.
  Evidência: `PS_Marketing_AnaliseCampanhas` já existe na dev e foi desenhado para leitura de Marketing.
  Como mudar: ajustar o permission set e a pasta compartilhada.

- [x] **P9 — Relatórios existentes.** Pergunta (rodada anterior, item 8): substituir, complementar ou ignorar os relatórios atuais?
  Decisão: complementar. Nenhum relatório ou dashboard existente é alterado ou excluído (CA-10). Os relatórios antigos de amostra ficam como estão. Se algum atender ao critério, reaproveita-se; se não, cria-se o novo na pasta Marketing_Origem_Retorno.
  Evidência: regra 3 da conta; org tem 380 relatórios e 20 dashboards (sf, contagem); pasta Marketing_Origem_Retorno já existe na dev.
  Como mudar: a Eplast pode aposentar os antigos em demanda própria.

- [x] **P10 — Escopo do Marketing Cloud.** Pergunta (rodada anterior, item 10): qual plataforma de marketing foi decidida?
  Decisão: o painel usa só dados do CRM. Métricas de envio do Marketing Cloud ficam fora. Se a Eplast quiser essas métricas, quem opera o MC traz o dado por fora da esteira.
  Evidência: regra 2 da conta. A decisão de plataforma não está nesta workspace; incerteza declarada.
  Como mudar: abrir demanda de integração com o MC, com o operador do MC.

- [x] **P11 — Massa de teste.** Pergunta (rodada anterior, item 11): como obter amostra?
  Decisão: a dev não tem Lead, Campaign nem Opportunity (sf, contagem 0). A massa é sintética, criada na dev/QA pelo builder e documentada. Não se consulta produção. Na QA, a verificação usa contagens agregadas.
  Evidência: contagens confirmadas por sf. LGPD (guardrail 2).
  Como mudar: a Eplast pode fornecer amostra agregada, sem dado pessoal, para validar volumes.

- [x] **P12 — Ambiente de dev.** Não é pergunta de negócio; é de ambiente.
  Decisão: o build não começa até confirmar que o alias de dev é uma sandbox distinta da QA (CA-14, PC-1).
  Evidência: R6 (sf: instância `eplast--qa`).
  Como mudar: reconectar o alias de dev à sandbox correta, após confirmação de BASIS.

## 8. Pré-condições para o build

- **PC-1:** confirmar com a equipe que o alias `sbx-eplast-dev` deve apontar para a sandbox de dev e não para a QA (R6). Enquanto não confirmar, o builder não escreve nada na org.

Não é pendência de negócio: não é `- [ ]`. O orquestrador deve checar antes de acionar o build.

## 9. Perguntas em aberto (caso 3)

Nenhuma. Nenhuma resposta de negócio pendente trava o design. A única dúvida que bloqueia é de ambiente (PC-1), e está acima.

## 10. O que a org já tem (confirmado por sf)

| Item | O que é | Cobre o pedido? |
|---|---|---|
| `LeadSource` (Lead) | Picklist padrão, 13 valores ativos, não restrita | Sim, é a fonte de origem |
| `LeadSource` (Opportunity) | Picklist padrão | Sim, para conversão |
| `Campaign.ActualCost`, `BudgetedCost`, `ExpectedRevenue`, `Type` | Campos padrão | Sim, para retorno |
| `Opportunity.Amount`, `IsWon`, `CampaignId` | Campos padrão | Sim, para receita ganha |
| Relatórios (380) e dashboards (20) | Inclui amostras Salesforce e pasta Eplast | Parcial. Reaproveitar o que passar em CA-01 a CA-09; não alterar (P9) |
| Pasta `Marketing_Origem_Retorno` (report) | Já existe na dev | Reaproveitar; é o destino do build |
| `PS_Marketing_AnaliseCampanhas` | Permission set, já existe na dev | Reaproveitar; revisar contra CA-11 |
| Agente `SFAgent2` (bot com planner v1 a v4) | Já existe na dev | Não se aplica: não há assistente, resumo nem recomendação nesta demanda. Regra 3 não exige extensão |
| Trigger em Lead e Campaign | 0 (sf) | Nada a sobrepor |
| Flows com nome de Lead (`CreateSalesLead`, `CreateLeadAndOpp`) | Encontrados por nome. Não verifiquei o gatilho | Não tocados nesta demanda |

Lacuna: não verifiquei se a org tem campo UTM custom nem se Campaign Influence está licenciada (P4, P6).

## 11. Complexidade

**M.** Painel com 5 componentes que já existem em parte, 3 falhas de QA para corrigir, massa sintética a criar na dev e QA, e revisão de permissão.

## 12. Estimativa de esforço

**Estimativa de esforço:** 12–18 h

Premissas que mais pesam na faixa:
- Reaproveitar a pasta e o permission set já existentes na dev, sem reconstruir.
- Massa sintética leva parte do tempo, porque a dev está vazia (P11).
- Correção dos 3 achados da QA (F1 a F3) e revisão do dashboard.
- Não entra no número: o tempo de resolver PC-1 (R6), que pode ser maior se o alias precisar ser reconectado.
- Faixa larga porque a org de dev está vazia e o alias de ambiente está em dúvida.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
