# EPLAST-46 — Análise: sugestão de campanhas pelo comportamento dos clientes

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 4 · Marketing (não listada em `contrato.md`; autorizada pela regra 1 da conta e pelo card de 2026-11-13)
**Origem:** Solicitação de Proposta Konecta — Implantação de IA no Salesforce Sales e Marketing (Eplast)
**Org conectada nesta sessão:** `sbx-eplast-dev` (única org conectada, `sf org list`: Sandbox, Connected, Org Id `00DHa000006vfMLMAY`). Sandbox `eplast--qa`, que é o dev da esteira (regra 5). Nenhuma escrita feita; só metadata e contagens agregadas. Produção e QAS não foram tocadas.
**Etapa:** `analise` (ba-discovery). O preflight diz "Etapa que vai rodar: `backlog`"; esta sessão roda a etapa `analise`, conforme a instrução da orquestração. Divergência registrada, sem efeito no conteúdo.
**Marketing Cloud:** nada foi feito nem consultado nele. Toda a parte de Marketing Cloud aqui é desenho do lado do CRM.

---

## 0. Ponto de partida

- `demanda.md` tem uma frase: "Sugerir campanhas com base no comportamento e nas necessidades dos clientes", com a dependência "plataforma de Marketing ainda não definida". Os comentários do card (2026-11-15) já definiram a plataforma: **Marketing Cloud**.
- A demanda não traz critério de aceite, regra de "comportamento", definição de "necessidade", público, canal nem quem recebe a sugestão. Tudo isso está nas premissas (seção 8), não em suposição silenciosa.
- Escopo: Onda 4 não contratada. Pela regra 1 da conta, segue análise, design e build. Não é pendência.

---

## 1. Contexto de negócio

A Eplast quer usar o histórico de compra e o perfil da conta para sugerir, a cada conta, qual ação de marketing ou de acompanhamento comercial faz sentido agora: reativar cliente parado, ampliar produto em conta que compra pouco de uma família, ou priorizar lead. Quem executa o disparo é o Marketing Cloud (regra 2). O Sales Cloud precisa entregar a leitura e a sugestão, não o envio.

Demandas correlatas já no histórico (RAG, consultadas nesta sessão):

- **EPLAST-36** (segmentação e públicos, Onda 4): reaproveitou relatórios na pasta `MARKETING CLOUD` e definiu como o público fica identificável no CRM. [demandas/EPLAST-36/03-design.md]
- **EPLAST-33** (cross-sell, aumento de volume e recuperação de clientes): regras de recuperação ("mais de 60 dias"), cruzada e exclusão de produto comprado nos últimos 180 dias. [demandas/EPLAST-33/04-plano-build.md — rodada anterior, não confirmada como em produção]
- **EPLAST-42** (automação de campanhas de relacionamento, prospecção e reativação): mesma divisão de lado CRM e lado Marketing Cloud. [demandas/EPLAST-42/01-analise.md]
- **EPLAST-43** (jornadas): premissas PA-05 (retorno de envio fica no conector) e PA-06 (campanha do CRM fora da v1). [demandas/EPLAST-43/01-analise.md]
- **EPLAST-27** (próxima melhor ação por cliente): já tem uma ação de recomendação no SFAgent2 (ver seção 4). [demandas/EPLAST-27/04-plano-build.md]

Itens do contrato que tocam o tema, ambos fora da Onda 1–2: "Quais clientes estão há mais tempo sem comprar?" (eplast-ent-11, Onda 2, [contrato.md]) e a segmentação da EPLAST-36.

---

## 2. Objetivo

Para cada conta de cliente, o time (Marketing e Comercial) enxerga **uma ou mais campanhas sugeridas** com o motivo, baseadas no comportamento de compra e na família de produto, e pode levá-las ao Marketing Cloud como público ou lista. A sugestão **não dispara, não cria e não altera nada** fora do CRM.

Fora do objetivo nesta análise: medir resultado da campanha (retorno de envio e clique), que depende do conector (seção 5, item c).

