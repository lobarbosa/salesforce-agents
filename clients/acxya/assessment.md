# Assessment da org — Konecta (acxya)

**Org auditada:** sbx-acxya-dev (`https://acxya--sbxacxya.sandbox.my.salesforce.com`) · **API:** v67.0 · **Data:** 2026-09-13
**Saúde geral:** vermelho

Confirmado via `sf org display --target-org sbx-acxya-dev` e `sf org list`: única org conectada
deste cliente, tipo `Sandbox`, status `Connected`, Org Id `00DHa000006bRsDMAU`. Produção não está
configurada (não foi e não será tocada). Sandbox de QA ainda não existe. Todo o recon abaixo foi
feito com `sf data query` (Tooling API onde aplicável) e `sf project retrieve` — nenhum comando de
escrita (`deploy`, DML, anonymous Apex) foi executado.

## Veredito em três linhas

A org é dominada por seis pacotes gerenciados (Marketing Cloud Connect/`et4ae5`, integração de
WhatsApp/`ChatIntegration`, `sfcma`, `CHANNEL_ORDERS`, `KPIapp`, `sfLma` — Salesforce License
Manager) — o cliente não tem praticamente nenhum objeto custom próprio, e a automação nativa que
existe (16 Flows ativos, todos sem namespace) já tem pontos reais de concorrência: três Flows
disputam o mesmo evento (criação/atualização) em `Task`, e dois brigam pela mesma atualização em
`Contact`. Segurança está com quase um perfil customizado por usuário ativo (11 perfis distintos
para 16 usuários) e sharing aberto (`Account`/`Lead`/`Case` em leitura-escrita ampla), e todo o
parque Apex — customizado e de pacote — aparece como `IsValid = false` na Tooling API, o que
precisa ser confirmado (cache de compilação vencido vs. erro real) antes de qualquer deploy.
Nada aqui impede começar demandas, mas a primeira demanda de automação em `Task`, `Contact` ou
`Lead` precisa mapear os Flows existentes antes de somar mais um ponto de disparo.

## Inventário

