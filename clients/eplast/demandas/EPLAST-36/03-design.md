# EPLAST-36 — Design: segmentação da base e criação de públicos

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** 3 (design) · **Data:** 2026-11-15
**Org consultada:** alias `sbx-eplast-dev` (Sandbox, Connected). Só leitura, só metadata e contagens agregadas. **Ver condição C1:** a instância deste alias se identifica como `qa`.
**Base:** `01-analise.md` (gate aprovado em 2026-11-15, em lote: as premissas da análise são revistas aqui), `02-recon.md`, `comentarios-do-card.md`, `assessment.md`. Linhas novas de evidência levantadas nesta etapa estão marcadas com **[design]**.

---

## 0. Correções sobre a análise

1. **Escopo contratual não bloqueia.** A seção 0 e a Q6 da análise tratam a Onda 4 como bloqueio. Pela regra 1 do `CLAUDE.md` da conta e pela orientação do responsável no card (2026-11-13), a demanda está autorizada. Q6 e a premissa P7 saem da lista de pendências e não serão devolvidas ao cliente.
2. **Plataforma de marketing está definida.** A análise dizia não saber qual plataforma `eplast-ent-05` decidiu. A regra 2 da conta responde: o disparo é pelo Marketing Cloud, e o CRM entrega dado, segmento, público e status. Isso resolve Q2 (destino) e afasta a opção (d) de Q1 (segmentar dentro do Marketing Cloud ou do Data Cloud pela esteira).
3. **As perguntas Q1 a Q5 viram premissas assumidas** (seção 8), resolvidas com o que a org mostra. Nenhuma fica bloqueante.

---

## 1. O que a org já mostra (e muda o desenho)

A Eplast **já segmenta a base para o Marketing Cloud por relatório**. A pasta de relatórios `MARKETING CLOUD` **[design]** tem 35 relatórios que funcionam como públicos:

| Família | Relatórios | Tipo de relatório | Filtro (lido via describe do relatório) |
|---|---|---|---|
| Comportamento × região (Contatos) | `RECORRENTES (ATIVOS) - <região>`, `SAZONAIS - <região>`, `PROSPECTS - <região>` para CO, ES, MG, NO/NE, RJ, SP, SUL e GERAL | `ContactList` (Contatos e Contas) | `TYPE` (Categoria da Conta: Recorrente, Sazonal, Prospect) + `ACCOUNT.ADDRESS1_STATE` (UF de cobrança da Conta) |
| Comportamento (Contatos) | `NOVOS`, `REATIVOS - GERAL` | `ContactList` | `TYPE = Novo` / `Reativo` |
| Leads × região | `LEADS - <região>`, `LEADS - GERAL`, `LEADS - NÃO CONVERTIDOS` | `LeadList` | `STATE` / `STATUS = Fechado - Não convertido` |

O mapeamento UF → região que a Eplast usa está nos filtros desses relatórios **[design]**:

| Região | UFs |
|---|---|
| NO/NE | AC, AP, AM, PA, RO, RR, AL, BA, CE, MA, PB, PE, PI, RN, SE |
| CO | GO, DF, MT, MS, TO |
| SUL | PR, SC, RS |
| SP, RJ, MG, ES | uma UF cada |

Problemas encontrados nesses relatórios **[design]**:
- `RECORRENTES (ATIVOS) - SP` e `RECORRENTES (ATIVOS) - NO/NE` filtram **só a UF, sem `TYPE = Recorrente`**. Devolvem todos os contatos da região, não os recorrentes. O `- GERAL` está correto. Os de CO, ES, MG, RJ e SUL não foram lidos um a um; o build confere cada um.
- Há **dois relatórios chamados `SAZONAIS - MG`** na mesma pasta.
- Nenhum dos relatórios lidos filtra opt-out (`HasOptedOutOfEmail`).
- Não existem públicos por **segmento** (`Sector__c`), por **histórico de compra** (`LastPurchase__c`) nem a categoria `Inativo`.

Ou seja: a demanda não parte do zero. Ela completa a matriz de públicos que já existe, corrige o que está errado e organiza o resto.

