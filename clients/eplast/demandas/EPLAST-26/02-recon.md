# EPLAST-26 — Recon da org (score e faixa de prioridade, Lead e Opportunity)

**Org:** `sbx-eplast-dev`, Sandbox, Connected (`sf org list`, nesta sessão, 2026-11-15). Só leitura. Só metadata e contagens agregadas; nenhum registro lido.
**Insumos:** `01-analise.md` (rodada 2), `comentarios-do-card.md`, regras 1 a 4 do `CLAUDE.md` da Eplast. Os artefatos de `rodada-anterior/` não foram usados como fato.
**Observação de ambiente:** o `instanceUrl` do alias dev tem host com "qa" (já apontado no assessment, achado 6). Não consegui provar daqui que dev e QA são sandboxes distintas (ver "O que não consegui confirmar").

---

## 1. O que já cobre o pedido

Resultado: **nada na org calcula score ou faixa de prioridade de Lead ou Opportunity.** Há peças vizinhas para reaproveitar.

| Elemento | O que existe | Cobre o pedido? | Prova |
|---|---|---|---|
| Campo de score/faixa em Lead | Nenhum. Os 12 custom de Lead são: `CNAE`, `CompanyDocument`, `CompanyName`, `Facebook`, `Instagram`, `LinkedIn`, `Subsector`, `WhatsApp`, `Sector`, mais `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c` e `maps__AssignmentRule__c` | Não | `sf data query --use-tooling-api` em `CustomField` (Lead) |
| Campo de score/faixa em Opportunity | Nenhum campo de score. O mais próximo é `Previs_o_Eintein__c` (rótulo "Previsão Einstein", double, sem descrição) | Parcial, não comprovado | `CustomField` (Opportunity) e `sf sobject describe` |
| Quem escreve `Previs_o_Eintein__c` | Nenhum Apex nem Flow do repositório o referencia; só aparece no field-meta e na list view `AllOpportunities`. Não consegui consultar dependência na org | Indeterminado | `grep -rl` em `force-app`; `MetadataComponentDependency` recusou o filtro |
| Agente `SFAgent2` | Existe. Bot `SFAgent2` e 4 planner bundles (`SFAgent2_v1` a `v4`). Na v4 retrieve: **4 tópicos** (`agent_router`, `ambiguous_question`, `off_topic`, `insights_comerciais`) e **3 ações**, todas no tópico `insights_comerciais`: `ConsultarPedidos` (`queryRecords`), `AgregacaoPedidos` (`queryRecordsWithAggregate`) e `IdentificarConta` (`identifyRecordByName`) | Não para score (nenhuma ação lê Lead ou score). Ponto de extensão se vier pedido de assistente | `sf org list metadata -m Bot` e `-m GenAiPlannerBundle`; `sf project retrieve start -m GenAiPlannerBundle:SFAgent2_v4` em diretório temporário, já removido |
| Relatórios | 380 relatórios na org. Úteis à medição pós-go-live: "Taxa de Conversão de Leads", "Leads Convertidos e Ganhos", "Oportunidades Abertas no Pipeline", "Oportunidades ganhas AF/T", "Oportunidades Perdidas", "Pipeline de Produtos de Oportunidades", "Marketing Exec Leads by Campaigns" (pasta "Sales and Marketing Reports") | Não calculam faixa; servem de base | `sf data query` em `Report` (COUNT e `Name LIKE`, LIMIT 30) |
| Painéis | 20 painéis. Eplast: "Leads & Oportunidades" e "Pedidos". Marketing: "Marketing - Origem e Retorno de Campanhas" | Não calculam faixa; "Leads & Oportunidades" é o candidato a receber a faixa | `sf data query` em `Dashboard` |
| List views Lead | `AllOpenLeads`, `My_Leads`, `TodaysLeads`, `RecentlyViewedLeads`, `C_pia_de_Todos_os_leads_Abertos`, `C_pia_de_Todos_os_leads_Abertos2` | Servem de base para coluna e ordenação | `ListView` (SobjectType Lead) |
| List views Opportunity | `AllOpportunities`, `MyOpportunities`, `ClosingThisMonth`, `ClosingNextMonth`, `NewThisWeek`, `Won`, `Default_Opportunity_Pipeline`, mais 6 cópias pessoais (nomes de usuário) | Idem | `ListView` (SobjectType Opportunity) |
| Prompt Flows de Opportunity | `Opportunity_PromptFlow_DadosOportunidade` (PromptFlow, Capability) | Não é score | `FlowDefinitionView` com `ApiName LIKE '%portunidade%'` |

### Campos de entrada propostos pela análise (confirmados por describe)

