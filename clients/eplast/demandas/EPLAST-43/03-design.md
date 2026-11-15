# EPLAST-43 — Design: Personalização de conteúdos, e-mails e mensagens (lado do Sales Cloud)

**Cliente:** Eplast · **Etapa:** design (arquiteto) · **Data:** 2026-11-15
**Org de dev:** `sbx-eplast-dev` (Sandbox, Org Id `00DHa000006vfMLMAY`, conferida com `sf org list` nesta sessão; é a `eplast--qa` da Eplast, regra 5)
**Resultado do desenho:** pronto para o gate do arquiteto humano. Sem pendência bloqueante. Sem mudança de modelo de dados (nenhum objeto ou campo novo).
**Entradas:** `01-analise.md` (aprovada em `gates.md`, 2026-11-15), `02-recon.md`, `00-preflight.md` (sem bloqueios, sem outras demandas nos mesmos componentes), `comentarios-do-card.md`.

---

## 1. Solução em poucas linhas

O CRM já tem quase tudo que o Marketing Cloud precisa para personalizar por cliente e segmento: **60 relatórios de público** na pasta `MARKETING CLOUD`, todos os de Contact e Lead já com filtro de opt-out de e-mail, os campos de segmento (setor, categoria da conta, UF, última compra, classe de relacionamento, origem e prioridade do lead) e o permission set `PS_Marketing_Publicos`. O design **ajusta o que existe e cria só o que falta**:

1. **Ajusta** os 16 relatórios de Lead da pasta para excluir lead convertido (`CONVERTED = 0`). Hoje nenhum deles filtra isso, então um lead convertido continua no público como lead e também aparece como contato (CA-04).
2. **Cria** 2 relatórios de público de mensagem (celular), que excluem o opt-out de celular `et4ae5__HasOptedOutOfMobile__c` (CA-02). Hoje nenhum relatório da pasta usa esse campo.
3. **Cria** 1 relatório de prospecção por origem e faixa de prioridade (PA-02 c), que hoje não existe.
4. **Ajusta** `PS_Marketing_Publicos`, dando leitura (FLS) nos campos de personalização e de canal que faltam (CA-05).
5. **Cria** 1 grupo público, `Marketing_Publicos`, e compartilha a pasta com ele como leitura. Hoje a pasta só está compartilhada com um usuário nominal: quem recebe o permission set não vê os públicos (CA-05).

Sem Flow, sem Apex, sem trigger, sem campo novo, sem envio pelo CRM e sem nenhuma ação no Marketing Cloud.

**Por que essa forma:** segmento como relatório é a decisão já em uso na conta (EPLAST-36, PA-06 da análise): muda sem migração de dado e é o formato que o Marketing Cloud Connect importa. Qualquer alternativa com campo ou automação seria sobreposição (regra 3) e mexeria em objetos com automação concorrente (achado 1 do assessment).

---

## 2. O que a org mostrou nesta sessão (complemento ao recon)

Conferências pontuais feitas no design, só metadata e contagens. Corrigem ou fecham itens da seção 9 do `02-recon.md`:

| # | Ponto | Resultado | Comando |
|---|---|---|---|
| D1 | Tamanho da pasta `MARKETING CLOUD` | **60 relatórios** (o recon listou 25; o filtro dele cortou) | `SELECT COUNT() FROM Report WHERE FolderName = 'MARKETING CLOUD'` |
| D2 | Opt-out de e-mail nos filtros | **58 de 60** têm `EMAIL_OPT_OUT equals 0`. Os 2 sem filtro são `CLASSIFICACAO_CONTAS_POR_CLASSE` (`AccountList`) e `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO` (`OrderItemList`), que não têm destinatário (não são público de envio) | retrieve dos 60 em pasta temporária, descartada |
| D3 | Opt-out de celular em filtro | **0 de 60** | idem |
| D4 | Lead convertido em filtro | **0 de 16** relatórios `LeadList` filtram `CONVERTED`. Só `Cpia_de_LEADS_GERAL_D2D` ("LEADS - NÃO CONVERTIDOS") filtra `STATUS = Fechado - Não convertido`, o que já exclui convertido | idem |
| D5 | `Lead.MKT_Origem_Agrupada__c` | **Existe** (fórmula texto, EPLAST-39). O recon não o achou porque o perfil Administrador do sistema não tem FLS nele; a leitura vem só por `PS_Marketing_AnaliseCampanhas`. A fórmula devolve o próprio valor de `LeadSource` para os 13 valores da picklist, "Sem origem" para vazio e "Fora da lista" para o resto | Tooling `CustomField` |
| D6 | Coluna `MKT_Origem_Agrupada__c` no tipo `LeadList` | **Não aparece** para o usuário da esteira (falta FLS no perfil) | `/analytics/report-types/LeadList` |
| D7 | `PS_Marketing_Publicos` | Lê Account, Contact, Lead, Order, Product2; cria e edita Campaign; `RunReports`, `CreateCustomizeReports`; FLS de leitura em 9 campos: `Account.Inactive__c`, `LastPurchase__c`, `RelationshipClass__c`, `Sector__c`, `Subsector__c`; `Contact.et4ae5__HasOptedOutOfMobile__c`; `Lead.Sector__c`, `Subsector__c`, `et4ae5__HasOptedOutOfMobile__c`. **0 atribuições** | retrieve + `PermissionSetAssignment` |
| D8 | Compartilhamento da pasta | `AccessType = Hidden`; `folderShares` com **um único usuário nominal** (acesso Manage). Nenhum grupo. O nome do usuário não entra aqui (guardrail 2) | `Folder` + retrieve `ReportFolder` |
| D9 | Grupo público de marketing | `Marketing_Origem_Retorno` existe (EPLAST-39, pastas de origem e retorno de campanha, 0 membros). Não há grupo de públicos | `Group` |
| D10 | `CampaignMember.et4ae5__Activity__c` | **Existe** (pacote `et4ae5`) | Tooling `CustomField` |
| D11 | Campos de compra e conta | `Account.LastPurchase__c` (data, calculado), `Account.RelationshipClass__c` (fórmula: Potencial, Inativo, Ativo), `Account.Inactive__c` (fórmula: mais de 90 dias sem compra), `Account.Type` (picklist: Inativo, Novo, Prospect, Prospect Indústria, Reativo, Recorrente, Sazonal, Stand-by, Encerrou atividades). `Account.Sector__c`, `Account.LastPurchase__c` e `Lead.Sector__c` **sem description** (achado 4) | describe + Tooling |
| D12 | Status de Lead | `Aberto - Não contatado`, `Contatado`, `Fechado - Não convertido`, `Fechado - Convertido` (único com `IsConverted = true`) | `LeadStatus` |
| D13 | Campos que aceitam FLS em permission set | Aceitam: `Lead/Contact.Email`, `HasOptedOutOfEmail`, `MobilePhone`, `LeadSource`, `et4ae5__Mobile_Country_Code__c`, `et4ae5__HasOptedOutOfMobile__c`; `Lead.State`, `Lead.PriorityBand__c`, `Lead.Sector__c`; `Contact.MailingState`; `Account.Type`, `BillingState`, `Sector__c`, `LastPurchase__c`. Não aceitam: `Lead.Status`, `Lead.IsConverted` | `EntityParticle.IsPermissionable` |
| D14 | Colunas de celular nos tipos de relatório | `LeadList`: `MOBILE_PHONE`, `CONVERTED`, `Lead.et4ae5__HasOptedOutOfMobile__c`, `Lead.PriorityBand__c`, `LEAD_SOURCE`. `ContactList`: `PHONE3` (Celular), `Contact.et4ae5__HasOptedOutOfMobile__c`, `TYPE` (Categoria da conta) | `/analytics/report-types/<Tipo>` |
| D15 | Validation rules de telefone | Lead `Celular`: `MobilePhone` vazio ou `(DD)` seguido de 8 ou 9 dígitos **sem espaço e sem hífen**. Lead `Telefone`: `Phone` vazio ou `(DD)` + 8 dígitos. Contact `Telefone` (`MobilePhone`) e `WhatsApp` (`WhatsApp__c`): vazio ou `(DD)`, espaço opcional, 4 ou 5 dígitos, hífen opcional, 4 dígitos | Tooling `ValidationRule` |
| D16 | Usuários ativos por perfil (contagem) | Administrador do sistema 9; Comercial - Analista 4; Financeiro 1; demais são usuários de integração | `User` agregado por perfil |
| D17 | Pasta `fixtures/` do cliente | **Não existe ainda** | `ls` |

Observação sem ação nesta demanda: há nomes técnicos que não batem com o rótulo (ex.: `Cpia_de_LEADS_SP_fWa` = "LEADS - CO", `Cpia_de_PROSPECTS_MG_Kk0` = "PROSPECTS - RJ") e um duplicado rotulado pela própria Eplast (`SAZONAIS_MG_X7D` = "SAZONAIS - MG (DUPLICADO - REVISAR)"). Renomear ou apagar pode quebrar uma importação já configurada no Marketing Cloud. Fica como recomendação (seção 12).

---

## 3. Item a item: reaproveita, ajusta, cria (regra 3)

