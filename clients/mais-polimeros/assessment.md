# Assessment da org — Mais Polímeros

**Org auditada:** sbx-mais-polimeros-dev (`https://maispolimeros--devkonecta.sandbox.my.salesforce.com`) · **API:** v67 · **Data:** 2026-09-30
**Tipo confirmado:** Sandbox (`Organization.IsSandbox = true`, Unlimited Edition, username `projetos@maispolimeros.com.br.devkonecta`)
**Saúde geral:** vermelho

## Veredito em três linhas
A org tem automação empilhada em camadas sucessivas sem nunca ter sido limpa: Opportunity sozinho reúne 7 mecanismos de automação ativos (1 trigger, 2 Workflow Rules, 4 Flows) e 2 Process Builders — tecnologia fim de vida — continuam ativos. Quase metade das classes Apex de produção (47 de 101) não tem classe de teste dedicada e há código Apex parado em API version 36, dez anos atrás da v67 atual da org. Nenhuma demanda nova deveria ser desenhada em Account, Opportunity, Order ou OpportunityLineItem sem antes mapear o que já dispara ali.

## Inventário

| Item | Valor medido | Comando |
|---|---|---|
| Sandboxes conectadas | 1 (`sbx-mais-polimeros-dev`, Sandbox, Connected) | `sf org list` |
| Usuários ativos | 67 | `SELECT COUNT() FROM User WHERE IsActive=true` |
| Registros em Account / Opportunity (dev) | 0 / 0 | `SELECT COUNT() FROM Account` / `Opportunity` |
| Definições de Flow (`FlowDefinition`) | 185, sendo 145 com versão ativa | Tooling: `SELECT COUNT() FROM FlowDefinition` |
| Versões de Flow no total (histórico) | 1.411 (1.161 Obsolete, 145 Active, 91 Draft, 14 InvalidDraft) | Tooling: `SELECT Status, COUNT() FROM Flow` (agregado em Python) |
| Flows ativos por tipo | AutoLaunchedFlow 111, Flow (screen) 29, Workflow (Process Builder) 2, Survey 2, RoutingFlow 1 | idem |
| Workflow Rules | 7 (Order 1, Opportunity 2, Lead 3, Quote 1) | Tooling: `SELECT COUNT() FROM WorkflowRule` |
| Apex Triggers (total, incl. pacotes gerenciados) | 42 ativos | Tooling: `SELECT COUNT() FROM ApexTrigger` |
| Apex Triggers custom (sem namespace) | 13, API version entre 36 e 55 | Tooling: `SELECT Name, ApiVersion FROM ApexTrigger WHERE NamespacePrefix=null` |
| Apex Classes (total no org, incl. pacotes) | 2.246 (sf_devops 1.859, ChatIntegration 101, dlrs 100, aibp 9, beeCnpj 4, quotesync 3, PowerBIApp 2, sem namespace 168) | Tooling: `SELECT Name, NamespacePrefix FROM ApexClass` |
| Apex Classes custom (sem namespace) | 168 (67 parecem classe de teste, 101 de produção) | idem |
| Classes de produção sem `<Classe>Test` correspondente | 47 de 101 (46,5%) | comparação de nomes em Python sobre a lista acima |
| Cobertura de código agregada (última medição registrada) | 21% (2.098 linhas cobertas / 9.916 totais, 58 itens com 0%) — **ver ressalva abaixo** | Tooling: `SELECT NumLinesCovered, NumLinesUncovered FROM ApexCodeCoverageAggregate` |
| Objetos custom (`CustomObject`) | 125 | Tooling: `SELECT COUNT() FROM CustomObject` |
| Campos em Account / custom fields sem descrição | 381 campos totais · 433 campos custom, 418 sem descrição (96,5%) | `sf sobject describe --sobject Account` + Tooling `SELECT DeveloperName, Description FROM CustomField WHERE TableEnumOrId='Account'` |
| Campos em Opportunity / sem descrição | 177 campos totais · 153 custom, 146 sem descrição (95,4%) | idem, objeto Opportunity |
| Campos em Order / sem descrição | 185 campos totais · 146 custom, 141 sem descrição (96,6%) | idem, objeto Order |
| Campos em Product2 / sem descrição | 64 campos totais · 30 custom, 27 sem descrição (90%) | idem, objeto Product2 |
| Perfis | 57 (muitos nomeados por função/área, ex.: "Vendedor interno", "Supervisor vendas", "Coordenador Comercial") | `SELECT COUNT() FROM Profile` |
| Permission Sets (não vinculados a perfil) | 249 · Permission Set Groups: 21 | `SELECT COUNT() FROM PermissionSet WHERE IsOwnedByProfile=false` |
| ObjectPermissions concedidas via perfil vs. via permission set | 8.334 via perfil (57,6%) vs. 6.122 via permission set (42,4%) | `SELECT COUNT() FROM ObjectPermissions WHERE Parent.IsOwnedByProfile = true/false` |
| Validation Rules | 202 total (141 ativas, 61 inativas = 30%) | Tooling: `SELECT COUNT() FROM ValidationRule [WHERE Active=...]` |
| Page Layouts | 420 | Tooling: `SELECT COUNT() FROM Layout` |
| Record Types | 15 (todos ativos) | `SELECT COUNT() FROM RecordType [WHERE IsActive=true]` |
| Data Storage / File Storage (desta sandbox) | 2/200 MB (1%) / 0/200 MB (0%) — **não representa produção** | `sf limits api display` |
| Licenças Salesforce (full) usadas (espelho da sandbox) | 30 de 32 (93,75%) | `SELECT Name, TotalLicenses, UsedLicenses FROM UserLicense` |

