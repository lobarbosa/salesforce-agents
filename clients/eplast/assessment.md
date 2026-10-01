# Assessment da org — Eplast

**Org auditada:** sbx-eplast-dev (https://eplast--qa.sandbox.my.salesforce.com) · **API:** v67 · **Data:** 2026-09-30
**Saúde geral:** vermelho

## Veredito em três linhas
A org de dev roda em cima do Salesforce CPQ (SBQQ), Marketing Cloud Connect e um punhado de
outros pacotes geridos — a base é grande, mas a automação **própria** do cliente em Account,
Opportunity e Order concorre com a automação do CPQ no mesmo evento, e a cobertura de teste
Apex real do org é de **10%**, bem abaixo do mínimo de deploy da Salesforce (75%) e do padrão
do squad (85%). Nenhum dado de negócio foi lido — a sandbox de dev está vazia de registros
(0 Account/Contact/Opportunity), então volume de produção não pôde nem deveria ser inferido
daqui. Antes de aceitar qualquer demanda nova em Account/Opportunity/Order, mapeie a ordem de
execução entre trigger custom, trigger do CPQ e Flows — hoje ninguém tem essa foto.

## Inventário

| Métrica | Valor | Comando |
|---|---|---|
| Org / Edition / Sandbox | sbx-eplast-dev · Enterprise Edition · isSandbox=true | `sf org display --target-org sbx-eplast-dev` |
| API version da org | v67.0 | idem |
| Apex classes (total / custom sem namespace / gerenciadas) | 1830 / 54 / 1776 | `SELECT COUNT() FROM ApexClass`; `SELECT ... FROM ApexClass` |
| Pacotes geridos com mais classes | SBQQ (CPQ) 836 · et4ae5 (Marketing Cloud Connect) 519 · maps (Salesforce Maps) 331 · trailheadapp 90 | idem, agrupado por `NamespacePrefix` |
| Apex triggers (total / custom / gerenciados) | 103 / 3 / 100 | `SELECT ... FROM ApexTrigger` |
| Cobertura de teste Apex (org-wide) | **10%** | `SELECT PercentCovered FROM ApexOrgWideCoverage` (Tooling) |
| Cobertura das classes custom com registro de execução | 11,1% (76/686 linhas), 35 de 54 classes com algum registro | `SELECT ... FROM ApexCodeCoverageAggregate` (Tooling) cruzado com `ApexClass` |
| Classes de produção custom sem classe de teste identificável | ~27 de 39 | inspeção de nomes (`ApexClass` sem namespace) |
| Flow definitions (total / custom sem namespace / gerenciados) | 111 / 25 / 86 | `SELECT ... FROM FlowDefinitionView` |
| Flows custom ativos / inativos | 23 / 2 | idem |
| Workflow Rules | 17 (100% pacote instalado `et4ae5`, 0 custom) | `sf org list metadata --metadata-type WorkflowRule` |
| Process Builder (ProcessType=Workflow) próprio do cliente | 0 encontrados | inspeção do `ProcessType` nos Flows sem namespace |
| Approval Processes | 3 | `sf org list metadata --metadata-type ApprovalProcess` |
| Objetos custom próprios (unmanaged) | 15 | `sf org list metadata --metadata-type CustomObject` |
| Campos custom em Account/Order/Opportunity/OrderItem | 223 (90/64/28/41) | `SELECT ... FROM CustomField` (Tooling) |
| Campos custom sem descrição (mesmos 4 objetos) | 153 de 223 (68,6%) | idem |
| Validation Rules (total / ativas) | 122 / 114 | `SELECT ... FROM ValidationRule` (Tooling) |
| Validation Rules em Order (Pedido) | 23 | idem, filtrado por objeto |
| Record Types (total / inativos) | 14 / 0 | `SELECT ... FROM RecordType` |
| Page Layouts (total) | 311 | `sf org list metadata --metadata-type Layout` |
| Profiles (total) | 33 (padrão + ~8 customizados de negócio) | `sf org list metadata --metadata-type Profile` |
| Permission Sets / Permission Set Groups | 41 / 14 | `sf org list metadata --metadata-type PermissionSet`; `SELECT COUNT() FROM PermissionSetGroup` |
| Usuários (total) | 46 | `SELECT COUNT() FROM User` |
| Data Storage / File Storage | 0 MB usados de 200 MB cada (0%) | `sf org list limits` |
| Licença Salesforce (sandbox) | 14 de 14 usadas (100%, específico desta sandbox) | `SELECT ... FROM UserLicense` |

## Achados

### 1. Automação concorrente no mesmo evento em Account, Opportunity e Order
- **Severidade:** alta
- **Área:** automação
- **Evidência:** `SELECT ... FROM ApexTrigger` e `SELECT ... FROM FlowDefinitionView` mostram,
  no mesmo objeto/evento: **Conta (Account)** — trigger custom `AccountTrigger` (before+after
  insert/update) coexistindo com o trigger do CPQ `AccountBefore` (namespace `SBQQ`) e dois
  Flows `RecordAfterSave` (`AccountTriggered`, `UpdateParentAccountUsedLimit`); **Oportunidade
  (Opportunity)** — trigger custom `OpportunityTrigger` (after insert/update) + triggers do CPQ
  `OpportunityAfter`/`OpportunityBefore` + dois Flows `RecordAfterSave` (`Oportunidade_Industria`,
  `OpportunityFlow`); **Pedido (Order)** — trigger custom `OrderTrigger` (before+after update) +
  trigger do CPQ `OrderTrigger` (namespace `SBQQ`, before/after insert/update/delete) + Flow
  `RecordBeforeSave` e Flow `RecordAfterSave` (`Order`).
- **Risco:** ordem de execução entre múltiplos triggers e Flows no mesmo evento não é garantida
  pela plataforma; qualquer nova demanda em um desses três objetos corre risco real de recursão,
  race condition ou de quebrar um fluxo do CPQ sem ninguém perceber até o UAT.
- **Recomendação:** antes da próxima demanda que toque Account/Opportunity/Order, mapear a ordem
  de execução real (trigger nativo do CPQ roda antes ou depois do Flow?) e consolidar a automação
  própria em um único ponto de entrada por objeto (um handler ou um Flow orquestrador), documentando
  a interação com o CPQ em vez de adicionar mais um ponto de automação.
- **Esforço:** alto.

### 2. Cobertura de teste Apex em ~10% no org
- **Severidade:** alta
- **Área:** código
- **Evidência:** `SELECT PercentCovered FROM ApexOrgWideCoverage` retornou `10`.
  `ApexCodeCoverageAggregate` cruzado com as 54 classes custom mostra 76 linhas cobertas de 686
  nas 35 classes que têm algum registro de execução (11,1%) — as outras 19 "classes" sem registro
  são majoritariamente classes de teste/mock, não produção. Das 39 classes de produção custom,
  apenas 2 seguem a convenção `<Classe>Test` do `CLAUDE.md` raiz (`CreateQuoteCPQControllerTest`,
  `FlowOpportunityControllerTest`); classes centrais da integração com o ERP Protheus —
  `ProtheusAPI`, `SendAccountToProtheus`, `SendOrderToProtheus`, `OrderAdapter`,
  `OrderTriggerHandler`, `OrderUtility`, `Logger`, `StringUtility`, `TriggerUtility` — não têm
  nenhuma classe de teste identificável pelo nome.
- **Risco:** qualquer deploy real para produção fica abaixo do mínimo de 75% exigido pela
  Salesforce (ou já está); a integração com o ERP (Protheus) — que move pedido e financeiro —
  não tem rede de segurança de teste nenhuma hoje.
- **Recomendação:** priorizar teste da cadeia Protheus (Account/Order → ERP) antes de qualquer
  nova automação nesses objetos; adotar `<Classe>Test` como convenção daqui pra frente; rodar
  `sf apex run test --code-coverage` como gate antes de qualquer release, não só confiar no
  agregado do org.
- **Esforço:** alto.

### 3. Validation Rules do Pedido (Order): obrigatoriedade duplicada e máquina de estados abandonada
- **Severidade:** média
- **Área:** qualidade de config
- **Evidência:** `SELECT ValidationName, Active, ErrorMessage FROM ValidationRule WHERE
  EntityDefinition.QualifiedApiName = 'Order'` (Tooling) retornou 23 regras no total. Oito delas —
  `CheckOrderHasDeliveryDate`, `CheckOrderHasDispatchBranch`, `CheckOrderHasEffectiveDate`,
  `CheckOrderHasExpectedSaleDate`, `CheckOrderHasOperationType`, `CheckOrderHasShippingCompany`,
  `CheckOrderHasSpecies1`, `CheckOrderHasTypeShipping`, `CheckOrderHasVolume1` — têm a mesma
  mensagem genérica "Este campo precisa ser preenchido", o padrão clássico de regra replicando
  campo obrigatório. Outras seis — `CheckOrderCanHaveSecondStatus` até `CheckOrderCanHaveSeventhStatus`
  (exceto a primeira) — estão com `Active = false`, indicando uma máquina de estados de status do
  Pedido que foi desligada e nunca removida.
- **Risco:** manutenção redundante (9 regras a revisar a cada mudança de processo), erro só
  aparece ao salvar em vez de no campo; a configuração inativa confunde quem olha a lista de
  metadata sem saber se pode reativar ou remover com segurança.
- **Recomendação:** avaliar migrar as 8 regras de obrigatoriedade simples para "Required" no
  próprio campo (respeitando layout/record type); decidir explicitamente sobre as 6 regras
  inativas de status — remover ou documentar por que ficaram assim antes de mexer no processo de
  Pedido de novo.
- **Esforço:** médio.

### 4. Maioria dos campos custom em Account/Order/Opportunity sem descrição
- **Severidade:** média
- **Área:** modelo de dados
- **Evidência:** `SELECT TableEnumOrId, DeveloperName, Description FROM CustomField WHERE
  TableEnumOrId IN ('Account','Order','Opportunity','OrderItem')` (Tooling): 153 de 223 campos
  (68,6%) sem `Description` — 78 de 90 em Account, 53 de 64 em Order, 19 de 28 em Opportunity,
  3 de 41 em OrderItem.
- **Risco:** ninguém novo no time (nem agente, nem consultor) sabe pra que serve a maioria dos
  campos de Account e Order sem perguntar para quem construiu; risco de depreciar campo em uso
  ou duplicar campo que já existe com outro nome.
- **Recomendação:** sessão de curadoria com o time de negócio priorizando Account e Order (maior
  volume de campos sem descrição); qualquer campo novo criado nas próximas demandas já sai com
  `Description` preenchida.
- **Esforço:** médio.

### 5. Convenção de nome de classe de teste não seguida
- **Severidade:** média
- **Área:** código
- **Evidência:** das 15 classes de teste/mock custom, 13 usam o prefixo `Test<Classe>` (ex.
  `TestAccountUtility`, `TestSendAccountToProtheus`) em vez do sufixo `<Classe>Test` exigido pelo
  `CLAUDE.md` raiz; só 2 seguem o padrão (`CreateQuoteCPQControllerTest`,
  `FlowOpportunityControllerTest`). Ver evidência completa no achado 2.
- **Risco:** ferramentas e agentes que procuram `<Classe>Test` para localizar a classe de teste de
  uma classe de produção não vão encontrar a maioria; reforça o problema de cobertura do achado 2.
- **Recomendação:** ao tocar em qualquer classe existente por causa de uma demanda nova, já
  renomear/criar a classe de teste seguindo `<Classe>Test` — não precisa ser big-bang.
- **Esforço:** médio.

### 6. Alias `sbx-eplast-dev` conectado a uma sandbox cujo usuário e instância se identificam como "qa"
- **Severidade:** média
- **Área:** dívida técnica
- **Evidência:** `sf org display --target-org sbx-eplast-dev` retorna
  `username: projetos@konectabr.com.eplast2.qa` e
  `instanceUrl: https://eplast--qa.sandbox.my.salesforce.com` — ou seja, o alias usado pela esteira
  para o ambiente **dev** aponta para uma sandbox cujo próprio nome/usuário indica **qa**.
- **Risco:** o `CLAUDE.md` raiz depende de dev e qa serem dois ambientes fisicamente distintos
  (`ambientes.py` valida por nome de alias, não por conteúdo); se essa sandbox for de fato a
  mesma usada como QA, builds de demanda e o roteiro de QA podem estar competindo no mesmo
  ambiente sem que ninguém tenha decidido isso.
- **Recomendação:** confirmar com o time do cliente/BASIS se existe uma segunda sandbox distinta
  para `sbx-eplast-qa`, ou se o alias de dev foi apontado para a sandbox errada na conexão inicial.
  Não é algo que este assessment pode corrigir sozinho — é read-only por definição.
- **Esforço:** baixo (é uma checagem, não uma migração) — mas bloqueante para confiar na separação
  dev/qa até confirmar.

### 7. Perfil custom "Financeiro" atribuído a exatamente 1 usuário ativo
- **Severidade:** baixa
- **Área:** segurança
- **Evidência:** `SELECT Profile.Name, COUNT(Id) FROM User WHERE IsActive = true GROUP BY
  Profile.Name` retornou `Financeiro | 1`, entre os únicos perfis de negócio com usuário ativo
  (`Administrador do sistema`: 8, `Comercial - Analista`: 5, demais são perfis de integração de
  sistema com 1 usuário cada, o que é esperado para licenças técnicas).
- **Risco:** perfil-por-pessoa é difícil de auditar e de dar manutenção; quando a pessoa sai, o
  perfil geralmente fica órfão ou é copiado para o próximo sem revisão.
- **Recomendação:** migrar as permissões específicas do perfil Financeiro para um permission set
  sobre um perfil-base comum.
- **Esforço:** baixo.

### 8. 33 perfis no org, com nomenclatura de negócio inconsistente
- **Severidade:** baixa
- **Área:** segurança
- **Evidência:** `sf org list metadata --metadata-type Profile` retorna 33 perfis; entre os que
  parecem de negócio (não padrão/integração) aparecem `Comercial`, `Comercial - Analista`,
  `Comercial - Analistas` (singular e plural coexistindo) e `Comercial Padrão` — quatro variações
  do mesmo time comercial.
- **Risco:** dá pra confundir qual perfil é o vigente; sugere que permissão foi resolvida no
  perfil (concedendo um perfil novo por variação de cargo) em vez de permission set, o que o
  `CLAUDE.md` raiz já trata como prática a evitar.
- **Recomendação:** consolidar os perfis comerciais em um perfil-base + permission sets por
  variação de função; confirmar com o cliente se `Comercial - Analista` e `Comercial - Analistas`
  são o mesmo perfil duplicado por engano.
- **Esforço:** médio.

### 9. Classes Apex custom em API version bem atrás da org
- **Severidade:** baixa
- **Área:** código
- **Evidência:** distribuição de `ApiVersion` nas 54 classes custom: v58 (10), v59 (36), v61 (6),
  v64 (2) — nenhuma em v65 ou mais recente, enquanto a org roda em v67.
- **Risco:** comportamento de runtime fixado em versão antiga (ex. serialização, contexto de
  segurança) pode surpreender quando a classe for finalmente editada.
- **Recomendação:** ao editar qualquer classe existente por causa de uma demanda nova, subir a
  API version antes de mexer na lógica, com teste de regressão cobrindo o comportamento anterior.
- **Esforço:** baixo (mas recorrente).

### 10. Nome de trigger duplicado entre o pacote CPQ e a customização própria
- **Severidade:** baixa
- **Área:** dívida técnica
- **Evidência:** `SELECT Id, Name, TableEnumOrId, NamespacePrefix FROM ApexTrigger WHERE Name =
  'OrderTrigger'` retorna dois registros ativos: um com `NamespacePrefix = SBQQ` (api 57) e outro
  sem namespace (api 59, o custom do cliente), ambos no objeto `Order`.
- **Risco:** buscar "OrderTrigger" no código, em log de erro de Apex ou em stack trace é ambíguo —
  fica difícil saber de cara qual dos dois causou um efeito colateral.
- **Recomendação:** renomear o trigger customizado para algo inequívoco (ex. `EplastOrderTrigger`)
  na próxima janela de manutenção desse objeto.
- **Esforço:** baixo.

## Não pôde ser medido

- **Uso real de campos custom** (quais dos 223 campos analisados são de fato lidos/escritos por
  layout, relatório ou integração) — não há um comando `sf` simples para isso sem Salesforce
  Optimizer ou Field Trip instalados; não tentado por não termos certeza de que esses apps estão
  na org e por fugir do escopo read-only simples desta rodada.
- **Layouts órfãos** — a org tem 311 Page Layouts; determinar quais não estão atribuídos a
  nenhuma combinação Profile × Record Type exigiria retrieve e parsing de todos os 33 perfis
  (`layoutAssignments`), volume grande demais para esta rodada. Fica como próximo passo.
- **Sharing Settings (Organization-Wide Default) por objeto** — `sf org list metadata
  --metadata-type SharingRules` retornou apenas a lista de 287 objetos elegíveis a regras de
  compartilhamento (indício de que não estão em Public Read/Write), não o OWD configurado nem as
  regras em si. Precisaria retrieve de `Settings` ou da Tooling API de `Organization`, não feito
  por tempo.
- **API version dos 25 Flows custom** — a Tooling API rejeitou `SELECT ApiName, VersionNumber
  FROM Flow` (`INVALID_FIELD`); não persegui um caminho alternativo (ex. metadata retrieve
  individual de cada Flow) dentro do escopo desta rodada.
- **Cobertura de teste dos 3 Apex Triggers custom especificamente** — os Ids de
  `AccountTrigger`, `OpportunityTrigger` e `OrderTrigger` não apareceram nos 38 registros
  retornados por `ApexCodeCoverageAggregate`; não confirmei se isso significa 0% de cobertura ou
  se o dado simplesmente não foi recalculado recentemente.
- **Volume de dados e uso de licença em produção** — esta sandbox de dev está vazia (0
  Account/Contact/Opportunity) e os números de `UserLicense` (ex. 14/14 de licença Salesforce)
  refletem a alocação da própria sandbox, não de produção; por definição desta etapa, org de
  produção não foi e não deve ser consultada.
