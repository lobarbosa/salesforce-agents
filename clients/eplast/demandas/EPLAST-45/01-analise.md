# EPLAST-45 · Análise: nutrição de leads até a abordagem comercial

**Cliente:** eplast · **Etapa:** analise · **Data:** 2026-11-15 · **Autor:** ba-discovery
**Org consultada:** `sbx-eplast-dev` (Sandbox, Org Id `00DHa000006vfMLMAY`), confirmada por `sf org list` (conta de dev, não de produção).
**Status:** pronta para gate. Nenhuma pendência bloqueante.
**Insumos:** `demanda.md`, `comentarios-do-card.md` (2026-11-13 e 2026-11-15), `00-preflight.md`, `clients/eplast/CLAUDE.md` (regras 1 a 6), `assessment.md` (só os trechos de Lead, Campaign, conector e automação), RAG do cliente, `sf` (metadata e contagens agregadas).

> **Divergência registrada:** o cabeçalho do `00-preflight.md` diz etapa `backlog`, mas esta sessão roda `analise`. Tratado como ruído da esteira; seguido com `analise`.

---

## 1. Contexto de negócio e objetivo

**Demanda do consultor (`demanda.md`):** "Nutrir os leads até o momento adequado para a abordagem comercial." A demanda original dizia que dependia da plataforma de marketing, ainda não definida. Isso foi fechado no card em 2026-11-15: a plataforma é o **Marketing Cloud**, e a demanda foi descongelada.

**Regras que valem para esta demanda (`comentarios-do-card.md`, regra 2 e regra 4 da conta):**
- Nada é feito no Marketing Cloud. A esteira não conecta, não configura e não cria jornada, público ou envio.
- O que é de marketing (e-mail, mensagem, campanha, jornada, nutrição) sai pelo Marketing Cloud. No CRM fica o que o alimenta: dado, segmento, público e status.
- Pergunta de regra de negócio sem resposta vira premissa assumida, decidida pela org ou pelo padrão, e fica configurável.

**Objetivo:** deixar o Sales Cloud preparado para a nutrição:
1. Identificar no CRM quais leads estão em nutrição (elegíveis) e quais já estão prontos para a abordagem comercial.
2. Garantir que quem deu opt-out não entra no público.
3. Mostrar ao vendedor, sem e-mail do CRM, os leads que chegaram ao ponto de abordagem.
4. Receber de volta, do Marketing Cloud, o sinal de engajamento em campo rastreável.

**Não é objetivo:** criar jornada, conteúdo, cadência ou envio. Isso é do Marketing Cloud, e quem opera é quem declara o passo.

---

## 2. Escopo

**Dentro:**
- Público de nutrição: **Lead** (premissa PA-02).
- Campo ou fórmula de elegibilidade e de "pronto para abordagem" no Lead.
- Relatório ou list view com os leads elegíveis e os prontos, para o time comercial e para o Marketing Cloud ler.
- Campo para o sinal de engajamento que o Marketing Cloud devolve (criado no design, se ainda não houver).
- Respeito a opt-out de e-mail e de mobile no segmento.

**Fora:**
- Qualquer configuração, jornada, público, conteúdo, envio, tracking ou conexão no Marketing Cloud (passo de quem opera).
- Envio de e-mail, mensagem ou campanha pelo CRM: Flow com e-mail alert, Apex de e-mail ou ferramenta de disparo dentro do CRM. Não é desenhado.
- Escrita em Account, Opportunity ou Order.
- Account Engagement (Pardot). A plataforma definida é o Marketing Cloud.
- Onda 4 (Marketing), não contratada no projeto atual. Não é bloqueio: a regra 1 da conta autoriza a demanda a seguir.

---

## 3. Regras de negócio (como ficam após as premissas)

