# EPLAST-45 · Recon da org

**Org:** `sbx-eplast-dev` (Sandbox, Org Id `00DHa000006vfMLMAY`), única conectada em `sf org list`. **Data:** 2026-11-15. Só leitura; só metadata e contagens agregadas.

## 1. O que já existe e será tocado (Lead)

| Item | Confirmado | Comando |
|---|---|---|
| `Lead.PriorityScore__c` | Fórmula (Número), com Description. 30 se `Sector__c` preenchido + 30 se `LeadSource` preenchido + 40 se `Status = Contatado` ou `IsConverted` | Tooling `CustomField` Metadata |
| `Lead.PriorityBand__c` | Fórmula (Texto), com Description. Score >= 70 "Alta", >= 40 "Média", senão "Baixa"; "Sem dados suficientes" se setor e origem vazios | idem |
| `Lead.MKT_Origem_Agrupada__c` | Existe (com Description). FLS de leitura só em 3 permission sets: PS Marketing Analise Campanhas, PS Marketing Publicos, Data Cloud Salesforce Connector. Não aparece no describe do usuário conectado | `FieldPermissions`; `sf sobject describe` |
| `Lead.Sector__c`, `Subsector__c` | Picklist / multipicklist, sem Description | `FieldDefinition` |
| `Lead.et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c` | Checkbox / picklist, do pacote `et4ae5` | `FieldDefinition` |
| `Lead.HasOptedOutOfEmail` | Campo padrão (já usado na análise) | confirmado na análise; não repetido |
| `Lead.Status` | 4 valores ativos: `Aberto - Não contatado`, `Contatado`, `Fechado - Convertido`, `Fechado - Não convertido` | `sf sobject describe` |
| Outros custom em Lead | `CNAE__c`, `CompanyDocument__c`, `CompanyName__c`, `Facebook__c`, `Instagram__c`, `LinkedIn__c`, `WhatsApp__c`, `maps__AssignmentRule__c` | `FieldDefinition` |
| Campo de score/engajamento do Marketing Cloud em Lead | **Não existe** (nenhum dos 14 campos `__c` listados é de engajamento) | `FieldDefinition` Lead `LIKE '%__c'` |

Descrições: 3 dos campos custom de Lead têm Description (`PriorityScore`, `PriorityBand`, `MKT_Origem_Agrupada`); os demais, não (consulta Tooling `CustomField`).

**Ponto de atenção para o desenho:** "Alta" (>= 70) só é atingida com `Status = Contatado` (ou convertido) mais setor ou origem. Lead `Aberto - Não contatado` chega no máximo a 60 (Média). Logo, na fórmula atual, "pronto para abordagem" = Contatado com setor ou origem; RN1 (Aberto ou Contatado) e RN2 (Alta) só se sobrepõem em `Contatado`. Isso decorre da fórmula lida, não é suposição.

## 2. Automação concorrente em Lead

| Item | Resultado | Comando |
|---|---|---|
| Flow `Lead_AfterInsert_AplicaRegraAtribuicao` v1 | Ativo. RecordAfterSave, evento Create, objeto Lead. Contém ação do tipo `apex` (invocable, provavelmente aplica a regra de atribuição; classe não identificada). Sem criação ou atualização de registro no próprio Flow | Tooling `Flow` Metadata |
| Outros Flows ativos com nome ligado a Lead | Nenhum. Os demais ativos são de Opportunity, Account, Order, Quote, Task, CPQ, `MCC_*` (conector) e Trailhead | Tooling `Flow` Status='Active' |
| Triggers Apex em Lead, Campaign, CampaignMember, Contact | 0 | Tooling `ApexTrigger` |
| Triggers `et4ae5` | 14, em `User`, `et4ae5__Automated_Send__c`, `et4ae5__IndividualEmailResult__c`, `et4ae5__SMSDefinition__c`, `et4ae5__SendDefinition__c` e eventos `et4ae5__JB_*`. Nenhum em Lead | Tooling `ApexTrigger` NamespacePrefix='et4ae5' |
| Workflow Rules em Lead | 0 (as 17 do `et4ae5` não atuam em Lead) | Tooling `WorkflowRule` |
| Validation Rules em Lead | 2 ativas: `Celular`, `Telefone` (lógica não lida; podem barrar o save de lead de teste) | Tooling `ValidationRule` |
| Account, Opportunity, Order | Fora do escopo: a demanda não grava lá | análise, CA-08 |

