# EPLAST-42 — Análise: automação de campanhas de relacionamento, prospecção e reativação

**Org conectada nesta sessão:** `sbx-eplast-dev` (alias da sandbox de dev; usuário e ID da org omitidos). Nenhum deploy, DML ou anonymous Apex foi feito.
**Etapa:** ANÁLISE (ba-discovery). Sem design, sem build.
**Base de verificação:** consultas `sf` só de metadata, nomes e contagens. Nenhum registro real foi lido.

---

## 1. Entendimento do pedido

O pedido quer automatizar três tipos de campanha: relacionamento com a base ativa, prospecção de leads e reativação de clientes que pararam de comprar. Pelo card (comentários de 13/11 e 15/11), a plataforma de disparo é o **Marketing Cloud**. Nada é enviado pelo CRM.

Isso faz a demanda ter dois lados:

- **Lado Marketing Cloud (fora do escopo da esteira):** envio, jornada, público e campanha lá dentro. Não será configurado nem alterado pela esteira. Fica como passo de quem opera o Marketing Cloud.
- **Lado Sales Cloud (escopo do build):** o que o Marketing Cloud precisa ler e que hoje não está organizado para isso. Ou seja: dado, segmento, público, status, opt-out e onde o retorno é gravado.

A palavra "automatizar" é o ponto de maior ambiguidade. Foi resolvida na premissa PA-03 com base na org (a Eplast já tem um modelo de segmento baseado em relatórios).

---

## 2. O que a org já tem (confirmado por `sf`)

### 2.1 Reaproveitar

| Item | Evidência (sf, sbx-eplast-dev) | Uso nesta demanda |
|---|---|---|
| **Pasta `MARKETINGCLOUD` com 60 relatórios de público** | `sf org list metadata --metadata-type Report --folder MARKETINGCLOUD` (60 relatórios). Nomes: `LEADS_*` (por segmento e região), `PROSPECTS_*` (por região), `REATIVOS_GERAL_*`, `SEM_COMPRA_91_A_180_DIAS`, `SEM_COMPRA_181_A_365_DIAS`, `SEM_COMPRA_MAIS_DE_365_DIAS`, `RECORRENTES_ATIVOS_*` (por região), `SAZONAIS_*` (por região), `SEGMENTO_*` (por setor), `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO`, `SEGMENTO_HIGIENE_LIMPEZA`. | É a base de público. Ajustar filtro antes de criar relatório novo (regra 3). |
| Pasta `Volume_Inativos` (3 relatórios) | `ReportFolder` e `Report` por pasta | Candidato a reativação; a análise de filtros fica para o recon. |
| `Lead.MKT_Origem_Agrupada` | Tooling `CustomField` (EPLAST-39): agrupa `LeadSource` em 13 valores, com "Sem origem" e "Fora da lista" | Critério de origem para prospecção. |
| `Lead.PriorityScore` e `Lead.PriorityBand` | Tooling `CustomField` (EPLAST-26): fórmula de leitura, somente leitura; faixa Alta, Média, Baixa ou "Sem dados suficientes" | Critério de prioridade para prospecção. |
| Opt-out de e-mail | Standard `HasOptedOutOfEmail` (boolean, atualizável) em `Contact` e `Lead` (describe) | Exclusão de e-mail nos públicos. |
| Opt-out de celular do conector | `et4ae5__HasOptedOutOfMobile__c` em `Contact` e `Lead` (describe) | Exclusão de mensagem nos públicos. |
| Filtro de opt-out nos relatórios | Histórico: `[demandas/EPLAST-36/04-plano-build.md]` diz que 35 relatórios da pasta ganharam filtro de opt-out. Estado atual a confirmar no recon. | Não recriar; conferir que o filtro está presente. |
| Campo de atividade do conector em `CampaignMember` | Tooling `CustomField` `Activity`, namespace `et4ae5`, em `CampaignMember` | Retorno do Marketing Cloud gravado no CRM (ver seção 5). |
| Lead, Campaign e CampaignMember como objetos | Tooling `EntityDefinition` (customizable) | Base do lado CRM. |

### 2.2 Não criar sem antes checar