| # | Componente | Decisão | Estado confirmado via `sf` | O que muda |
|---|---|---|---|---|
| 1 | Pasta `MARKETING CLOUD` (`MARKETINGCLOUD`) | **Reaproveita** | Existe (D1) | Recebe os 3 relatórios novos. O compartilhamento ganha uma linha (item 9) |
| 2 | 42 relatórios `ContactList` da pasta (segmento por setor, recência, categoria × UF, prospects, potenciais) | **Reaproveita sem alterar** | Existem; todos com `EMAIL_OPT_OUT = 0` (D2) | Nada. São os públicos de e-mail para cliente e contato (CA-01, CA-03) |
| 3 | 16 relatórios `LeadList` da pasta: `LEADS_SEGMENTO_` (8 setores), `LEADS_ES_SQz`, `LEADS_MG_26H`, `LEADS_RJ_24t`, `LEADS_SP_2yf`, `LEADS_SUL_0EK`, `Cpia_de_LEADS_SP_fWa`, `LEADS_OlB`, `Cpia_de_LEADS_GERAL_D2D` | **Ajusta** | Existem; nenhum com `CONVERTED` (D4) | Acrescenta o critério `CONVERTED equals 0`. Nada mais muda: colunas, formato e nome continuam iguais. A contagem só cai onde houver lead convertido (CA-04, CA-08) |
| 4 | `CLASSIFICACAO_CONTAS_POR_CLASSE`, `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO` | **Reaproveita sem alterar** | Existem (D2) | Nada. São de análise de conta e produto, sem destinatário |
| 5 | Relatório `MSG_CONTATOS_CELULAR_APTOS` | **Cria** | Não existe | `ContactList`, tabular, escopo `organization` (copiado dos `ContactList` da pasta). Filtros: `Contact.et4ae5__HasOptedOutOfMobile__c equals 0` e `PHONE3` (Celular) não vazio. Colunas: id do contato, nome, conta, `PHONE3`, `Contact.et4ae5__Mobile_Country_Code__c`, `ADDRESS2_STATE`, `TYPE` (categoria), `Account.Sector__c`, `Account.RelationshipClass__c`, `Account.LastPurchase__c` |
| 6 | Relatório `MSG_LEADS_CELULAR_APTOS` | **Cria** | Não existe | `LeadList`, tabular, escopo `org`. Filtros: `Lead.et4ae5__HasOptedOutOfMobile__c equals 0`, `CONVERTED equals 0`, `MOBILE_PHONE` não vazio. Colunas: id do lead, nome, empresa, `MOBILE_PHONE`, `Lead.et4ae5__Mobile_Country_Code__c`, `STATE`, `Lead.Sector__c`, `LEAD_SOURCE`, `Lead.PriorityBand__c`, `STATUS` |
| 7 | Relatório `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` | **Cria** | Não existe (nenhum relatório agrupa por origem ou faixa, D4) | `LeadList`, resumo, escopo `org`, agrupado por `LEAD_SOURCE` e `Lead.PriorityBand__c`. Filtros: `EMAIL_OPT_OUT equals 0`, `CONVERTED equals 0`, `STATUS` igual a `Aberto - Não contatado,Contatado`, `Lead.PriorityBand__c notEqual Sem dados suficientes`. Colunas: id do lead, nome, empresa, e-mail, `STATE`, `Lead.Sector__c` |
| 8 | Permission set `PS_Marketing_Publicos` | **Ajusta** (inclusão de FLS de leitura, nada é retirado) | Existe, 0 atribuições (D7) | Acrescenta leitura em: `Lead.MKT_Origem_Agrupada__c`, `Lead.PriorityBand__c`, `Lead.LeadSource`, `Lead.MobilePhone`, `Lead.HasOptedOutOfEmail`, `Lead.et4ae5__Mobile_Country_Code__c`, `Contact.LeadSource`, `Contact.MobilePhone`, `Contact.HasOptedOutOfEmail`, `Contact.et4ae5__Mobile_Country_Code__c`, `Account.Type`. A description ganha "EPLAST-43: FLS de canal e personalização". `Lead.Status` e `Lead.IsConverted` não aceitam FLS (D13) e já são legíveis com leitura no objeto |
| 9 | Grupo público `Marketing_Publicos` ("Públicos de Marketing") | **Cria** | Não existe (D9) | Grupo sem membros, com description. Destino do compartilhamento de leitura da pasta. Quem recebe `PS_Marketing_Publicos` entra no grupo (passo da Eplast) |
| 10 | Compartilhamento da pasta com `Marketing_Publicos` (leitura) | **Cria** (acrescenta uma linha) | Hoje só um usuário nominal (D8) | Ver seção 7.3: **não** se implanta `ReportFolder` por metadata |
| 11 | `PS_Marketing_AnaliseCampanhas` e grupo `Marketing_Origem_Retorno` | **Não mexe** | Existem (D5, D9) | São da análise de campanha (EPLAST-39). Usá-los para os públicos daria lista de contatos a quem só analisa campanha (mesmo critério da EPLAST-36, item 14 do design dela) |
| 12 | `Lead.MKT_Origem_Agrupada__c` | **Reaproveita** (só ganha FLS no item 8) | Existe (D5) | Fica disponível para o Marketing Cloud ler. Não é usado como coluna nos relatórios: ver decisão 4.3 |
| 13 | Campos de segmento e opt-out (`Sector__c`, `LastPurchase__c`, `RelationshipClass__c`, `Type`, `PriorityBand__c`, `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c`) | **Reaproveita** | Existem (D11, D13, recon seção 4) | Nenhum campo novo. CA-09 não se aplica (não há campo criado) |
| 14 | Objetos de resultado do conector (`et4ae5__IndividualEmailResult__c`, `et4ae5__IndividualLink__c`, `CampaignMember.et4ae5__Activity__c`) | **Reaproveita sem alterar** | Existem (recon seção 4, D10) | Onde o retorno do Marketing Cloud é gravado (seção 6 c) |
| 15 | Conector `et4ae5`: objetos, Flows `MCC_*`, workflow rules, permission sets do pacote | **Não mexe** | Existem (recon) | Regra 2 |
| 16 | `Campaign`, `CampaignMember`, campanhas `PUB -` | **Não usa na v1** | 0 registros; 0 campanhas `PUB -` (recon 3.3) | PA-06 |
| 17 | Agente `SFAgent2` | **Não mexe** | Existe, versões `SFAgent2_v2` a `_v5` na dev (recon 3.4) | PA-07: a demanda não pede assistente, resumo nem recomendação |
| 18 | Campo de opt-out de WhatsApp | **Não cria** | Não existe; só `WhatsApp__c` (telefone) em Lead e Contact (recon) | PA-04: fica para a EPLAST-34 |

**Total:** 3 relatórios novos, 16 relatórios ajustados (um critério cada), 1 permission set ajustado, 1 grupo novo, 1 compartilhamento de pasta. Zero objeto, zero campo, zero automação.

---

## 4. Decisão de nível: configuração, não Flow nem Apex

### 4.1 Decisão

Tudo é **configuração** (relatório, permission set, grupo, compartilhamento), o primeiro nível da ordem de preferência da skill `salesforce-doutrina`. Não se desce para Flow nem Apex.

### 4.2 Por que não os níveis abaixo

- **Flow:** um público é critério de leitura, não reação a evento. Um Flow que marcasse "apto a e-mail" ou "apto a celular" num campo repetiria o que o filtro de relatório já faz. Também criaria automação em Lead e Contact (hoje só há o Flow de atribuição no insert de Lead) e, se tocasse Account, entraria na ordem de execução com o CPQ (achado 1).
- **Apex:** nada pede lógica que relatório não expresse. Também esbarraria na cobertura de 10% da org (achado 2).
- **Campo novo (fórmula "apto a canal"):** avaliado e descartado. Seria um campo a mais em Lead e Contact sem ganho: o Marketing Cloud lê os dois campos de opt-out diretamente, e o relatório já filtra. O achado 4 (campos sem descrição) recomenda não multiplicar campos.