| Área | Item | Medido | Comando |
|---|---|---|---|
| Automação | Flow — definições totais | 57 (25 sem namespace/custom, 32 de pacote: et4ae5=13, sfcma=10, ChatIntegration=5, CHANNEL_ORDERS=3, KPIapp=1) | `SELECT DeveloperName, NamespacePrefix FROM FlowDefinition` (Tooling) |
| Automação | Flows custom — por status | 16 Active, 3 Draft, 6 Obsolete (de 25) | retrieve `Flow` + grep `<status>` |
| Automação | Process Builder ativos | 0 | `SELECT COUNT() FROM Flow WHERE ProcessType='Workflow'` (Tooling) |
| Automação | Workflow Rules | 27 (100% em objetos de pacote gerenciado — nenhuma em objeto padrão ou custom próprio) | `SELECT TableEnumOrId FROM WorkflowRule` (Tooling) |
| Automação | Apex Triggers | 34 (100% de pacote gerenciado — 0 sem namespace) | `SELECT Name, NamespacePrefix, TableEnumOrId FROM ApexTrigger` |
| Código | Apex Classes — total org | 1.137 | `SELECT COUNT() FROM ApexClass` |
| Código | Apex Classes — customizadas (sem namespace) | 20 (10 controllers + 10 `<Classe>Test`, todos boilerplate de Sites/Communities: login, self-registration, troca de senha) | `SELECT Name, NamespacePrefix FROM ApexClass WHERE NamespacePrefix = null` |
| Código | Cobertura de teste — org-wide | 0% | `SELECT PercentCovered FROM ApexOrgWideCoverage` (Tooling) |
| Código | Cobertura por classe (10 controllers custom) | 0 linhas cobertas em todas as 10 | `SELECT ... FROM ApexCodeCoverageAggregate` (Tooling) |
| Código | API version — classes custom | v57 (org está em v67; 10 versões atrás) | `SELECT ApiVersion FROM ApexClass WHERE NamespacePrefix=null` |
| Código | API version — Flows custom | varia de v56 a v67 | grep `<apiVersion>` nos 25 Flow retrieved |
| Modelo de dados | Objetos custom (`__c`) | 84 total — **0 sem namespace** (et4ae5=24, ChatIntegration=20, sfcma=18, CHANNEL_ORDERS=13, KPIapp=6, sfLma=3) | `SELECT QualifiedApiName, NamespacePrefix FROM EntityDefinition WHERE IsCustomizable=true` |
| Modelo de dados | Campos por objeto-chave | Lead 86, Contact 63, Opportunity 89, Account 68, Case 68 | `SELECT COUNT() FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName='<obj>'` |
| Modelo de dados | Campos custom próprios (sem namespace) nesses 5 objetos | 101 (Lead 27, Contact 5, Opportunity 35, Account 22, Case 12) | `SELECT QualifiedApiName, Description, NamespacePrefix FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName='<obj>'` |
| Modelo de dados | Desses 101, sem descrição preenchida | 72 (71%) — Lead 20/27, Contact 5/5, Opportunity 17/35, Account 18/22, Case 12/12 | mesmo comando acima |
| Segurança | Perfis | 25 total (inclui 5 perfis Guest de sites/surveys: `surveys`, `surveys2`, `survey`, `Atendimento Konecta Perfil`, `WP callback url Profile`) | `SELECT COUNT() FROM Profile` |
| Segurança | Permission Sets (não vinculados a perfil) | 94 | `SELECT COUNT() FROM PermissionSet WHERE IsOwnedByProfile=false` |
| Segurança | Permission Set Groups | 4 | `SELECT COUNT() FROM PermissionSetGroup` |
| Segurança | Usuários ativos × perfis distintos em uso | 16 usuários ativos, 11 perfis distintos (a maioria com exatamente 1 usuário) | `SELECT Profile.Name, COUNT(Id) FROM User WHERE IsActive=true GROUP BY Profile.Name` |
| Segurança | Org-Wide Defaults | Account=Edit, Opportunity=Read, Contact=ControlledByParent, Case=ReadEditTransfer, Lead=ReadEditTransfer | `SELECT Default*Access FROM Organization` |
| Qualidade de config | Validation Rules | 63 total — 41 ativas, 22 inativas (35%) | `SELECT Active, COUNT(Id) FROM ValidationRule GROUP BY Active` (Tooling) |
| Qualidade de config | Record Types | 21 | `SELECT COUNT() FROM RecordType` |
| Qualidade de config | Flow com versão `InvalidDraft` | 1 (`[Caso] Automação de Direto, Origem e Prioridade`) | `SELECT MasterLabel, Status FROM Flow WHERE Status='InvalidDraft'` |
| Limites | Data Storage | 0 MB usados de 200 MB (0%) — sandbox, não representa produção | `sf org list limits` |
| Limites | File Storage | 0 MB usados de 200 MB (0%) — idem | `sf org list limits` |
| Limites | Daily API Requests | 176 de 101.000 usados (~0,17%) | `sf org list limits` |
| Limites | Licenças com uso 100% | Analytics Cloud Integration User (2/2), Salesforce (2/2) — restante com folga | `SELECT Name, TotalLicenses, UsedLicenses FROM UserLicense` |
| Dívida técnica | ApexClass com `IsValid=false` | 950 de 1.137 (inclui as 20 customizadas e praticamente todo pacote gerenciado) | `SELECT Name, NamespacePrefix FROM ApexClass WHERE IsValid=false` |
| Dívida técnica | ApexTrigger com `IsValid=false` | 33 de 34 | `SELECT COUNT() FROM ApexTrigger WHERE IsValid=false` |

## Achados