---

## 3. Regra de negócio (proposta, com premissas marcadas)

1. **Conta sem compra recente:** sem compra há mais de 90 dias (`Account.Inactive__c = true`, fórmula `today() − LastPurchase__c > 90`, confirmada na org) → sugestão **reativação**.
2. **Conta com compra recente em uma família e sem compra em outra família que clientes do mesmo setor compram:** sugestão **ampliação de mix** (cross-sell). Exclusão: produto comprado nos últimos 180 dias (regra herdada da EPLAST-33, premissa PA-02).
3. **Lead sem conversão:** sugestão **nutrição** conforme `Lead.PriorityScore__c` e origem. Premissa PA-06: entra só se a Eplast confirmar que lead também é público desta sugestão; na v1 fica como item opcional do design.
4. **Opt-out:** contato com `HasOptedOutOfEmail = true` (ou `et4ae5__HasOptedOutOfMobile__c` para mensagem) não entra como elegível para o canal correspondente. A sugestão de canal é filtrada no nível do contato.
5. **Sem histórico:** conta sem nenhum pedido recebe a sugestão "sem histórico", sem erro e sem sugestão de reativação.
6. Se a conta cair em mais de uma regra, a sugestão é ordenada pela regra de maior prioridade (ordem: reativação, ampliação de mix, nutrição) e a lista inteira aparece com o motivo de cada uma.

Limites numéricos (90 dias, 180 dias) estão em metadata configurável no design (premissa PA-02), não fixos no código.

---

## 4. O que a org já tem (reaproveitar, sem sobrepor)

Confirmado por `sf` em `sbx-eplast-dev` (metadata e contagens; nenhum registro lido):

| Item | Evidência | Decisão (regra 3) |
|---|---|---|
| Agente `SFAgent2` | `BotDefinition` `SFAgent2_v1` … `SFAgent2_v6`; `GenAiPlannerDefinition` com 6 registros | **Reaproveita.** Sugestão aparece como pergunta ao agente ("o que sugerir para a conta X?"). Mudança sai como nova versão do planner, não como agente novo |
| Ação `ProximaAcaoCliente_EPLAST27` (e `_v5`) | `GenAiFunctionDefinition`, confirmada por `sf` | **Estende.** É a ação de recomendação de próxima ação por cliente já existente. Esta demanda acrescenta o critério de campanha nela, por versão nova. Não cria ação paralela |
| Ações `ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta` | `GenAiFunctionDefinition` (versões `_v5` também existem) | **Reaproveita** para leitura de pedido e de conta dentro da conversa |
| `Account.Inactive__c`, `Account.LastPurchase__c`, `Account.LastMonthPurchaseValue__c`, `Account.Sector__c`, `Account.Subsector__c` | `FieldDefinition` | **Reaproveita.** Não cria campo de recência nem de setor. `LastPurchase__c` é resumo (MAX de Oportunidade): ver risco R9 da EPLAST-36 |
| `Lead.PriorityScore__c`, `Opportunity.PriorityScore__c`, `Opportunity.IqScore` | `FieldDefinition` | **Reaproveita** como sinal de priorização. Não é "necessidade" do cliente |
| Relatórios da pasta `MARKETING CLOUD` (EPLAST-36) | pasta `MARKETING CLOUD` (tipo Report) existe; 409 relatórios na org | **Reaproveita** como público do Marketing Cloud. Nenhum relatório novo nesta demanda sem antes conferir o existente |
| `Campaign` / `CampaignMember` | contagem 0 e 0 em `sbx-eplast-dev` | **Não usa** na v1 (premissa PA-06 da EPLAST-43) |
| Permission set de análise de campanhas | citado no design da EPLAST-36 (`PS_Marketing_AnaliseCampanhas`) | **Reaproveita** para leitura de quem analisa. Não junta escrita nele |

**Cria:** nada de objeto novo. Campo novo só se o arquiteto provar que o relatório ou a ação não cobrem (premissa PA-03). Critério de criação de Apex: só se a regra não couber em fórmula, relatório ou configuração de ação. Se houver Apex, classe própria com `<Classe>Test` e sem nome `OrderTrigger` (ver seção 7).