## Achados

### 1. Sete mecanismos de automação diferentes disparam sobre Opportunity
- **Severidade:** alta
- **Área:** automação
- **Evidência:** Tooling API mostra, para `Opportunity`: 1 Apex Trigger ativo (`SELECT COUNT() FROM ApexTrigger` agrupado por `TableEnumOrId` → `Opportunity: 1`), 2 Workflow Rules ativas (`SELECT TableEnumOrId FROM WorkflowRule` → `Opportunity` aparece 2×), e 4 Flows ativos com start em `Opportunity` (`AlterarProprietariodaCotacao` — RecordAfterSave/CreateAndUpdate; `FlowOpp04 - Before Create Update` — RecordBeforeSave/CreateAndUpdate; `MP - Opp Alterações de Registro 2026` — RecordAfterSave/CreateAndUpdate; `UltimaCotaçãoElegível - Agenda` — Scheduled), obtidos consultando `Metadata.start` de cada Flow ativo via Tooling API. `OpportunityLineItem` tem o mesmo padrão: 2 Apex Triggers + 4 Flows ativos (2 deles `RecordAfterSave/CreateAndUpdate`). `Account` tem 1 trigger + 3 Flows concorrendo no evento create/update.
- **Risco:** ordem de execução não determinística entre trigger/workflow rule/flow, efeitos colaterais difíceis de depurar, e qualquer nova demanda em Opportunity corre risco real de duplicar lógica que já existe em algum dos 7 pontos ou de conflitar com um deles.
- **Recomendação:** mapear os 7 pontos de automação de Opportunity num quadro único (o que cada um faz, em que ordem), consolidar os Flows `RecordAfterSave`/`CreateAndUpdate` num só Flow orquestrado, e migrar a lógica das 2 Workflow Rules para dentro dele. Repetir o exercício para Account e OpportunityLineItem.
- **Esforço:** alto

### 2. Dois Process Builders continuam ativos (tecnologia em fim de vida)
- **Severidade:** alta
- **Área:** automação
- **Evidência:** `SELECT Id, MasterLabel, ProcessType, Status FROM Flow` via Tooling API retorna 2 registros com `ProcessType='Workflow'` (o rótulo interno de Process Builder) e `Status='Active'`: **"Automação de Queue"** e **"Produto Cod"**, ambos sem `ApiVersion` definida (nunca migrados).
- **Risco:** a Salesforce não aceita mais criação/edição de Process Builder e sinalizou fim de suporte; qualquer necessidade de ajuste nessas duas automações hoje exige reescrevê-las do zero em Flow sob pressão, no lugar de uma migração planejada.
- **Recomendação:** recriar as 2 automações como Record-Triggered Flow e desativar os Process Builders originais, com testes formais antes do corte.
- **Esforço:** médio