---

## 2. Solução proposta

Completar e corrigir os **públicos por relatório** na pasta `MARKETING CLOUD`, no mesmo padrão que a Eplast já usa, e padronizar a **campanha como público congelado** para quando o Marketing precisar de uma lista fixa ou combinar critérios. Tudo por configuração: sem Flow, sem Apex, sem campo novo e sem gravar nada em Account, Opportunity ou Order.

| Critério do pedido | Onde fica no CRM | Como vira público |
|---|---|---|
| Região | `Account.BillingState` (Contato) e `Lead.State` | Filtro de UF agrupado pela tabela da seção 1 (relatórios existentes) |
| Segmento | `Account.Sector__c` (9 valores) e `Lead.Sector__c` | Relatórios novos `SEGMENTO - <setor>` (Contatos) e `LEADS - SEGMENTO - <setor>` |
| Comportamento | `Account.Type` (Categoria: Novo, Recorrente, Reativo, Sazonal, Prospect, Inativo...) | Relatórios existentes corrigidos + `INATIVOS - GERAL` novo |
| Histórico de compra | `Account.LastPurchase__c` (data) | Relatórios novos por faixa de tempo desde a última compra (seção 3) |
| Produto | Pedido → itens do pedido → produto (`Order`, `OrderItem`, `Product2`) | No CRM: relatório de Contas por produto comprado. O público de contatos por produto é montado no Marketing Cloud, com os dados sincronizados (seção 7). Motivo na seção 4 |
| Combinação de critérios | Campanha + membro de campanha | O usuário filtra num relatório de Contatos ou Leads e usa "Adicionar à campanha" (recurso padrão). A campanha `PUB - <descrição>` fica como público congelado |

**Dinâmico ou congelado (Q3):** os dois, cada um no seu lugar. Relatório é público dinâmico: o Marketing Cloud lê o que estiver valendo na hora. Campanha é público congelado: guarda quem estava no recorte no dia em que foi montada.

---

## 3. Componentes: reaproveita / ajusta / cria

| # | Item | Ação | Detalhe |
|---|---|---|---|
| 1 | Pasta de relatórios `MARKETING CLOUD` | **Reaproveita** | Todos os públicos novos entram nela. Nenhuma pasta nova |
| 2 | `RECORRENTES (ATIVOS) - CO/ES/MG/NO-NE/RJ/SP/SUL` (7) | **Ajusta** | Acrescenta `TYPE = Recorrente` onde faltar (confirmado que falta em SP e NO/NE; o build confere os outros 5) |
| 3 | Relatórios de público `ContactList` e `LeadList` da pasta (os 35, exceto se o build achar algum que não é público) | **Ajusta** | Acrescenta filtro "Não enviar e-mail" (`HasOptedOutOfEmail`) = Falso (premissa PA-07) |
| 4 | `SAZONAIS - MG` duplicado | **Ajusta (não apaga)** | O build compara os dois. Se forem iguais, renomeia o mais novo para `SAZONAIS - MG (DUPLICADO - REVISAR)`; a exclusão fica para o cliente na homologação |
| 5 | `INATIVOS - GERAL` | **Cria** | `ContactList`, `TYPE = Inativo`, mesmas colunas de `NOVOS` |
| 6 | `SEGMENTO - <setor>` (9, um por valor de `Account.Sector__c`) | **Cria** | `ContactList`, filtro no setor da Conta. Ex.: `SEGMENTO - ALIMENTOS` |
| 7 | `LEADS - SEGMENTO - <setor>` (9) | **Cria** | `LeadList`, filtro em `Lead.Sector__c` |
| 8 | Públicos por histórico de compra (4) | **Cria** | `ContactList` com filtro em `LastPurchase__c` da Conta: `COMPRA - ÚLTIMOS 90 DIAS`; `SEM COMPRA - 91 A 180 DIAS`; `SEM COMPRA - 181 A 365 DIAS`; `SEM COMPRA - MAIS DE 365 DIAS` (premissa PA-04) |
| 9 | `PRODUTO - CONTAS POR PRODUTO COMPRADO` | **Cria** | Relatório de Pedidos com itens (tipo padrão de pedido com produtos; o build confirma o nome do tipo de relatório e, se não servir, avalia o custom `Pedidos_customizados`, que existe na org **[design]**), agrupado por produto e por Conta. Fica em `MARKETING CLOUD` |
| 10 | `REGIÃO COM PRODUTOS - CONTAS/PRODUTO` (pasta `ANALISTAS`) | **Não mexe** | São do Comercial e usam Oportunidade com produtos; não são públicos |
| 11 | Relatórios `MKT Desempenho de Campanhas`, `MKT Resposta de Membros de Campanha` e painel `Marketing - Origem e Retorno de Campanhas` (EPLAST-39) | **Reaproveita** | Medem o retorno das campanhas-público sem mudança |
| 12 | Campaign / CampaignMember | **Reaproveita (sem metadata nova)** | Convenção de nome `PUB - <critério> - <AAAA-MM>`, `Type = Other`, tipo de registro `Mestre` (único que existe **[design]**). Status de membro padrão. Nenhum valor de picklist novo (premissa PA-06) |
| 13 | Permission set `PS_Marketing_Publicos` | **Cria** | Ver seção 6 |
| 14 | `PS_Marketing_AnaliseCampanhas` | **Não mexe** | É leitura de Campaign/Lead para análise (EPLAST-39). Juntar daria escrita em campanha a quem só analisa |
| 15 | Agente `SFAgent2`, tópicos e ações | **Não mexe** | Ver seção 9 |
| 16 | Conector `et4ae5`, objetos, workflow rules e permission set `Marketing_Cloud_Connected_App` | **Não mexe** | Regra 2 da conta |
| 17 | Campo `Account.Region__c` (fórmula UF → região) | **Não cria** | Alternativa avaliada e descartada nesta demanda (seção 4) |