- **RN1 · Lead em nutrição:** Lead não convertido (`IsConverted = false`) com status `Aberto - Não contatado` ou `Contatado`. Premissa PA-04.
- **RN2 · Pronto para abordagem:** Lead em nutrição cuja `PriorityBand__c` é `Alta`. Premissa PA-03. O sinal de engajamento do Marketing Cloud entra como critério adicional, configurável.
- **RN3 · Opt-out:** Lead com `HasOptedOutOfEmail = true` ou `et4ae5__HasOptedOutOfMobile__c = true` fica fora do segmento do canal correspondente. Premissa PA-06.
- **RN4 · Conversão:** Lead convertido sai do segmento de nutrição e da lista de prontos.
- **RN5 · Dono do lead:** a abordagem não muda o dono. Premissa PA-07.

---

## 4. Critérios de aceite (testáveis)

Todos verificáveis no ambiente de dev com dados de teste pelos scripts de `fixtures/` (regra 6), ou por metadata e contagens agregadas. Nenhum critério exige dado pessoal no contexto.

```gherkin
Funcionalidade: Nutrição de leads até a abordagem comercial (EPLAST-45)

  Cenário: CA-01 Lead aberto e sem opt-out entra como elegível
    Dado um Lead não convertido, com status "Aberto - Não contatado" e sem opt-out
    Quando o registro é salvo
    Então ele aparece no segmento de elegíveis (campo ou fórmula de elegibilidade = verdadeiro)
    E a contagem do relatório de elegíveis é igual à contagem SOQL agregada com o mesmo filtro

  Cenário: CA-02 Lead com opt-out de e-mail fica fora do segmento de e-mail
    Dado um Lead elegível com HasOptedOutOfEmail = true
    Quando o segmento de e-mail é consultado
    Então o Lead não aparece nesse segmento
    E continua visível no segmento de elegíveis de outros canais, se houver

  Cenário: CA-03 Lead com opt-out de mobile fica fora do segmento de mensagem
    Dado um Lead elegível com et4ae5__HasOptedOutOfMobile__c = true
    Quando o segmento de mensagem é consultado
    Então o Lead não aparece nesse segmento

  Cenário: CA-04 Lead passa a "pronto para abordagem" ao ficar com prioridade Alta
    Dado um Lead elegível com PriorityBand__c diferente de "Alta"
    Quando a faixa passa para "Alta" (por mudança de status ou de origem que altera o score)
    Então o Lead aparece na lista de prontos para abordagem sem nenhuma ação manual
    E a lista de prontos não contém leads de faixa Média ou Baixa

  Cenário: CA-05 Lead convertido sai da nutrição e da lista de prontos
    Dado um Lead elegível e pronto para abordagem
    Quando o Lead é convertido
    Então ele não aparece no segmento de elegíveis nem na lista de prontos

  Cenário: CA-06 A abordagem não muda o dono do lead
    Dado um Lead com OwnerId "X" que ficou pronto para abordagem
    Quando a faixa vira "Alta"
    Então OwnerId continua "X"
    E nenhum registro de atribuição é criado ou alterado pela solução

  Cenário: CA-07 O campo de sinal do Marketing Cloud aceita o valor devolvido sem sobrescrever o status
    Dado um Lead elegível
    Quando um valor de engajamento é gravado no campo de sinal (simulando a devolução do Marketing Cloud)
    Então o valor fica gravado no campo de sinal
    E Status, PriorityBand__c e OwnerId não mudam por causa dessa gravação

  Cenário: CA-08 Nenhuma automação da solução envia e-mail ou mensagem
    Dado a solução implantada na dev
    Quando os Flows e Apex novos ou alterados são inspecionados por metadata
    Então nenhum deles tem ação de e-mail alert, envio de e-mail ou de mensagem
    E nenhum deles é um Flow ou trigger em Account, Opportunity ou Order

  Cenário: CA-09 Nova automação em Lead respeita a ordem existente
    Dado que o Flow ativo Lead_AfterInsert_AplicaRegraAtribuicao já roda em Lead após inserção
    Quando a solução adiciona qualquer automação em Lead
    Então a ordem de execução entre as duas está documentada no design
    E a ordem é validada em teste de inserção de Lead na dev (CA-01 cobre a inserção)

  Cenário: CA-10 Campos novos têm descrição
    Dado os campos criados ou alterados por esta demanda em Lead
    Quando o metadata é inspecionado
    Então cada campo tem a propriedade Description preenchida

  Cenário: CA-11 Código, se houver, tem cobertura mínima
    Dado que o design não prevê Apex (preferência por fórmula e relatório)
    Quando algum Apex for criado para esta demanda
    Então cada classe tem cobertura de 85% ou mais e uma classe de teste dedicada <Classe>Test

  Cenário: CA-12 Sem dado pessoal fora da org
    Dado os roteiros de teste e os relatórios de evidência
    Quando são gravados
    Então não contêm e-mail, telefone ou nome real de lead, somente dados de fixtures ou contagens agregadas
```