- `Lead_AfterInsert_AplicaRegraAtribuicao` (Flow ativo, versão `301Ha000016Tll8IAC`, dispara no insert de Lead) e a classe `LeadAssignmentService` com teste. Qualquer lead criado pelo build passa por esse fluxo. Não é alterado nesta análise.
- Assignment rules de Lead e Case existem (metadata).
- Campos já existentes de Lead sem namespace: `CNAE`, `CompanyName`, `Sector`, `Subsector`, `CompanyDocument`, redes sociais e `WhatsApp`. Podem servir a segmentação, mas a análise não os usa como critério sem validar o preenchimento no recon (dev vazia).

### 2.3 Criar (candidato, a confirmar no design)

- Nada obrigatório nesta análise. O desenho prevê **zero Apex**, **zero Flow novo** e **zero campo novo em Account, Opportunity ou Order**. Se o design achar necessário algum campo de segmento persistido, ele entra como item separado de "criar", justificado contra os 60 relatórios existentes.
- Campos novos em Lead ou Contact, se houver, saem com `Description` preenchida (ver risco 4.4).

### 2.4 Não se aplica

- **SFAgent2** (agente Agentforce, existe como `Bot` criado em 10/11): a demanda não envolve assistente, resumo, recomendação nem linguagem natural. Não estendido.
- **Campaign** não tem campos custom (0 na Tooling). Não criado nesta análise.

### 2.5 Incerteza de acesso (não é pendência de negócio)

- Consultas de contagem em `Lead`, `Campaign` e `CampaignMember` com `sf data query` retornaram "sObject type not supported", mesmo com `describe` de `Lead` funcionando. Não consegui contagem agregada. O recon confirma o acesso de leitura do usuário de integração antes do design.
- Os filtros dos 60 relatórios não foram abertos aqui (seria despejo de metadata no contexto). O recon lê apenas os relatórios-alvo.

---

## 3. Premissas assumidas (validar na homologação)

Cada premissa tem pergunta, decisão, evidência e como mudar. Todas foram resolvidas pela ordem da regra 4 (org, depois padrão). Nenhuma é pendência de caso 3.

- [x] **PA-01 — Quais públicos entram?**
  - Pergunta: quais públicos de prospecção, relacionamento e reativação a demanda cobre?
  - Decisão: o conjunto já existente na pasta `MARKETINGCLOUD`, separado por finalidade pelo nome. Prospecção = `LEADS_*` e `PROSPECTS_*`. Relacionamento = `RECORRENTES_ATIVOS_*` e `SAZONAIS_*`. Reativação = `REATIVOS_GERAL_*` e `SEM_COMPRA_*`.
  - Evidência: lista de 60 relatórios na org (seção 2.1). A separação é pelo nome; o recon confirma nos filtros.
  - Como mudar: a Eplast indica quais públicos entram. O build altera só os listados.

- [x] **PA-02 — Campanha existe no CRM?**
  - Pergunta: a campanha é um registro no Salesforce (Campaign) ou só existe no Marketing Cloud?
  - Decisão: a campanha de envio fica no Marketing Cloud. No CRM, o público é o relatório. Nenhum `Campaign` novo e nenhum campo novo em `Campaign`. O único retorno gravado no CRM é o que o conector já grava em `CampaignMember`.
  - Evidência: `Campaign` com 0 campos custom; `CampaignMember.Activity` (`et4ae5`) já existe, o que mostra que o conector grava atividade em `CampaignMember`.
  - Como mudar: se a Eplast quiser registro de campanha no CRM para medir retorno, vira demanda ligada a EPLAST-39 (origem e retorno).

- [x] **PA-03 — O que é "automatizar"?**
  - Pergunta: automatizar significa público que se atualiza sozinho, gravar segmento em registro por Flow, ou disparo automático?
  - Decisão: público sempre atual, lido direto dos relatórios, sem gravar segmento no registro. O disparo fica no Marketing Cloud. Nenhum trigger ou Flow novo em Account, Opportunity ou Order.
  - Evidência: 60 relatórios já são o modelo de segmento da Eplast; regra 2 (marketing sai pelo Marketing Cloud); assessment, achado 1 (automação concorrente em Account, Opportunity e Order).
  - Como mudar: segmento persistido em registro exige demanda própria, com a ordem de execução mapeada antes (assessment, achado 1).