Nada é depreciado.

---

## 4. Decisão: configuração (nível 1), sem Flow e sem Apex

Ordem de preferência da skill `salesforce-doutrina`: configuração → Flow → código.

**Por que configuração basta.** Todos os critérios do pedido já têm dado no CRM (`Type`, `Sector__c`, `BillingState`, `LastPurchase__c`, pedidos). Público é leitura e seleção, não cálculo gravado em registro. Relatório, campanha e membro de campanha são os recursos nativos para isso, e o Marketing Cloud Connect lê relatórios e campanhas do Sales Cloud como origem de público. A Eplast já opera assim (seção 1).

**Alternativas descartadas:**

| Alternativa | Por que não |
|---|---|
| Flow ou Apex que classifica a Conta (grava segmento, faixa de compra ou região no registro) | Grava em Account: dispara `AccountTrigger` (valida CNPJ e, no after update, atualiza dados de CNPJ), `AccountBefore` (SBQQ) e o Flow `AccountTriggered` (achado 1, alta). Com a org a 10% de cobertura (achado 2), seria mais um ponto de automação sem rede. E não acrescenta nada que o filtro do relatório não faça |
| Campo fórmula `Account.Region__c` (UF → região) | Seria só de leitura e não dispara automação, mas é campo novo (modelo de dados) e duplica uma regra que hoje vive nos filtros dos relatórios. Fica como **sugestão para o arquiteto humano** decidir depois: ajuda o Marketing Cloud a segmentar por região sem repetir a lista de UFs. Não bloqueia nem entra neste build |
| Público por produto em nível de Contato no CRM | O produto fica dois níveis abaixo da Conta (Conta → Pedido → Item → Produto). Filtro cruzado de relatório só desce um nível, e roll-up não funciona porque Pedido não é mestre-detalhe de Conta. Resolver no CRM exigiria Flow ou Apex gravando na Conta (achado 1). O Marketing Cloud junta esses dados sem tocar no CRM |
| Segmentação por IA (Einstein, Data Cloud) ou estender o `SFAgent2` | Ver seção 9 e premissa PA-01 |

---

## 5. Ordem de execução por objeto

