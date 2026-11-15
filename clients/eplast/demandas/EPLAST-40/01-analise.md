# EPLAST-40 — Ciclo Marketing → SDR → Comercial → Pós-vendas

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 4 (Marketing), não contratada no `contrato.md`. Escopo autorizado pelo responsável da conta (card, 2026-11-13, regra 1 do briefing). Não é pendência.
**Origem:** Solicitação de Proposta Konecta — Implantação de IA no Salesforce Sales e Marketing (Eplast). O documento de origem não está no workspace; a análise parte de `demanda.md` (três linhas).
**Org confirmada:** `sbx-eplast-dev` (`sf org list`, tipo Sandbox, status Connected, sandbox `eplast--qa`). Todas as consultas desta etapa foram de metadata e contagens agregadas. Nenhum registro de negócio foi lido.
**Status:** análise pronta para validação humana. **Pendências de negócio em aberto (caso 3 da regra 4): nenhuma.** As decisões que a demanda não tomou estão nas premissas assumidas (seção 5), com evidência.

---

## 1. Contexto de negócio

A demanda pede que o ciclo entre quatro áreas tenha **estágios e passagem de responsabilidade definidos**. Hoje a org tem peças de cada etapa, mas nenhuma regra que as conecte:

- **Marketing:** Lead com origem de marketing (`LeadSource`) e campos de Marketing Cloud Connect (`et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c`). O Marketing Cloud dispara e-mail, campanha e nutrição (regra 2 da conta).
- **SDR:** `Lead.Status` tem 4 valores (`Aberto - Não contatado`, `Contatado`, `Fechado - Convertido`, `Fechado - Não convertido`). Não existe estágio SDR próprio. A origem `SDR` existe em `LeadSource`.
- **Comercial:** `Opportunity.StageName` tem 13 valores (de `Qualificação` a `Fechado/Ganho` e `Fechado/Perdido`). Há checkboxes de qualificação (`Discovery_Completed__c`, `Budget_Confirmed__c`, `ROI_Analysis_Completed__c`).
- **Pós-vendas:** o objeto padrão `Case` existe, com `Status` (`New`, `On Hold`, `Escalated`, `Closed`) e 0 campos custom. Há Flows ativos de atendimento (`CreateCase`, `CloseCase`, `AddCaseComment`, `CheckRepAvailability`). O objeto-alvo desses Flows não foi confirmado no describe desta etapa; isso vai para o recon.

**Fatos da org que pesam na análise** (`sf`, 2026-11-15):

| Ponto | Achado | Fonte |
|---|---|---|
| Filas de Lead | 8 filas (Centro-Oeste, ES, MG, Norte e Nordeste, RJ, SP, Sul, Triagem), **0 membros** | `Group` (Queue), `GroupMember` |
| Distribuição de Lead | Regra `Distribuicao_Regional_Leads` ativa; Flow `Lead_AfterInsert_AplicaRegraAtribuicao` ativo (after insert) | `AssignmentRule`, `FlowDefinitionView` |
| Score de prioridade | `PriorityScore__c` e `PriorityBand__c` já existem em Lead e Opportunity | `describe` |
| Volume na dev | Lead 0, Opportunity 0, Order 0, Case 0 | `COUNT()` |
| Campos de passagem | Não existe campo de data de passagem SDR→Comercial nem Comercial→Pós-vendas | lista de campos custom de Lead, Opportunity e Case |
| Fila de Pós-vendas | Não existe | `Group` (Queue) |

O achado de filas sem membros importa para a passagem de responsabilidade: uma regra que atribui Lead a fila vazia não entrega a ninguém. O histórico registra o mesmo achado na EPLAST-38 (`[demandas/EPLAST-38/01-analise.md]`), e a confirmação de hoje mantém o problema.

**Histórico relacionado** (RAG de delivery, não é a org):
- `[demandas/EPLAST-38/01-analise.md]`: distribuição de Lead, mesma regra e mesmas filas; decisão PA-06 de não notificar vendedor nesta entrega, pela regra 2.
- `[demandas/EPLAST-26/01-analise.md]`: `PriorityScore`/`PriorityBand` (Lead e Opportunity) já existentes, reaproveitáveis para priorização do SDR.
- `[demandas/EPLAST-33/03-design.md]`: `Campaign` e `CampaignMember` existem e estão vazios; não foram usados na v1 de exportação para o Marketing Cloud, porque montar público por pessoa é passo do Marketing Cloud.
- `[demandas/EPLAST-39/rodada-anterior/02-recon.md]`: `Campaign.Type` usa valores padrão em inglês, sem relação com `Lead.LeadSource`.