### 1. Três Flows ativos disputam o mesmo evento (criação/atualização) em Task
- **Severidade:** alta
- **Área:** automação
- **Evidência:** retrieve de `Flow` + inspeção de `<object>`/`<triggerType>`/`<recordTriggerType>`/`<status>`:
  `Count_de_Tasks_Pendentes` (Task, RecordAfterSave, CreateAndUpdate, Active), `Count_de_Tasks_Pendentes_para_Opp`
  (Task, RecordAfterSave, CreateAndUpdate, Active) e `Oportunidades_Envio_Email` (Task, RecordAfterSave,
  CreateAndUpdate, Active). Um quarto Flow no mesmo objeto/evento (`Oportunidades_Follow_Up`) está Obsolete.
- **Risco:** ordem de execução não determinística entre os três, race condition em campos de contagem,
  e qualquer alteração futura em um deles pode quebrar a lógica dos outros dois sem que ninguém perceba
  — exatamente o cenário que o assessment existe para evitar descobrir na terceira demanda.
- **Recomendação:** consolidar os três Flows de Task num único Flow (ou Flow + subflows) antes de aceitar
  qualquer nova demanda de automação em Task; documentar a ordem de execução esperada enquanto isso não
  acontece.
- **Esforço:** médio

### 2. Dois Flows ativos na mesma atualização de Contact
- **Severidade:** média
- **Área:** automação
- **Evidência:** `Lead_AfterSave_MapeiaAniversarioNaConversao` (Contact, RecordAfterSave, Update, Active)
  e `Oportunidade_Validar_Contato_na_Conta` (Contact, RecordAfterSave, Update, Active).
- **Risco:** mesmo risco de ordem/concorrência do achado 1, em escala menor.
- **Recomendação:** avaliar fusão dos dois numa próxima janela de manutenção; não é bloqueante para
  demandas novas, mas registrar a dependência.
- **Esforço:** baixo

### 3. Lead tem dois Flows ativos + um trigger de pacote gerenciado no mesmo evento de criação
- **Severidade:** média
- **Área:** automação
- **Evidência:** `Update_Atividades_Pendentes` (Lead, RecordAfterSave, CreateAndUpdate, Active) e
  `Leads_do_Marketing_Cloud` (Lead, RecordAfterSave, Create, Active) — mais o trigger `updatePackages`
  do pacote `sfLma` no objeto `Lead`, `Status=Active`.
- **Risco:** qualquer nova automação de Lead soma um quarto ponto de disparo sem visibilidade do que
  já existe, incluindo lógica de pacote que o time não controla diretamente.
- **Recomendação:** antes de qualquer demanda de automação em Lead, mapear explicitamente os três pontos
  (dois Flows + trigger de pacote) e decidir onde a nova lógica entra.
- **Esforço:** baixo

### 4. Quase um perfil customizado por usuário ativo
- **Severidade:** média
- **Área:** segurança
- **Evidência:** `SELECT Profile.Name, COUNT(Id) FROM User WHERE IsActive=true GROUP BY Profile.Name`
  retornou 16 usuários ativos distribuídos em 11 perfis distintos — a maioria dos perfis (`Administrador
  do sistema`, `Usuário Padrão`, `Analytics Cloud Security User`, `Sales Insights Integration User`,
  `WP callback url Profile`, `Chatter Free User`, `Identity User`, `surveys2 Perfil`, `survey Perfil`,
  `Atendimento Konecta Perfil`, `Analytics Cloud Integration User`) tem exatamente 1 usuário.
- **Risco:** manutenção de permissão vira manutenção de pessoa — qualquer ajuste de acesso exige mexer
  em perfil individual em vez de permission set, e sair/entrar gente vira trabalho de metadata.
- **Recomendação:** migrar a diferenciação de acesso hoje capturada em perfil individual para permission
  sets/permission set groups sobre um perfil-base menor (a org já tem 94 permission sets e 4 grupos
  disponíveis — a estrutura para isso já existe, falta usá-la).
- **Esforço:** médio

