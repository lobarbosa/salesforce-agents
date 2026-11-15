**Resultado do build:** concluído

# EPLAST-26 — Plano de build: score e faixa de prioridade em Lead e Opportunity

**Branch:** `feature/EPLAST-26`. **Org:** `sbx-eplast-dev` (`sf org list`: Sandbox, Connected; `Organization.IsSandbox` = true). Nenhum deploy fora da dev. Nada feito no Marketing Cloud nem em produção.
**Base:** `03-design.md` (gate de design aprovado em 2026-11-15, `gates.md`). Premissas PD-01 a PD-08 construídas como decididas.
**Só declarativo:** nenhum ApexTrigger, ApexClass, Flow, Custom Metadata ou lote agendado no pacote.

## B0 — Dev distinta de QA (achado 6 do assessment)

- Conferi que a org do alias dev é sandbox (`IsSandbox` = true, Enterprise Edition) e que `sf org list` mostra só o alias dev conectado nesta sessão.
- **Não consegui provar que dev e QA são sandboxes distintas.** O alias QA não está conectado aqui, então não há como comparar Org Id nem instância das duas. O username do alias dev contém "qa" (já registrado no recon). Incerteza mantida: o verificador e a esteira de QA devem comparar o Org Id do alias dev com o do alias QA antes de assumir isolamento. Não bloqueia o build (checagem técnica, não pergunta de negócio).

## Componentes criados (todos com `description`)

| # | Componente | Caminho | Observação |
|---|---|---|---|
| C1 | `Lead.PriorityScore__c` (fórmula Number 3,0) | `force-app/main/default/objects/Lead/fields/PriorityScore__c.field-meta.xml` | Fórmula e texto de ajuda da seção 4.1 do design |
| C2 | `Lead.PriorityBand__c` (fórmula Text) | `.../objects/Lead/fields/PriorityBand__c.field-meta.xml` | Lê `PriorityScore__c`. Faixas: Alta, Média, Baixa, Sem dados suficientes |
| C3 | `Opportunity.PriorityScore__c` (fórmula Number 3,0) | `.../objects/Opportunity/fields/PriorityScore__c.field-meta.xml` | Fórmula da seção 4.2, com `ROUND` (PD-04) e janela hoje a 60 dias (PD-03) |
| C4 | `Opportunity.PriorityBand__c` (fórmula Text) | `.../objects/Opportunity/fields/PriorityBand__c.field-meta.xml` | Faixas: Alta, Média, Baixa, Encerrada |
| C5 | Permission Set `PS_Comercial_ScorePrioridade` | `.../permissionsets/PS_Comercial_ScorePrioridade.permissionset-meta.xml` | Só `fieldPermissions` de leitura em C1 a C4; sem permissão de objeto; nenhum perfil alterado |
| C6 | List view `Lead.Leads_Abertos_Prioridade` | `.../objects/Lead/listViews/Leads_Abertos_Prioridade.listView-meta.xml` | Filtro: Status diferente dos dois "Fechado"; escopo Todos; visível a todos os usuários internos (PD-08) |
| C7 | List view `Opportunity.Oportunidades_Abertas_Prioridade` | `.../objects/Opportunity/listViews/Oportunidades_Abertas_Prioridade.listView-meta.xml` | Filtro: não encerrada |
| C8 | List view `Opportunity.Oportunidades_Prioridade_Alta` | `.../objects/Opportunity/listViews/Oportunidades_Prioridade_Alta.listView-meta.xml` | Não encerrada e `PriorityBand__c` = "Alta" |

Valores de API conferidos na dev antes de referenciar: `Lead.Status` ("Contatado", "Fechado - Convertido", "Fechado - Não convertido"), `Lead.Sector__c`, `Lead.LeadSource`, `Lead.IsConverted`, `Opportunity.Probability`, `Amount`, `CloseDate`, `LeadSource`, `IsClosed` (describe e `FieldDefinition`, só metadata). Nenhum campo `PriorityScore__c`/`PriorityBand__c` existia antes.

## Componentes alterados

| # | Componente | Alteração |
|---|---|---|
| A1 | Layout `Lead-Lead Layout` | Seção "Prioridade" (2 campos, somente leitura) antes de "Custom Links" |
| A1 | Layout `Opportunity-Opportunity Layout` | Idem |
| B3 | FlexiPage `Lead_Record_Page` | Seção de campos "Prioridade" (2 campos, `uiBehavior` readonly) na aba de detalhes |
| B3 | FlexiPage `Opportunity_Record_Page` | Idem |