## 2. Objetivo

Definir, no CRM, os estágios do ciclo Marketing → SDR → Comercial → Pós-vendas, com dono e critério de passagem em cada transição, e deixar no CRM o lado de dados que o Marketing Cloud precisa para a nutrição.

**Objetivo testável:** cada passagem de responsabilidade deixa no registro o dono atual e a data da passagem, e um Lead ou Oportunidade consegue ser rastreado do Marketing até o Pós-vendas sem consulta fora da org.

**Dentro do escopo:**
- Uso dos estágios e campos padrão já existentes (premissa P2), com um mínimo de campos novos para rastrear a passagem.
- Regra de passagem SDR→Comercial e Comercial→Pós-vendas (premissas P3 a P5).
- Responsável por etapa, com filas existentes e uma fila nova de Pós-vendas (premissa P6).
- Lado do CRM da preparação para o Marketing Cloud (seção 4).

**Fora do escopo:**
- Qualquer envio de e-mail, mensagem ou campanha pelo CRM (regra 2).
- Qualquer ação no Marketing Cloud: conexão, público, jornada, envio (regra 2, reforço de 2026-11-15).
- Notificação ao vendedor e SLA de atendimento (premissa P7).
- Alteração no processo de venda do CPQ e na integração com o ERP Protheus, salvo o que o design provar necessário.

## 3. Regra de negócio

Cada regra abaixo é a decisão desta análise, tomada pela regra 4 da conta. As premissas da seção 5 dizem de onde veio cada uma.

- **RN1 — Entrada pelo Marketing.** Lead entra no funil com `LeadSource` de origem de marketing (`Campanha`, `E-mail MKT`, `Evento`, `Google Ads`, `Google Orgânico`, `Instagram`, `Facebook`, `WhatsApp`). (P1)
- **RN2 — SDR trabalha o Lead.** O SDR move o Lead de `Aberto - Não contatado` para `Contatado` ao fazer o primeiro contato. Lead qualificado é convertido. Lead sem interesse vai para `Fechado - Não convertido`. (P3)
- **RN3 — Passagem SDR→Comercial.** A passagem acontece na conversão do Lead, que cria a Oportunidade no estágio `Qualificação`. A data da passagem é gravada na Oportunidade. (P3, P8)
- **RN4 — Qualificação na Comercial.** A Oportunidade avança de `Qualificação` para `Qualificado` quando `Discovery_Completed__c` e `Budget_Confirmed__c` estiverem ambos marcados. (P4)
- **RN5 — Passagem Comercial→Pós-vendas.** Oportunidade em `Fechado/Ganho` gera o registro de Pós-vendas (Case) na fila de Pós-vendas, com data de passagem gravada. A venda continua sendo registrada pelo processo atual (Order). (P5, P6, P8)
- **RN6 — Sem envio no CRM.** Nenhuma passagem dispara e-mail, mensagem ou ação de envio. (regra 2 da conta)

## 4. Critérios de aceite

Os critérios usam dados de massa sintética, criada na dev pelo builder (a dev não tem registro). Na QA, a verificação usa contagens agregadas e registros criados pelo agente, sem ler registro real da QAS.

