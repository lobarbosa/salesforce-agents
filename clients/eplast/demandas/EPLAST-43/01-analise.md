# EPLAST-43 — Análise: Personalização de conteúdos, e-mails e mensagens

**Cliente:** Eplast · **Etapa:** analise (ba-discovery) · **Data:** 2026-11-15
**Org conectada:** `sbx-eplast-dev` (usuário `projetos@…eplast2.qa`, Org Id `00DHa000006vfMLMAY`) — é a sandbox "QA" da Eplast, conforme regra 5 do briefing da conta. Conferido com `sf org list`.
**Preflight:** cabeçalho diz "Etapa que vai rodar: `backlog`"; esta sessão é a etapa `analise`. Divergência registrada e tratada como válida (sem bloqueios, sem outras demandas nos mesmos componentes, nada a conferir na org).

---

## 1. Contexto de negócio

A Eplast quer que conteúdos, e-mails e mensagens sejam personalizados por cliente e por segmento. O card original (`demanda.md`) diz apenas que isso "depende da plataforma de Marketing, ainda não definida".

Essa dependência foi resolvida pelo responsável pela conta em 2026-11-15 (`comentarios-do-card.md`): **a plataforma é o Marketing Cloud**. Tudo que é marketing (e-mail, mensagem, campanha, jornada, nutrição) é disparado por ele. O CRM fornece o que alimenta o Marketing Cloud: dado, segmento, público e status.

A demanda está na Onda 4 (Marketing), ainda não contratada no projeto atual. Pela regra 1 do briefing, escopo não bloqueia: a análise, o design e o build seguem normalmente.

Pontos de contexto da org que tocam a demanda (`sbx-eplast-dev`, confirmados por `sf` com contagem e describe pontual):
- Campos do conector Marketing Cloud Connect (`et4ae5`) existem em `Lead` e `Contact`: `HasOptedOutOfMobile__c` e `Mobile_Country_Code__c`. Existe também `CampaignMember.et4ae5__Activity__c`.
- `HasOptedOutOfEmail` existe em `Contact` (consulta de contagem executada sem erro).
- A sandbox não tem registros em `Lead`, `Contact`, `Campaign` nem `CampaignMember` (contagem zero). Nenhum dado de cliente foi lido.

Demandas anteriores da mesma conta já definiram boa parte da base do lado do CRM (histórico via RAG):
- `[demandas/EPLAST-36/03-design.md]`: públicos e relatórios da pasta `MARKETING CLOUD`, campanhas `PUB -`, permission set `PS_Marketing_Publicos`, filtro de opt-out nos relatórios, e a divisão de passos com quem opera o Marketing Cloud.
- `[demandas/EPLAST-40/01-analise.md]`: dados de prospecção (`LeadSource`, `Status`, `Sector__c`, `PriorityBand__c`).
- `[demandas/EPLAST-42/01-analise.md]`: decisões de opt-out (PA-04) e de critério de prospecção (PA-05), que esta análise reaproveita.
- `[demandas/EPLAST-39/02-recon.md]`: recon do conector, com a lacuna de objetos `et4ae5__` ainda não levantados.

## 2. Objetivo

Deixar o CRM da Eplast pronto para que o Marketing Cloud personalize conteúdos, e-mails e mensagens por cliente e segmento, com:
1. os dados que o Marketing Cloud precisa ler disponíveis e identificáveis no Sales Cloud;
2. os segmentos e públicos de marketing identificáveis no CRM (campo, status, relatório ou lista);
3. exclusão de quem não pode receber comunicação (opt-out);
4. nenhum envio de comunicação feito pelo CRM.

O que a demanda **não** cobre: a composição do conteúdo (blocos, textos, personalização de envio) e o disparo, que são do Marketing Cloud e de quem o opera.

## 3. Regras de negócio

- **RN-01.** Todo e-mail e toda mensagem de marketing são disparados pelo Marketing Cloud. Não se usa Flow com e-mail alert, Apex de e-mail ou outra ferramenta de disparo no CRM (regra 2 do briefing).
- **RN-02.** Nada é feito no Marketing Cloud pela esteira: sem conexão, configuração, jornada, público ou envio. O que é dele aparece como passo de quem o opera.
- **RN-03.** Quem não pode receber comunicação fica fora de qualquer público de envio. E-mail: `HasOptedOutOfEmail`. Celular e mensagem: `et4ae5__HasOptedOutOfMobile__c`.
- **RN-04.** Não se sobrepõe o que já existe (regra 3): reaproveitar públicos, relatórios e campos já definidos antes de criar algo.
- **RN-05.** Dado de cliente não entra no contexto de agente: só metadata e contagens agregadas.