### 5. Toda a base Apex (custom e de pacote) reporta `IsValid = false` na Tooling API
- **Severidade:** média
- **Área:** dívida técnica
- **Evidência:** `SELECT Name, NamespacePrefix FROM ApexClass WHERE IsValid = false` retornou 950 de
  1.137 classes — as 20 customizadas sem namespace **e** praticamente todo o código dos 6 pacotes
  instalados. `SELECT COUNT() FROM ApexTrigger WHERE IsValid = false` retornou 33 de 34. As 20 classes
  customizadas continuam com `Status = Active`, o que sugere fortemente um cache de compilação
  desatualizado (comum após refresh de sandbox) em vez de 950 componentes de fato quebrados — mas isso
  não foi confirmado, porque confirmar exigiria recompilar (`Setup > Apex Classes > Compile all classes`)
  ou rodar um deploy validate, ações que ficam fora do escopo read-only deste assessment.
- **Risco:** se for cache, é inofensivo; se for erro real em algum ponto, um deploy futuro nessa sandbox
  pode falhar ou se comportar de forma inesperada sem aviso prévio.
- **Recomendação:** antes do primeiro build nesta org, rodar `Compile all classes` no Setup (ação do
  humano, fora do escopo deste agente) e/ou um `sf project deploy validate` de um pacote mínimo para
  confirmar se o estado é real ou só cache.
- **Esforço:** baixo

### 6. 71% dos campos customizados nos objetos-chave estão sem descrição
- **Severidade:** média
- **Área:** modelo de dados
- **Evidência:** nos 5 objetos padrão mais usados (Lead, Contact, Opportunity, Account, Case), 101 campos
  customizados sem namespace foram encontrados; 72 deles (71%) não têm `Description` preenchida
  (Lead 20/27, Contact 5/5, Opportunity 17/35, Account 18/22, Case 12/12 sem descrição).
- **Risco:** ninguém novo no time sabe pra que serve o campo sem abrir o Flow ou o layout que o usa —
  cada demanda futura de dados vai gastar tempo redescobrindo o que já existe.
- **Recomendação:** antes de criar campo novo em qualquer um desses 5 objetos, documentar retroativamente
  os campos que a demanda vai tocar; não precisa ser um projeto à parte, mas vira parte do 02-recon.md
  de cada demanda que passar por lá.
- **Esforço:** médio

### 7. Cobertura de teste Apex agregada em 0%
- **Severidade:** média
- **Área:** código
- **Evidência:** `SELECT PercentCovered FROM ApexOrgWideCoverage` retornou 0. Por classe,
  `ApexCodeCoverageAggregate` mostra 0 linhas cobertas em todas as 10 classes customizadas com lógica
  (`CommunitiesSelfRegController`, `MicrobatchSelfRegController`, `SiteRegisterController`, etc.), apesar
  de cada uma ter uma `<Classe>Test` correspondente.
- **Risco:** não dá para saber se os testes existentes ainda passam ou se cobrem alguma coisa de verdade
  sem rodá-los — e este agente não roda testes (executar Apex, mesmo de teste, sai do escopo read-only
  desta etapa).
- **Recomendação:** próxima etapa de QA/build deve rodar `sf apex run test` numa sandbox e confirmar
  cobertura real antes de assumir que os testes existentes protegem algo; se a cobertura por classe se
  confirmar em 0%, essas 10 classes de teste precisam de revisão (podem estar vazias ou desatualizadas).
- **Esforço:** médio

### 8. Org-Wide Defaults abertos em objetos com múltiplos perfis Guest ativos
- **Severidade:** baixa
- **Área:** segurança
- **Evidência:** `SELECT Default*Access FROM Organization` — `Account=Edit` (Public Read/Write),
  `Case=ReadEditTransfer`, `Lead=ReadEditTransfer`. A org tem 5 perfis do tipo Guest ativos (sites de
  survey e atendimento).
  Comando: `SELECT DefaultAccountAccess, DefaultOpportunityAccess, DefaultContactAccess,
  DefaultCaseAccess, DefaultLeadAccess FROM Organization`.
