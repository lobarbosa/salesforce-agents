# 02 — Recon da org: SOMOSAGILITY-15 — Layout de página inicial

**Data da coleta:** 2026-10-21
**Org:** `sbx-somos-agility-dev` (Org ID `00DHa0000070wxfMAA`), confirmada `IsSandbox = true`,
Enterprise Edition, API v68.0. Nenhuma escrita feita na org: só consulta de metadata (Tooling API,
retrieve para diretório temporário fora do repositório) e contagens agregadas.

**Convenção de citação neste artefato:** vários DeveloperNames/labels de páginas, dashboards e um
perfil desta org contêm prenomes de pessoas. Para não levar nome de ninguém ao artefato, eles
aparecem com o trecho do nome trocado por `<nomes>` ou `<prenome>` e sempre com o **Id da
FlexiPage**, que é o identificador inequívoco para o build (o API name completo sai da org pelo Id).

## 1. Páginas Lightning do tipo Home existentes (14)

Fonte: `SELECT ... FROM FlexiPage WHERE Type = 'HomePage'` (Tooling API).

| # | Id FlexiPage | DeveloperName (sanitizado) | Template | Última alteração | Atribuída? |
|---|---|---|---|---|---|
| H1 | `0M00z000000GoLuCAK` | `Equipe_vendas_SP` | home:desktopTemplate | 2019-08-02 | Sim |
| H2 | `0M04z000000g1AxCAI` | `Home_Page_GC` | home:desktopTemplate | 2023-09-06 | **Não** (nenhum app/perfil) |
| H3 | `0M04z000000g1BHCAY` | `Home_Page_Geral` | home:desktopTemplate | 2023-09-06 | Sim |
| H4 | `0M0U40000002p6TKAQ` | `Home_Page_<prenome>` (template flowsapp) | flowsapp:homePageTemplateHeaderTwoColumnLeftSidebar | 2025-06-16 | **Não**; página sem componentes |
| H5 | `0M0U400000049fpKAA` | `Home_Page_Marketing` | runtime_alm_devops:homeDesktopTemplate | 2026-05-08 | Sim |
| H6 | `0M038000000CbqCCAS` | `Home_page_padr_o` | home:desktopTemplate | 2026-08-03 | Sim |
| H7 | `0M0U40000001G17KAE` | `Homepage_Customer_Success_Painel_de_Relacionamento_Operacional` | home:desktopTemplate | 2024-07-31 | Sim |
| H8 | `0M0U40000001G2jKAE` | `Homepage_GPs_PMO_<nomes>_Painel_de_Projetos` | home:desktopTemplate | 2025-09-12 | Sim |
| H9 | `0M0U40000001HhxKAE` | `Homepage_Grupo_Operacoes_Painel_de_Controle_de_Operacoes` | home:desktopTemplate | 2024-08-16 | Sim |
| H10 | `0M0U40000002p9hKAA` | `Homepage_<prenome>` | home:desktopTemplate | 2025-06-16 | Sim (perfil sem usuário ativo) |
| H11 | `0M0U40000001GnVKAU` | `Homepage_Renovacoes_e_<prenome>_Painel_de_Controle_de_Renovacoes` | home:desktopTemplate | 2025-05-23 | Sim |
| H12 | `0M0U40000001FzVKAU` | `Homepage_SE_GCs_<nomes>_Painel_Geral` | home:desktopTemplate | 2024-07-31 | Sim |
| H13 | `0M038000000GmdwCAC` | `P_gina_Inicial_Customizada` | home:desktopTemplate | 2017-10-09 | Sim (perfil Admin) |
| H14 | `0M00z000000fxzFCAQ` | `PaginaInicialGerenteContas` | home:desktopTemplate | 2019-06-10 | **Não** |

Baseline do repositório (`force-app/main/default/flexipages/`, commit `6ffa5a54`): tem H2–H12 e
estão **idênticas** à org hoje. **H1, H13 e H14 não estão no baseline** — o build precisa
recuperá-las da org antes de editar.

## 2. Atribuições (app + perfil → página Home)