**Incerteza declarada:** a ação `ProximaAcaoCliente_EPLAST27` está na org, mas a busca no repositório local (`clients/eplast/force-app`) não encontrou o nome. Não afirmo o conteúdo dela nesta análise; o recon confirma o que ela faz e onde está o código-fonte.

---

## 5. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca marketing (campanha, segmentação, público, nutrição). Esta seção é obrigatória (regra 2).

**a) Dados que o Marketing Cloud precisa ler e onde ficam no CRM:**
- `Account`: `Sector__c`, `Subsector__c`, `LastPurchase__c`, `Inactive__c`, `LastMonthPurchaseValue__c`. Confirmados por `sf`.
- `Contact`: `AccountId`, `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c`, `LeadSource`, `MailingState`. Confirmados por `sf` (`FieldDefinition`), exceto `MailingState` e `AccountId`, que vêm do design da EPLAST-36 e são padrão do objeto.
- `Order` / `OrderItem` / `Product2` (`Family`, `Group__c`): base da regra de mix. Vêm do Protheus pela integração. Dev vazia (ver seção 6).
- Nenhum campo novo nesta versão.

**b) Como o público fica identificável no CRM:**
- Relatório da pasta `MARKETING CLOUD`, com o critério no nome (ex.: `SEM COMPRA - 181 A 365 DIAS`), como já feito na EPLAST-36. Quem opera o Marketing Cloud importa o relatório como público.
- Por campanha: fora da v1 (`Campaign` e `CampaignMember` vazios na dev e a decisão PA-06 da EPLAST-43).
- Status ou campo de sugestão em `Account`: fora da v1 (premissa PA-03). Se o Marketing Cloud precisar ler a sugestão diretamente, vira campo, em demanda de design.

**c) O que o Marketing Cloud devolve e onde é gravado:**
- Envio, abertura e clique: conector `et4ae5`, em `et4ae5__IndividualEmailResult__c`, `et4ae5__IndividualLink__c` e `CampaignMember.et4ae5__Activity__c`, conforme decidido na EPLAST-43 (PA-05). Essas existências não foram reconfirmadas nesta sessão.
- A v1 **não consome** esse retorno. Não há campo de retorno novo.
- Em `Account`, o conector `et4ae5` não tem campo algum (consulta de `FieldDefinition` retornou zero). Se o Marketing Cloud precisar de campo em `Account`, quem opera o conector decide, em demanda própria.

**d) Consentimento e opt-out:**
- Contato: `HasOptedOutOfEmail` (padrão) e `et4ae5__HasOptedOutOfMobile__c`, ambos confirmados.
- Conta: nenhum campo de consentimento ou opt-out em `Account` (consulta retornou zero).
- A sugestão filtra opt-out por contato e por canal (regra 4 da seção 3). A regra de consentimento final é do Marketing Cloud, e o CRM apenas entrega o filtro.

**e) O que fica para quem opera o Marketing Cloud:**
- Importar o relatório ou lista como público.
- Aplicar opt-out de novo no envio e criar jornada, envio e conteúdo.
- Decidir o uso do retorno de envio e clique, se quiser que a sugestão use isso numa versão futura.
- Nada disso é feito pela esteira.

---

## 6. Dados de teste e ambiente

- `sbx-eplast-dev` está vazia para o que esta demanda usa: `Account` = 0, `Order` = 0, `Campaign` = 0 (contagens confirmadas). Não é possível validar a regra com dado real na dev.
- Testes saem de fixtures, conforme regra 6 da conta e `fixtures/README.md`. A fixture deve criar contas, contatos com opt-out, pedidos e itens com datas controladas (ex.: última compra há 100 dias, compra em família A há 30 dias, nenhuma compra em família B).
- Dados de teste em produção: não. QAS (`sbx-eplast-qa`, Partial Copy com dado real): leitura e execução de automação da própria solução, sem DML do agente sobre registros que não criou (regra 5).
- Usuário de teste para acesso negado: Id `005…` ainda **a informar pelo responsável** (regra 6). Sem ele, o critério de acesso fica como pendente de execução, não de análise.