## 4. Divisão de responsabilidade

| Parte | Quem faz | Nesta esteira |
|---|---|---|
| Composição do conteúdo, personalização de envio, jornada, público no Marketing Cloud, envio | Quem opera o Marketing Cloud | Não |
| Conexão e configuração do Marketing Cloud Connect | Quem opera o Marketing Cloud | Não |
| Campos, status, públicos e relatórios no CRM que alimentam o Marketing Cloud | Esteira (builder) | Sim |
| Permissões de acesso aos públicos no CRM | Esteira (permission set, sem alterar perfil) | Sim |
| Validação dos públicos e do opt-out | QA da esteira e homologação da Eplast | Sim |

## 5. Critérios de aceite

Os critérios valem para o lado do CRM. A verificação é feita na sandbox de dev (com dados de teste criados pelo verificador) e, depois, na sandbox de QA.

**CA-01 — Opt-out de e-mail fica fora do público de e-mail**
Dado que existe um Lead com `HasOptedOutOfEmail = true` e outro sem opt-out, ambos no mesmo critério de público de e-mail,
Quando o público de e-mail é executado (relatório ou lista do público),
Então o Lead com opt-out não aparece e o Lead sem opt-out aparece.

**CA-02 — Opt-out de celular fica fora do público de mensagem**
Dado que existe um Contact com `et4ae5__HasOptedOutOfMobile__c = true` e outro sem opt-out, ambos no mesmo critério de público de mensagem,
Quando o público de mensagem é executado,
Então o Contact com opt-out não aparece.

**CA-03 — Todo segmento de marketing tem um público identificável no CRM**
Dado que a lista de segmentos aprovada pela Eplast (ver premissa PA-02),
Quando o build termina,
Então cada segmento tem um relatório ou lista de visualização com nome, pasta, filtro documentado e contagem executável, e a análise de build registra o nome de cada um.

**CA-04 — Públicos respeitam o status do registro**
Dado um Lead convertido e um Lead aberto, ambos com a mesma origem,
Quando o público de prospecção é executado,
Então só o Lead aberto aparece (critério de `Status` da PA-05 da EPLAST-42).

**CA-05 — Campos de dado para o Marketing Cloud são legíveis pelo público de marketing**
Dado o permission set de marketing da demanda atribuído a um usuário de teste,
Quando esse usuário executa os relatórios e as listas de cada segmento,
Então não há erro de campo inacessível (FLS) e os campos listados na seção 8 aparecem.

**CA-06 — Nenhuma composição ou envio de comunicação no CRM**
Dado o conjunto de metadata entregue pela demanda,
Quando a esteira faz a busca por componentes de envio (`EmailAlert`, `sendEmail`, `Messaging.`, `SingleEmailMessage`, Flow com ação de e-mail),
Então o resultado é zero em componentes novos ou alterados.

**CA-07 — Nenhum componente de automação novo em Account, Opportunity ou Order**
Dado que a demanda usa dados de compra apenas para leitura,
Quando o design e o build são revisados,
Então não há trigger, Flow ou classe nova nesses objetos. Se algum for necessário, a demanda volta ao arquiteto para mapear a ordem de execução (achado 1 do assessment).

**CA-08 — Mudanças em relatórios existentes são declaradas**
Dado que o build altera um relatório existente (ex.: filtro de opt-out),
Quando a entrega é gravada,
Então `06-entrega.md` lista cada relatório alterado, com a mudança de contagem esperada, para quem opera o Marketing Cloud ser avisado.

**CA-09 — Campos novos têm descrição e não duplicam campo existente**
Dado que o build cria algum campo custom,
Quando o verificador confere a metadata,
Então o campo tem `description` preenchida e a análise de build cita o campo existente que foi considerado e descartado.