| Objeto.campo | Tipo | Observação |
|---|---|---|
| `Lead.Sector__c` | picklist, rótulo "Setor" | 8 valores. Sem descrição. A análise cita `Sector`; o API name real é `Sector__c` |
| `Lead.Subsector__c` | multipicklist, "Subsetor" | Sem descrição |
| `Lead.LeadSource` | picklist, "Origem do lead" | Inclui "Campanha", "E-mail MKT", "WhatsApp", "Google Ads" etc. |
| `Lead.Status` | picklist | Valores: "Aberto - Não contatado", "Contatado", "Fechado - Convertido", "Fechado - Não convertido". "Contatado" existe com esse texto |
| `Lead.IsConverted` | boolean | Existe |
| `Opportunity.Probability` | percent | Existe |
| `Opportunity.Amount` | currency | Existe |
| `Opportunity.CloseDate` | date | Existe |
| `Opportunity.LeadSource` | picklist | Existe |
| `Opportunity.StageName`, `IsClosed`, `IsWon` | picklist, boolean, boolean | Existem |
| `Opportunity.CampaignId` | reference | Existe |

Prova: `sf sobject describe -s Lead` e `-s Opportunity`, filtrando por nome de campo.
Opportunity tem 28 custom segundo a análise; nesta sessão a consulta de `CustomField` listou 41 linhas entre Opportunity (inclusive 9 do namespace `SBQQ`); não reconciliei a contagem da análise.

## 2. O que será tocado

| Objeto | Campo/Componente | Tipo | Descrição? | Prova |
|---|---|---|---|---|
| Lead | campos novos de score e faixa | a criar (ausentes hoje) | n/a | Tooling `CustomField` |
| Opportunity | campos novos de score e faixa | a criar (ausentes hoje) | n/a | Tooling `CustomField` |
| Lead | `Sector__c`, `LeadSource`, `Status` (leitura) | picklist | `Sector__c` sem descrição; `LeadSource` e `Status` são padrão | describe e `CustomField` |
| Opportunity | `Probability`, `Amount`, `CloseDate`, `LeadSource` (leitura) | padrão | n/a | describe |
| Opportunity | `Previs_o_Eintein__c` | double | sem descrição | `CustomField` |
| Lead e Opportunity | layouts de página | não inspecionados | n/a | Ver incertezas |

### Preparação do Sales Cloud para o Marketing Cloud (o que já existe no CRM)

O score é de Sales, mas toca origem e status de lead, então registro o que há para o Marketing Cloud.

| Fato | Resultado | Prova |
|---|---|---|
| Pacote Marketing Cloud (namespace `et4ae5`) | Instalado, versão 264.1.0.1. Também `MarketingCloudConnectedApp` (namespace `MCCA5PROD`) | `sf package installed list` |
| Objetos `et4ae5` | `et4ae5__Email_Linkage__c`, `et4ae5__IndividualEmailResult__c`, `et4ae5__IndividualLink__c`, `et4ae5__MC_CDC_Journey__c`, `et4ae5__ET4AE_User_Information__c` e as variantes Share, OwnerSharingRule e ChangeEvent. A lista foi cortada em 50 linhas, então pode haver mais objetos | `EntityDefinition WHERE NamespacePrefix='et4ae5'` LIMIT 50 |
| Campos `et4ae5` em objetos de CRM | `Lead.et4ae5__HasOptedOutOfMobile__c`, `Lead.et4ae5__Mobile_Country_Code__c`, `Contact` (os mesmos 2), `CampaignMember.et4ae5__Activity__c`. Nenhum em Campaign | `CustomField WHERE NamespacePrefix='et4ae5'` em Campaign, CampaignMember, Contact e Lead |
| Opt-out de e-mail no Lead | `Lead.HasOptedOutOfEmail` (padrão) existe | describe |
| Campanha e membro no CRM | `Opportunity.CampaignId` existe; `LeadSource` tem "Campanha" e "E-mail MKT". Campaign e CampaignMember têm 0 registros | describe; `COUNT()` |
| Flows do conector | Dezenas de Flows `MCC_*` ativos (RecordBeforeSave e RecordAfterSave) em objetos de envio e rastreio do pacote (`Envio de email`, `Envio acionado`, `Resultado de email individual`, `Solicitação de suporte`). Nenhum visto em Lead ou Opportunity | `FlowDefinitionView` (IsActive) LIMIT 100; corte de 100 linhas |
| Flows em Lead | 0 | `FlowDefinitionView WHERE TriggerObjectOrEventLabel='Lead'` |

Nada foi feito no Marketing Cloud.

## 3. Automação concorrente

### Opportunity (objeto com concorrência; Lead quase não tem)