Fonte: `profileActionOverrides` com `pageOrSobjectType = standard-home` nos `CustomApplication`
recuperados. **Nenhum app tem default de app** (`actionOverrides` de `standard-home` vazio em todos).
Todas as atribuições são `formFactor = Large` (desktop); **nenhuma atribuição para celular**.

Apps Lightning que carregam atribuições de Home por perfil:
`standard__LightningSales`, `standard__LightningSalesConsole`, `standard__DataManager`,
`standard__FlowsApp`, `standard__OnlineSales`, `standard__SalesforceCMS`, `Partner_Portal`.
Os cinco últimos repetem o mesmo conjunto (H7, H8, H9, H11, H12). Os dois apps de vendas têm o conjunto
completo:

| Página | Perfis atribuídos (apps de vendas) |
|---|---|
| H12 `Homepage_SE_GCs_<nomes>_Painel_Geral` | System Engineer, Admin, Diretor Financeiro, PO EA, Diretor Comercial |
| H8 `Homepage_GPs_PMO_<nomes>_Painel_de_Projetos` | adminPMO, Gerente de Contas, Professional Services, Gerente de Operações, Diretor de Projetos, Gerente de Contas e Soluções, Gerente de Projetos |
| H11 `Homepage_Renovacoes_e_<prenome>_...` | Renovações, Gerente de renovações, Administração (este último só no Console e nos apps secundários) |
| H9 `Homepage_Grupo_Operacoes_...` | Grupo Operações, Compras Financeiro |
| H7 `Homepage_Customer_Success_...` | Customer Success Squad |
| H6 `Home_page_padr_o` | PO SEG, PO DT, Diretor  DT |
| H1 `Equipe_vendas_SP` | Gerente Comercial SP |
| H3 `Home_Page_Geral` | Sales Operations (só `standard__LightningSales`) |
| H5 `Home_Page_Marketing` | Marketing |
| H10 `Homepage_<prenome>` | perfil `Gerente de contas - <prenome>` (só `standard__LightningSales`) |
| H13 `P_gina_Inicial_Customizada` | Admin (apps de vendas) |

Observação: o perfil **Admin** aparece com duas atribuições no mesmo app (`standard__LightningSales`
e `...Console`): H13 e H12. Não confirmei qual delas o runtime aplica — anotar como incerteza.

**Default da org para Home: não confirmado.** O default de org não aparece nos `CustomApplication`
e não foi localizado por metadata nesta sessão. Perfis com usuário ativo **sem** atribuição explícita
nos apps de vendas (caem no default de app/org): `Administrador do sistema`, `Gerente de Contas - AI`
e os usuários de integração (Sales Insights / Analytics Cloud).

## 3. Componentes presentes em cada página

Só tipo e referência — o conteúdo dos componentes de texto rico (`flexipage:richText`) foi omitido.

| Componente (API) | O que é | Páginas onde está |
|---|---|---|
| `desktopDashboards:embeddedDashboard` | Dashboard embutido | H1(2x), H2(2x), H3, H5, H6, H7, H8, H9, H10, H11, H12, H14 |
| `runtime_approval_process:pendingApprovalCard` | Itens a aprovar | todas exceto H4 |
| `runtime_sales_activities:todayTaskContainer` | Tarefas de hoje | todas exceto H4 |
| `home:recentRecordContainer` | Registros recentes | H1, H6, H7, H8, H9, H10, H11, H12, H14 |
| `home:eventContainer` | Eventos de hoje | H1, H6, H7, H8, H9, H12, H13, H14 |
| `forceChatter:exposedFeed` | Feed do Chatter | H1, H7, H8, H9, H12, H14 |
| `home:heroChart` | Gráfico de desempenho (assistente de vendas) | H1, H7, H8, H9, H12, H14 |
| `home:topDealsContainer` | Principais negócios | H1, H7, H8, H9, H12, H13, H14 |
| `flexipage:richText` | Texto rico | H6, H7, H8, H9, H11, H12, H13, H14 |
| `home:assistant` | Assistente | H1, H13, H14 |
| `flexipage:filterListCard` | Lista de Opportunity `OportunidadesAtrasadas` | H1, H14 |
| `flexipage:reportChart` | Gráfico de relatório | H13 (3x: `Funil_de_Vendas_2017`, `Rentabilidade_Realizada_Projetos`, report Id `00O38000004w1vO`) |
| `flexipage:recentItems` | Itens recentes | H13 |
| `forceChatter:recommendations` | Recomendações | H13 |