**CA-10 — Passos de quem opera o Marketing Cloud estão declarados**
Dado o design aprovado,
Quando o usuário da Eplast lê o roteiro do cliente (`05-roteiro-cliente.md`),
Então há uma seção de passos fora da esteira com cada item da seção 8 e a seção "O que assumimos e você precisa confirmar" com as premissas PA-01 a PA-06.

## 6. Premissas assumidas (validar na homologação)

Cada premissa tem pergunta, decisão, evidência e forma de mudar. Nenhuma foi tratada como pendência, porque a org e o padrão indicam caminho.

- [x] **PA-01 — Onde nasce o texto do e-mail e da mensagem**
  - Pergunta: a personalização de conteúdo é montada no CRM (texto gerado ou modelo no Salesforce) ou no Marketing Cloud?
  - Decisão: no Marketing Cloud. O CRM não compõe texto de e-mail ou mensagem e não usa IA generativa para isso nesta demanda.
  - Evidência: regra 2 do briefing da Eplast e comentário de 2026-11-15 ("o CRM fornece dado, segmento, público e status"). Nenhum componente de composição ou envio é previsto no design.
  - Como mudar: se a Eplast quiser geração de texto no CRM, é nova demanda, com design próprio. Nesse caso, antes de qualquer assistente, o SFAgent2 (regra 3) entra na análise.

- [x] **PA-02 — Quais segmentos entram**
  - Pergunta: quais segmentos o Marketing Cloud vai usar (produto, região, compra, prospecção)?
  - Decisão: reaproveitar a base de públicos já definida nas EPLAST-36, EPLAST-39, EPLAST-40 e EPLAST-42: (a) clientes por produto e última compra (públicos de Account/Contact/Order/OrderItem/Product2), (b) região pela UF, (c) prospecção de Leads por origem agrupada (`MKT_Origem_Agrupada`), prioridade (`PriorityBand`, excluindo "Sem dados suficientes") e status não convertido. Nenhum segmento novo é criado nesta etapa.
  - Evidência: `[demandas/EPLAST-36/03-design.md]`, `[demandas/EPLAST-40/01-analise.md]`, `[demandas/EPLAST-42/01-analise.md]` (PA-05). A pasta `MARKETING CLOUD` e as campanhas `PUB -` foram criadas pela EPLAST-36; a existência atual não foi reconferida nesta etapa.
  - Como mudar: a lista final de segmentos é aprovada pela Eplast na homologação. Cada segmento é um relatório, então mudar não exige alteração de dado.

- [x] **PA-03 — Opt-out**
  - Pergunta: quem não pode receber comunicação e como isso é marcado?
  - Decisão: e-mail usa `HasOptedOutOfEmail`; celular e mensagem usam `et4ae5__HasOptedOutOfMobile__c`. Todo público exclui quem tem opt-out. Não se cria registro de consentimento novo.
  - Evidência: `Contact.HasOptedOutOfEmail` e campos `et4ae5` confirmados nesta sessão; decisão PA-04 da EPLAST-42.
  - Como mudar: se o Marketing Cloud tiver regra de consentimento própria, quem o opera a aplica, e a regra fica declarada no design.

- [x] **PA-04 — WhatsApp sem campo de opt-out**
  - Pergunta: como tratar WhatsApp se a Eplast usar esse canal?
  - Decisão: não se cria campo de opt-out de WhatsApp nesta demanda. Nenhum público de WhatsApp é criado no CRM. Se a Eplast quiser esse canal, o caso vai para a demanda de LGPD (EPLAST-34).
  - Evidência: recon da EPLAST-36 (não existe campo de opt-out de WhatsApp na org). Não reconferido nesta etapa; a incerteza fica declarada.
  - Como mudar: a EPLAST-34 define o campo e a base legal.

- [x] **PA-05 — Retorno de envio fica onde o conector grava**
  - Pergunta: o retorno de envio e de clique do Marketing Cloud volta ao CRM, e onde?
  - Decisão: nenhum campo de retorno novo. O retorno fica em `et4ae5__IndividualEmailResult__c`, `et4ae5__IndividualLink__c` e `CampaignMember.et4ae5__Activity__c`, como já decidido na EPLAST-36.
  - Evidência: existência de `CampaignMember.et4ae5__Activity__c` confirmada por `sf` nesta sessão. A forma como esse campo é preenchido não foi verificada (incerteza declarada).
  - Como mudar: se a Eplast precisar do retorno no Lead, é integração com quem opera o Marketing Cloud, em demanda própria.