- [x] **PA-04 — Opt-out e consentimento**
  - Pergunta: quem não pode receber comunicação e como isso é marcado?
  - Decisão: e-mail usa `HasOptedOutOfEmail`. Mensagem e celular usa `et4ae5__HasOptedOutOfMobile__c`. Todo público exclui quem tem opt-out marcado. Não é criado registro de consentimento novo.
  - Evidência: describe de `Contact` e `Lead`; filtro de opt-out nos relatórios (`[demandas/EPLAST-36/04-plano-build.md]`).
  - Como mudar: se o Marketing Cloud tiver regra de consentimento própria, quem opera o Marketing Cloud decide e a regra fica declarada no desenho.

- [x] **PA-05 — Critério de prospecção**
  - Pergunta: como um lead é classificado para prospecção?
  - Decisão: por origem (`MKT_Origem_Agrupada`) e prioridade (`PriorityBand`, excluindo "Sem dados suficientes"). Não é criada picklist nova.
  - Evidência: campos existentes e documentados (EPLAST-39 e EPLAST-26).
  - Como mudar: é filtro de relatório; muda sem tocar em metadata de dado.

- [x] **PA-06 — Janelas de reativação**
  - Pergunta: a partir de quanto tempo sem compra o cliente é "reativável"?
  - Decisão: as faixas já nomeadas na org: 91 a 180 dias, 181 a 365 dias e mais de 365 dias. Fronteiras exatas (ex.: 180 ou 181) seguem o filtro atual do relatório.
  - Evidência: nomes `SEM_COMPRA_91_A_180_DIAS`, `SEM_COMPRA_181_A_365_DIAS` e `SEM_COMPRA_MAIS_DE_365_DIAS`.
  - Como mudar: ajuste de filtro no relatório; não exige mudança de dado.

- [x] **PA-07 — Lead criado pelo build e atribuição**
  - Pergunta: o build cria leads e isso altera a atribuição?
  - Decisão: a demanda não cria lead de produção. Lead de teste passa pelo fluxo existente de atribuição, sem alterá-lo.
  - Evidência: `Lead_AfterInsert_AplicaRegraAtribuicao` ativo; `LeadAssignmentService` com teste.
  - Como mudar: nova regra de atribuição é demanda própria.

- [x] **PA-08 — Apex**
  - Pergunta: é preciso código?
  - Decisão: o desenho prevê zero Apex. Se o design precisar de código, a classe nasce com teste `<Classe>Test` e cobertura de 85%, conforme o padrão do squad.
  - Evidência: regra de decisão declarativo x código (skill `salesforce-doutrina`); cobertura org-wide de 10% (assessment, achado 2).
  - Como mudar: o arquiteto decide no design, com justificativa.

- [x] **PA-09 — Dados de teste**
  - Pergunta: como testar sem dado real?
  - Decisão: na dev (vazia de registros), o verificador cria dado sintético com prefixo `EPLAST42 TESTE`. Na QA (QAS, Partial Copy), o teste usa só dado sintético com esse prefixo. Nenhum registro real é lido ou alterado.
  - Evidência: regra 5 do cliente (QAS é Partial Copy com dado real); guardrail 2 (LGPD).
  - Como mudar: não se aplica; é regra de segurança.

- [x] **PA-10 — Quem opera o Marketing Cloud**
  - Pergunta: quem monta a campanha, o público e o envio lá?
  - Decisão: passo declarado para quem opera o Marketing Cloud, sem atribuir a um nome. A esteira não o executa.
  - Evidência: regra 2 e reforço de 15/11 do card.
  - Como mudar: a Eplast indica o responsável; o passo é só registrado no desenho e no roteiro.

---

## 4. Riscos do assessment que tocam este pedido

Assessment de onboarding (foto antiga). Cada item foi conferido pela org quando afirmado acima.

1. **Automação concorrente em Account, Opportunity e Order (achado 1, alta).** Aplica-se em parte. Os relatórios de reativação leem Order, Account e Opportunity, mas não escrevem neles. O desenho não cria trigger nem Flow nesses objetos (PA-03). Se o design precisar escrever, a ordem de execução entre trigger custom, trigger do CPQ (`SBQQ`) e Flow é mapeada antes.
2. **Cobertura de teste em 10% (achado 2).** Aplica-se só se houver Apex (PA-08). Não é tratado aqui por falta de código.
3. **Order: 23 validation rules e colisão de nome `OrderTrigger` (achados 3 e de nomenclatura).** Não se aplica. Nenhum registro de Order é gravado pela demanda.
4. **Campos sem descrição (achado 4, 153 de 223 em Account, Order, Opportunity e OrderItem).** Aplica-se a campos novos em Lead ou Contact: saem com `Description`. Não há curadoria de campos existentes nesta demanda.
5. **Dev parecida com QA (achado 6).** Resolvido pela regra 5 do cliente: os nomes são esperados. Não é bloqueio. Conferido: a conectada é `sbx-eplast-dev` (usuário e org na seção de cabeçalho).
6. **Risco novo, não está no assessment:** o Flow `Lead_AfterInsert_AplicaRegraAtribuicao` é ativo e criado em 15/11. Qualquer teste ou build que crie lead passa por ele (PA-07). Tratado como premissa; o recon confirma antes do design.

