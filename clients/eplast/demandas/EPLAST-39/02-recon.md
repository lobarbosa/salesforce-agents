# EPLAST-39 — Recon da org (refeito em 2026-11-17, após as respostas do cliente)

**Org:** alias `sbx-eplast-dev` (`sf org list`: Sandbox, Connected, único alias conectado). Na esteira é a dev; a Eplast a chama de "QA" (regra 5 da conta, não é bloqueio). Só leitura, só metadata e `COUNT()`.
**Pré-checagem da esteira:** sem bloqueios; nenhuma outra demanda nos mesmos componentes. Observação do recon: a org já tem campos da EPLAST-45 em Lead (ver seção 3), então o objeto Lead não é exclusivo desta demanda.
**Mudança em relação ao recon de 15/11:** o build da rodada anterior já está na org e no repositório (`force-app/`). Este recon descreve o estado atual, para o design partir dele.

Pedido a cobrir (respostas do cliente de 17/11, fim do `03-design.md`): "Sem origem" no lugar de "-"; origens padronizadas em 10 valores com sinônimos consolidados e `LeadSource` original preservado; oportunidades por origem com o mesmo agrupamento; período padrão mês atual com filtros mensal, trimestral e anual; retorno de campanha com investimento, leads, convertidos, oportunidades ganhas e receita atribuída, e "não calculável" sem custo.

## 1. O que já cobre o pedido

| Item | Estado atual na org | Distância do pedido | Prova |
|---|---|---|---|
| `Lead.MKT_Origem_Agrupada__c` | Fórmula (Texto). Vazio vira "Sem origem"; só os 13 valores da picklist passam como estão; o resto vira "Fora da lista". Sem consolidação de sinônimos e sem a lista de 10 | Cobre "Sem origem". Não cobre a lista de 10 nem o de-para. Hoje o "Fora da lista" esconde o valor original no relatório | FieldDefinition (descrição e tipo); fórmula lida em `force-app/.../Lead/fields/MKT_Origem_Agrupada__c.field-meta.xml` |
| `MKT_Leads_por_Origem` | Summary, grupos `MKT_Origem_Agrupada__c` × mês de criação. Filtro de data fixo 2000-01-01 a 2099-12-31 (INTERVAL_CUSTOM) | Falta período padrão "mês atual" | Query em `Report` (formato); filtro lido no XML do repo |
| `MKT_Conversao_Leads_por_Origem` | Summary, grupo `MKT_Origem_Agrupada__c`, fórmula `CONVERTED:SUM / RowCount`, mesmo filtro 2000–2099 | Falta período padrão | idem |
| `MKT_Oportunidades_por_Origem` | Summary, tipo `Opportunity`, agrupa por `LEAD_SOURCE` (campo padrão da oportunidade, sem agrupamento nem "Sem origem") × `WON`; filtro 2000–2099 | **Diverge do pedido (item 2)**: usa a picklist crua, não o agrupamento | idem |
| `MKT_Desempenho_Campanhas` | Summary (na rodada 1 era Tabular), tipo `CampaignList`, grupo `CAMPAIGN_NAME`. Colunas: `ACTUAL_COST`, `BUDGETED_COST`, `NUM_LEADS`, `NUM_CONVERTED_LEADS`, `NUM_RESPONSES`, `NUM_OPPORTUNITIES`, `NUM_WON_OPPORTUNITIES`, `AMOUNT_WON`, `ROI`. Fórmula `IF(ACTUAL_COST:SUM > 0, AMOUNT_WON:SUM / ACTUAL_COST:SUM, null)`. Sem filtro de data | Já traz as colunas pedidas. O vazio da fórmula não mostra o texto "não calculável"; a coluna padrão `ROI` convive com a fórmula | Query em `Report` (formato); colunas e fórmula no XML do repo |
| `MKT_Resposta_Membros_Campanha` | Summary, tipo `CampaignLead`, grupos `CAMPAIGN_NAME` × `MEMBER_STATUS` | Complementar, sem divergência | idem |
| Dashboard `MKT_Origem_e_Retorno_Campanhas` | 1 na pasta; 5 componentes, um por relatório acima (Barra empilhada, Donut, Barra empilhada, Donut, Barra empilhada); `dashboardType` LoggedInUser. Sem filtro de painel declarado no XML | O componente de oportunidades agrupa por `LEAD_SOURCE`; o painel não tem filtro de período | Query em `Dashboard`; componentes no XML do repo |
| Pastas `Marketing_Origem_Retorno` (relatório) e `Marketing_Origem_Retorno_Dash` (painel) | Existem; no repo compartilhadas com o grupo `Marketing_Origem_Retorno`. Na org `Folder.AccessType` = Hidden (não confirmei o compartilhamento efetivo) | Reaproveitar | `SELECT Name, Type, AccessType FROM Folder WHERE DeveloperName IN (...)` |
| Agente `SFAgent2` | Existe (1 `BotDefinition`). Tópicos e ações não reexaminados; a demanda não tem assistente nem resumo | Não se aplica | `SELECT DeveloperName FROM BotDefinition` |
| Valor "Fora da lista" com visibilidade do valor original | Não existe campo nem relatório que mostre o valor cru do que caiu em "Fora da lista"; só o próprio `LeadSource` (que a Eplast quer preservar) | Lacuna para "manter a visibilidade" | Ausência em FieldDefinition e nos relatórios |