| Componente | Tipo | Evento | Prova |
|---|---|---|---|
| `OpportunityBefore` (SBQQ) | ApexTrigger do pacote, Active | Eventos não verificados | Tooling `ApexTrigger` (Lead, Opportunity) |
| `OpportunityTrigger` (custom) | ApexTrigger, Active | `after insert, after update` (cabeçalho do arquivo no repositório; o código da org não foi baixado) | Tooling `ApexTrigger`; `head` de `force-app/main/default/triggers/OpportunityTrigger.trigger` |
| `OpportunityAfter` (SBQQ) | ApexTrigger do pacote, Active | Eventos não verificados | Tooling `ApexTrigger` |
| `Oportunidade_Industria` | Flow, RecordAfterSave | after save | `FlowDefinitionView WHERE TriggerObjectOrEventLabel='Oportunidade'` |
| `OpportunityFlow` | Flow, RecordAfterSave | after save | idem |
| `ScheduledFlowOpportunity` | Flow, Scheduled | agendado | idem |
| Classes | `OpportunityTriggerHandler` e `OpportunityTriggerHelper` (API 59); `FlowOpportunityController` e `FlowOpportunityControllerTest` (API 64) | n/a | Tooling `ApexClass` |
| Validation rules | 16 ativas, de 16 totais (inclui `CheckHasAccount`, `CheckOppHasBranch`, `CheckOppHasPaymentMethods`, `CheckOppHasPaymentTermId`, `FinancialAnalysis`, `TaxAnalysis`, `LossReason`, `PriceBook`, `Industria_Fase_Cotacao_Sem_Catalogo`, `CheckAccountOwnerHasProtheusSellerId`; as 6 restantes não foram listadas) | before save | Tooling `ValidationRule` (COUNT total e com `Active=true`) |

Nenhum Flow before-save foi encontrado em Opportunity. Os nomes de Flow vêm de `ApiName` (a análise cita os rótulos "Oportunidade Indústria" e "Fluxo Oportunidade"; o vínculo rótulo para API name não foi conferido).

**Ordem de execução esperada em Opportunity** (ordem padrão da plataforma aplicada ao que foi listado; não executei nada): validation rules do sistema, triggers before (`OpportunityBefore`), regras de validação, `OpportunityTrigger` e `OpportunityAfter` (after), Flows after-save (`Oportunidade_Industria`, `OpportunityFlow`). O Salesforce não garante ordem entre triggers do mesmo evento, nem entre Flows do mesmo tipo (ver incertezas).

**Para campo de fórmula (proposta da análise):** fórmula não entra na ordem de execução porque não grava nem dispara automação. Isso é fato de plataforma, não verificado na org.

### Lead

| Componente | Resultado | Prova |
|---|---|---|
| ApexTrigger | 0 | Tooling `ApexTrigger WHERE TableEnumOrId IN ('Lead','Opportunity')` retornou só os 3 de Opportunity |
| Flows | 0 | `FlowDefinitionView` |
| Validation rules | `Celular` e `Telefone`, ativas | Tooling `ValidationRule` (Lead) |
| Regra de atribuição | Campo `maps__AssignmentRule__c` (pacote com namespace `maps`) existe. Regras de atribuição de Lead não foram consultadas | `CustomField` |

## 4. Volume e dados de teste

| Objeto | Contagem | Comando |
|---|---|---|
| Lead | 0 | `sf data query -q "SELECT COUNT() FROM Lead"` |
| Lead convertido | 0 | `... WHERE IsConverted=true` |
| Opportunity | 0 | `SELECT COUNT() FROM Opportunity` |
| Account | 0 | `SELECT COUNT() FROM Account` |
| Campaign | 0 | `SELECT COUNT() FROM Campaign` |
| CampaignMember | 0 | `SELECT COUNT() FROM CampaignMember` |

A dev não tem dado nenhum nesses objetos: todo teste precisa de registro sintético, sem dado pessoal. Não há como ver o que `Previs_o_Eintein__c` guarda nem calibrar pesos com histórico.

## 5. Permissões

| Fato | Resultado | Prova |
|---|---|---|
| OWD Lead | Externo `Private`, interno `ReadWriteTransfer` | Tooling `EntityDefinition` |
| OWD Opportunity | Externo `Private`, interno `Read` | idem |
| Perfis na org | 33 | `COUNT()` em `Profile` |
| Permission sets (não de perfil) | 180 | `COUNT()` em `PermissionSet WHERE IsOwnedByProfile=false` |
| Perfis com leitura em Lead e Opportunity (consulta com LIMIT 60 retornou 41 linhas, completa) | Administrador do sistema, Gerente de soluções, Gerente do contrato, Usuário do Marketing, Usuário Padrão, Read Only (só leitura), Executive Sponsor, End User, Comercial, Engenharia de Produtos, Financeiro, Marketing, Pricing, Comercial - Analista, SalesforceIQ Integration User, Sales Insights Integration User, Analytics Cloud Integration User e Security User (só leitura). Em Lead, `Comercial Padrão` e `Comercial - Analistas` editam; em Opportunity, só leem | `ObjectPermissions` por perfil (`IsOwnedByProfile=true`) |
| Perfis só com Opportunity | `CPQ Integration User` (edita) | idem |