```gherkin
Funcionalidade: Passagem de responsabilidade no ciclo Marketing → SDR → Comercial → Pós-vendas

  Cenário: Lead de origem de marketing entra no funil
    Dado um Lead criado com LeadSource "E-mail MKT"
    Quando o Lead é salvo
    Então o Lead tem Status "Aberto - Não contatado"
    E o LeadSource permanece "E-mail MKT"
    E a regra de atribuição existente é executada uma vez

  Cenário: SDR marca primeiro contato
    Dado um Lead com Status "Aberto - Não contatado"
    Quando o SDR altera o Status para "Contatado"
    Então o Lead tem Status "Contatado"
    E nenhum registro de Oportunidade é criado

  Cenário: Conversão do Lead gera a Oportunidade da Comercial
    Dado um Lead com Status "Contatado" e LeadSource "SDR"
    Quando o Lead é convertido
    Então existe uma Oportunidade com StageName "Qualificação"
    E a Oportunidade tem LeadSource "SDR"
    E o campo de data de passagem SDR→Comercial está preenchido com a data da conversão
    E o Lead convertido tem Status "Fechado - Convertido"

  Cenário: Oportunidade só avança para Qualificado com os dois critérios
    Dado uma Oportunidade em StageName "Qualificação"
    Quando Discovery_Completed__c é marcado e Budget_Confirmed__c não é marcado
    Então o StageName continua "Qualificação"
    Quando Budget_Confirmed__c também é marcado
    Então o StageName passa para "Qualificado"

  Cenário: Oportunidade ganha gera Pós-vendas sem duplicar a venda
    Dado uma Oportunidade em StageName "Fechado/Ganho" com uma Order criada pelo processo atual
    Quando a passagem para Pós-vendas é executada
    Então existe exatamente 1 Case de Pós-vendas para essa Oportunidade
    E o Case tem o dono igual à fila "Pós-vendas"
    E o campo de data de passagem para Pós-vendas está preenchido
    E o número de Orders da Oportunidade não muda

  Cenário: Fila que recebe passagem tem membro
    Dado as filas de Lead e a fila "Pós-vendas"
    Quando a contagem de GroupMember por fila é consultada na QA
    Então toda fila que recebe passagem tem pelo menos 1 membro ativo

  Cenário: Nenhuma passagem envia comunicação pelo CRM
    Dado o conjunto de Flows, Apex e Email Alerts criados ou alterados pela entrega
    Quando o conteúdo é verificado
    Então nenhum componente chama envio de e-mail, Email Alert ou ação de disparo de mensagem

  Cenário: Campos de opt-out do Marketing Cloud não são alterados pela passagem
    Dado um Lead com et4ae5__HasOptedOutOfMobile__c e HasOptedOutOfEmail definidos
    Quando o Lead passa pelas etapas do ciclo
    Então os dois campos têm o mesmo valor antes e depois

  Cenário: Reuso dos componentes existentes
    Dado a lista de metadata criados pela entrega
    Quando comparada com o design aprovado
    Então não há objeto customizado novo
    E os campos novos são somente os de data de passagem e a fila de Pós-vendas
    E a regra Distribuicao_Regional_Leads e o Flow Lead_AfterInsert_AplicaRegraAtribuicao permanecem sem alteração de versão ativa

  Cenário: Código Apex novo é testado
    Dado uma classe Apex criada ou alterada pela entrega
    Quando a suíte de testes roda na sandbox de dev
    Então a classe tem cobertura de pelo menos 85%
    E existe uma classe de teste dedicada com o sufixo "Test"
```

**Critérios não testáveis que ficam fora:** "o ciclo funciona bem", "a equipe adota". Adoção depende do treinamento e da homologação com o cliente; não entra como critério automatizado.

## 5. Premissas assumidas (validar na homologação)

Cada premissa tem a pergunta que a demanda não respondeu, a decisão, a evidência e como mudar se a Eplast discordar.

- [x] **P1 — Quem entra no funil de marketing.** Pergunta: quais origens fazem o Lead entrar no ciclo como marketing? Decisão: as origens de marketing da lista atual de `LeadSource` (RN1). Evidência: `Lead.LeadSource` tem 13 valores ativos, incluindo origens de marketing (`Campanha`, `E-mail MKT`, `Google Ads`, `Instagram`, `Facebook`, `WhatsApp`, `Evento`). Como mudar: ajustar a lista de origens; é mudança de dado de configuração, sem código.

- [x] **P2 — Estágios usam os campos padrão existentes.** Pergunta: é preciso criar um estágio SDR e outros estágios novos? Decisão: não. O ciclo usa `Lead.Status` (4 valores), `Opportunity.StageName` (13 valores) e `Case.Status`. Evidência: a org não tem estágio SDR; criar picklist paralela duplicaria o que já existe (regra 3 da conta). Como mudar: incluir valores nas picklists existentes ou criar status dedicado numa demanda própria.