### 4.3 Alternativas discutidas que a análise deixou abertas

| Ponto | Alternativas | Escolha e porquê |
|---|---|---|
| Opt-out de celular nos públicos | (a) Acrescentar `HasOptedOutOfMobile = 0` aos 58 relatórios existentes; (b) duplicar cada segmento numa versão de celular; (c) **um público-base de celular por objeto, com as colunas de segmento para o recorte** | **(c).** (a) tiraria do público de e-mail quem só recusou SMS (erro de negócio). (b) dobraria a pasta para 116 relatórios sem pedido. (c) entrega a base apta ao canal; o recorte por setor, UF, categoria ou recência é feito pelas colunas, e um segmento de celular específico vira um clone com um filtro a mais (PA-10) |
| "Origem agrupada" no público de prospecção | (a) Coluna `MKT_Origem_Agrupada__c`; (b) bucket sobre `LeadSource`; (c) **agrupar direto por `LEAD_SOURCE`** | **(c).** A fórmula devolve o próprio valor de `LeadSource` para os 13 valores, então o agrupamento é o mesmo (D5). (a) falha no deploy: o usuário da esteira, administrador, não enxerga a coluna (D6), e o mesmo vale para a implantação na QA. (b) tem armadilhas já registradas na doutrina (bucket sobre picklist). Única diferença: o lead sem origem aparece como `-` em vez de "Sem origem"; renomear o grupo é ajuste manual na tela, se a Eplast pedir |
| Lead convertido nos públicos de Lead | (a) Filtro `STATUS`; (b) **filtro `CONVERTED = 0`** | **(b).** É o critério que a plataforma usa (`IsConverted`) e não depende do rótulo do status. Nos públicos de Lead por setor e UF, o lead `Fechado - Não convertido` **continua** (é reativação, já coberta por "LEADS - NÃO CONVERTIDOS"); no de prospecção sai (PA-09) |
| Acesso dos usuários de marketing à pasta | (a) Reaproveitar `Marketing_Origem_Retorno`; (b) compartilhar com papel; (c) **grupo próprio** | **(c).** (a) mistura análise de campanha com lista de contatos (D9, item 11). (b) não há papel de marketing levantado. Grupo vazio é o padrão já usado na conta (EPLAST-39) |
| Composição de conteúdo e envio | CRM ou Marketing Cloud | Marketing Cloud (PA-01, regra 2). Nada de e-mail alert, `Messaging`, template ou agente |

---

## 5. Ordem de execução e impacto nas automações existentes

- **Nenhum componente novo é executado em transação de registro.** Relatório, permission set, grupo e compartilhamento não entram na ordem de execução (validação, before-save Flow, triggers, after-save Flow, etc.). Não há conflito de automação a sinalizar nesta demanda.
- **Account, Opportunity, Order:** sem trigger, Flow ou classe nova (CA-07). Os relatórios só leem `Account` (colunas e filtros). Os 7 triggers e os Flows desses objetos não são tocados.
- **Lead e Contact:** 0 triggers; único Flow em Lead é `Lead_AfterInsert_AplicaRegraAtribuicao` (ativo). Não é alterado. Ele **roda** quando o dado de teste é inserido e pode trocar o proprietário do lead de teste. Isso não afeta os relatórios (escopo `org`), mas o verificador não deve tratar a troca de dono como defeito.
- **Conector `et4ae5`:** Flows `MCC_*` e 17 workflow rules do pacote ficam como estão. Os relatórios novos não disparam nada do conector.
- **Dado de teste que cria Account** (necessário para os públicos de contato, seção 9) dispara a automação de Account (triggers custom e do CPQ, Flows). É inserção simples de conta fictícia na dev, sem pedido e sem oportunidade. Se alguma validação recusar a conta, o fixture registra o erro e usa os campos mínimos que passarem; isso não muda o design.

---

## 6. Preparação do Sales Cloud para o Marketing Cloud

A demanda é de marketing (personalização, segmentação, público, comunicação, reativação): seção obrigatória pela regra 2. **Nada é feito no Marketing Cloud. Nada é enviado pelo CRM.**

### a) Dados que o Marketing Cloud lê e onde ficam no CRM

| Dado | Objeto e campo | Uso | Estado (via `sf`) | Leitura em `PS_Marketing_Publicos` |
|---|---|---|---|---|
| Identificador do destinatário | `Contact.Id`, `Lead.Id` | Chave do assinante | padrão | — |
| E-mail | `Contact.Email`, `Lead.Email` | Destinatário de e-mail | padrão, aceita FLS | perfil (padrão) |
| Celular | `Contact.MobilePhone`, `Lead.MobilePhone` | Destinatário de mensagem | padrão | **acrescenta** |
| Código do país do celular | `et4ae5__Mobile_Country_Code__c` (Lead, Contact) | Formatação de envio | pacote | **acrescenta** |
| Nome, cargo, empresa, conta | `FirstName`, `LastName`, `Title`, `Lead.Company`, `Account.Name` | Personalização (saudação) | padrão | perfil |
| UF | `Contact.MailingState`, `Account.BillingState`, `Lead.State` | Região | padrão | perfil |
| Setor e subsetor | `Account.Sector__c`, `Account.Subsector__c`, `Lead.Sector__c`, `Lead.Subsector__c` | Conteúdo por segmento | custom | já tinha |
| Categoria do cliente | `Account.Type` (Recorrente, Sazonal, Prospect, Reativo, Inativo, Novo…) | Conteúdo por relacionamento | padrão | **acrescenta** |
| Recência de compra | `Account.LastPurchase__c`, `Account.Inactive__c`, `Account.RelationshipClass__c` | Reativação e recência | custom | já tinha |
| Produto comprado | `OrderItem` (família do produto) via relatório `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO` | Conteúdo por produto | existente | leitura de Order já existe |
| Origem do lead | `Lead.LeadSource`, `Lead.MKT_Origem_Agrupada__c`, `Contact.LeadSource` | Prospecção e nutrição | padrão / custom | **acrescenta** |
| Prioridade do lead | `Lead.PriorityBand__c` | Recorte de prospecção | custom | **acrescenta** |
| Status do lead | `Lead.Status`, `Lead.IsConverted` | Exclusão de convertido | padrão, sem FLS (D13) | leitura do objeto |