**O build não grava em nenhum registro e não cria nem altera automação.** Ele implanta só relatórios, permission set e documentação. Por isso o risco de ordem de execução **não se aplica ao que é entregue**. Ele se aplica a dois momentos, e o design diz como tratar cada um:

| Objeto | Automação ativa (recon) | Quando dispara nesta demanda | Tratamento |
|---|---|---|---|
| Account | `AccountTrigger` (custom: BI, AI, BU, AU), `AccountBefore` (SBQQ: BI, BU), Flows `AccountTriggered` (after-save) e `UpdateParentAccountUsedLimit` (ativo não reconfirmado) | **Só na massa de teste do QA** (insert de Contas sintéticas) | **Risco de ordem de execução: dois triggers no mesmo evento (BI/BU) e Flow after-save.** O QA cria as Contas uma vez e não as atualiza. O `AccountTrigger` valida CNPJ no insert **[design]**: a massa precisa de CNPJ sintético com dígito verificador válido e a busca de dados de CNPJ do after insert pode falhar sem consequência para o teste. `LastPurchase__c`, `Type` e `Sector__c` são preenchidos já no insert, não por update |
| Order / OrderItem | `OrderTrigger` (SBQQ: todos os eventos), `OrderTrigger` (custom, mesmo nome: BU, AU), Flow before-save de Id externo, Flow after-save `Order`, 23 validation rules; `OrderProductTrigger` (SBQQ) | **Só na massa de teste do QA**, para o relatório de produto | **Risco de ordem de execução e colisão de nome `OrderTrigger`** (achado 10: no log, os dois triggers aparecem com o mesmo nome; o QA identifica pelo namespace). O QA cria Pedido e item em rascunho, sem update depois (o custom só roda em update). Se as validation rules impedirem, o caso de produto vira "inconclusivo" com o motivo, sem contornar regra |
| Opportunity | Triggers SBQQ e custom, 2 Flows after-save | Não dispara | Não se aplica: nada lê nem grava Oportunidade |
| Contact, Lead, Campaign, CampaignMember | Nenhum trigger nem Flow custom (recon) | Massa do QA e "Adicionar à campanha" | Sem concorrência. O conector `et4ae5` tem 17 workflow rules; o build não as altera |

---

## 6. Permissões

- **Cria `PS_Marketing_Publicos`:**
  - leitura em Account, Contact, Lead, Order, OrderItem, Product2;
  - leitura, criação e edição em Campaign; CampaignMember é controlado pela campanha (OWD `ControlledByCampaign`);
  - leitura de campo (FLS) em `Account.Type`, `Sector__c`, `Subsector__c`, `BillingState`, `BillingCity`, `LastPurchase__c`, `Inactive__c`; `Lead.Sector__c`, `Lead.Subsector__c`, `Lead.State`, `Lead.Status`, `Lead.LeadSource`, `HasOptedOutOfEmail` (Lead e Contact) e `et4ae5__HasOptedOutOfMobile__c` (Lead e Contact);
  - "Executar relatórios" e "Criar e personalizar relatórios" (o usuário pode salvar variações na pasta pessoal).
- Valores de compra (`TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c`, `LastMonthPurchaseValue__c`) **não** entram no PS: não são necessários para o público e são valor financeiro do cliente.
- **Nenhum perfil é alterado** (perfis `Marketing` e `Usuário do Marketing` existem; perfis duplicados são achado do assessment).
- Criar campanha exige a caixa "Usuário de marketing" no cadastro do usuário. Isso é configuração de usuário, não metadata: fica para o administrador da Eplast na homologação (seção 11).
- **Compartilhamento da pasta `MARKETING CLOUD`:** não li quem tem acesso. O build confere e, se o Marketing não enxergar a pasta, dá acesso de visualização ao grupo ou papel de Marketing, sem retirar acesso de ninguém. O usuário de integração do Marketing Cloud Connect precisa ler a pasta; o build não altera nada nele, só confere e registra.

---

## 7. Preparação do Sales Cloud para o Marketing Cloud