Totais da org: 419 relatórios e 21 dashboards (`SELECT COUNT() FROM Report` / `Dashboard`), contra 380 e 20 no recon de 15/11. O aumento não é explicado aqui (pode vir de outra demanda ou de amostras); o critério "nada existente alterado" precisa de uma linha de base nova.

## 2. O que será tocado

| Objeto.Campo | Tipo e estado | Prova |
|---|---|---|
| `Lead.LeadSource` | Picklist, não restrita (`restrictedPicklist=false`), anulável, 13 valores ativos: Campanha, WhatsApp, Indicação, Evento, Google Ads, Google Orgânico, Instagram, Facebook, Prospecção ativa, Prospecção passiva, Econodata, E-mail MKT, SDR. Nenhum dos 10 valores novos do cliente existe como valor (por exemplo Meta Ads, Parceiros, Site/formulário, Busca orgânica, Outros) | `sf sobject describe -s Lead` (campo `LeadSource`) |
| `Opportunity.LeadSource` | Picklist, não restrita, mesmos 13 valores ativos | `sf sobject describe -s Opportunity` |
| `Lead.MKT_Origem_Agrupada__c` | Fórmula (Texto), com Descrição preenchida (cita EPLAST-39). Será revista para a lista de 10 | `FieldDefinition` |
| `Opportunity` custom | **Nenhum campo custom** em Opportunity. Não existe campo de origem agrupada na oportunidade | `FieldDefinition WHERE EntityDefinition.QualifiedApiName='Opportunity' AND QualifiedApiName LIKE '%__c'` (0 linhas) |
| `Campaign` custom | **Nenhum campo custom** em Campaign. Se o design pedir campo fórmula em Campaign (autorizado pelo cliente), ele não existe hoje | idem para `Campaign` (0 linhas) |
| `Campaign.ActualCost`, `BudgetedCost`, `NumberOfConvertedLeads`, `NumberOfWonOpportunities`, `AmountWonOpportunities`, `ExpectedRevenue` | Campos padrão, confirmados no recon de 15/11 (não repeti o describe hoje) | describe Campaign em 15/11 |
| Relacionamento Lead → Oportunidade para herdar a origem agrupada | Não confirmado. Não verifiquei se o relatório de oportunidades pode alcançar `MKT_Origem_Agrupada__c` por tipo de relatório (por exemplo oportunidade com lead convertido) | Fora do que levantei |
| Opt-out | `Lead.HasOptedOutOfEmail` (checkbox, padrão) e `Lead.et4ae5__HasOptedOutOfMobile__c` (checkbox, conector) existem | `FieldDefinition WHERE EntityDefinition.QualifiedApiName='Lead'` (filtro por nome) |
| Campo UTM/canal/origem custom em Lead | Nenhum encontrado pelos filtros `%rigem%`, `%UTM%`, `%Source%`, `%Canal%`, `%Campanha%` (só `LeadSource`, `MKT_Origem_Agrupada__c`) | `FieldDefinition` (filtros por nome) |
| `CampaignInfluence` | Não suportado nesta org (recon de 15/11) | `SELECT COUNT() FROM CampaignInfluence` |

