**Verificação:** reprovada
**Org de teste:** sbx-eplast-dev (alias; usuário de conexão omitido, Org Id 00DHa000006vfMLMAY, Sandbox, Connected; única org em `sf org list`)

# EPLAST-35: Verificação do build (rodada 3, distribuição de Leads sem Apex)

Nada tocado em QA, QAS, produção ou Marketing Cloud. Usuário de teste: `005bJ00000piKAaQAM` (ativo, perfil Administrador do sistema; só membro de fila e dono de conta de teste, sem alteração de perfil, permissão ou papel). Segundo elegível: `005bJ000004gGVxQAM` (Comercial - Analista). Inativo para T11: `005bJ00000hBJmYQAW`.

## Resumo
O caminho "dono da conta" do Flow funciona (T5, T6, T10 com conta, T13 interruptor e transferência manual). O **rodízio nunca roda**: o Get `Get_Membros` cai no caminho de falha em toda execução, o Flow sai por `Fim_Falha` e o Lead fica na fila. É o caso principal do critério (Lead sem conta em fila regional com elegíveis recebe dono), então a verificação é reprovada.

### FALHA 1: Get_Membros do rodízio falha sempre, Lead não sai da fila
- **Reproduzir:** DEV com v2 ativa e `DistribuicaoAtiva__c=true`; membros diretos em `Leads_SP` (`005bJ00000piKAaQAM` e `005bJ000004gGVxQAM`); inserir 1 Lead `State='SP'` com `useDefaultRule=true` (script T1 em Apex anônimo, 3 vezes, mesmo resultado).
- **Obtido:** Lead fica com dono `00GHa000006b8peMAA` (fila Leads_SP). `LeadHistory`: criação, depois só atribuição Konecta2 para fila. Log de Flow (FINER): `Config_Ligada`, `Lead_Em_Fila`, `Fila_Valida` = verdadeiro, `Usar_Conta` = falso, `Rodizio_Habilitado` = verdadeiro, depois `FLOW_ELEMENT_FAULT|Fault path taken|FlowRecordLookup|Get_Membros` e `Fim_Falha`.
- **Esperado:** dono = um dos membros elegíveis (T1), alternando (T2).
- **Causa provável (reproduzida):** o filtro `UserOrGroupId StartsWith '005'` em `GroupMember`. Consulta direta `SELECT Id FROM GroupMember WHERE UserOrGroupId LIKE '005%'` devolve "invalid operator on id field". A plataforma não aceita operador de texto em campo Id. Saída declarativa: buscar `GroupMember` só por `GroupId` (sem filtro no `UserOrGroupId`) e separar usuários na etapa seguinte (o Get de `User` com `Id In` coleção já filtra para usuários; Id de grupo não casa), ou filtrar o `User` pelos Ids da coleção sem o pré-filtro.
- Efeito: T1, T2, T3, T3b, T7, T8, T9, T11, T14, T15 e T18 não podem passar, pois dependem do rodízio ou ficam sem prova (tabela).

## Preparação e estado original (para reverter)
| Item | Antes | Durante | Agora |
|---|---|---|---|
| Regra `Distribuicao_Regional_Leads` (v1) | ativa | inativa | **inativa** |
| Regra `Distribuicao_Regional_Leads_v2` | inativa | ativa (deploy de Lead.assignmentRules, só `active` alterado, a partir de cópia em /tmp; arquivo do repo intocado) | **ativa** (deixada assim para o reteste do builder; para voltar, reativar a v1) |
| `DistribuicaoLeadSetting.Padrao.DistribuicaoAtiva__c` | false | true (T1 a T12), false em T13, true de novo | **false** (original) |
| `RodizioAtivo__c` / `RespeitarDonoConta__c` | true / true | sem mudança | true / true |
| Flow `Lead_AfterSave_DistribuiDonoRodizio` | v1 ativa (301Ha000016bZTNIA2) | sem mudança | idem |
| Flow antigo `Lead_AfterInsert_AplicaRegraAtribuicao` | 301Ha000016Tll8IAC | sem mudança | idem |
| Debug Level `V35Lvl` e TraceFlag no usuário `005bJ00000piKAaQAM` | inexistentes | criados para ler o log | **apagados** |
| Membros de fila (Leads_MG, Leads_SP, Leads_RJ_ES, Leads_Sul) | 0 membros diretos nas filas `Leads_*` | criados | **0** (apagados) |
| Dados de teste | 0 | contas A a D e Leads `TESTE EPLAST-35` | **0** (Leads, contas e membros apagados; conferido por COUNT) |

Nenhuma mudança no usuário de execução além do TraceFlag (sem permission set, sem Marketing User). Campo `Lead.DIST_SequenciaRodizio__c` não é visível ao usuário de execução (sem permissão de campo, query direta devolve "No such column"); o Flow roda em contexto de sistema e não foi o motivo da falha.