---

## 5. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca segmentação, público, origem, nutrição, relacionamento e reativação. Esta seção é obrigatória (regra 2). **Nada é feito no Marketing Cloud. Nada é enviado pelo CRM.**

**a) Dados que o Marketing Cloud precisa ler e onde ficam no CRM**

| Dado | Objeto e campo | Uso |
|---|---|---|
| E-mail | `Contact.Email`, `Lead.Email` | Destinatário de e-mail |
| Opt-out de e-mail | `Contact.HasOptedOutOfEmail`, `Lead.HasOptedOutOfEmail` | Exclusão |
| Opt-out de celular | `et4ae5__HasOptedOutOfMobile__c` em `Contact` e `Lead` | Exclusão de mensagem |
| Origem do lead | `Lead.LeadSource` e `Lead.MKT_Origem_Agrupada` | Público de prospecção |
| Prioridade do lead | `Lead.PriorityBand` (ou `PriorityScore`) | Recorte de prospecção |
| Status do lead | `Lead.Status` | Exclusão de lead convertido |
| Última compra e data de última atividade | campos lidos pelos relatórios `SEM_COMPRA_*` e `LastActivityDate` (standard) | Reativação e recência |

Nota: a lista acima foi confirmada por describe ou por nome de campo. Os campos de data de compra usados pelos relatórios `SEM_COMPRA_*` são confirmados pelo recon ao abrir os filtros.

**b) Como o público fica identificável no CRM**

- Não há campo de segmento persistido. O público é o relatório da pasta `MARKETINGCLOUD`, atualizado sempre que lido.
- Quem precisa ver o público lê o relatório; o Marketing Cloud consome a lista pelo mecanismo que o conector já usa (a confirmar no recon).
- Não há campanha nova no CRM (PA-02).

**c) O que o Marketing Cloud devolve e onde é gravado**

- Atividade de envio e resposta é gravada pelo conector em `CampaignMember.Activity` (`et4ae5`). Não criado campo novo nesse retorno.
- Resultado agregado para análise fica no relatório existente, não em campo novo.
- Mudança em opt-out feita no Marketing Cloud é sincronizada pelo conector em `et4ae5__HasOptedOutOfMobile__c` e no padrão do e-mail. Confirmar no recon se o sentido é esse.

**d) Consentimento e opt-out**

- Exclusão nos públicos por `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c` (PA-04).
- Não há registro de consentimento novo. Se a Eplast precisar de registro formal de consentimento (LGPD), é demanda própria.

**e) O que fica para quem opera o Marketing Cloud**

- Criar, no Marketing Cloud, os públicos e jornadas que consomem os relatórios.
- Definir a frequência de envio, o conteúdo e a cadência de nutrição.
- Decidir a regra de consentimento do próprio Marketing Cloud, se houver.
- Atualizar, se mudar, o mapeamento de cada público com o nome do relatório.

---

## 6. Critérios de aceite (testáveis)

Todos os cenários usam dado sintético com prefixo `EPLAST42 TESTE`. Nenhum critério exige ler registro real.

**CA-01 — Reaproveitamento dos relatórios**
- Dado a pasta `MARKETINGCLOUD` com 60 relatórios antes do build,
- Quando o build terminar,
- Então todo relatório novo ou alterado aparece na lista de `04-plano-build.md` com a justificativa de por que o existente não atendia, e o número de relatórios de público sem justificativa é zero.

**CA-02 — Opt-out de e-mail excluído**
- Dado um `Contact` sintético com `HasOptedOutOfEmail = true` que pertence ao público de relacionamento,
- Quando o relatório desse público for executado com o filtro vigente,
- Então esse contato não aparece no resultado.

**CA-03 — Opt-out de celular excluído**
- Dado um `Lead` sintético com `et4ae5__HasOptedOutOfMobile__c = true` que pertence ao público de prospecção,
- Quando o relatório for executado,
- Então esse lead não aparece no resultado.