---

## 7. Critérios de aceite (Gherkin, testáveis)

Todos os critérios são verificáveis na sandbox de dev com fixture. Nenhum depende de registro real.

```gherkin
CA-01 Reativação por recência
  Dado uma conta com LastPurchase__c há 100 dias e nenhuma compra posterior
  Quando o usuário de Marketing pede a sugestão para essa conta
  Então a sugestão contém "reativação"
  E o motivo cita "sem compra há mais de 90 dias"

CA-02 Conta recente não é reativação
  Dado uma conta com LastPurchase__c há 30 dias
  Quando a sugestão é gerada
  Então a sugestão não contém "reativação"

CA-03 Opt-out de e-mail é respeitado
  Dado uma conta elegível para reativação
  E todos os contatos com HasOptedOutOfEmail = true
  Quando a sugestão de canal e-mail é gerada
  Então nenhum contato da conta aparece como elegível para e-mail
  E a sugestão informa "sem contato elegível"

CA-04 Opt-out de mensagem é respeitado no canal certo
  Dado um contato com et4ae5__HasOptedOutOfMobile__c = true e HasOptedOutOfEmail = false
  Quando a sugestão de canal mensagem é gerada
  Então esse contato não aparece como elegível para mensagem
  E continua elegível para e-mail

CA-05 Ampliação de mix exclui produto recente
  Dado uma conta com compra do produto da família B há 60 dias
  Quando a sugestão de ampliação de mix é gerada
  Então a família B não aparece como sugestão
  E uma família não comprada em clientes do mesmo setor aparece com o motivo

CA-06 Conta sem histórico
  Dado uma conta sem nenhum pedido
  Quando a sugestão é gerada
  Então a sugestão é "sem histórico"
  E nenhum erro é registrado no log de Apex

CA-07 Sugestão não dispara nem grava fora do CRM
  Dado a contagem de Campaign, CampaignMember, EmailMessage e registros de envio do conector antes da execução
  Quando a sugestão é gerada para 20 contas
  Então as contagens depois são iguais às de antes
  E nenhum e-mail ou mensagem é enviado

CA-08 Assistente reaproveita o agente existente
  Dado o SFAgent2 com versão ativa anterior à demanda
  Quando a sugestão é publicada
  Então existe uma nova versão do planner ou da ação "ProximaAcaoCliente"
  E o número de agentes SFAgent2 (BotDefinition) continua o mesmo

CA-09 Acesso
  Dado o usuário de teste sem o permission set de Marketing (Id 005… a informar)
  Quando ele pergunta ao SFAgent2 a sugestão de uma conta
  Então a resposta é de acesso negado, sem dado da conta

CA-10 Qualidade do código novo (se houver Apex)
  Dado as classes novas
  Então cada classe tem cobertura igual ou maior que 85%
  E existe uma classe de teste `<Classe>Test` para cada uma
  E nenhum nome colide com o trigger `OrderTrigger` do CPQ

CA-11 Escopo de dados
  Dado a execução da sugestão em lote
  Então o log e a resposta não mostram CPF, e-mail, telefone ou valor de cliente (somente Id e critério)
```

---

## 8. Premissas assumidas (validar na homologação)

Regra 4 da conta: pergunta de regra de negócio sem resposta foi decidida pela org, depois pelo padrão. Cada item traz pergunta, decisão, evidência e como mudar.

- [x] **PA-01 — "Comportamento" do cliente**
  - Pergunta: o que conta como comportamento?
  - Decisão: histórico de compra (pedido com status de compra, recência e frequência). Interação de e-mail ou clique do Marketing Cloud não entra na v1.
  - Evidência: `Inactive__c` e `LastPurchase__c` já calculados na org; contrato eplast-ent-11 fala em "sem comprar"; retorno de envio fica no conector (EPLAST-43, PA-05).
  - Como mudar: se a Eplast quiser engajamento, entra como nova regra em demanda própria, depois que o retorno do conector for lido pelo CRM.