Nenhum componente tem regra de visibilidade (`visibilityRule`) hoje. Nenhum componente custom
(LWC/Aura) nem Flow embutido nas páginas Home.

Dashboards embutidos (título; pasta):

| DeveloperName | Título | Páginas |
|---|---|---|
| `nYmbUdnjSAfkyQvdlDbTEqUHKwgnwN11` | Painel Geral (Metas) | H3, H12 |
| `nYmbUdnjSAfkyQvdlDbTEqUHKwgnwN1` | Painel GCs (Metas) | H2 |
| `hqLIkOwOlSASAdwsIgimglCJZashgC` | Oportunidades quarter: Gerente de contas (Metas) | H2, H14 |
| `hqLIkOwOlSASAdwsIgimglCJZashgC1` | Oportunidades: Equipe farmers SP | H1 (2x) |
| `yVwmPPIUToNKCOkYfGtxVvfkFreSfZ` | Painel de projetos (Projetos - Atuais 2024) | H8 |
| `vkQlEVaJCFSDkBWuZkDDrksCVAOZiX` | Controle Operações (Projetos - Atuais 2024) | H9 |
| `NRMOobtthBzaSTNKJCpidFFISgluBD` | Controles de Renovações (Projetos - Atuais 2024) | H11 |
| `pebKCJyjKFPipRhSZkzbIceFkLSfTG` | Relacionamento Operacional - CS (CS) | H7 |
| `pIQfmXROUoPwKVrzbyZokYkUfTsSTW` | Main Dashboard (Activities) | H6 |
| `rZJCYIvKNAmvBcLFIoQubdixWLNFcg` | Controle Marketing (Marketing) | H5 |
| `IJzllqLKMpJoeGzyKCFDFSGUoGghIT` | Painel - `<prenome>` | H10 |

## 4. Usuários ativos por perfil (contagem agregada, `UserType = 'Standard'`)

Gerente de Contas 7; PO EA 3; Administração 2; Admin 2; Sales Operations 2; 1 cada em System Engineer,
Gerente de Contas e Soluções, Gerente de Projetos, Diretor Comercial, Customer Success Squad,
Gerente de renovações, Professional Services, Diretor de Projetos, Gerente de Contas - AI, adminPMO,
Administrador do sistema, Compras Financeiro, Marketing, e 3 perfis de integração. Total: 21 perfis
com usuário ativo, ~31 usuários. Volume irrelevante para limites de governador (não há DML/automação).

Perfis atribuídos sem usuário ativo nesta sandbox: Diretor Financeiro, PO SEG, PO DT, Diretor  DT,
Gerente Comercial SP, Renovações, Grupo Operações, Gerente de Operações, perfil
`Gerente de contas - <prenome>`. Atenção: isso é a sandbox de dev; não confirma o quadro de produção.

## 5. Automação, validação e código impactados

Nenhum. Página Lightning é metadata de UI: não há Flow, trigger, validation rule ou classe Apex
envolvidos na renderização dessas páginas (nenhum componente custom nem Flow embutido, ver seção 3).
Sem conflito de ordem de execução possível nesta demanda.

## 6. Incertezas declaradas

- Lista real do que retirar (P1) e escopo de perfis (P2): **continuam sem resposta**. O anexo liberado
  foi lido por extração de texto; a lista está em imagem embutida e não é legível por essa via.
- Default de Home da org e qual atribuição vence para o perfil Admin: não confirmados.
- Se "objetos" no pedido significa **componentes da Home** ou **abas de objeto na barra de navegação**
  do app: não há como distinguir sem a lista. Os mecanismos são diferentes (seção de riscos do design).