## Casos
| Caso | Resultado | Evidência |
|---|---|---|
| T1 tela, SP, 2 elegíveis | **falhou** | Lead fica em `Leads_SP`. Ver FALHA 1 |
| T2 4 Leads MG alternando | **falhou** | 4 Leads MG ficaram todos em `Leads_MG` (`00GHa000006b8pbMAA`) |
| T3 lote 200, 3 regiões | **falhou / não prova** | Sem erro de limite, mas todos os 200 ficaram em fila (0 com dono usuário). Roda só o caminho de falha |
| T3b lote por usuário de integração, sem cabeçalho | não executado | Não havia como validar enquanto T1 falha; usuário com `PS_Integracao_DistribuicaoLead` não foi montado |
| T4 RJ e ES | passou | Os 2 Leads em `Leads_RJ_ES` (`00GHa000006cVaVMAU`), nenhum em `Leads_RJ` ou `Leads_ES`. A regra v2 funciona; a distribuição ao membro não ocorreu (FALHA 1) |
| T5 CNPJ de conta, UF de outra região | passou | Lead UF RS com CNPJ da conta B: dono = dono da conta (`005bJ00000piKAaQAM`), não `Leads_Sul` |
| T6 máscara no Lead e só dígitos na conta, e o inverso | passou | Conta A só dígitos + Lead com máscara: dono da conta. Conta B com máscara + Lead só dígitos: dono da conta |
| T6b (só QAS) | não executado | Fora da DEV |
| T7 40 Leads alternando SP/MG | não executado | Depende do rodízio (FALHA 1) |
| T8 CNPJ em 2 contas, donos diferentes | não executado | Cairia no rodízio, que falha; a parte "não usa conta" não foi isolada |
| T9 conta casada com dono inativo | não executado | Idem |
| T10 UF vazia, com e sem conta | passou | Com conta: dono = dono da conta. Sem conta: fica em `Leads_Triagem` (`00GHa000006b8pgMAA`) |
| T11 fila só com membro inativo | não executado | A fila `Leads_Sul` ficaria em fila de qualquer forma pela falha; sem prova do mecanismo |
| T12 tela, caixa desmarcada | passou | `useDefaultRule=false`: dono = criador `005bJ00000piKAaQAM` |
| T13 interruptor / transferência manual | passou (parte) | Interruptor false: Lead de usuário transferido a `Leads_MG` ficou na fila. Interruptor true: transferido a `Leads_SP`, voltou ao dono da conta. `RodizioAtivo=false` não testado |
| T14 falha de gravação | não executado | Não há perfil de teste específico e o rodízio não roda |
| T15 `Comercial - Analista` cria o Lead | não executado | Não foi possível usar o usuário (só o de serviço; outro usuário intocado) |
| T16 isolamento | passou | COUNT antes/depois: Account 2/2, Opportunity 0/0, Order 0/0, Lead 4/4. `AsyncApexJob`: `SendAccountToProtheus` 279/279, `UpdateAccountCompanyInfo` 11/11 |
| T17 versões | passou (parte) | Flow antigo mesma versão ativa; ApexClass 1852/1852 (nenhuma classe nova). Os 3 `ApprovalProcess` não foram comparados (tipo não consultável por query; retrieve estourou o tempo) |
| T18 lead convertido | não executado | Sem prova |

## Medições (T3, lote de 200 Leads, 3 regiões, cabeçalho de regra, só caminho de falha)
- SOQL: 3 de 100. DML: 1 de 150. CPU: 5.643 ms com log FINER e 5.377 ms com log INFO, de 10.000 (cerca de 54%, o log mostrou "CLOSE TO LIMIT").
- **Não vale como medição da solução**: o Flow saiu por `Fim_Falha` e nunca montou coleção de membros, nem leu usuários, nem fez o loop. A CPU do caminho completo é maior e tem de ser remedida depois da correção (limite de 70% = 7.000 ms).
- T3b (assíncrono): sem medição.

## Premissas e decisões desta verificação
- Ativação na DEV (v2 e depois interruptor) feita como o plano e o design (seção 13, passo 8) mandam. Nenhuma premissa de negócio do design foi contestada.
- Correção da fixture `fixtures/lead_rodizio_dono_conta.apex` (não é correção do build): `MIXED_DML_OPERATION` entre Account e GroupMember, por isso as ações `filas` e `limparfilas` agora são separadas; CNPJ da conta A corrigido para `99000000000100` (os dígitos de `99.000.000/0001-00`); incluído Lead com CNPJ só dígitos para o inverso do T6. Linha da fixture a acrescentar ao `fixtures/README.md` na hora do rebase (o arquivo não existe neste branch). Os membros de `Leads_SP`, `Leads_RJ_ES` e `Leads_Sul` (inativo) foram criados por script avulso, não pela fixture.
- Usuário de teste do CLAUDE.md existe e está ativo, e foi usado como dono de conta e membro.

## O que ficou sem prova
T3b, T7, T8, T9, T11, T14, T15, T18, o ciclo completo do rodízio (alternância, AssignCount com coleção vazia, `Get ... In` de coleção, filtro de usuário inativo), a medição de CPU do caminho completo, `RodizioAtivo=false`, e a comparação dos 3 `ApprovalProcess`. Todos dependem da correção da FALHA 1; T14 e T15 também de usuário/perfil de teste que o job não tem. Depois da correção, o builder refaz e o verificador roda T1 a T18 de novo.

## O que pode ter saído da org
Nada. Nenhum Account foi gravado fora do bypass da trigger (contas criadas com `TriggerUtility.bypassTrigger`), nenhum job de Protheus novo, nenhum e-mail ou callout.