- **Risco:** sharing aberto não é automaticamente um problema, mas combinado com múltiplos perfis
  Guest voltados para fora, vale confirmar que nenhum desses perfis herda mais acesso do que o
  pretendido via OWD.
- **Recomendação:** revisar especificamente o que cada perfil Guest consegue enxergar hoje via OWD +
  sharing rules antes de expor qualquer objeto novo a um site público.
- **Esforço:** baixo

### 9. Classes Apex customizadas 10 versões de API atrás da org
- **Severidade:** baixa
- **Área:** código
- **Evidência:** as 20 classes customizadas (controllers de login/self-registration de Sites/Communities)
  estão todas em API v57; a org está em v67. Flows customizados variam de v56 a v67 — 12 dos 25 Flows
  custom estão em v57 ou anterior.
- **Risco:** classes/Flows em API antiga não pegam correções de segurança e comportamento mais recentes
  do runtime, e ficam mais longe de qualquer atualização de bulkificação/limits feita por versão.
- **Recomendação:** ao tocar em qualquer uma dessas classes/Flows por outro motivo, subir a API version
  para a atual como parte do mesmo PR (não abrir demanda só para isso).
- **Esforço:** baixo

### 10. 35% das Validation Rules estão inativas
- **Severidade:** baixa
- **Área:** qualidade de config
- **Evidência:** `SELECT Active, COUNT(Id) FROM ValidationRule GROUP BY Active` → 41 ativas, 22 inativas
  de um total de 63.
- **Risco:** regra inativa é ambígua — ninguém sabe se foi desligada de propósito ou esquecida, e some do
  radar até alguém tentar reativar sem saber por que foi desligada.
- **Recomendação:** revisão pontual das 22 regras inativas: arquivar (deletar) as que não servem mais,
  documentar o motivo das que ficam.
- **Esforço:** baixo

## Não pôde ser medido

- **Cobertura de teste real (execução):** só o valor agregado já registrado em `ApexOrgWideCoverage`/
  `ApexCodeCoverageAggregate` foi lido — não rodei `sf apex run test` porque isso executa Apex, e o
  guardrail read-only desta etapa não distingue "é só teste" de "é execução". O 0% relatado pode estar
  desatualizado (a tabela só reflete a última execução de teste na org, que pode nunca ter ocorrido nesta
  sandbox após o último refresh).
- **Se `IsValid=false` é erro real ou cache de compilação:** confirmar isso exigiria recompilar as classes
  (`Compile all classes` no Setup) ou tentar um deploy validate — ambos fora do escopo read-only. Reportado
  como está, com a ressalva de que `Status=Active` nas classes customizadas sugere cache, não quebra real.
- **Uso de Data/File Storage representativo de produção:** os 200 MB de limite desta sandbox são uma
  alocação fixa de ambiente de desenvolvimento, não uma fração do storage de produção — não há como
  inferir o uso real de produção a partir daqui, e produção não está conectada nem pode ser tocada.
- **Uso de licenças representativo de produção:** mesma ressalva — números de licença numa sandbox
  refletem o snapshot do momento do último refresh, não o consumo atual de produção.
- **Inventário completo de campos sem descrição em todos os objetos da org:** `FieldDefinition` via
  Tooling API exige filtrar por `EntityDefinitionId`/`EntityDefinition.QualifiedApiName` objeto a objeto —
  não há uma consulta agregada única. Cobri os 5 objetos padrão mais prováveis de receber demanda
  (Lead, Contact, Opportunity, Account, Case); os demais ~1.400 sobjects visíveis na org (a maioria de
  pacote gerenciado) não foram varridos campo a campo.
- **Page layouts órfãos e record types sem uso real:** contei Record Types (21) mas não cruzei com
  atribuição por perfil/uso em registros — precisaria de mais tempo de recon dedicado por objeto.
- **Segmento/indústria, marcas atendidas e contatos principais do cliente:** não são metadata da org,
  seguem como "a confirmar" no `CLAUDE.md` do cliente — fora do escopo deste assessment técnico.