| Ponto | Onde fica no CRM |
|---|---|
| **Dados que o Marketing Cloud lê** | Contact: `FirstName`, `LastName`, `Title`, `Email`, `AccountId`, `MailingState`, `LeadSource`, `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c`. Account: `Type`, `Sector__c`, `Subsector__c`, `BillingState`, `BillingCity`, `LastPurchase__c`, `Inactive__c`. Lead: `FirstName`, `LastName`, `Company`, `Email`, `State`, `Sector__c`, `Subsector__c`, `Status`, `LeadSource`, `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c`. Para produto: `Order` (`AccountId`, data, status), `OrderItem` (`Product2Id`, quantidade), `Product2` (`Name`, `Family`, `Group__c`). Nenhum campo novo |
| **Como o público fica identificável** | (1) Pelo **relatório** da pasta `MARKETING CLOUD`, com o nome dizendo o critério (`SEGMENTO - ALIMENTOS`, `SAZONAIS - SUL`, `SEM COMPRA - 181 A 365 DIAS`): público dinâmico. (2) Pela **campanha** `PUB - <critério> - <AAAA-MM>` e seus membros: público congelado ou combinado. (3) Produto: relatório `PRODUTO - CONTAS POR PRODUTO COMPRADO` mostra as Contas; o segmento de contatos por produto é montado no Marketing Cloud com os dados de Pedido, Item e Produto sincronizados |
| **O que o Marketing Cloud devolve e onde grava** | Resultado de envio e clique continua onde o conector já grava: `et4ae5__IndividualEmailResult__c`, `et4ae5__IndividualLink__c`, `et4ae5__AggregateLink__c` (existem). Atividade do membro de campanha em `CampaignMember.et4ae5__Activity__c`. Resposta à campanha em `CampaignMember.HasResponded`/`Status`, lida pelos relatórios de EPLAST-39. A demanda não cria campo de retorno |
| **Consentimento e opt-out** | E-mail: `HasOptedOutOfEmail` (Lead e Contact), agora filtrado em todos os públicos da pasta (PA-07). Celular: `et4ae5__HasOptedOutOfMobile__c`. **WhatsApp: não existe campo de opt-out na org** (recon); fica como lacuna para a demanda de LGPD (EPLAST-34), não é criado aqui. A base legal do uso do contato em campanha é tema da EPLAST-34 |
| **O que fica para quem opera o Marketing Cloud** | 1) Confirmar que a conexão do Marketing Cloud Connect está ativa e qual Business Unit usa (não verificado; a esteira não toca). 2) Usar os relatórios da pasta `MARKETING CLOUD` ou as campanhas `PUB -` como público de envio ou de entrada de jornada. 3) Para público por produto, sincronizar `Order`, `OrderItem` e `Product2` (e `Account`, `Contact`) como dados sincronizados e montar o segmento lá. 4) Se quiser região como atributo, aplicar a tabela UF → região da seção 1. 5) Respeitar o opt-out do Marketing Cloud em conjunto com o do CRM |

---

## 8. Premissas assumidas (validar na homologação)