- [x] **PA-06 — Campanha do CRM fora da v1**
  - Pergunta: o público será montado com `Campaign` e `CampaignMember` ou com relatório e lista?
  - Decisão: relatório e lista, sem uso de `Campaign` na v1. A sandbox tem `Campaign` e `CampaignMember` vazios.
  - Evidência: decisão da EPLAST-33, citada na EPLAST-40; contagem zero confirmada por `sf` nesta sessão.
  - Como mudar: o campo `CampaignId` existe em `Opportunity`. Se a Eplast quiser campanha como público, é ajuste de design.

- [x] **PA-07 — SFAgent2 não entra nesta demanda**
  - Pergunta: a demanda pede assistente, resumo ou recomendação?
  - Decisão: não. O texto da demanda não pede isso, e a PA-01 tira a composição do CRM. O SFAgent2 não é estendido.
  - Evidência: `demanda.md` e regra 3 do briefing. A existência do agente não foi reconfirmada nesta sessão: o objeto Bot não é consultável por `sf data query` (incerteza declarada), e a comparação QA x DEV é de 2026-11-10 (briefing).
  - Como mudar: se a Eplast pedir assistente, o SFAgent2 vira a base, conforme a regra 3.

- [x] **PA-08 — Reuso antes de criação**
  - Pergunta: o build cria campo, objeto ou componente novo?
  - Decisão: só se nenhum componente existente atender ao critério. A análise de build cita o que foi considerado e descartado (CA-09).
  - Evidência: regra 3 do briefing e achado 4 do assessment (153 campos sem descrição em Account, Order, Opportunity e OrderItem).
  - Como mudar: o arquiteto decide no design.

## 7. O que a demanda não diz

Todas as lacunas abaixo foram resolvidas pela regra 4, com evidência. Nenhuma ficou como `- [ ]`. Ver seção 6 para o detalhe.

1. **Onde o conteúdo é montado** (PA-01): a demanda não diz. Resolvido pelo comentário de 2026-11-15 e pela regra 2.
2. **Quais segmentos** (PA-02): a demanda não nomeia nenhum. Resolvido pela base já definida nas EPLAST-36 e EPLAST-40/42.
3. **Canal de mensagem** (PA-04): a demanda fala em "mensagens" sem dizer se é SMS, WhatsApp ou push. Resolvido: celular pelo campo `et4ae5`, WhatsApp fora até a EPLAST-34.
4. **Frequência, jornada e gatilho** de envio: a demanda não diz. Ficam no Marketing Cloud, fora desta esteira.
5. **Dado de personalização** (ex.: nome, produto de interesse, última compra): a demanda não diz quais campos. O design deve listar os campos em uso pelos segmentos e, se faltar algum, justificar.

## 8. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca marketing, segmentação, público, relacionamento e reativação. Esta seção é obrigatória (regra 2). **Nada é feito no Marketing Cloud. Nada é enviado pelo CRM.**

**a) Dados que o Marketing Cloud precisa ler e onde ficam no CRM**

| Dado | Objeto e campo | Uso | Situação na org |
|---|---|---|---|
| E-mail | `Contact.Email`, `Lead.Email` | Destinatário de e-mail | padrão |
| Opt-out de e-mail | `Contact.HasOptedOutOfEmail`, `Lead.HasOptedOutOfEmail` | Exclusão | padrão; `Contact` confirmado |
| Opt-out de celular | `et4ae5__HasOptedOutOfMobile__c` em `Contact` e `Lead` | Exclusão de mensagem | confirmado por `sf` |
| Código de país do celular | `et4ae5__Mobile_Country_Code__c` em `Contact` e `Lead` | Formatação | confirmado por `sf` |
| Origem do lead | `Lead.LeadSource`, `Lead.MKT_Origem_Agrupada` | Público de prospecção | do histórico (EPLAST-40/42); não reconferido |
| Prioridade do lead | `Lead.PriorityBand__c` | Recorte de prospecção | do histórico (EPLAST-26/40/42); não reconferido |
| Status do lead | `Lead.Status` | Exclusão de lead convertido | padrão |
| Última compra e atividade | campos lidos pelos relatórios `SEM_COMPRA_*` e `LastActivityDate` | Reativação e recência | do histórico; não reconferido |