- [x] **PA-02 — "Necessidade" do cliente e limites de tempo**
  - Pergunta: o que é necessidade, e quais são os prazos de reativação e de exclusão?
  - Decisão: necessidade = família de produto que clientes do mesmo setor compram e a conta não comprou. Reativação em 90 dias sem compra. Exclusão de produto comprado nos últimos 180 dias.
  - Evidência: não há campo de necessidade ou interesse em `Account`, `Opportunity`, `Lead` e `Product2` (consulta por nome retornou zero). Os prazos de 90 e 180 dias vêm da fórmula `Inactive__c` (confirmada) e da regra da EPLAST-33 (rodada anterior).
  - Como mudar: limites e famílias em metadata configurável (custom metadata), sem alterar código.

- [x] **PA-03 — Onde a sugestão aparece e se é gravada**
  - Pergunta: a sugestão é gravada no registro ou calculada na hora?
  - Decisão: calculada na hora, pela ação do SFAgent2 e por relatório da pasta `MARKETING CLOUD`. Sem campo novo gravado em `Account` na v1.
  - Evidência: regra 3 da conta (reaproveitar o assistente); evita DML em massa sobre registro real em QAS; o público já sai de relatório (EPLAST-36).
  - Como mudar: se o Marketing Cloud precisar ler a sugestão, vira campo de sugestão em `Account`, em design próprio, com o trigger do CPQ previsto no assessment (seção 9).

- [x] **PA-04 — Quem vê a sugestão**
  - Pergunta: Marketing, Comercial ou os dois?
  - Decisão: Marketing e Comercial, em leitura. Ninguém grava nem dispara pela sugestão.
  - Evidência: a demanda fala em "campanhas" (Marketing) e o card cita o SFAgent2 como ponto de partida; permission set de análise existente (EPLAST-36).
  - Como mudar: ajuste de permission set, sem mudança de design.

- [x] **PA-05 — Quem dispara e onde**
  - Pergunta: a sugestão dispara envio?
  - Decisão: não. A sugestão nomeia a campanha, o público e o canal. O disparo é do Marketing Cloud.
  - Evidência: regra 2 da conta e card de 2026-11-15.
  - Como mudar: não muda. É regra da conta.

- [x] **PA-06 — Catálogo de campanhas e lead**
  - Pergunta: quais campanhas existem e lead entra?
  - Decisão: catálogo = reativação, ampliação de mix e nutrição (lead, opcional). Os nomes seguem o padrão de relatório da EPLAST-36.
  - Evidência: tipos já definidos nas EPLAST-33, EPLAST-36 e EPLAST-42; `Campaign` vazia na dev, então o catálogo não pode vir de campanha existente.
  - Como mudar: catálogo em custom metadata, sem código.

- [x] **PA-07 — Reaproveitar `ProximaAcaoCliente_EPLAST27`**
  - Pergunta: a sugestão é uma ação nova ou estende a existente?
  - Decisão: estende a ação existente, por versão nova. Não cria ação paralela.
  - Evidência: `GenAiFunctionDefinition` com `ProximaAcaoCliente_EPLAST27` e versão `_v5` confirmadas; regra 3 da conta; convenção de versão nova antes da implementação (commit 00794d37).
  - Como mudar: se o arquiteto mostrar que a ação não serve, cria-se ação nova com nome próprio, decisão no design.

- [x] **PA-08 — Dado de teste**
  - Pergunta: como testar com dev vazia?
  - Decisão: fixtures em `fixtures/`, com dados fictícios e rótulo de teste, criados e apagados pelo verificador ou QA. Nenhum dado real.
  - Evidência: `Account` = 0, `Order` = 0, `Campaign` = 0 na dev; regra 6 da conta autoriza dado de teste.
  - Como mudar: não muda.