**CA-04 — Janelas de reativação**
- Dado um cliente sintético com último pedido há 100 dias,
- Quando o público `SEM_COMPRA_91_A_180_DIAS` for executado,
- Então o cliente aparece nesse público e não aparece em `SEM_COMPRA_181_A_365_DIAS`.
- E dado um cliente sintético com último pedido há 400 dias,
- Então ele aparece somente em `SEM_COMPRA_MAIS_DE_365_DIAS`.

**CA-05 — Origem do lead**
- Dado um `Lead` sintético com `LeadSource` preenchido com um dos 13 valores,
- Quando o relatório de prospecção por origem for executado,
- Então o lead aparece com o grupo correspondente em `MKT_Origem_Agrupada`.
- E dado um `Lead` sintético com `LeadSource` vazio,
- Então ele aparece como "Sem origem" e não entra em público de origem definida.

**CA-06 — Prioridade do lead**
- Dado um `Lead` sintético com `PriorityBand = Alta`,
- Quando o público de prospecção prioritária for executado,
- Então o lead aparece.
- E dado um `Lead` sintético com "Sem dados suficientes",
- Então ele não aparece.

**CA-07 — Retorno do conector gravado onde o desenho diz**
- Dado um `CampaignMember` sintético com atividade do conector (`Activity`),
- Quando o relatório de retorno for executado,
- Então o resultado aparece com o rótulo esperado e sem alteração de campo fora do desenho.

**CA-08 — Nenhum envio pelo CRM**
- Dado o pacote do build,
- Quando inspecionado (metadata do branch),
- Então não existe Flow com ação de e-mail alert, Apex de envio de e-mail nem componente de disparo.

**CA-09 — Marketing Cloud não alterado**
- Dado o pacote do build,
- Quando inspecionado,
- Então não há mudança em componente do namespace `et4ae5` e `06-entrega.md` lista os passos de quem opera o Marketing Cloud.

**CA-10 — Sem sobreposição**
- Dado o pacote do build,
- Quando inspecionado,
- Então não há trigger ou Flow novo em Account, Opportunity ou Order. Se houver, a ordem de execução entre trigger custom, trigger do CPQ e Flow está mapeada no design.

**CA-11 — Campo novo documentado**
- Dado um campo novo criado em Lead ou Contact pelo build,
- Quando inspecionado,
- Então o campo tem `Description` preenchida.

**CA-12 — Dado real não lido**
- Dado a sandbox de QA (Partial Copy),
- Quando a QA executar os relatórios,
- Então os totais registrados no artefato vêm só de registros com o prefixo `EPLAST42 TESTE`.

---

## 7. O que a demanda não diz (respondido nas premissas ou no recon)

- Quais campanhas o cliente quer e quantas por mês (PA-01 e PA-10 cobrem o formato; volume não é definido aqui).
- Se a Eplast quer medir retorno de campanha no CRM (PA-02; ligado a EPLAST-39).
- Se "automatizar" inclui gravar segmento em registro (PA-03).
- Quem opera o Marketing Cloud (PA-10).
- Como o Marketing Cloud recebe o público (mecanismo do conector; confirmar no recon).
- Janelas exatas de reativação e critérios de prioridade (PA-05 e PA-06).
- Se há registro formal de consentimento além do opt-out (PA-04).

Nenhum item acima precisa de pergunta de caso 3. Todos foram resolvidos pela ordem da regra 4 e ficam como premissa para validação na homologação.

---

## 8. Complexidade e esforço

- **Complexidade:** M. Pelo reaproveitamento dos 60 relatórios e pela ausência de Apex e Flow novo, o trabalho é ajuste de filtro, teste com dado sintético e documentação; o tamanho sobe com o número de públicos no escopo.

**Estimativa de esforço:** 12–20 h

Premissas que mais pesam na faixa:
- Número de públicos no escopo: se for só a lista de PA-01, perto do piso; se for a pasta inteira (60), perto do teto.
- Dev vazia de registros: o teste de filtro exige dado sintético criado pelo verificador.
- Sem Apex nem Flow novo (PA-08 e PA-03). Se o design precisar de algum, a faixa sobe.
- Recon dos filtros dos relatórios-alvo e confirmação do acesso a `Lead`, `Campaign` e `CampaignMember` (seção 2.5).

---

## 9. Encerramento

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