### 3. Quase metade das classes Apex de produção não tem classe de teste dedicada
- **Severidade:** alta
- **Área:** código
- **Evidência:** das 168 classes Apex custom (sem namespace), 67 têm nome terminado em `Test`; das 101 restantes ("classes de produção"), 47 não têm nenhuma classe `<Nome>Test` ou `<Nome>_Test` correspondente — entre elas `OrderTriggerHandler`, `OpportunityBO`, `QuoteBO`, `AccountDAO`, `EstoqueBO`, `FreteBO`, `Util`. Adicionalmente, `ApexCodeCoverageAggregate` retornou cobertura agregada de 21% (2.098 linhas cobertas de 9.916), com 58 classes/triggers em 0% — mas `ApexTestResult` está vazio nesta sandbox, então não há como confirmar a data da última execução de teste que gerou esse número; ele deve ser tratado como indicativo, não como medição corrente.
- **Risco:** sem teste dedicado por classe, regressões em código como `OrderTriggerHandler` ou `OpportunityBO` (que sustentam parte da automação do achado #1) não são pegas antes de produção; se o número de cobertura estiver mesmo perto de 21%, a org não passaria nem no mínimo de 75% que a Salesforce exige para deploy em produção.
- **Recomendação:** rodar `sf apex run test --code-coverage` nesta sandbox para obter um número de cobertura atual e confiável, e priorizar classe de teste para as 47 sem cobertura, começando pelas que sustentam Order/Opportunity/Account.
- **Esforço:** alto

### 4. Código Apex parado em API version até 31 versões atrás da atual
- **Severidade:** média
- **Área:** dívida técnica
- **Evidência:** `SELECT Name, ApiVersion FROM ApexTrigger WHERE NamespacePrefix=null` mostra `Account`, `EstoqueTrigger`, `FreteTrigger`, `OpportunityLineItemTrigger`, `Queue`, `QuoteLineItemTrigger` todos em **API v36** (a org está em v67 hoje). Entre as 168 classes custom, a distribuição de `ApiVersion` inclui 5 em v36, 16 em v45, 3 em v47, 1 em v49, 13 em v50 — 38 classes (23%) presas em API version anterior a v51.
- **Risco:** classes em API version muito antiga não se beneficiam de comportamentos corrigidos por versão (ex.: mudanças de contexto de trigger, governor limits) e sinalizam código que ninguém revisita há anos — cada uma é uma incógnita antes de qualquer alteração.
- **Recomendação:** subir a API version dessas classes/triggers junto de um ciclo de regressão de teste, começando pelos 6 triggers em v36 por tocarem objetos centrais (Account, Estoque, Frete, OpportunityLineItem, Queue, QuoteLineItem).
- **Esforço:** médio

### 5. 14 versões de Flow em estado InvalidDraft
- **Severidade:** média
- **Área:** dívida técnica
- **Evidência:** `SELECT Status FROM Flow` via Tooling API retorna 14 registros com `Status='InvalidDraft'`, incluindo `AlterarProprietariodaCotacao`, `AlterarProprietarioRegistro`, `MP - Quadro de Metas`, `MP - OFF GRADE`, `[Agentforce] - Get Order by Cod Totvs`, `MP - Limite de Crédito`.
- **Risco:** são versões de Flow que já falham validação hoje — se alguém tentar ativá-las ou usá-las como base de um clone, o erro só aparece na hora, não antes.
- **Recomendação:** revisar as 14 versões, corrigir ou excluir as que não servem mais; nenhuma delas deve ser usada como ponto de partida para uma nova demanda sem antes entender por que está inválida.
- **Esforço:** baixo

### 6. Campos customizados sem descrição em massa nos objetos centrais
- **Severidade:** média
- **Área:** modelo de dados
- **Evidência:** consulta Tooling API a `CustomField` por `TableEnumOrId`: Account 418 de 433 campos custom sem `Description` (96,5%), Opportunity 146 de 153 (95,4%), Order 141 de 146 (96,6%), Product2 27 de 30 (90%). Padrão consistente nos 4 objetos centrais verificados.
- **Risco:** ninguém sabe para que serve a maioria dos campos sem abrir o Setup e investigar o histórico — isso trava qualquer decisão de "podemos remover esse campo?" e aumenta o risco de recriar campo que já existe com outro nome.
- **Recomendação:** antes de criar qualquer campo novo num desses objetos, checar se já existe algo equivalente; abrir uma iniciativa de documentação incremental (descrição obrigatória em campo novo, retroativa por prioridade de uso).
- **Esforço:** alto

### 7. Account já está em 381 campos, perto do teto prático de um objeto
- **Severidade:** média
- **Área:** modelo de dados
- **Evidência:** `sf sobject describe --sobject Account` retorna 381 campos (`fields.length`). Para efeito de comparação, Opportunity tem 177, Order 185.
- **Risco:** objetos com centenas de campos ficam lentos para carregar em layout/list view, dificultam onboarding de quem desenha uma solução nova, e se aproximam de limites de plataforma por objeto.
- **Recomendação:** antes de adicionar qualquer campo novo em Account, avaliar se algum campo existente (dos 418 sem descrição) já cobre a necessidade; considerar auditoria de uso via Optimizer para aposentar campos mortos.
- **Esforço:** médio

### 8. Permissão concedida majoritariamente por perfil, com 57 perfis custom
- **Severidade:** média
- **Área:** segurança
- **Evidência:** `SELECT COUNT() FROM ObjectPermissions WHERE Parent.IsOwnedByProfile = true` retorna 8.334 contra 6.122 com `= false` (57,6% das concessões de permissão de objeto vêm de perfil, não de permission set). `SELECT COUNT() FROM Profile` retorna 57 perfis, muitos nomeados por função/área (`Vendedor interno`, `Supervisor vendas`, `Coordenador Comercial`, `GAC - Comercial`, `Crédito e Cadastro`), o que sugere perfil usado como unidade de configuração de acesso granular em vez de permission set.
- **Risco:** mudar o acesso de uma pessoa ou de um grupo pequeno exige mexer em perfil, que afeta todo mundo naquele perfil — mais difícil de auditar e mais fácil de errar do que compor via permission sets.
- **Recomendação:** não sobrepor a doutrina do squad (permissão via permission set, não perfil) em nenhuma demanda nova; nas próximas revisões, migrar gradualmente as permissões hoje presas ao perfil para permission sets dedicados.
- **Esforço:** alto

### 9. 30% das Validation Rules estão inativas e nunca foram removidas
- **Severidade:** baixa
- **Área:** qualidade de config
- **Evidência:** `SELECT COUNT() FROM ValidationRule` retorna 202 no total; `WHERE Active=true` retorna 141; `WHERE Active=false` retorna 61 (30,2%). Também há 420 `Layout` (Tooling API) para 125 objetos custom + objetos standard, sem forma de confirmar quantos estão de fato atribuídos a algum perfil/record type sem uma extração adicional de `ProfileLayout` (não feita nesta rodada).
- **Risco:** regra inativa não quebra nada, mas confunde quem está investigando comportamento de validação de um objeto — precisa checar 202 regras para saber quais das 141 realmente valem.
- **Recomendação:** revisar as 61 regras inativas numa faxina pontual; decidir remover ou reativar cada uma.
- **Esforço:** baixo

### 10. Uso de licença Salesforce full próximo do limite (na cópia mais recente da sandbox)
- **Severidade:** baixa
- **Área:** limites
- **Evidência:** `SELECT Name, TotalLicenses, UsedLicenses FROM UserLicense` retorna `Salesforce: TotalLicenses=32, UsedLicenses=30` (93,75%) nesta sandbox. Isso é um espelho de produção na última cópia/refresh da sandbox, não uma leitura ao vivo de produção — a org de produção não foi e não deve ser consultada por este agente (guardrail #1).
- **Risco:** se o número reflete a realidade atual de produção, sobra pouco espaço para novos usuários internos sem comprar licença.
- **Recomendação:** confirmar com o cliente o número atual de licenças usadas em produção antes de planejar qualquer expansão de usuários.
- **Esforço:** baixo

## Não pôde ser medido
- **Sharing settings (OWD) por objeto** — `sf sobject describe` não retorna `sharingModel` populado por esta via, e uma consulta Tooling a `SharingRules`/OWD não tem um sObject de leitura direta acessível por SOQL simples. Precisaria de retrieve de metadata `Settings` para confirmar — não feito nesta rodada por escopo de tempo.
- **Data storage e file storage de produção** — os números de storage reportados no Inventário são desta sandbox de dev (2 MB / 0 MB usados), que tem alocação própria e pequena, sem relação com o volume de produção. Este agente não tem e não deve ter acesso a produção (guardrail #1), então o uso real de storage em produção fica sem medição possível por este caminho.
- **Cobertura de teste corrente e confiável** — `ApexCodeCoverageAggregate` devolveu 21% agregado, mas `ApexTestResult` está vazio nesta sandbox (sem registro de quando os testes rodaram pela última vez), então não dá para afirmar que 21% é o número de hoje — pode ser resíduo de um teste rodado há muito tempo, antes de deploys subsequentes. Rodar `sf apex run test --code-coverage` resolveria isso, mas essa é uma ação nova (execução de teste), não coleta passiva, e ficou fora do escopo puramente read-only desta rodada.
- **Objeto/evento de cada Workflow Rule** e **campos não usados** (fora da amostra de 4 objetos verificados) — daria para levantar via retrieve de metadata completo, mas o volume (185 Flows, 125 objetos custom) tornaria a rodada de recon muito mais longa; ficou registrado como próximo passo, não como número inventado.
- **Quantos dos 420 page layouts estão de fato órfãos** (sem atribuição a nenhum perfil/record type) — exigiria cruzar `Layout` com `ProfileLayout`/`RecordTypeLayout`, não feito nesta rodada.