Nenhum valor de compra (faturamento, ticket) entra na lista: a regra de "sem valores de compra" do `PS_Marketing_Publicos` (description da EPLAST-36) é mantida.

### b) Como o público fica identificável no CRM

Por relatório na pasta `MARKETING CLOUD`, com nome, filtro documentado e contagem executável:

| Canal | Públicos | Exclusão |
|---|---|---|
| E-mail, cliente e contato | 42 relatórios `ContactList` existentes (setor, recência, categoria × UF, prospects, potenciais) | `EMAIL_OPT_OUT = 0` (já existe) |
| E-mail, lead | 16 relatórios `LeadList` existentes + `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` (novo) | `EMAIL_OPT_OUT = 0` (já existe) + `CONVERTED = 0` (**novo**) |
| Mensagem (celular) | `MSG_CONTATOS_CELULAR_APTOS` e `MSG_LEADS_CELULAR_APTOS` (novos), com as colunas de segmento para recorte | `et4ae5__HasOptedOutOfMobile__c = 0` + celular preenchido (+ `CONVERTED = 0` em Lead) |
| WhatsApp | nenhum | fora (PA-04) |

A lista de nomes de todos os relatórios (60 + 3) vai no `04-plano-build.md` (CA-03).

### c) O que o Marketing Cloud devolve e onde é gravado

Sem campo de retorno novo. O conector grava em `et4ae5__IndividualEmailResult__c`, `et4ae5__IndividualLink__c`, `et4ae5__SMSDefinition__c`/`et4ae5__SMSJunction__c` e `CampaignMember.et4ae5__Activity__c` (todos confirmados). Opt-out feito pelo destinatário (descadastro) volta pelo conector para `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c`. **Não verificado** se essa sincronização está ligada na Eplast; é configuração do conector, de quem opera o Marketing Cloud.

### d) Consentimento e opt-out

- E-mail: `HasOptedOutOfEmail` (Lead, Contact). Todos os públicos de e-mail filtram.
- Celular e mensagem: `et4ae5__HasOptedOutOfMobile__c` (Lead, Contact). Os públicos de mensagem filtram.
- WhatsApp: sem campo de opt-out; nenhum público (PA-04, EPLAST-34).
- Nenhum registro ou objeto de consentimento novo (PA-03). Regra de consentimento própria do Marketing Cloud, se houver, é aplicada por quem o opera.

### e) O que fica para quem opera o Marketing Cloud (fora da esteira)

1. Confirmar que o Marketing Cloud Connect está ativo e qual Business Unit usa (não verificado; a esteira não toca).
2. Confirmar que o usuário de integração do conector **enxerga a pasta `MARKETING CLOUD` e os campos da tabela (a)**. Se não enxergar, pedir ao administrador da Eplast para atribuir `PS_Marketing_Publicos` e incluí-lo no grupo `Marketing_Publicos` (ação no Salesforce, feita pela Eplast; a esteira não identifica nem altera o usuário de integração).
3. Importar os relatórios como público ou entrada de jornada; para mensagem, usar só os relatórios `MSG_`.
4. Montar a personalização (setor, categoria, UF, recência, origem, prioridade) com os campos da tabela (a), por sincronização de objeto ou pelas colunas do relatório.
5. Aplicar o opt-out do CRM e o do próprio Marketing Cloud; confirmar que o descadastro volta ao CRM (item c).
6. Compor conteúdo e fazer o envio.
7. **Ser avisado da mudança de contagem** nos 16 relatórios de Lead (CA-08) antes de reusar uma importação já configurada.

---

## 7. Impacto em permissões

### 7.1 Perfis

**Nenhum perfil é alterado.** Observação: o perfil Administrador do sistema não tem FLS em `Lead.MKT_Origem_Agrupada__c` (D5). Não é corrigido aqui (seria alteração de perfil). Quem precisar lê-lo recebe `PS_Marketing_Publicos` ou `PS_Marketing_AnaliseCampanhas`.

### 7.2 Permission set

`PS_Marketing_Publicos`: inclusão de 11 FLS de leitura (item 8). Permission set não tem versão nem ativação (a regra "nova versão primeiro" vale para Flow, agente e classe). A mudança só **acrescenta** leitura, e não há ninguém atribuído hoje (D7), então não muda o acesso de ninguém na hora do deploy. O build parte do XML retirado da org, nunca reescrito do zero, para não perder as 9 FLS e as permissões atuais.

### 7.3 Grupo e compartilhamento da pasta

- O grupo `Marketing_Publicos` vai por metadata (`Group`, sem membros).
- **O compartilhamento da pasta não vai por metadata `ReportFolder`.** Dois motivos: (1) o `ReportFolder` traz o compartilhamento nominal atual com o identificador do usuário, que não pode entrar no repositório (guardrail 2); (2) implantar `folderShares` define o compartilhamento da pasta e pode tirar o acesso do usuário que já a administra.
- **Como fazer:** pela API REST de compartilhamento de pasta do Analytics (`POST /services/data/vNN.0/folders/<folderId>/shares`, que **acrescenta** um compartilhamento sem mexer nos existentes), com `shareType` de grupo, `accessType` de leitura e o Id do grupo. Na dev, o builder executa depois de implantar o grupo e registra o comando no plano. Na QA, como a esteira só implanta metadata, isso é **passo pós-deploy declarado em `06-entrega.md`**, feito por quem libera a QA (agente de release, se a esteira permitir chamada REST lá, ou administrador da Eplast pela tela: Compartilhar pasta → grupo "Públicos de Marketing" → Visualizar).
- Se o `POST` for recusado na dev, o builder não tenta `ReportFolder`. Registra o erro e deixa o compartilhamento como passo manual na tela, com o caso de QA marcado como dependente dele.