- [x] **P3 — Passagem SDR→Comercial é a conversão do Lead.** Pergunta: quando o SDR passa o Lead para a Comercial? Decisão: na conversão, que a plataforma já faz (cria Oportunidade). Evidência: conversão padrão do Lead; `Lead.Status` tem o valor `Fechado - Convertido`; origem `SDR` existe em `LeadSource`. Como mudar: passar a usar um status intermediário "Pronto para Comercial" antes da conversão.

- [x] **P4 — Critério de qualificação.** Pergunta: o que qualifica a Oportunidade para a Comercial? Decisão: `Discovery_Completed__c` e `Budget_Confirmed__c` marcados (RN4). Evidência: os dois checkboxes existem em `Opportunity`, com nomes alinhados aos estágios `Qualificação` e `Qualificado`, que também existem na picklist. Como mudar: trocar a condição, ou acrescentar `ROI_Analysis_Completed__c`. Consequência de design: esta regra é automação nova em Opportunity (ver seção 6, risco 1).

- [x] **P5 — Pós-vendas começa em Oportunidade ganha, sem substituir a venda.** Pergunta: o que o Pós-vendas acompanha, e a partir de quando? Decisão: Case de Pós-vendas criado na passagem de `Fechado/Ganho` (RN5). A venda continua registrada pelo processo atual (Order). Evidência: `Case` padrão existe com Flows de atendimento ativos; `Order` tem Flows ativos e a integração com o ERP Protheus existe pelas classes do assessment. Como mudar: trocar o gatilho para a Order faturada, ou para `Closed` em outro estágio. Confirmação pendente no recon: se a Order já é criada automaticamente pelo CPQ nesta org.

- [x] **P6 — Responsável por etapa.** Pergunta: quem é dono em cada etapa? Decisão: Lead e Oportunidade seguem o dono e a regra de distribuição já existentes. Pós-vendas recebe Case numa fila nova, `Pós-vendas`, criada nesta entrega, com membros definidos pela Eplast antes da homologação. Evidência: 8 filas existentes, nenhuma de Pós-vendas; as filas de Lead têm 0 membros (achado da seção 1). Como mudar: reaproveitar a fila `Triagem` ou outra, ou usar dono individual.

- [x] **P7 — Sem notificação ao vendedor e sem SLA na v1.** Pergunta: o vendedor é avisado da passagem? Existe prazo para cada etapa? Decisão: não nesta entrega. Evidência: regra 2 da conta proíbe disparo de e-mail no CRM; a mesma decisão foi tomada na EPLAST-38 (PA-06); nenhum prazo foi informado. Como mudar: aviso e prazo entram por demanda própria; aviso por e-mail passa pelo Marketing Cloud, e prazo exige regra de SLA.

- [x] **P8 — Rastro da passagem em campos novos.** Pergunta: como saber quando cada passagem aconteceu? Decisão: dois campos de data novos (SDR→Comercial em Opportunity; Comercial→Pós-vendas em Case), com descrição preenchida. Evidência: não existe campo de data de passagem em Lead, Opportunity nem Case na org (lista de campos custom confirmada). Como mudar: usar o histórico de campo padrão, se o cliente preferir não criar campo.

## 6. Riscos do assessment e da org que tocam o pedido

O assessment (`clients/eplast/assessment.md`, onboarding de 2026-09-30) é foto antiga. Os itens abaixo foram conferidos por `sf` nesta sessão quando citados como fato.