---

## 5. Premissas assumidas (validar na homologação)

Cada premissa tem a pergunta, a decisão, a evidência e como mudar se a Eplast discordar. Todas estão resolvidas (`- [x]`). Nenhuma pendência bloqueia o gate.

- [x] **PA-01 · Plataforma de nutrição.** Pergunta: qual plataforma nutre os leads? Decisão: Marketing Cloud. Evidência: card de 2026-11-15, regra 2 da conta. Como mudar: só por decisão do responsável pela conta; mudaria o desenho inteiro do lado do CRM.
- [x] **PA-02 · Público de nutrição é Lead.** Pergunta: lead, contato ou oportunidade? Decisão: Lead. Evidência: os campos de opt-out e de conector do Marketing Cloud estão no Lead (`et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c`); Campaign não tem registro nem campo custom na dev (contagem 0 e 0 campos custom); Contact atende cliente já convertido, fora do escopo. Como mudar: incluir Contact com o mesmo campo de elegibilidade.
- [x] **PA-03 · "Pronto para abordagem" é faixa Alta.** Pergunta: qual é o momento adequado para o comercial? Decisão: `PriorityBand__c = "Alta"`, somado ao sinal de engajamento do Marketing Cloud como critério adicional e configurável. Evidência: o campo existe na dev como fórmula de texto (confirmado por FieldDefinition); a faixa combina setor, origem e status (`[demandas/EPLAST-38/01-analise.md]`, `[demandas/EPLAST-26/03-design.md]`). Padrão: prioridade por score é a forma mais simples de decidir a abordagem e fácil de ajustar. Como mudar: alterar a fórmula da faixa ou o critério de engajamento, sem refazer o desenho.
- [x] **PA-04 · Lead em nutrição.** Pergunta: quais status contam como nutrição? Decisão: não convertido, com `Aberto - Não contatado` ou `Contatado`. Evidência: picklist de `Lead.Status` na dev tem 4 valores ativos: `Aberto - Não contatado`, `Contatado`, `Fechado - Convertido` e `Fechado - Não convertido` (describe, 2026-11-15). Como mudar: ajustar o filtro do campo de elegibilidade.
- [x] **PA-05 · Origem não filtra o público.** Pergunta: entram leads de todas as origens? Decisão: sim, todas as origens de `LeadSource` (13 valores ativos, inclusive `SDR` e `Prospecção ativa`). Evidência: picklist de `LeadSource` na dev. Padrão: filtrar por origem é a exceção, não a regra. Como mudar: incluir filtro por `LeadSource` no campo de elegibilidade.
- [x] **PA-06 · Opt-out é respeitado no CRM.** Pergunta: como tratar quem não quer receber? Decisão: o segmento de e-mail exclui `HasOptedOutOfEmail`, e o de mensagem exclui `et4ae5__HasOptedOutOfMobile__c`. Evidência: os dois campos existem em Lead (`HasOptedOutOfEmail` é padrão). A regra de honrar o opt-out na entrega é do Marketing Cloud, e o CRM só deixa de ofertar o lead. Padrão LGPD: opt-out vale antes do envio. Como mudar: incluir ou remover campos de opt-out por canal.
- [x] **PA-07 · A abordagem não reatribui o lead.** Pergunta: o lead pronto muda de dono? Decisão: não. Evidência: o Flow `Lead_AfterInsert_AplicaRegraAtribuicao` está ativo e roda em inserção de Lead (confirmado na dev). A regra `Distribuicao_Regional_Leads` aponta para filas de Lead que não têm membros (`[demandas/EPLAST-38/01-analise.md]`, não reconfirmado nesta etapa). Reatribuir agora mandaria o lead para fila vazia. Como mudar: criar regra de reatribuição depois que as filas tiverem membros, em demanda separada.
- [x] **PA-08 · Aviso ao vendedor sem e-mail do CRM.** Pergunta: como o vendedor fica sabendo? Decisão: relatório ou list view de prontos, sem notificação por e-mail. Evidência: regra 2 da conta (e-mail sai só pelo Marketing Cloud). Como mudar: notificação in-app ou tarefa, em demanda própria.
- [x] **PA-09 · Volume moderado.** Pergunta: qual o volume de leads? Decisão: volume moderado, com fórmula e relatório, sem processamento em lote. Evidência: a dev não tem registro de negócio (Lead não convertido e Campaign com contagem 0). O volume real não se infere; a Eplast precisa informar. Como mudar: se o volume for alto, o campo de elegibilidade vira processo em lote, o que muda o design e o esforço.
- [x] **PA-10 · Campo de sinal do Marketing Cloud.** Pergunta: onde o sinal de engajamento fica no CRM? Decisão: um campo novo no Lead, criado no design, se o recon não achar campo equivalente. Evidência: entre os 16 campos custom de Lead, não há campo de score ou engajamento do Marketing Cloud. Os campos de conector que existem são de opt-out e código de país. Como mudar: reutilizar campo existente, se o recon achar um.