---

## 8. Premissas assumidas (validar na homologação)

Herdadas da análise (sem mudança): **PA-01** (conteúdo nasce no Marketing Cloud), **PA-03** (opt-out por `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c`), **PA-04** (WhatsApp fora, EPLAST-34), **PA-05** (retorno onde o conector grava), **PA-06** (sem Campaign na v1), **PA-07** (`SFAgent2` fora), **PA-08** (reuso antes de criação: cumprido, nenhum campo novo). Ajustada e novas:

- [x] **PA-02 (ajustada) — Quais segmentos entram**
  - Pergunta: quais segmentos o Marketing Cloud vai usar?
  - Decisão: os 60 relatórios já existentes na pasta são os segmentos de e-mail. Somam-se 2 públicos-base de celular e 1 de prospecção por origem e prioridade. Nenhum segmento é removido.
  - Evidência: D1 a D4. A pasta tem setor, recência, categoria × UF, prospects e potenciais, mais do que a análise supunha (25).
  - Como mudar: segmento novo é clone de relatório com um filtro. Retirar um segmento é apagá-lo da pasta, decisão da Eplast.

- [x] **PA-09 — O que é "lead apto" em cada público**
  - Pergunta: lead `Fechado - Não convertido` recebe comunicação?
  - Decisão: nos 16 públicos de Lead existentes, só sai o lead **convertido** (`CONVERTED = 0`); o fechado não convertido continua, porque a própria Eplast mantém um público para ele ("LEADS - NÃO CONVERTIDOS"). No público novo de prospecção, só entram `Aberto - Não contatado` e `Contatado`.
  - Evidência: `LeadStatus` (D12) e o relatório `Cpia_de_LEADS_GERAL_D2D` (D4); padrão da plataforma: lead convertido vira contato e passa a ser comunicado como contato.
  - Como mudar: um critério no relatório, sem dado e sem código.

- [x] **PA-10 — Público de mensagem é base única por objeto**
  - Pergunta: cada segmento precisa da sua versão para celular?
  - Decisão: não na v1. Um público de celular para Contact e um para Lead, com as colunas de segmento; o recorte é feito pelas colunas.
  - Evidência: nenhum público de celular existe hoje (D3); padrão: a opção mais simples e fácil de mudar.
  - Como mudar: clonar o relatório `MSG_` e acrescentar o filtro do segmento.

- [x] **PA-11 — "Origem agrupada" no relatório é `LeadSource`**
  - Pergunta: o público de prospecção agrupa pelo campo `MKT_Origem_Agrupada__c` ou por `LeadSource`?
  - Decisão: por `LeadSource`. O campo continua existindo e ganha leitura no permission set para o Marketing Cloud.
  - Evidência: a fórmula devolve o mesmo valor para os 13 valores (D5); a coluna não aparece para o usuário de implantação (D6).
  - Como mudar: dar FLS do campo ao perfil de quem implanta (decisão de perfil, fora desta demanda) e trocar a coluna de agrupamento.

- [x] **PA-12 — Quem vê os públicos no CRM**
  - Pergunta: quais usuários da Eplast precisam enxergar os públicos?
  - Decisão: quem a Eplast incluir no grupo `Marketing_Publicos` e atribuir a `PS_Marketing_Publicos`. A esteira não atribui a ninguém da Eplast.
  - Evidência: pasta compartilhada com um único usuário (D8); permission set sem atribuição (D7); não há perfil de marketing entre os usuários ativos (D16).
  - Como mudar: incluir ou retirar membros do grupo, sem metadata.

- [x] **PA-13 — Relatórios com nome técnico divergente e duplicado não são mexidos**
  - Pergunta: corrigir `Cpia_de_…` e o duplicado `SAZONAIS_MG_X7D`?
  - Decisão: não nesta demanda. Recebem o critério de convertido só os de Lead; os de contato ficam intactos.
  - Evidência: a Eplast já marcou o duplicado para revisão; renomear pode quebrar importação no Marketing Cloud.
  - Como mudar: a Eplast decide na homologação; apagar o duplicado é um clique.

---