Campos de outra demanda em Lead (existem na org, não são desta demanda): `MKT_MC_Engajamento__c`, `MKT_MC_EngajamentoData__c`, `MKT_Nutricao_Elegivel__c`, `MKT_Nutricao_ProntoAbordagem__c` (todos citam EPLAST-45 na descrição). Atenção ao prefixo `MKT_` compartilhado.

## 3. Automação concorrente

| Objeto | Achado | Prova |
|---|---|---|
| Lead, Campaign, CampaignMember | 0 triggers Apex | `SELECT Name, TableEnumOrId FROM ApexTrigger WHERE TableEnumOrId IN ('Lead','Campaign','CampaignMember')` (Tooling, 0 linhas) |
| Lead | 2 validation rules ativas: `Celular` e `Telefone`. Campaign e CampaignMember: nenhuma ativa | `SELECT ... FROM ValidationRule WHERE EntityDefinition.QualifiedApiName IN (...) AND Active=true` (Tooling) |
| Flows em Lead, Campaign, CampaignMember | **Não confirmei.** Tooling `Flow` não expõe objeto nem tipo de gatilho nesta org e `FlowDefinitionView` não é suportado. No repo, nenhum dos 25 flows tem `<object>` Lead, Campaign ou CampaignMember, mas o repo tem menos flows que a org (42 ativos em 15/11) | grep em `force-app/main/default/flows` |
| Account, Opportunity, Order | Triggers custom existem (recon de 15/11: `AccountBefore`, `AccountTrigger`, `OpportunityBefore`, `OpportunityAfter`, `OpportunityTrigger`, `OrderTrigger`) e 8 validation rules ativas em Opportunity. Ordem de execução com SBQQ e Flows **não analisada** | recon de 15/11 |

Leitura para o design: a solução só lê Opportunity e só cria campo fórmula/relatório/painel; não grava em Lead (decisão 5 do cliente: não regravar lead existente). Fórmula não dispara automação nem validation rule. Se o design incluir qualquer escrita em Opportunity, Account ou Order, a ordem de execução precisa ser levantada antes (não está feita). Defeito conhecido de `UpdateAccountCompanyInfo`: irrelevante, não há escrita em Account.

## 4. Marketing Cloud Connect (`et4ae5`)

| Item | Estado | Prova |
|---|---|---|
| Objetos custom do conector (28) | Entre eles `Campaign_Member_Configuration`, `SendDefinition`, `SendJunction`, `IndividualEmailResult`, `IndividualLink`, `Automated_Send`, `Business_Unit`, `Triggered_Send_Execution`, `SMSDefinition`, `SMSJunction`, `JB_Event` | `SELECT DeveloperName FROM CustomObject WHERE NamespacePrefix='et4ae5'` (Tooling) |
| Classes Apex `et4ae5` | 523 (recon de 15/11) | `SELECT COUNT() FROM ApexClass WHERE NamespacePrefix='et4ae5'` |
| Campos `et4ae5__` em Lead | `et4ae5__HasOptedOutOfMobile__c` (checkbox) e `et4ae5__Mobile_Country_Code__c` (picklist, recon de 15/11) | describe Lead |
| Campos `et4ae5__` em Campaign e CampaignMember | **Não levantei** | n/a |
| Flows `MCC_*` ativos | Existem (recon de 15/11); objeto de cada um não confirmado | query de Flow em 15/11 |

Para a seção "Preparação do Sales Cloud para o Marketing Cloud": o conector não usa `LeadSource` nem `MKT_Origem_Agrupada__c` que eu tenha confirmado. O campo agrupado já fica legível no CRM para segmentação. Opt-out de e-mail (`HasOptedOutOfEmail`) e de celular (`et4ae5__HasOptedOutOfMobile__c`) existem em Lead. Onde o Marketing Cloud devolve engajamento: campos da EPLAST-45 (`MKT_MC_Engajamento__c`, `MKT_MC_EngajamentoData__c`). Nada foi feito no Marketing Cloud.

## 5. Volume e dados de teste

| Objeto | Contagem na dev | Prova |
|---|---|---|
| Lead | 0 | `SELECT COUNT() FROM Lead` |
| Campaign | 0 | `SELECT COUNT() FROM Campaign` |
| CampaignMember | 0 | `SELECT COUNT() FROM CampaignMember` |
| Opportunity | 0 | `SELECT COUNT() FROM Opportunity` |