Os nomes marcados como "não reconferido" vêm do histórico de demandas anteriores. Antes do design, o recon confirma cada um por `sf`.

**b) Como o público fica identificável no CRM**

Por relatório ou lista de visualização em pasta própria (`MARKETING CLOUD`, conforme EPLAST-36), com filtro documentado e opt-out aplicado. Cada segmento da PA-02 tem um nome. Campanha não é usada na v1 (PA-06).

**c) O que o Marketing Cloud devolve e onde é gravado**

Sem campo de retorno novo. O resultado fica no conector: `et4ae5__IndividualEmailResult__c`, `et4ae5__IndividualLink__c` e `CampaignMember.et4ae5__Activity__c` (PA-05).

**d) Consentimento e opt-out**

E-mail por `HasOptedOutOfEmail`; celular por `et4ae5__HasOptedOutOfMobile__c`; WhatsApp fora (PA-04). Todo público exclui opt-out. Se o Marketing Cloud tiver regra própria de consentimento, quem o opera a aplica.

**e) Passos de quem opera o Marketing Cloud (fora da esteira)**
1. Confirmar que a conexão do Marketing Cloud Connect está ativa e qual Business Unit é usada. Não verificado; a esteira não toca.
2. Importar ou sincronizar os públicos do CRM (relatórios da pasta `MARKETING CLOUD` ou campanhas `PUB -`) como dados de envio ou entrada de jornada.
3. Montar o segmento lá, incluindo os campos de origem, status e prioridade listados na seção (a).
4. Respeitar o opt-out do CRM e o do próprio Marketing Cloud, se houver.
5. Compor o conteúdo (blocos, personalização) e o envio.

## 9. Riscos do assessment que tocam a demanda

- **Achado 1 (automação concorrente em Account, Opportunity e Order, com o CPQ).** A demanda lê dados de compra em Account, Order e OrderItem, mas não cria automação nesses objetos. Risco baixo, desde que se respeite CA-07. Se o desenho pedir um trigger ou Flow nesses objetos, a ordem de execução precisa ser mapeada antes.
- **Achado 4 (153 campos custom sem descrição, a maioria em Account e Order).** O risco é reaproveitar ou criar campo sem saber o uso. Cobertos por CA-09 e PA-08.
- **Achado 2 (cobertura Apex de 10%).** A demanda não prevê Apex. Se o build precisar de Apex, aplica-se a meta de 85% por classe e a classe `<Classe>Test`.
- **Marketing Cloud Connect (`et4ae5`).** Os objetos `et4ae5__` e seus campos de envio não foram levantados em detalhe (lacuna do recon da EPLAST-39). O recon desta demanda deve confirmar os campos da seção 8 (a) antes de o design propor qualquer um.
- **Achado de validation rules em Order (23 regras).** Não afeta leitura. Se o build gravar em Order, o risco volta a valer.

## 10. Complexidade

**M.** O lado do CRM é pequeno se reaproveitar os públicos já definidos. A complexidade está na dependência de três definições de segmento de demandas anteriores e na entrega para quem opera o Marketing Cloud, que fica fora da esteira.

## 11. Estimativa de esforço

**Estimativa de esforço:** 8–16 h

Premissas que mais pesam na faixa:
- Reuso dos públicos e relatórios já definidos (EPLAST-36, 40 e 42), sem criação de objeto e com até dois campos novos. Se o recon mostrar que faltam campos, somam-se 2–4 h.
- Validação com a Eplast da lista de segmentos (PA-02) e de WhatsApp (PA-04) na homologação.
- Conferência de opt-out e de FLS na sandbox de dev e de QA.
- Trabalho do Marketing Cloud (conexão, público, jornada, envio) não entra nesta faixa; é de quem o opera.

## 12. Próximos passos

1. Recon (`02-recon.md`): confirmar por `sf` os campos da seção 8 (a) marcados como "não reconferido", o estado da pasta `MARKETING CLOUD` e as campanhas `PUB -`, e os campos `et4ae5__` de envio, sem ler registros.
2. Design (`03-design.md`): reaproveitar, item a item, o que já existe, e levar PA-01 a PA-08 adiante.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