| # | Pergunta | Decisão | Evidência | Como mudar se o cliente discordar |
|---|---|---|---|---|
| PA-01 | Q1 — "Segmentação inteligente" é IA, regra gravada ou filtro? | Filtro por critérios combináveis em relatório e campanha, com os campos de comportamento que a Eplast já mantém (`Type`, `LastPurchase__c`). Sem IA | Org: a Eplast já segmenta assim (35 relatórios na pasta `MARKETING CLOUD`). Padrão: opção mais simples e reversível. Regra 2: segmentação avançada é do Marketing Cloud | Para linguagem natural, demanda nova estendendo o `SFAgent2` (seção 9). Para score, demanda nova com design próprio por causa do achado 1 |
| PA-02 | Q2 — Onde o público vive e para onde vai? | Relatório ou campanha no Sales Cloud, lido pelo Marketing Cloud | Regra 2 da conta; conector `et4ae5` instalado; pasta `MARKETING CLOUD` existente | Exportação por arquivo não é feita; se pedida, avaliar LGPD antes (EPLAST-34) |
| PA-03 | Q3 — Público congelado ou calculado na hora? | Os dois: relatório = dinâmico; campanha = congelado | Comportamento padrão de relatório e de membro de campanha | Nada a reconstruir: o usuário escolhe qual usar |
| PA-04 | Q5 — "Histórico de compra": métrica e janelas? | Data da última compra (`Account.LastPurchase__c`) em quatro faixas: até 90, 91–180, 181–365 e mais de 365 dias | Org: o campo existe e é data. Faixas: prática comum de recência e fáceis de mudar (filtro do relatório). Valor acumulado fica fora (dado financeiro, PA-08) | Editar o filtro de data em cada relatório; criar faixa nova é copiar o relatório |
| PA-05 | Região: qual agrupamento? | As 7 regiões comerciais da Eplast (CO, ES, MG, NO/NE, RJ, SP, SUL), pela UF de cobrança da Conta e pela UF do Lead | Org: filtros dos relatórios da pasta `MARKETING CLOUD` (tabela da seção 1) e relatórios de carteira com os mesmos nomes em `ANALISTAS` | Ajustar a lista de UFs no filtro; se a regra mudar muito, avaliar o campo fórmula `Region__c` (seção 4) |
| PA-06 | Segmento: `Sector__c` ou `Industry`? E como marcar campanha de público? | `Sector__c` (setor). Campanha de público pelo prefixo `PUB -` e `Type = Other`, sem valor novo de picklist | Org: `Sector__c` tem 9 valores próprios do negócio da Eplast e existe também no Lead; `Industry` tem os 32 valores padrão. `Campaign.Type` só tem valores padrão em inglês | Trocar o campo do filtro; se quiserem um tipo "Público", é um valor de picklist acrescentado depois |
| PA-07 | Públicos devem excluir quem pediu para não receber e-mail? | Sim: filtro `HasOptedOutOfEmail = Falso` em todos os públicos da pasta, inclusive os existentes | Padrão de consentimento (LGPD) e campo padrão já na org. O Marketing Cloud também filtra pelo lado dele | Retirar o filtro de um relatório específico (ex.: público para ação comercial, não de e-mail) |
| PA-08 | Valores de compra entram no público? | Não. Público usa categoria, setor, região e data; valores ficam fora do PS e dos relatórios novos | Guardrail #2 e mínimo necessário (LGPD) | Acrescentar o campo de valor e a FLS, depois de validar com a EPLAST-34 |
| PA-09 | Quem usa? (Q4) | Usuários de Marketing, por `PS_Marketing_Publicos` atribuído na homologação | Perfis `Marketing` e `Usuário do Marketing` existem; PS evita mexer em perfil | Atribuir o PS a outros usuários (ex.: Comercial) |
| PA-10 | `LastPurchase__c` é confiável? Quem o calcula? | Usado como está. O QA testa com valores sintéticos gravados no insert | Recon não achou quem calcula (provavelmente a integração com o Protheus, não confirmado). O design não toca a cadeia Protheus | Se o campo não for mantido em produção, trocar o critério por filtro cruzado "Contas com Pedidos" com data de pedido |
| PA-11 | Os `RECORRENTES (ATIVOS) - <região>` sem filtro de categoria estão errados de propósito? | Erro: corrigir com `TYPE = Recorrente` | Nome do relatório, o `- GERAL` que tem o filtro e todos os `SAZONAIS`/`PROSPECTS` regionais que filtram categoria + UF | Remover o filtro de categoria do relatório |

Premissas da análise revistas: P0 vira a condição C1; P1 e P4 confirmadas pelo recon (campos existem, região é UF); P2 vira C4; P3 = PA-03; P5 = PA-04; P6 = PA-10; P7 retirada (seção 0).

---

## 9. O que NÃO será feito nesta demanda

