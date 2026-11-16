**Resultado do build:** concluído

# EPLAST-40: Plano de build

**Org:** `sbx-eplast-dev` (Sandbox, Org ID `00DHa000006vfMLMAY`, a "QA" da Eplast, regra 5 do cliente), conferida por `sf org list`. Branch `feature/EPLAST-40`. Gate de design aprovado em `gates.md` (2026-11-15). Deploy ID `0AfHa00000EI1OzKAL` falhou na 1a tentativa e a 2a passou (ver "Ajustes no deploy").

## Componentes criados/alterados (caminhos em `force-app/main/default/`)

| Componente | Tipo | Caminho | Situação |
|---|---|---|---|
| `Case.Oportunidade__c` | Lookup(Opportunity), opcional, SetNull, related list "Casos de Pós-vendas" | `objects/Case/fields/Oportunidade__c.field-meta.xml` | criado, com descrição |
| `PosVendas` ("Pós-vendas") | Queue, `QueueSobject` Case, sem membros (PD4) | `queues/PosVendas.queue-meta.xml` | criada |
| `Opportunity_BeforeSave_QualificaOportunidade` | Flow before-save, Create/Update | `flows/Opportunity_BeforeSave_QualificaOportunidade.flow-meta.xml` | novo, Active (design seção 11) |
| `Opportunity_AfterSave_CriaCasoPosVendas` | Flow after-save, caminho assíncrono (`AsyncAfterCommit`) | `flows/Opportunity_AfterSave_CriaCasoPosVendas.flow-meta.xml` | novo, Active |
| `PS_PosVendas_Atendimento` | Permission Set (leitura de `Case.Oportunidade__c` e de Opportunity) | `permissionsets/PS_PosVendas_Atendimento.permissionset-meta.xml` | criado |
| `Case.PosVendas_Fila` | ListView (fila `PosVendas`, casos abertos) | `objects/Case/listViews/PosVendas_Fila.listView-meta.xml` | criado |
| Layout `Opportunity-Opportunity Layout` | related list `Case.Oportunidade__c` (Número, Assunto, Status, Criado em) | `layouts/Opportunity-Opportunity Layout.layout-meta.xml` | alterado |

Detalhes dos Flows:
- Before-save: entrada por fórmula `ISPICKVAL(StageName,"Qualificação") E Discovery_Completed__c E Budget_Confirmed__c`; ação `StageName = Qualificado` no próprio `$Record`. Sem consulta, DML ou envio.
- After-save: entrada `StageName = Fechado/Ganho` com "só quando passa a atender" (`doesRequireRecordChangedToMeetCriteria`). Tudo no caminho assíncrono: consulta Case com `Oportunidade__c = $Record.Id`; se não houver, consulta a fila por `DeveloperName = PosVendas` (sem Id fixo) e cria o Case (`Oportunidade__c`, `AccountId`, `ContactId`, `OwnerId` = fila, `Status = New`, `Subject` = "Pós-vendas: " + nome). Os 3 elementos de dados têm fault connector para uma Assignment de encerramento (não afeta a venda). Sem `actionCalls`, e-mail ou mensagem.

## Layouts: desvio do design (registrar)
O design previa alterar o layout de cada um dos 6 record types. Pela atribuição na org (`ProfileLayout`, Tooling), só existem 2 layouts em uso: `Opportunity Layout` (todos os record types e o padrão) e `CPQ Opportunity Layout` (RT `012bJ000000m049QAA`, 32 perfis). O `CPQ Opportunity Layout` é **instalado do pacote SBQQ (managed)** e não pode ser alterado. Consequência: nos 32 perfis atribuídos ao CPQ layout nesse RT, a related list **não aparece** (o vínculo e o Case continuam funcionando; os 4 perfis restantes do mesmo RT usam `Opportunity Layout`). Alternativa fora desta entrega: criar layout próprio e reatribuir (mexe em atribuição de 32 perfis). Para o verificador/QA: provar o vínculo por `Case.Oportunidade__c`, não só pela related list. Rollback do layout: reimplantar a versão anterior do arquivo pelo git (`git show main:...`).

## Ajustes no deploy (1a tentativa falhou)
- Fórmula do before-save: `StageName` é picklist, trocada para `ISPICKVAL`.
- Scheduled path `AsyncAfterCommit` não aceita `label`; removido.

## Reaproveitado (sem alteração)
`Lead.Status`/`LeadSource`, conversão padrão e `Lead.ConvertedDate`/`ConvertedOpportunityId` (PD1), `Case.CreatedDate` (PD2), Flow `Order`, `OpportunityFlow`, `Oportunidade_Industria`, `OpportunityTrigger`, `OrderTrigger`, `SBQQ.*`, `Discovery_Completed__c`, `Budget_Confirmed__c`, `Opportunity.ContactId`/`AccountId`. `SFAgent2` não se aplica. Nenhum Flow, classe ou agente existente editado, logo sem versão nova.

## Evidência de confirmação na org (só metadata e contagens)
- Antes do build: 0 campo `%Oportunidade%` em Case, 0 fila `PosVendas`, 0 permission set `PS_PosVendas_Atendimento`, 0 Flow `Opportunity_%Save%`/`%PosVendas%` (nada a sobrepor).
- `OpportunityStage` ativos: confirmados `Qualificação`, `Qualificado`, `Fechado/Ganho` (valores exatos usados nos Flows).
- Depois do deploy: fila `PosVendas` com contagem 1.
- Sem Marketing Cloud: nenhum componente toca `et4ae5`, opt-out ou envio.