---

## 6. Riscos do assessment que tocam o pedido

| Achado do assessment | Toca a demanda? | Tratamento |
|---|---|---|
| Automação concorrente em Account, Opportunity e Order (achado 1, alta) | Não diretamente. A demanda não grava nesses objetos. | CA-08 proíbe Flow ou trigger novo nesses objetos. |
| Cobertura de Apex em 10% (achado 2) | Só se houver Apex. | Desenho prefere fórmula e relatório. CA-11 vale se houver Apex. |
| Campos sem descrição (achado 4: 153 de 223) | Sim, nos campos novos de Lead. | CA-10 exige `Description`. Não há curadoria de campos existentes nesta demanda. |
| Dev parecida com QA (achado 6) | Não é bloqueio. Regra 5 da conta. | Conferido com `sf org list`: a conectada é `sbx-eplast-dev`. |
| Workflow Rules: 17, todas do pacote `et4ae5` (assessment, linha 30) | **Sim, incerto.** Não verificado se alguma atua em Lead. | Recon confere quais Workflow Rules tocam Lead antes de o design propor campo. Se houver, o design lista. |
| Ordem de execução em Lead (não está no assessment; achado da própria dev) | Sim. O Flow `Lead_AfterInsert_AplicaRegraAtribuicao` está ativo na dev. Não há trigger Apex em Lead, Campaign, CampaignMember nem Contact (Tooling, 2026-11-15). | CA-09 documenta a ordem. Preferência por fórmula, que não cria ordem de execução. |

---

## 7. Preparação do Sales Cloud para o Marketing Cloud

Esta demanda toca marketing (leads, nutrição, segmentação, público, comunicação). O build entrega só o lado do CRM. O Marketing Cloud não é configurado nem consultado pela esteira.

**a) Dados que o Marketing Cloud precisa ler e onde ficam no CRM**

| Dado | Objeto e campo | Observação |
|---|---|---|
| Identificador do lead | Lead · `Id` | Chave de integração. |
| Contato para envio | Lead · `Email`, `MobilePhone` | Dado pessoal. Enviar só o necessário ao Marketing Cloud (LGPD). |
| Nome e empresa | Lead · `FirstName`, `LastName`, `CompanyName__c` | Para personalização. Dado pessoal. |
| Origem | Lead · `LeadSource`, `MKT_Origem_Agrupada__c` | `MKT_Origem_Agrupada__c` existe (fórmula de texto, confirmada por FieldDefinition). Não aparece no describe do usuário conectado, possivelmente por acesso de campo. Incerteza declarada: o recon confirma o acesso. |
| Segmento do lead | Lead · `Sector__c`, `Subsector__c`, `PriorityBand__c` | Campos já existentes na dev. |
| Status do lead | Lead · `Status`, `IsConverted` | Para saber se ainda está em nutrição. |
| Consentimento | Lead · `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c` | Ver item d. |