1. **Automação concorrente em Opportunity (risco alto, assessment vermelho).** Em Opportunity já há trigger custom `OpportunityTrigger`, triggers do CPQ (`SBQQ` `OpportunityAfter`/`OpportunityBefore`) e Flows ativos no mesmo evento: `Oportunidade_Industria`, `OpportunityFlow`, `Opportunity_Scheduled_AlertaParada`, `ScheduledFlowOpportunity`, `PaymentTermsOpportunity`. P4 e P8 mexem nesse evento. **Exigência para o design:** mapear a ordem real de execução (trigger custom, trigger CPQ e Flows) antes de propor qualquer automação nova em Opportunity, e preferir consolidar a existente.
2. **Colisão de nome em Order (assessment).** `OrderTrigger` existe duas vezes (trigger custom e trigger `SBQQ`). P5 toca a Order na verificação de "não duplica venda". O design deve referenciar o trigger pelo nome completo.
3. **Validation rules de Order (assessment: 23 regras; 8 de obrigatoriedade duplicada; 6 de máquina de estados abandonada).** A passagem para Pós-vendas não deve alterar Order. Se a verificação de "Order não muda" falhar por validation rule, é achado de build, não motivo para mudar a regra.
4. **Cobertura Apex baixa (assessment: 10%).** Qualquer classe nova precisa de `<Classe>Test` com 85% (critério de aceite). Pela convenção, a cobertura da classe alterada é regra de entrega.
5. **Campos custom sem descrição (assessment: 153 de 223 em Account, Order, Opportunity e OrderItem).** Os dois campos novos de P8 saem com descrição. Os campos de Opportunity usados em P4 não podem ser alterados sem análise, porque a descrição ausente impede saber quem os usa.
6. **Filas de Lead sem membros (confirmado nesta etapa).** Não é item do assessment, mas afeta RN3 e RN5. Sem membro, a passagem não chega a ninguém. Vira pré-requisito de homologação (critério "Fila que recebe passagem tem membro").
7. **Dev sem registros.** Volume zero na dev. Os critérios usam massa sintética; nenhum tempo de resposta ou volume é inferido daqui.

**Antes do design, o recon precisa confirmar:** ordem de execução em Opportunity e Order (risco 1); se a Order é criada automaticamente pelo CPQ (P5); o objeto-alvo dos Flows `CreateCase` e `CloseCase` (P5, para não duplicar atendimento); quem hoje são os membros das filas (P6).

## 7. Reaproveitamento item a item (preliminar, para o design)

| Peça | Decisão | Motivo |
|---|---|---|
| `Lead.Status` (4 valores) | Reaproveita | P2 |
| `Lead.LeadSource` (origens) | Reaproveita | P1 |
| `PriorityScore__c`, `PriorityBand__c` (Lead e Opportunity) | Reaproveita para priorizar o SDR | `[demandas/EPLAST-26/01-analise.md]` |
| Regra `Distribuicao_Regional_Leads` e Flow `Lead_AfterInsert_AplicaRegraAtribuicao` | Reaproveita, sem alterar | Já ativos; a passagem usa o dono que eles definem |
| `Opportunity.StageName`, `Discovery_Completed__c`, `Budget_Confirmed__c` | Reaproveita | P2, P4 |
| `Case` (objeto padrão) e Flows `CreateCase`, `CloseCase` | Reaproveita; checar antes de criar Flow | P5 |
| Fila `Pós-vendas` | Cria (não existe) | P6 |
| 2 campos de data de passagem | Cria (não existem) | P8 |
| Objeto customizado novo | Não cria | Nenhum requisito pede |
| Campos e público do Marketing Cloud (`et4ae5__*`) | Reaproveita, não altera | Regra 2 da conta |
| `SFAgent2` | Não se aplica | A demanda não fala em assistente, resumo, recomendação ou linguagem natural |

## 8. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca leads, origem, nutrição e segmentação do ciclo, então a seção é obrigatória (regra 2). **Nada é feito no Marketing Cloud, e nada é enviado pelo CRM.** A esteira não conecta, não configura e não cria público, jornada ou envio lá.

- **Dados que o Marketing Cloud lê e onde ficam no CRM:**
  - `Lead`: `LeadSource` (origem), `Status` (etapa), `HasOptedOutOfEmail` (padrão), `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c`, `Sector__c`, `PriorityBand__c`.
  - `Opportunity`: `StageName` e `Type` (`Nova Compra`, `Compra Recorrente`, `Reativação`), para o público de Comercial, se o Marketing Cloud precisar.