- Nada no Marketing Cloud nem no conector `et4ae5` (conexão, Business Unit, jornada, envio, dados sincronizados).
- Nenhum envio por Flow, e-mail alert, Apex de e-mail ou outra ferramenta do CRM.
- Nenhum campo novo, Flow, Apex ou alteração de trigger. Nenhuma gravação em Account, Opportunity ou Order fora da massa de teste do QA.
- **`SFAgent2` não é estendido.** O pedido é público para disparo, não pergunta em linguagem natural. As ações existentes (`ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta`) são de consulta de Pedido e Conta e não tocam Contact, Lead nem Campaign. Se o cliente quiser perguntar "quantos clientes sazonais do Sul?" ao assistente, o caminho é demanda nova estendendo o tópico `Insights Comerciais sobre Pedidos`, não agente novo (regra 3).
- IA, score, Einstein ou Data Cloud.
- Opt-out de WhatsApp e base legal de uso de contato (EPLAST-34).
- Excluir o `SAZONAIS - MG` duplicado (só sinaliza).
- Renomear o `OrderTrigger` custom (recomendação do assessment, fora desta demanda).
- Mexer nos relatórios da pasta `ANALISTAS` ou nos de EPLAST-39.

---

## 10. Riscos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | Alias `sbx-eplast-dev` aponta para a instância da sandbox de QA (achado 6) | **Alta** | Condição C1. Sem resolver, a separação dev/QA não existe e o build cairia direto na QA |
| R2 | Achado 1 — automação concorrente em Account e Order | Média (só na massa de teste) | Build não grava registro; massa do QA só por insert, sem update (seção 5) |
| R3 | Achado 2 — cobertura Apex 10% | Não se aplica | Sem Apex. A massa do QA não exercita a cadeia Protheus de propósito |
| R4 | Achado 4 — campos sem descrição | Baixa | Usados só campos com valores lidos no recon. Os relatórios novos têm descrição dizendo o critério |
| R5 | Achado 10 — dois `OrderTrigger` | Baixa | Só aparece em log da massa de Pedido; o QA identifica pelo namespace |
| R6 | Assessment (validation rules de Pedido, 23) | Média | Podem impedir a massa de Pedido; caso de produto pode ficar inconclusivo, com o motivo |
| R7 | Sandbox vazia (0 registros) | Média | Massa sintética no QA, sem dado real (guardrail #2) |
| R8 | Mudança nos relatórios existentes muda a contagem de públicos que o Marketing Cloud talvez já use | Média | É correção (PA-07, PA-11). O `06-entrega.md` lista os relatórios alterados para quem opera o Marketing Cloud |
| R9 | `LastPurchase__c` pode não estar sendo mantido | Média | PA-10 |
| R10 | Conexão do Marketing Cloud Connect não verificada | Baixa para o build | Passo de quem opera o Marketing Cloud (seção 7) |
| R11 | Limite de "Adicionar à campanha" a partir de relatório (padrão da plataforma: até 50 mil registros por vez) | Baixa | Base atual não medida (dev vazia). Se passar, montar a campanha em partes ou usar o relatório como público dinâmico |

Governador e escala: nenhuma transação nova de Apex ou Flow. Relatório e "Adicionar à campanha" são recursos padrão; o CPU não se aplica ao que é entregue. Na massa do QA, inserir Contas em lote dispara `AccountTrigger` (callout de CNPJ no after insert): o QA insere em lotes pequenos.

---

## 11. Condições antes do build

| # | Condição | Como verificar |
|---|---|---|
| **C1** | **Confirmar que o alias de dev é a sandbox de dev.** Nesta sessão **[design]**: o alias `sbx-eplast-dev` responde com instância cujo subdomínio contém `--qa`, e o usuário conectado também termina em `.qa`. Não afirmo que a org é dev. | Antes de qualquer deploy: `sf org display -o sbx-eplast-dev` e `sf org display -o sbx-eplast-qa`, comparando só o subdomínio da instância e o Org Id (sem expor usuário). Se forem a mesma org, ou se o alias de dev apontar para a sandbox `qa`, o build **não começa**: a esteira reconecta o alias de dev na sandbox certa. Quem resolve é o humano de delivery |
| C2 | Build em `feature/EPLAST-36`, relatórios e PS em metadata versionada | Padrão do squad |
| C3 | Ler os filtros dos 7 `RECORRENTES (ATIVOS) - <região>` e dos dois `SAZONAIS - MG` antes de ajustar | Describe de relatório (só metadata) |
| C4 | Confirmar o tipo de relatório de Pedidos com produtos e se `Account.Sector__c`/`LastPurchase__c` aparecem como filtro no tipo `ContactList` | Ao montar o relatório; se não aparecerem, usar o tipo custom de Contas com Contatos e registrar no plano de build |
| C5 | Conferir quem tem acesso à pasta `MARKETING CLOUD` | Compartilhamento da pasta |

---

## 12. Critérios para o QA testar

Massa sintética na sandbox de QA, sem dado real: Contas em pelo menos 3 regiões (ex.: SP, uma UF de NO/NE, uma do SUL), 3 setores, categorias Recorrente, Sazonal, Inativo e Prospect, `LastPurchase__c` em cada faixa; 1 Contato por Conta, 1 com "Não enviar e-mail" marcado; Leads em 2 setores e 2 UFs; se as validation rules deixarem, 2 Pedidos com produtos diferentes.

1. **Região × comportamento:** `SAZONAIS - SUL` traz só contatos de Contas sazonais em PR, SC ou RS.
2. **Correção:** `RECORRENTES (ATIVOS) - SP` traz só contatos de Contas recorrentes de SP (antes trazia todas de SP).
3. **Segmento:** `SEGMENTO - <setor>` traz só contatos de Contas daquele setor; `LEADS - SEGMENTO - <setor>` só Leads daquele setor.
4. **Inativos:** `INATIVOS - GERAL` traz só contatos de Contas com categoria Inativo.
5. **Histórico de compra:** cada Conta aparece em exatamente uma das quatro faixas, conforme `LastPurchase__c`; Conta sem data não aparece em nenhuma.
6. **Opt-out:** o contato com "Não enviar e-mail" não aparece em nenhum público da pasta.
7. **Produto:** `PRODUTO - CONTAS POR PRODUTO COMPRADO` agrupa as Contas pelo produto do pedido (ou inconclusivo com o motivo, se a massa de Pedido for barrada).
8. **Campanha congelada:** a partir de um relatório de público, "Adicionar à campanha" numa campanha `PUB -` cria os membros; alterar a categoria de uma Conta depois não muda os membros, mas muda o relatório.
9. **Nada gravado:** contar registros de Account, Opportunity e Order antes e depois de usar os públicos: só a massa do próprio teste.
10. **Permissão:** usuário com `PS_Marketing_Publicos` (e "Usuário de marketing") roda os relatórios e cria a campanha; usuário sem o PS e sem acesso à pasta não vê os públicos. Valores de compra não aparecem para ele.
11. **Sem automação nova:** a contagem de Flows ativos e triggers na QA é igual antes e depois do deploy.

---

## 13. Perguntas abertas

Nenhuma bloqueante. Todas as lacunas viraram premissas (seção 8). Não bloqueantes, para o gate de design:
- O arquiteto humano quer o campo fórmula `Account.Region__c` agora (modelo de dados, seção 4)? O padrão deste design é não criar.
- R1/C1 não é pergunta de negócio: é condição de ambiente e trava o build até ser resolvida.

---

**Estimativa de esforço:** 14–24 h

O que mudou em relação à análise (12–40 h): o topo caiu porque o recon e o design mostraram que (1) a Eplast já tem a matriz de públicos por relatório na pasta `MARKETING CLOUD`, que é só completada e corrigida; (2) todos os critérios já têm campo, então não há classificação gravada, nem Flow, nem Apex; e (3) a plataforma de marketing está definida pela regra 2. O piso subiu um pouco por causa do volume real: ~23 relatórios novos, ~35 ajustados (opt-out e correções), permission set, conferência de pasta e a massa sintética com CNPJ válido e Pedidos sob 23 validation rules. Não inclui a resolução de C1 (ambiente) nem o trabalho de quem opera o Marketing Cloud.

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