O assessment cita perfil custom `Financeiro` e perfis comerciais duplicados; ambos aparecem na lista acima (`Comercial`, `Comercial Padrão`, `Comercial - Analista`, `Comercial - Analistas`, `Financeiro`). Field-level security dos campos novos não existe ainda; permission sets de campo não foram inspecionados.

## 6. Riscos do assessment que tocam a demanda

| Risco | Confirmado na org? |
|---|---|
| Automação concorrente em Opportunity (trigger custom, triggers CPQ, Flows) | Sim: 3 triggers e 3 Flows em Opportunity (seção 3). Ordem real entre eles não foi medida |
| Cobertura Apex de 10% | Não medida nesta sessão. Existem `FlowOpportunityControllerTest` e classes de handler/helper de Opportunity; cobertura por classe não consultada |
| `OpportunityTrigger` com nome colidindo com o pacote CPQ | Parcial: os triggers do CPQ têm nomes diferentes (`OpportunityBefore`, `OpportunityAfter`) e namespace `SBQQ`; `OpportunityTrigger` não tem namespace |
| API version antiga em classes | Sim: `OpportunityTriggerHandler` e `OpportunityTriggerHelper` em API 59 (as de Flow em 64) |
| Campos custom sem descrição | Sim para os campos de Lead e Opportunity listados: sem descrição, exceto os de `SBQQ` (com descrição). Sem descrição inclui `Lead.Sector__c` e `Opportunity.Previs_o_Eintein__c` |
| Perfil `Financeiro` e perfis comerciais duplicados | Sim, existem (seção 5) |
| Dev apontando para QA | Indício: host com "qa" no `instanceUrl`; username do alias também termina em `.qa` (não transcrito aqui). Não provado |
| Validation rules (assessment cita 23 em Order) | Order não é tocado. Em Opportunity, 16 ativas |
| Classes de teste fora do padrão `<Classe>Test`, Account e Order | Fora do escopo desta demanda; não verificado |

## 7. O que está ausente (candidato a criação)

- Campos de score e de faixa em Lead e em Opportunity.
- List view de Lead ordenada por score, e list view de Opportunity filtrada por faixa (as existentes podem receber a coluna, mas as 6 cópias pessoais de Opportunity são de usuários e não devem ser alteradas por padrão).
- Estágio de "encerrada" tratado por `IsClosed`: o campo existe, então não é preciso criar nada.
- Nenhuma ação de agente para ler score (ver SFAgent2 na seção 1).

---

## O que não consegui confirmar

1. **Quem alimenta `Previs_o_Eintein__c`.** O repositório não o referencia em Apex ou Flow e a consulta de dependência foi recusada. Pode ser populado por pacote, integração ou carga manual. Com 0 Opportunity, o conteúdo não é observável.
2. **Eventos dos triggers `OpportunityBefore` e `OpportunityAfter` (SBQQ)** e o corpo atual de `OpportunityTrigger` na org. Só vi o cabeçalho do arquivo do repositório, que pode diferir da org.
3. **Ordem real de execução** entre os triggers e os 2 Flows after-save de Opportunity: não executei nada; a ordem acima é a padrão da plataforma, e a ordem entre triggers e entre Flows do mesmo tipo é indefinida.
4. **Rótulos dos Flows citados na análise** ("Oportunidade Indústria", "Fluxo Oportunidade") versus os API names encontrados (`Oportunidade_Industria`, `OpportunityFlow`). Não conferi o rótulo.
5. **6 das 16 validation rules de Opportunity** não foram listadas por nome.
6. **Layouts de página, FLS e permission sets** de Lead e Opportunity não foram inspecionados; também não sei qual perfil os usuários-alvo (vendedor e gestor) usam.
7. **Lista completa de objetos `et4ae5`** (corte em 50 linhas) e se o conector usa algum campo de Lead além dos 2 de celular listados.
8. **Dev distinta de QA.** O host e o username do alias sugerem "qa". Não tenho como provar a separação pela CLI; fica como checagem de pré-build.
9. **Cobertura Apex real por classe** de Opportunity: não medida.
10. **Tópicos e ações do SFAgent2 na QA.** Confirmei só na dev (v4). A comparação com a QA é do briefing; não a repeti.
11. **Contagem de campos custom de Opportunity.** A análise diz 28; esta consulta trouxe 41 linhas (com os 9 do `SBQQ`). Não reconciliei a diferença; a lista de nomes acima vale.
12. **Regras de atribuição de Lead** (`maps__AssignmentRule__c` existe, mas as regras não foram lidas); relevante para a EPLAST-35, não para esta demanda.