## 9. Riscos e tratamento

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Mudança de contagem nos 16 relatórios de Lead** pode surpreender uma importação já configurada no Marketing Cloud | Média | CA-08: o QA mede na QA (Partial Copy) a contagem agregada antes e depois pela Analytics API; `06-entrega.md` lista cada relatório e a variação. Passo 7 da seção 6 e. Na dev o efeito não é mensurável (0 leads) |
| R2 | Deploy de `ReportFolder` sobrescreveria o compartilhamento atual e poria identificador de usuário no repositório | **Alta** se feito; evitada | `ReportFolder` fica **fora** do pacote. Compartilhamento por API REST que acrescenta (7.3). O verificador confere que não há `reportFolder-meta.xml` em `force-app` |
| R3 | `PS_Marketing_Publicos` reescrito do zero perderia FLS e permissões atuais | Média | Build parte do retrieve da org; o verificador compara as 9 FLS e 6 permissões de objeto originais |
| R4 | Filtro "celular não vazio" sem exemplo na org; sintaxe do XML pode ser recusada | Baixa | Seguir a doutrina: copiar a sintaxe de um filtro da org; duas recusas no mesmo item → tirar o filtro de "não vazio" e manter só o de opt-out (o Marketing Cloud ignora destinatário sem número), registrando no plano |
| R5 | Coluna `MKT_Origem_Agrupada__c` invisível para quem implanta | Média | Evitada por PA-11 (agrupa por `LEAD_SOURCE`) |
| R6 | Usuário de teste é administrador: não prova FLS nem acesso à pasta | Média | Ver seção 11, caso Q6: prova por describe de campo e pelo compartilhamento da pasta, não por "acesso negado" com usuário real |
| R7 | Dado de teste recusado pelas validation rules de telefone | Baixa | Formatos de D15 nos fixtures: Lead `MobilePhone` como `(DD)` + 9 dígitos sem espaço nem hífen; Contact `MobilePhone` como `(DD) NNNNN-NNNN`. Números fictícios |
| R8 | Inserir Account de teste dispara triggers custom e do CPQ e Flows de Account (achado 1) | Baixa | Só inserção de conta fictícia, sem Order ou Opportunity. Converter lead de teste com `setDoNotCreateOpportunity(true)` para não acionar a automação de Opportunity |
| R9 | Sincronização de descadastro do Marketing Cloud para o CRM não verificada | Média (negócio) | Fora da esteira; passo 5 da seção 6 e |
| R10 | Usuário de integração do conector sem acesso à pasta ou aos campos | Média | Passo 2 da seção 6 e |

### Riscos do assessment que tocam o pedido

- **Achado 1 (ordem de execução entre trigger custom, trigger SBQQ e Flows em Account, Opportunity e Order):** não se aplica à solução, que não cria automação nem grava nesses objetos (CA-07). Toca só o dado de teste (R8).
- **Achado 2 (cobertura Apex de 10%):** não se aplica; não há Apex. O script de fixture roda como anonymous Apex na dev e não é implantado.
- **Achado 3 (23 validation rules de Order):** não se aplica; nada grava em Order, nem o fixture.
- **`OrderTrigger` com nome igual ao do CPQ:** não se aplica; nenhum trigger é tocado nem citado em log do build.
- **Achado 4 (campos sem descrição):** nenhum campo é criado. `Account.Sector__c`, `Account.LastPurchase__c` e `Lead.Sector__c` continuam sem description; a seção 6 a serve de dicionário para quem opera o Marketing Cloud. Preencher a description é recomendação (seção 12), porque mexer em metadata de picklist pode sobrescrever valores.
- **Achado 6 (alias de dev com "qa"):** resolvido pela regra 5 da conta.
- **Conector `et4ae5` (519 classes, 17 workflow rules):** não é tocado.

---

## 10. Plano de build (ordem)

Branch `feature/EPLAST-43`. Org `sbx-eplast-dev`. Nenhum Flow, agente ou classe existente é alterado, portanto não há versão nova nem passo de ativação. Relatórios e permission set são ajustes declarados (CA-08), não versionáveis.

| Passo | O quê | Componente | Observação |
|---|---|---|---|
| B1 | Retrieve do que será ajustado | `PermissionSet:PS_Marketing_Publicos` e os 16 `Report:MARKETINGCLOUD/<nome>` de Lead (item 3) | Base do diff; **não** retirar `ReportFolder` para o `force-app` |
| B2 | Permission set | `PS_Marketing_Publicos`: +11 FLS de leitura, description com "EPLAST-43" | Deploy; conferir que as 9 FLS anteriores continuam |
| B3 | Grupo | `Group:Marketing_Publicos` (rótulo "Públicos de Marketing", description com a finalidade, sem membros) | Deploy |
| B4 | Compartilhamento da pasta | `POST /folders/<Id da pasta>/shares` com o grupo, leitura | Fora de `force-app`; registrar o comando (sem identificador de usuário) no plano e em `06-entrega.md` como passo da QA |
| B5 | 16 relatórios de Lead | Acrescentar `CONVERTED equals 0` em cada um | Diff de uma linha de critério por arquivo; nada mais muda |
| B6 | 3 relatórios novos | `MSG_CONTATOS_CELULAR_APTOS`, `MSG_LEADS_CELULAR_APTOS`, `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` | Copiar `scope`, formato e sintaxe de filtro de um relatório da pasta do mesmo tipo |
| B7 | Fixtures | Criar `clients/eplast/fixtures/` com `README.md` e o script `eplast43_publicos.apex` | Ver lista abaixo |
| B8 | Verificação | Analytics API `/analytics/reports/<id>` lendo só contagens | Ver seção 11 |
| B9 | Limpeza | Apagar os registros de teste criados (prefixo `EPLAST43-TESTE`), registrando contagem antes e depois | Quem criou apaga |

**Dados de teste (fictícios, prefixo `EPLAST43-TESTE` no nome ou empresa, domínio de e-mail reservado `example.com`):**
- 2 Accounts: `Sector__c = Alimentos`, `Type = Recorrente`, `BillingState = SP`.
- 4 Contacts nessas contas, os 3 primeiros com celular: (1) sem opt-out; (2) `HasOptedOutOfEmail = true`; (3) `et4ae5__HasOptedOutOfMobile__c = true`; (4) sem opt-out e sem celular.
- 6 Leads, os 5 primeiros com celular, `Sector__c = Alimentos`, `State = SP` e `LeadSource` preenchido: (1) aberto, sem opt-out; (2) aberto, `HasOptedOutOfEmail = true`; (3) aberto, `et4ae5__HasOptedOutOfMobile__c = true`; (4) `Fechado - Não convertido`; (5) convertido (`Database.convertLead` com `setDoNotCreateOpportunity(true)`, para uma das contas de teste); (6) aberto, sem celular, sem `Sector__c` e sem `LeadSource` (faixa "Sem dados suficientes").
- Proprietário: o usuário de teste da regra 6, Id `005bJ00000piKAaQAM` (ativo, Administrador do sistema). O Flow de atribuição pode trocar o dono do lead; não é defeito.
- Na QA (Partial Copy) vale a mesma massa, criada pelo QA; só os registros que o agente criou são lidos ou apagados.

