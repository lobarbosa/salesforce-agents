**Resultado do build:** concluído

# EPLAST-35 — Plano de build

**Org de build:** `sbx-eplast-dev` (sandbox, `IsSandbox = true`, "eplast--qa" da Eplast, API 68.0). Nada tocado na QA da esteira, nem em produção. Branch `feature/EPLAST-35`.
Tudo foi construído conforme o `03-design.md`; nenhuma pergunta de negócio ficou sem resposta (todas são premissas PA-01 a PA-19 do design).

## 1. O que foi criado ou alterado (e implantado na dev)

| Componente | Ação | Arquivo |
|---|---|---|
| Classe `LeadAssignmentService` (`@InvocableMethod aplicarRegraPadrao`, `without sharing` justificado no cabeçalho, API 68.0) | Cria | `force-app/main/default/classes/LeadAssignmentService.cls` |
| Classe `LeadAssignmentServiceTest` | Cria | `.../classes/LeadAssignmentServiceTest.cls` |
| 8 filas de Lead: `Leads_SP`, `Leads_RJ`, `Leads_MG`, `Leads_ES`, `Leads_Sul`, `Leads_CO`, `Leads_NO_NE`, `Leads_Triagem` (sem membros) | Cria | `.../queues/` |
| Regra de atribuição `Lead.Distribuicao_Regional_Leads` (ativa; 7 entradas por `State` + Triagem sem critério, na ordem da seção 2.1 do design) | Altera (estava vazia) | `.../assignmentRules/Lead.assignmentRules-meta.xml` |
| Layout `Lead-Lead Layout`: `runAssignmentRulesDefault` false para true | Altera 1 linha | `.../layouts/Lead-Lead Layout.layout-meta.xml` |
| Histórico de campo: `enableHistory` em Lead e `trackHistory` em `OwnerId` e `Status` | Altera | `.../objects/Lead/Lead.object-meta.xml`, `fields/OwnerId`, `fields/Status` |
| Custom permission `Lead_DistribuicaoAutomaticaViaApi` | Cria | `.../customPermissions/` |
| Permission set `PS_Integracao_DistribuicaoLead` (custom permission + acesso à classe) | Cria | `.../permissionsets/` |
| Flow `Lead_AfterInsert_AplicaRegraAtribuicao` (after-save, só criação, caminho assíncrono, ativo; entrada: custom permission e dono começando com `005`) | Cria | `.../flows/` |
| Relatório `Aprovacoes_Pendentes_Por_Processo` (Summary, agrupado por processo, filtro `Status = Pending`, pasta Geral) | Cria | `.../reports/General/` |

Descrições "EPLAST-35. ..." em classe (cabeçalho), custom permission, permission set, Flow (flow e ação) e relatório. **Fila não tem campo de descrição na Metadata API**: o propósito está no nome e neste plano.
O histórico do objeto Lead foi implantado a partir de um pacote mínimo (só `enableHistory` e os dois campos), conforme R8; o arquivo completo do objeto no repo mudou só em 3 linhas.

## 2. O que reaproveitou (sem alteração)
Approval Processes `Quote.AssignPricing`, `Opportunity.FinancialAnalysis`, `Order.LiberationFinancial` (não implantados nem editados por esta demanda; `git diff` sem nada neles); relatório `Histrico_de_Aprovao_XNR` e o tipo de relatório `Inst_ncias_do_processo_de_aprova_o__c`; list views automáticas das filas; relatórios regionais da pasta `MARKETING CLOUD`; `Lead.Status`, `State`, `LeadSource`, campos de opt-out. Nenhum objeto ou campo custom novo. `SFAgent2` e Marketing Cloud: nada feito.

## 3. Ordem de execução verificada na dev
- Lead: **0 triggers** (Apex), **1 Flow ativo (o novo)**, 2 validation rules ativas (`Celular`, `Telefone`), uma regra de atribuição. Não há automação concorrente em Lead; a ordem é a da seção 3 do design (regra de atribuição depois das after triggers e antes dos after-save Flows; Flow só de criação, sem reentrada).
- Account, Opportunity, Order, Quote, `SBQQ__Quote__c`: não tocados.
- Limite: o caminho assíncrono do Flow **não executa dentro de teste Apex** (testado: Lead criado por usuário com o PS seguiu com o dono original). Por isso a entrega do Flow (usuário com o PS, Lead por API sem cabeçalho, lote de 200) fica para a **verificação na sandbox**, com Leads sintéticos. O teste unitário cobre a classe e prova a custom permission.

## 4. Testes e cobertura (`sf apex run test --target-org sbx-eplast-dev --code-coverage`)
`LeadAssignmentServiceTest`: **7 de 7 passam**, `LeadAssignmentService` com **100%** (13 de 13 linhas). Cobertura geral da org: 26% (era 10% no assessment; não é efeito desta demanda).
Cenários: UF de 7 regiões cai na fila certa; UF vazia e "Sao Paulo" caem em `Leads_Triagem`; lote de 200 (1 SOQL, 1 DML, 200 com fila como dono); lista nula/vazia sem SOQL nem DML; Id inexistente sem DML; custom permission ligada só com o PS; PS dá acesso à classe. Dados sintéticos; `Phone`/`MobilePhone` vazios por causa das VRs. Sem `SeeAllData`.
Dry-run (`0AfHa00000EHuaPKAT`) e deploy real com testes: verdes. Relatório renderiza pela Analytics API (`allData = true`, sem erro; 0 linhas porque a dev não tem aprovação pendente).
Evidência do `Lead` na dev: 0 registros; 8 filas criadas; Flow `Active`.

## 5. Premissas usadas (do design, seção 10)
PA-01 a PA-19, sem mudança. As que moldam o build: PA-03 (régua por região, vinda dos relatórios regionais da org), PA-15 (caixa de atribuição marcada por padrão, reversível no layout), PA-16 (integração só com o PS), PA-17 (UF fora do padrão vai para Triagem), PA-18 (sem e-mail de notificação, regra 2 da conta), PA-19 (relatório novo de pendentes).

## 6. Passos manuais pós-deploy (admin da Eplast)
1. Incluir vendedores nas 8 filas (o deploy não leva membros).
2. Atribuir `PS_Integracao_DistribuicaoLead` aos usuários de integração que criam Lead (incluindo o do conector Marketing Cloud, se criar Lead). Sem isso, Lead de API não é distribuído (R2).
3. Conferir que o layout de Lead usado pelos vendedores é o `Lead-Lead Layout`.

## 7. Rollback
Desativar a regra de atribuição e o Flow (Setup); reverter `runAssignmentRulesDefault` no layout; remover o PS das integrações. Filas e histórico não precisam de rollback para o sistema continuar íntegro.

## 8. Pendências e dívida registradas
- Teste do caminho do Flow só na verificação (acima).
- Cobertura geral da org continua abaixo de 75%: bloqueio de produção pré-existente (R6), fora da esteira.
- `sourceApiVersion` do projeto é 67.0 e o design cita 68.0; as classes novas nasceram em 68.0, sem tocar nas existentes.

## 9. Branch e commit
Branch `feature/EPLAST-35`. Commit: ver `git log -1` da branch (`EPLAST-35: constroi distribuicao regional de leads e relatorio de pendentes`).