Os dois FlexiPages foram retornados da dev antes da edição e vieram idênticos ao repositório (sem deriva).

## B3 — Páginas Lightning

- Override de visualização padrão (formFactor Large e Small) em `Lead.object-meta.xml` e `Opportunity.object-meta.xml` aponta para `Lead_Record_Page` e `Opportunity_Record_Page`.
- As duas usam **Dynamic Forms** (`fieldInstance` dentro de `flexipage:fieldSection`). Por isso os campos entraram nelas, e também nos layouts, para o caso de uso fora do Lightning ou de página que volte ao layout.
- `Lead_Record_Page_Three_Column` usa `force:detailPanel` (segue o layout). `Opportunity_Record_Page_Three_Column` usa Dynamic Forms, mas não é o padrão em nenhum override do objeto; **não foi alterada**. Se alguma app ou perfil a atribuir, a seção "Prioridade" não aparece ali. Não confirmei atribuições por app/perfil (não estão no metadata local dos objetos): o verificador ou o administrador devem conferir no Setup.

## Desvio do design

- **A1 do design previa também `Opportunity-CPQ Opportunity Layout`. Não alterado.** O layout é do pacote instalado SBQQ (`ManageableState` = installed, `NamespacePrefix` = SBQQ; o retrieve com o nome sem namespace não o encontrou). Layout de pacote gerenciado não é editável. Impacto: baixo, porque a página Lightning ativa usa Dynamic Forms. Se alguma Opportunity usar esse layout fora do Lightning, não mostra os campos.

## B4 — List views

- O deploy aceitou o filtro por `PriorityBand__c` (fórmula com `TODAY()`) em C8 e as colunas de score e faixa nas três vistas. Isso resolve a parte de filtro da incerteza I-3.
- **Não conferido:** a ordenação por clique na coluna de score. A metadata de list view não guarda ordenação e não há como exercitar a interface daqui. Fica para o `verificador`/QA conferirem na tela. Não construí relatório alternativo.
- Coluna de proprietário: no Lead usei `CORE.USERS.FIRST_NAME` e `CORE.USERS.LAST_NAME` (o nome `CORE.USERS.FULL_NAME` não foi aceito para Lead); nas vistas de Opportunity, `CORE.USERS.FULL_NAME`.

## B2 — Permissão

- Permission set atribuído ao usuário da esteira na dev (1 atribuição, conferida por contagem). Atribuição aos usuários reais dos perfis da PD-07 é passo manual do administrador, por ambiente, depois do deploy.

## B5 — Deploy

- `sf project deploy start --dry-run` na dev: primeiro falhou em 3 componentes (coluna `CORE.USERS.FULL_NAME` do Lead; `componentName` ausente na coluna do FlexiPage, nos dois). Corrigidos.
- Dry-run novo: Succeeded (Deploy ID 0AfHa00000EHt01KAD). Deploy real: **Succeeded** (Deploy ID 0AfHa00000EHstaKAD), 12 componentes, nível de teste padrão (sem Apex no pacote; sem `RunAllTestsInOrg`).
- Nenhum dado de registro foi lido. Nenhum Lead nem Opportunity foi criado (fica para a verificação).

## Pendências para a verificação (não são do build)

1. Criar Leads sintéticos e conferir C1/C2 pela API (design, seção 7).
2. Opportunity sintética: fixture com 16 validation rules e `OpportunityFlow` (design, seção 8). Não criei registros.
3. Confirmar ordenação por clique na coluna de score e se `PriorityScore__c` aparece como não editável na API (escrita recusada).
4. B0: comparar Org Id dev x QA.
5. Passos manuais depois do deploy em cada ambiente: atribuir o permission set aos perfis da PD-07.

## Premissas assumidas aplicadas (do design, seção 9)

Construído como decidido: PD-01 (sem prefixo), PD-02 (pesos literais na fórmula), PD-03 (fechamento vencido não pontua), PD-04 (`ROUND`), PD-05 (`IsConverted` conta como contatado), PD-06 (Lead "Fechado - Não convertido" sem faixa especial, fora de C6 pelo filtro), PD-07 (permission set), PD-08 (list views para todos os usuários internos). Nenhuma foi tratada como pendência.