## Premissas assumidas usadas (do `03-design.md`)
PD1 (sem campo de data em Opportunity), PD2 (`Case.CreatedDate`), PD3 (todos os record types, sem filtro), PD4 (fila sem membros; sem username no metadata), PD6 (estágio inicial `Qualificação`, a provar na conversão), PD7 (conteúdo do Case). PD5 e R1/R2 afetam a fixture de teste, não o build.

## Regressão Apex (design A2)
Classes de teste locais que citam Opportunity: `FlowOpportunityControllerTest` e `CreateQuoteCPQControllerTest`.
- `FlowOpportunityControllerTest`: **passou** (2 testes, 100%) com os Flows novos ativos.
- `CreateQuoteCPQControllerTest`: 2 de 3 falham com `FIELD_CUSTOM_VALIDATION_EXCEPTION, CNPJ incompleto ou inválido: [CompanyDocument__c]` no insert da **Conta** da fixture do teste, antes de qualquer Opportunity ser salva. Os Flows novos só disparam em Opportunity, então a causa parece ser a validação de CNPJ pré-existente. Não foi feita a rodada "antes" (os Flows já estavam ativos), então isto é inferência: a verificação deve confirmar desativando os 2 Flows e repetindo o teste, ou tratar como falha pré-existente da org.

## Para a verificação testar
Plano de testes do design (seção 9): conversão do Lead (RN3, PD5/PD6), promoção a `Qualificado` (inclui prova de R4, `SBQQ.OpportunityBefore` não reescrever `StageName`), fechamento até `Fechado/Ganho` com 1 Case na fila e sem duplicata, bulk de 200 e CPU com 150 itens (critério 70%), inspeção do XML sem envio, opt-out inalterado, GroupMember da fila (PD4 = pendência do cliente se 0), permissão. Os 2 Flows nasceram Active; para desfazer, desativar cada um. Atenção ao layout: related list invisível nos perfis do CPQ layout (ver acima).

## Commit
Branch `feature/EPLAST-40`; commit `EPLAST-40: construir ciclo de pos-vendas`. Sem PR nesta etapa.

## Correções da rodada 1
Lida `05-testes-rodada-1.md` (reprovado). Nenhuma alteração de metadata nesta rodada: as duas falhas não são corrigíveis no build, e os casos aprovados (T1, T2, T4 a T10, T12) não foram tocados.

- **FALHA 1 (conversão de Lead barrada pela validation rule `PriceBook`):** não corrigível aqui. A regra é pré-existente e o design (seção 10 e PD5) deixa explícito que revisar as validation rules que barram a conversão está fora do escopo. Alterá-la mudaria o comportamento de Opportunity da Eplast inteira, o que não está na solução aprovada. Nenhum componente da EPLAST-40 participa da falha: a conversão falha antes de qualquer Flow novo. Caminho para provar o critério: converter com usuário cujo RT padrão seja `Industria` (a regra só barra RT diferente de `Industria`), conforme o plano de testes do design (item 2, conversão com RT `Industria`), como ajuste de fixture e de execução do QA, não de build. Se a Eplast quiser a conversão no RT Venda, é decisão dela sobre a regra (PD5), registrada como premissa a confirmar na homologação.
- **FALHA 2 (fila `PosVendas` sem membros):** não corrigível aqui. É a PD4 do design: a fila nasce sem membros e a Eplast define quem atende, sem username no metadata (LGPD, guardrail 2). Adicionar membro exigiria escolher pessoas, o que é decisão do cliente. O Case já cai na fila e fica visível na list view `PosVendas_Fila`. Segue como pendência de homologação do cliente.

## Correções da rodada 2
Lida `05-testes-rodada-2.md` (reprovado). Org conferida: `sbx-eplast-dev`. Nenhuma alteração de metadata nesta rodada. Os casos aprovados (T1, T2, T3b, T4 a T10, T12) não foram tocados, e os 2 Flows seguem na versão 2.

- **FALHA 1 (conversão de Lead criando Oportunidade barrada pela validation rule `PriceBook`):** não corrigível no build. A regra é pré-existente. O design (seção 10, item 2 do plano de testes e PD5) já prevê que o barramento no RT padrão `Sale` seja registrado e que revisar as validation rules da conversão fique fora do escopo. Alterá-la mudaria o comportamento de toda a Opportunity da Eplast, o que a solução aprovada não cobre, e eu não improviso solução diferente da aprovada. Nenhum componente da EPLAST-40 participa da falha, porque a conversão falha antes de qualquer Flow novo. A prova do critério (Oportunidade nasce em `Qualificação`, PD6) depende de ajuste de execução do QA: usuário cujo RT padrão seja `Industria`, ou conversão feita pela interface com esse RT. A conversão para Oportunidade existente (T3b) já passou. Se a Eplast quiser a conversão no RT Venda, a decisão sobre a regra é dela, na homologação (premissa PD5, a confirmar).
- **FALHA 2 (fila `PosVendas` sem membros):** não corrigível no build. É a PD4: a fila nasce sem membros e a Eplast define quem atende, sem username no metadata (LGPD, guardrail 2). O Case cai na fila e aparece na list view `PosVendas_Fila`. Segue como pendência de homologação do cliente.