- [x] **PA-09 — Qualidade do pedido vindo do Protheus**
  - Pergunta: o histórico de compra é confiável para a regra?
  - Decisão: a regra é construída sobre `Order` como está. A validação de amostra com o Comercial (risco já apontado no contrato, Onda 2) fica como condição de homologação, não de análise.
  - Evidência: contrato, Onda 2, "qualidade dos dados de pedidos vindos do Protheus".
  - Como mudar: se a amostra mostrar pedido sem status, ajuste da regra de compra no CMDT.

### Pendências (`- [ ]`)

Nenhuma pendência de regra de negócio bloqueia esta etapa. Os pontos que dependem de quem opera o Marketing Cloud (importar público, usar retorno) e o usuário de teste (Id `005…`) são passos de execução, não de análise.

---

## 9. Riscos do assessment que tocam o pedido

Base: `clients/eplast/assessment.md` (foto de 2026-09-30; cada item abaixo foi reconferido só onde a demanda depende dele).

| Risco do assessment | Como o pedido é afetado | Tratamento |
|---|---|---|
| Automação concorrente em Account, Opportunity e Order com CPQ (achado 1) | A v1 é só leitura (sugestão calculada na hora, PA-03). Se o design precisar gravar em `Account`, cada trigger custom e do CPQ no mesmo evento precisa ser mapeado antes | Sem gravação na v1. Mapear execução se a PA-03 mudar |
| Cobertura Apex de 10% (achado 2) | Qualquer classe nova entra em 0% de cobertura. Hoje não há teste de regra de campanha | CA-10: 85% por classe e `<Classe>Test` obrigatório |
| Validation rules de Order (achado 3) | Sem impacto na v1 (leitura). Se a regra de compra usar `Order.Status`, a validação de status do pedido precisa ser lida antes | Conferir regra de status no recon |
| Nome de trigger `OrderTrigger` duplicado com o CPQ (achado 10) | Se a regra criar qualquer trigger, colide com o nome do CPQ | CA-10: nome próprio, sem `OrderTrigger` |
| Dev sem dado (achado de ambiente, reconfirmado nesta sessão) | Não é possível testar regra de compra com dado real na dev | Fixture (PA-08) |
| Alias `sbx-eplast-dev` apontando para sandbox `qa` | Não é risco nem bloqueio (regra 5 da conta) | Conferido por `sf org list` |

---

## 10. O que a demanda NÃO diz (e como ficou)

1. O que é "comportamento" e "necessidade": decidido em PA-01 e PA-02.
2. Quem recebe a sugestão e onde aparece: PA-03 e PA-04.
3. Se a sugestão é gravada ou calculada: PA-03.
4. Quais campanhas existem: PA-06.
5. Se lead entra: PA-06 (opcional).
6. Qual canal (e-mail, mensagem, outro) e a regra de opt-out aplicada: seção 5, item d, e CA-03, CA-04.
7. Frequência de atualização e se é sob demanda ou em lote: não definido. O design escolhe; a análise pressupõe sob demanda (PA-03).
8. Critério de sucesso (percentual de conta sugerida que vira campanha, resultado de envio): fora do escopo da v1; depende do retorno do conector.
9. Usuário de teste e permissões finais: Id `005…` a informar.

---

## 11. Complexidade e esforço

Complexidade: **M**. Justificativa: é configuração sobre ação e relatório existentes, com regra de opt-out e fixtures; Apex só se a regra não couber em configuração.

**Estimativa de esforço:** 16–32 h

Premissas que mais pesam na faixa:
- Catálogo de campanhas e famílias de produto definidos com o time (PA-02, PA-06); se não vier, a faixa sobe.
- Sem campo novo e sem gravação em `Account` (PA-03). Se a Eplast pedir campo de sugestão, sobe para a faixa G.
- Fixtures de teste em dev (PA-08) entram no esforço.
- Não inclui nada do Marketing Cloud (importar público, jornada, envio) nem a validação de amostra do Protheus (PA-09).

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
