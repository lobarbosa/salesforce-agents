# 02 — Recon da org — SOMOSAGILITY-21: Campo origem do Lead

Coleta em `sbx-somos-agility-dev` (sandbox, confirmada via `sf org list` / `sf org display`
— `Instance Url: https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`).
**Data da coleta: 2026-10-21.**

## D-1 — RESOLVIDA: qual valor de picklist é "Web Site Agility"

Recuperado `StandardValueSet:LeadSource` da org (`sf project retrieve start --metadata
"StandardValueSet:LeadSource"`):

- API name `Web Site Agility Networks` → **label exibido ao usuário: "Web Site Agility"**
  (sem "Networks" no label, só no nome interno).
- API name `Web Site Agility – E-mail` → label "Web Site Agility – E-mail" (valor distinto,
  para origem por e-mail).

O texto da demanda ("a opção web site Agility") bate exatamente com o **label** do valor
`Web Site Agility Networks`. Dúvida D-1 da análise está resolvida por evidência de metadata,
não por suposição: é este o valor, não o de e-mail. Recomendo ainda assim uma confirmação
rápida de Guilherme/Marketing no gate de design, só porque é decisão de negócio (qual canal
o valor representa), não técnica — mas a ambiguidade textual original está desfeita.

## D-3 — RESOLVIDA: campo vem vazio ou com valor default errado?

`sf sobject describe --sobject Lead` (campo `LeadSource`): `defaultValue` =
**"Prospecção - Gerente de Contas"**, marcado `default: true` no `StandardValueSet`
recuperado. Esse é um default de picklist em nível de org (Standard Value Set), que a
plataforma aplica a qualquer inserção — via UI **ou via API** — que não informe o campo
explicitamente.

Conclusão: quando a integração do site cria o Lead sem mandar `LeadSource` no payload, o
campo **não fica em branco** — ele herda "Prospecção - Gerente de Contas" (default de toda
a org, usado hoje para o fluxo de prospecção de Gerente de Contas). O relato "não está
vindo preenchido com a opção web site Agility" é compatível com os dois comportamentos
(vazio ou default errado), mas a evidência de metadata aponta para o segundo: o campo não
pode ficar vazio neste objeto quando há um default ativo. Isso muda o desenho: a correção
não é "preencher um campo vazio", é "sobrepor um default que não deveria se aplicar a este
canal de entrada" — e precisa cuidar para não afetar os outros canais que legitimamente
usam esse mesmo default (Prospecção via Gerente de Contas).

## D-2 — PARCIALMENTE RESOLVIDA: qual é o ponto de entrada técnico

- **Não há Web-to-Lead nativo** configurado (nenhum metadata `WebToLead`/`Web2Lead`
  encontrado no repo).
- **Não há Flow nem Apex trigger ativo** no objeto Lead que grave em `LeadSource`. O único
  Flow relacionado a criação de Lead (`Novo_Lead`, processo "Workflow"/Process Builder
  legado, `onCreateOnly`) só dispara e-mails de notificação por `RecordType` — está
  **`status: Obsolete`** e não toca em `LeadSource`. `Atualizar_Descri_o_com_Informa_es_do_
  Lead` e `Notifica_se_Novo_Lead_Criado` também não referenciam `LeadSource` (conferido por
  tamanho/conteúdo do XML). Não existe Apex (`classes`/`triggers`) que mencione `Lead` ou
  `LeadSource` no repo hoje (`grep` não achou nada em `triggers/`, achou só um teste de outro
  objeto em `classes/`).
- **Achado principal:** existe um Connected App dedicado, `force-app/main/default/
  connectedApps/Lead_Site_Agility.connectedApp-meta.xml` (label "Lead Site Agility"), OAuth
  configurado com `callbackUrl` apontando explicitamente para
  `https://agilitynetworks.my.salesforce.com/services/data/v52.0/sobjects/lead` — ou seja,
  um cliente externo autentica via OAuth com este Connected App e grava o Lead **direto via
  REST API** (`POST .../sobjects/lead`), sem passar por Web-to-Lead, Flow ou Apex do lado
  Salesforce. Existe também um segundo Connected App parecido, `Lead_Site_Eagle`, não
  investigado aqui por não ter relação aparente com o chamado (nome não bate com "site
  Agility"; registrar para não confundir caso apareça de novo).
- **Não confirmado:** qual sistema do lado de fora é esse (o nome "Lead Site Agility" sugere
  o site institucional, mas não há documentação de integração no repo) e qual usuário
  Salesforce autentica por ele. Tentei achar o usuário de integração via
  `SELECT Id, Username, Name, Profile.Name, IsActive FROM User WHERE Profile.Name IN
  ('Anypoint Integration','Salesforce API Only System Integrations','Minimum Access - API
  Only Integrations')` (metadata/contagem, sem dado pessoal) — **zero resultados** nesta
  sandbox de dev. Interpretação mais provável: o usuário de integração de verdade só existe
  configurado contra produção (que este agente não acessa, guardrail #1), e a sandbox de dev
  não tem esse usuário espelhado. Existe um profile chamado `Anypoint Integration` no
  metadata do repo (sugere que a integração roda via MuleSoft Anypoint), mas não achei
  nenhuma referência a `Lead` dentro desse profile — não dá para confirmar que é o mesmo
  usuário/profile que autentica no Connected App `Lead Site Agility` sem acesso a produção
  ou a quem administra a integração. **Fica como pergunta para o design/gate, não como
  suposição.**

## Outras automações no objeto Lead (sem relação direta com LeadSource, registradas por completude)

- `validationRules/Lead_Novo`: exige `Status = "Novo"` em qualquer inserção (`ISNEW()`).
  Relevante para QA: qualquer carga de teste da correção precisa criar o Lead já com
  `Status = "Novo"`, senão a inserção é rejeitada antes de chegar a testar `LeadSource`.
- `assignmentRules/Lead.Entrada de Leads`: existe mas está **inativa** (`active: false`) —
  não interfere.
- Nenhuma `duplicateRule` nem permission set achados tem lógica sobre `LeadSource`.
- `LeadSource` é usado também em `Opportunity` e `Contact` (campos homônimos, herdam o
  mesmo Standard Value Set da org). Qualquer mudança que altere o **Standard Value Set**
  (em vez de só a automação de entrada) atinge os três objetos — relevante para a decisão
  do arquiteto sobre onde aplicar a correção (ponto de entrada do Lead vs. valor
  default global).

## Volume de dados

`SELECT COUNT(Id) FROM Lead` não repetido aqui (já reportado em 01-analise.md: zero Leads
na sandbox de dev). Sem mudança desde a análise.

## O que não foi possível medir

- Não há como observar nesta sandbox o payload real que a integração do site envia hoje
  (zero Leads na org, e não há log de integração acessível por `sf` CLI). Qualquer
  confirmação de que o payload *de fato* omite `LeadSource` (em vez de mandar um valor
  errado) depende de evidência trazida por quem administra a integração/middleware, fora do
  alcance desta sessão.
- Não confirmei o usuário/profile exato de autenticação do Connected App `Lead_Site_Agility`
  (ver D-2 acima) — sandbox de dev não tem esse usuário.