A dev não tem dado: relatório e painel só se exercitam com massa sintética (autorizada, via `fixtures/` do cliente; Conta de teste exige o desvio `TriggerUtility.bypassTrigger`). Distribuição real de `LeadSource` (valores soltos, vazios) não é medível na dev. Na QAS (Partial Copy) pode haver valores soltos que a fórmula atual esconde em "Fora da lista"; contagem agregada por `LeadSource` lá é o único caminho para montar o de-para sem ler dado pessoal (não consultei a QAS; esta sessão só tem o alias de dev).

Usuário de teste da regra 6: a consulta por username da conta de serviço da Konecta (filtro por prefixo, sem citar o username no artefato) retornou 2 usuários, ambos Administrador do sistema: `005bJ00000hBJmYQAW` (inativo) e `005bJ00000piKAaQAM` (ativo). Para o caso de acesso negado, atenção: perfil Administrador do sistema tende a enxergar tudo, então não serve sozinho como prova de acesso negado (não confirmei as permissões efetivas dele).

## 6. Permissões

| Item | Estado | Prova |
|---|---|---|
| `PS_Marketing_AnaliseCampanhas` | Existe. Objetos: Campaign, Lead, Opportunity com Read=true e Create/Edit/Delete=false | `SELECT SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete FROM ObjectPermissions WHERE Parent.Name='PS_Marketing_AnaliseCampanhas'` |
| FLS no PS | `Lead.MKT_Origem_Agrupada__c` e `Lead.LeadSource`: leitura sim, edição não | `SELECT Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE Parent.Name='PS_Marketing_AnaliseCampanhas' AND SobjectType='Lead'` |
| Atribuições do PS | 0 na dev (a atribuição a usuários de Marketing é passo pós-deploy manual PA-07, decisão do card de 16/11) | `SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSet.Name='PS_Marketing_AnaliseCampanhas'` |
| Campos novos | Qualquer campo novo (por exemplo fórmula em Campaign ou em Opportunity) precisa entrar no FLS do PS; hoje o PS não tem FLS de Campaign nem Opportunity (só Lead aparece) | mesma query de FieldPermissions (2 linhas, ambas Lead) |
| Grupo `Marketing_Origem_Retorno` | Existe no repo (`groups/`), usado no compartilhamento das pastas; membros não verificados | arquivo do repo |
| OWD de Lead, Campaign, Opportunity e perfis que alcançam os objetos | Não verificado | n/a |

## O que não consegui confirmar

1. **Flows em Lead, Campaign e CampaignMember** na org: sem consulta que exponha objeto e gatilho; no repo não há, mas o repo é parcial.
2. **Ordem de execução** em Account, Opportunity e Order (trigger custom, SBQQ, Flows): não analisada; só importa se o design escrever nesses objetos.
3. **Distribuição real de `LeadSource`** (valores soltos, sinônimos, vazios) na QAS: só alias dev nesta sessão, e a dev tem 0 leads. O de-para de sinônimos não tem evidência de dados.
4. **Se o relatório de oportunidades consegue agrupar pelo campo agrupado do Lead** (tipo de relatório com lead convertido) ou se exige campo novo em Opportunity: não testei tipos de relatório.
5. **Campos `et4ae5__` em Campaign e CampaignMember**, e o objeto de cada Flow `MCC_*`.
6. **Fórmula efetivamente implantada na org**: li a fórmula e os XMLs de relatório e painel no repositório, não por retrieve; presumo que a org espelha o repo (tipos de relatório e formatos conferidos por query na org).
7. **Compartilhamento efetivo das pastas e membros do grupo** `Marketing_Origem_Retorno` (na org `AccessType` aparece Hidden).
8. **Causa do aumento de relatórios e painéis** (380 e 20 em 15/11; 419 e 21 hoje).
9. **Capacidade de a fórmula `ROI` padrão e a fórmula customizada de `MKT_Desempenho_Campanhas` exibirem texto "não calculável"**: relatório de resumo devolve número ou vazio; não testei rótulo de texto (campo fórmula de texto em Campaign é a alternativa, ainda inexistente).
10. **Perfis e OWD** que alcançam Lead, Campaign e Opportunity; permissões efetivas do usuário de teste ativo.
11. **Tópicos e ações do `SFAgent2`**: só confirmei que o bot existe.