**b) Como o público fica identificável no CRM**
- Campo de elegibilidade no Lead (fórmula booleana, nome a definir no design), verdadeiro para RN1 e RN3.
- Campo ou fórmula de "pronto para abordagem" (RN2).
- Relatório "Leads em nutrição" e relatório "Leads prontos para abordagem", ambos filtráveis pelos campos acima. São as fontes que o Marketing Cloud pode consumir para montar público, a decidir por quem opera.

**c) O que o Marketing Cloud devolve e onde é gravado**
- Sinal de engajamento (abertura, clique, score ou faixa do próprio Marketing Cloud), gravado em um campo novo do Lead (PA-10).
- O conector `et4ae5` já grava em `CampaignMember.et4ae5__Activity__c` (campo confirmado na dev). Não está confirmado se ele grava no Lead além dos campos de opt-out. O recon confirma.

**d) Consentimento e opt-out**
- E-mail: `HasOptedOutOfEmail` (padrão). Mobile: `et4ae5__HasOptedOutOfMobile__c` (existente).
- O segmento do CRM exclui quem optou por sair (RN3).
- Quem opera o Marketing Cloud deve garantir que a entrega também respeita o opt-out. Isso é do lado dele.

**e) O que fica com quem opera o Marketing Cloud**
- Criar jornada, público (importando o relatório ou o segmento do CRM), conteúdo, cadência, frequência e envio.
- Aprovar o conteúdo do lado da Eplast.
- Configurar o conector e a sincronização de campos de volta para o CRM.
- Decidir o que fazer com o sinal de engajamento dentro do Marketing Cloud.

---

## 8. O que a demanda não diz (e como ficou)

| Pergunta | Como ficou |
|---|---|
| Qual plataforma de nutrição | Resolvido no card: Marketing Cloud (PA-01). |
| Qual é o público (lead, contato, oportunidade) | PA-02. |
| Qual é o momento adequado para a abordagem | PA-03 e PA-04. |
| Quais origens entram | PA-05. |
| Como tratar opt-out | PA-06. |
| O lead muda de dono ao ficar pronto | PA-07. |
| Como o vendedor é avisado | PA-08. |
| Volume de leads | PA-09. Não se infere na dev. A Eplast precisa informar. |
| Onde o sinal de engajamento do Marketing Cloud é gravado | PA-10. O recon confirma. |
| Cadência, conteúdo e frequência | Passo de quem opera o Marketing Cloud, não do CRM. |
| Quem opera o Marketing Cloud e aprova o conteúdo | Passo da Eplast, declarado na seção 7e. |
| Consumo do sinal por assistente ou resumo (SFAgent2) | Não se aplica nesta demanda. Se surgir, a regra 3 manda estender o SFAgent2, sem agente novo. |

---

## 9. Complexidade e esforço

**Complexidade:** M. Um único objeto (Lead), basicamente declarativo, mas com coordenação de ordem com o Flow de atribuição e de campos com o Marketing Cloud.

**Estimativa de esforço:** 12–20 h
Premissas que mais pesam na faixa:
- Volume de leads não informado (PA-09). Se for alto, o esforço sobe.
- Recon do que o conector `et4ae5` já grava em Lead e de quais Workflow Rules tocam Lead. Sem isso, a faixa de cima se aplica.
- Campo de sinal do Marketing Cloud criado no build (PA-10). Se já existir, a faixa cai.
- Dados de teste pelos scripts de `fixtures/` e roteiro de QA em linguagem de usuário. Não inclui o tempo de configuração no Marketing Cloud, que não é da esteira.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