Fórmula não cria ordem de execução. Flow ou trigger novo em Lead rodaria depois do `AfterSave` existente.

## 3. Cobertura de teste das classes tocadas

Sem classe Apex tocada: nenhum trigger em Lead e a demanda prefere fórmula e relatório. Classe invocada pelo Flow de atribuição não identificada (ver seção 7). Cobertura global de 10% vem do assessment, não reconfirmada.

## 4. O que o Marketing Cloud Connect (`et4ae5`) já usa

| Objeto | Campos et4ae5 | Comando |
|---|---|---|
| Lead | `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c` (só esses 2) | `FieldDefinition` |
| CampaignMember | `et4ae5__Activity__c` | `FieldDefinition` |
| Flows `MCC_*` | 13 ativos (backup, envio agendado, tracking, status de envio). Objeto de cada um não verificado | Tooling `Flow` |
| Workflow Rules | 17 (nenhuma em Lead) | Tooling `WorkflowRule` |

Nada confirmado de que o conector grave engajamento em Lead além dos 2 campos acima.

## 5. O que já cobre o pedido (candidatos a reaproveitar)

| Candidato | Detalhe | Comando |
|---|---|---|
| `PriorityBand__c` / `PriorityScore__c` | Já classificam prioridade; base de "pronto para abordagem" | acima |
| List view `Leads_Abertos_Prioridade` ("Leads abertos por prioridade") | Existe em Lead; filtros não lidos | `ListView` |
| List views `AllOpenLeads`, `Leads_Triagem_Lead`, regionais | Existem; nenhuma de nutrição | `ListView` |
| Reports | `LEADS_PROSPECCAO_PRIORIDADE` ("LEADS - PROSPECÇÃO PRIORIZADA"), `Cpia_de_LEADS_GERAL_D2D` ("LEADS - NÃO CONVERTIDOS"), `Hot_Leads_w_o_Activity_96_Hours`, `LeadsbySource`, `Marketing_Exec_Leads_by_Campaigns`, segmentos por setor. Filtros e colunas não lidos. Nenhum nomeado "nutrição" | `Report` por nome |
| Dashboard | "Leads & Oportunidades" (conteúdo não lido) | `Dashboard` |
| Permission sets com leitura de `PriorityBand__c` | "Comercial - Score de prioridade", "PS Marketing Publicos", "Data Cloud Salesforce Connector" | `FieldPermissions` |
| Agente Agentforce | `SFAgent2` existe (`BotDefinition`); tópicos e ações não reconferidos aqui. Não se aplica ao pedido | `BotDefinition` |

Campo, relatório ou painel de nutrição, elegibilidade ou engajamento: **não existe**.

## 6. Volume, dados de teste e permissões

| Item | Resultado | Comando |
|---|---|---|
| `COUNT()` Lead / Campaign / CampaignMember | 0 / 0 / 0 (dev sem dado; teste exige `fixtures/`) | `sf data query` |
| OWD Lead | `ReadWriteTransfer` | `EntityDefinition.InternalSharingModel` |
| Usuário de teste Konecta | 2 usuários com esse username: `005bJ00000hBJmYQAW` (inativo, Administrador do sistema) e `005bJ00000piKAaQAM` (ativo, Administrador do sistema). Usar o ativo | `User` |
| Acesso de leitura a `PriorityBand__c` | Os 3 permission sets acima; perfis não listados | `FieldPermissions` |

## 7. O que não consegui confirmar

- Qual classe Apex o Flow `Lead_AfterInsert_AplicaRegraAtribuicao` invoca, e sua cobertura.
- Lógica das validation rules `Celular` e `Telefone` de Lead (efeito sobre dado de teste).
- Filtros e colunas de `Leads_Abertos_Prioridade`, dos reports de Lead e do dashboard "Leads & Oportunidades" (reaproveitamento parcial depende disso).
- Objeto-alvo dos 13 Flows `MCC_*`.
- Perfis (não só permission sets) com acesso a `PriorityBand__c` e `MKT_Origem_Agrupada__c`; por que esse último não aparece no describe do usuário conectado.
- Tópicos e ações do `SFAgent2` nesta sessão (a regra 3 da conta os registra; não reconferido, sem relevância direta).
- Volume real de leads em produção (dev vazia).
- `HasOptedOutOfEmail` não foi reconsultado nesta sessão (vem da análise).