- **Como o público fica identificável no CRM:** por filtro de `Lead.Status` e `Lead.LeadSource` (ex.: Leads em `Aberto - Não contatado` com origem de marketing e sem opt-out). Campanha e membro de campanha (`Campaign`, `CampaignMember`) existem e estão vazios; não são usados na v1, seguindo a decisão da EPLAST-33. Montar público por pessoa é passo de quem opera o Marketing Cloud.
- **O que o Marketing Cloud devolve e onde é gravado:** a entrega não grava retorno de envio. `CampaignMember.et4ae5__Activity__c` existe e pertence ao conector; a forma como ele é preenchido **não foi verificada nesta etapa** (incerteza declarada). Se a Eplast quiser o retorno no Lead, é demanda de integração com o operador do Marketing Cloud.
- **Consentimento e opt-out:** `HasOptedOutOfEmail` (padrão) e `et4ae5__HasOptedOutOfMobile__c` ficam no Lead. A passagem não altera esses campos (critério de aceite). Quem opera o Marketing Cloud aplica o opt-out ao montar o público.
- **O que fica para quem opera o Marketing Cloud:** importar ou sincronizar o público a partir do Lead, aplicar opt-out, criar a jornada de nutrição, disparar o envio e devolver o engajamento.

## 9. O que a demanda NÃO diz

Estas lacunas foram resolvidas pela regra 4 (seção 5), não deixadas em aberto:

1. Quais são os estágios exatos e a ordem do ciclo. Resolvido em P2 e RN1 a RN5.
2. Quem é o SDR (perfil, usuários, equipe) e se é a mesma equipe da Comercial. Não resolvido pela org: a análise não lê usuários. Fica para o recon com contagem agregada por perfil, sem nomes.
3. Critério de qualificação da Comercial. Resolvido em P4.
4. Prazo e SLA de cada etapa. Resolvido em P7 (não há na v1).
5. Quem é avisado da passagem. Resolvido em P7.
6. O que é Pós-vendas para a Eplast (suporte, reclamação, recompra, relacionamento). Resolvido em P5 como Case; o escopo do atendimento é um ponto a validar na homologação.
7. Se o ciclo volta do Pós-vendas para o Marketing (recompra, reativação). A demanda não diz. Não entra nesta versão; `Opportunity.Type` tem `Reativação` e `Compra Recorrente`, mas nenhuma regra de retorno foi definida.
8. Se a Order é criada pelo CPQ ou pelo processo do ERP. Vai para o recon (seção 6).
9. Volume de Leads, Oportunidades e Cases por mês, e quantidade de usuários de cada área. Sem dado na dev; nada é inferido.
10. Quais campanhas e qual conteúdo de nutrição. São do Marketing Cloud, fora do escopo do CRM.
11. Documento de origem (Solicitação de Proposta) não está no workspace. Se trouxer regra que contrarie P1 a P8, a análise é refeita.

## 10. Complexidade e esforço

**Complexidade: G.** Justificativa: a passagem toca Lead, Opportunity e Case; a automação nova em Opportunity exige mapear a concorrência com CPQ e Flows; o pós-vendas exige fila e campos novos; e há a preparação do Marketing Cloud.

**Estimativa de esforço:** 32–48 h

Premissas que mais pesam na faixa:
- Mapeamento da ordem de execução em Opportunity e Order (recon e design) é a maior parte da incerteza; se a concorrência exigir consolidar Flows existentes, sobe para o topo da faixa.
- Pós-vendas via Case depende de confirmar o objeto-alvo de `CreateCase` e `CloseCase`; se a Eplast quiser outro objeto, a faixa muda.
- Membros das filas e escopo de atendimento são definidos pela Eplast; o esforço da Eplast não entra nesta faixa.
- Massa sintética na dev e homologação com o cliente validando as premissas P1 a P8.

## 11. Fontes

- `clients/eplast/demandas/EPLAST-40/demanda.md` (história do consultor).
- `clients/eplast/demandas/EPLAST-40/comentarios-do-card.md` (orientações de 2026-11-13).
- `clients/eplast/assessment.md` (foto de 2026-09-30; trechos de Opportunity, Order e automação, via Grep).
- `sf` na `sbx-eplast-dev`, 2026-11-15: `describe` de Lead, Opportunity e Case (picklists e nomes de campos); `FlowDefinitionView` ativo; contagens de `Group`, `GroupMember`, Lead, Opportunity, Order e Case.
- RAG de delivery: EPLAST-26, EPLAST-33, EPLAST-38, EPLAST-39 (citados na seção 1).

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