**Estimativa de esforço:** 10–18 h

O que mudou em relação à análise (8–16 h): (1) a pasta tem 60 relatórios, não 25, e os 16 de Lead precisam do critério de convertido (+2 h, trabalho repetitivo de baixo risco); (2) surgiram o grupo e o compartilhamento da pasta, que a análise não previa, com passo fora de metadata na dev e na QA (+1–2 h); (3) por outro lado, nenhum campo novo é criado (−2 h da folga prevista na análise). A faixa alta cobre o histórico de relatório por metadata da EPLAST-39 (formato descoberto no deploy) e a medição de contagem antes e depois na QA para o CA-08.

---

## 11. Pontos que o QA deve testar

Todos pela Analytics API, lendo só rótulos e contagens agregadas, sobre a massa `EPLAST43-TESTE` (guardrail 2).

| # | Caso | Esperado | Critério |
|---|---|---|---|
| Q1 | `LEADS_SEGMENTO_ALIMENTOS` com a massa | Inclui leads 1, 3 e 4; exclui 2 (opt-out de e-mail) e 5 (convertido) | CA-01, CA-04 |
| Q2 | `SEGMENTO_ALIMENTOS` (contato) | Inclui contatos 1, 3 e 4; exclui 2 | CA-01 |
| Q3 | `MSG_CONTATOS_CELULAR_APTOS` | Inclui 1 e 2; exclui 3 (opt-out de celular) e 4 (sem celular) | CA-02 |
| Q4 | `MSG_LEADS_CELULAR_APTOS` | Inclui 1, 2 e 4; exclui 3 (opt-out de celular), 5 (convertido) e 6 (sem celular) | CA-02, CA-04 |
| Q5 | `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` | Inclui 1 e 3; exclui 2 (opt-out), 4 (fechado), 5 (convertido), 6 ("Sem dados suficientes") | CA-04, PA-09 |
| Q6 | FLS e acesso | Com `PS_Marketing_Publicos` atribuído ao próprio usuário de execução na dev (autorizado), o describe de Lead passa a mostrar `MKT_Origem_Agrupada__c` (prova de que o PS dá FLS, já que o perfil não dá, D5). Conferir que a pasta tem o compartilhamento de leitura para `Marketing_Publicos` e que o compartilhamento nominal anterior continua (contar `folderShares` antes e depois, sem registrar identificador) | CA-05 |
| Q7 | Busca por envio | Zero `EmailAlert`, `sendEmail`, `Messaging.`, `SingleEmailMessage`, Flow com ação de e-mail nos arquivos novos ou alterados da branch | CA-06 |
| Q8 | Objetos sensíveis | Zero trigger, Flow ou classe em Account, Opportunity, Order no diff | CA-07 |
| Q9 | Contagem antes e depois (só na QA) | Para cada um dos 16 relatórios de Lead, contagem agregada antes e depois do deploy, gravada em `05-testes.md` e repassada a `06-entrega.md` | CA-08 |
| Q10 | Lista de públicos | 63 relatórios na pasta, nome e filtro de cada um no plano de build | CA-03 |
| Q11 | Roteiro do cliente | Seção de passos fora da esteira (seção 6 e) e "O que assumimos e você precisa confirmar" com PA-01 a PA-13 | CA-10 |

**Caso de acesso negado:** o usuário de teste da regra 6 é administrador (vê toda pasta, View All Data) e não serve para provar negação. Há usuários ativos com perfil "Comercial - Analista" (D16), mas a regra 6 não autoriza usá-los, e mudar permissão de terceiro está fora. Por isso, a negação é provada pela metadata: (a) o perfil admin não tem FLS em `MKT_Origem_Agrupada__c` antes do PS (Q6); (b) a pasta continua `Hidden`, compartilhada só com o usuário nominal e o grupo. Se a Eplast quiser prova com usuário real, ela indica na homologação um usuário não administrador para entrar no grupo. Isso fica no roteiro do cliente.

**Fragilidades do assessment onde o QA deve olhar:** inserção da Account de teste (achado 1: se algum trigger ou Flow de Account recusar a conta fictícia, registrar o erro, que é achado da org e não defeito desta demanda); nenhuma escrita em Order (achado 3).

---

## 12. O que NÃO será feito nesta demanda

- Nada no Marketing Cloud: conexão, Business Unit, público, jornada, conteúdo, envio, sincronização de opt-out.
- Nenhum envio pelo CRM: e-mail alert, template, `Messaging`, agente.
- Nenhum campo, objeto, Flow, trigger ou classe. Nenhum perfil alterado.
- `SFAgent2` não é estendido (PA-07).
- WhatsApp: sem opt-out e sem público (PA-04, EPLAST-34).
- `Campaign` e `CampaignMember` não são usados (PA-06).
- Renomear ou apagar relatórios `Cpia_de_…` e o duplicado `SAZONAIS_MG_X7D` (PA-13): **recomendação** à Eplast.
- Preencher a description de `Account.Sector__c`, `Account.LastPurchase__c` e `Lead.Sector__c` (achado 4): **recomendação**, em demanda de saneamento.
- Dar FLS de `MKT_Origem_Agrupada__c` ao perfil Administrador do sistema: **recomendação**.
- Atribuir permission set ou incluir no grupo usuários da Eplast: é da Eplast (PA-12).

---

## 13. Pendências abertas que bloqueiam

Nenhuma.

Não há mudança de modelo de dados a escalar: nenhum objeto ou campo é criado ou alterado.

---

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o build.
