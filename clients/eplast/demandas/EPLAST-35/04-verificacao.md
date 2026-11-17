**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast, Org Id 00DHa000006vfMLMAY; única org em `sf org list`, Connected)

# EPLAST-35: Verificação do build (rodada 3, distribuição de Leads sem Apex; reteste após correção do `Get_Membros`)

Nada tocado em QA, QAS, produção ou Marketing Cloud. Dados de teste: só sintéticos (`TESTE EPLAST-35`), pelo script `fixtures/lead_rodizio_dono_conta.apex` (ações `preparar`, `filas`, `leads`) e por Apex anônimo próprio para os demais casos. Usuário de teste da Konecta: `005bJ00000piKAaQAM` (ativo, Administrador do sistema), só como membro de fila e dono de conta de teste; perfil, permissão e papel intocados. Segundo elegível: `005bJ000004gGVxQAM`. Terceiro (só no T3): `005Ha00000B3tknIAB`. Inativo: `005bJ00000hBJmYQAW`. Nenhum dado real lido; consultas só de Lead/Account de teste, metadata e contagens.

## Resumo
- A FALHA 1 da rodada 1 (`Get_Membros` caindo no caminho de falha) **foi corrigida**: com a v2 do Flow ativa, o Lead sem conta em fila regional recebe dono entre os membros elegíveis (T1, T2, T3, T7), o caminho do dono da conta funciona (T5, T6, T8, T10), e o interruptor e o `RodizioAtivo__c` desligam o comportamento (T13).
- Lote de 200: 6 SOQL, 2 DML, CPU 1.429 a 1.710 ms (limite 10.000), sem erro de limite. Bem abaixo de 70%.
- Não exercitados (motivo na tabela): T3b, T9, T14, T15, parte do T17 e a troca de dono do T18. Nenhum falhou.
- Observação ao cliente (R5/PA-24, não é falha): com `MOD`, chegada periódica concentra Leads num vendedor (T7 e uma região do T3).

## Estado antes, durante e depois (reversão)
| Item | Antes (como encontrei) | Durante | Agora |
|---|---|---|---|
| Flow `Lead_AfterSave_DistribuiDonoRodizio` | v1 Active, v2 Draft (`300Ha00000P1HA9IAN`) | v2 ativada por Tooling API (ativação é o passo separado que o plano deixou para a verificação; a ativação desativa a v1) | **v2 Active** (deixei assim; para voltar, ativar a v1) |
| Regra `Distribuicao_Regional_Leads` (v1) | inativa (deixada assim pela verificação 1) | sem mudança | inativa |
| Regra `Distribuicao_Regional_Leads_v2` | ativa | sem mudança | ativa |
| `DistribuicaoLeadSetting.Padrao` | `DistribuicaoAtiva__c=false`, `RodizioAtivo__c=true`, `RespeitarDonoConta__c=true` | alterado por deploy de CMDT (`true/true`; `true/false` em T13a; `false/true` em T13b) | **`false`, `true`, `true`** (original) |
| Membros diretos de `Leads_*` | 0 | 8 criados (MG, SP, RJ_ES, Sul) | **0** |
| Leads, Contas `TESTE EPLAST-35` | 0 | criados | **0** (conferido por COUNT) |
| Perfil, papel, permission set dos usuários | n/a | não tocados | não tocados |

`Account` voltou a 2 registros (2 antes), `Opportunity` 0, `Order` 0.

## Resultados por teste

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | Lead de tela, caixa marcada, SP, fila com 2 elegíveis | Apex anônimo, 1 Lead `State=SP`, `useDefaultRule=true`; membros diretos em `Leads_SP` | Dono = membro, não a fila; histórico fila → vendedor | Dono = `005bJ000004gGVxQAM` (User). `LeadHistory`: criação, `Owner` para fila `Leads SP`, `Owner` fila → usuário | passou |
| T2 | Rodízio alterna | 4 Leads MG, um por execução, 2 elegíveis | A, B, A, B | `…piKAaQAM`, `…4gGVxQAM`, `…piKAaQAM`, `…4gGVxQAM` | passou |
| T3 | Lote de 200, 3 regiões, 3 elegíveis, limites | 200 Leads em 1 insert com cabeçalho (SP, MG, CO alternando), 3 membros em `Leads_SP`, 2 em `Leads_MG`, 0 em `Leads_CO` | Todos os de fila com membro recebem dono; sem erro de limite; registrar SOQL/DML/CPU | 200 de 200 gravados, 0 `FLOW_ELEMENT_FAULT`. CO (sem membro) 66 ficaram na fila, MG 67 com dono (33/34), SP 67 com dono. Limites: **SOQL 6/100, DML 2/150, linhas DML 334/10.000, CPU 1.429/10.000 ms**. Segundo lote de 200 com ordem de região não periódica: SOQL 6, DML 2, CPU 1.710 ms; SP repartiu 34/33/33 entre os 3 elegíveis; MG 67 num só vendedor (R5) | passou (limites); ver observação R5 |
| T3b | Mesmo lote por usuário com `PS_Integracao_DistribuicaoLead`, sem cabeçalho | Não executado: exigiria atribuir esse permission set ao usuário de teste, o que a regra do verificador não autoriza (só o permission set criado pela demanda) | Todos com dono via caminho assíncrono | sem evidência | não executado |
| T4 | RJ e ES | 1 Lead RJ e 1 ES, com cabeçalho | Os dois em `Leads_RJ_ES` (com membro: dono membro); nenhum em `Leads_RJ`/`Leads_ES` | Os dois com dono usuário (membros de `Leads_RJ_ES`): ES = `…4gGVxQAM`, RJ = `…piKAaQAM`. Regra v2 só tem a entrada `RJ,ES` para `Leads_RJ_ES` (retrieve da org) | passou |
| T5 | CNPJ de conta de teste, UF de outra região | Lead UF RS com `CompanyDocument__c` com máscara; conta A só dígitos, dono `…piKAaQAM` | Dono = dono da conta | Dono = `…piKAaQAM` (User), embora UF RS (Sul só tem membro inativo) | passou |
| T6 | Máscara e dígitos nos dois sentidos | Lead máscara x conta A dígitos (T5); Lead máscara x conta B máscara; Lead dígitos x conta B máscara | Dono = X nos dois | Os 3 com dono `…piKAaQAM` | passou |
| T6b | Contagens de CNPJ na QAS | Só QAS | n/a | n/a | não executado (fora da dev) |
| T7 | Lote 40 alternando SP, MG | 40 Leads, 2 elegíveis em cada | Registrar distribuição | SP: 20 para `…piKAaQAM`, 0 para o outro. MG: 20 para `…4gGVxQAM`, 0 para o outro. Concentração total, como a seção 1.5 e a R5 do design preveem; é evidência para o cliente, não falha | passou (evidência R5) |
| T8 | CNPJ em 2 contas com donos diferentes | Lead MG com CNPJ das contas C (dono `…piKAaQAM`) e D (dono `…4gGVxQAM`) | Vai para o rodízio | Lead com dono `…4gGVxQAM`, usuário membro de `Leads_MG`. Limitação: o resultado coincide com um dos donos das contas, então a evidência de que passou pelo rodízio, e não pela conta, é indireta (a regra "exatamente 1 conta" está no XML) | passou (evidência indireta) |
| T9 | Conta casada com dono inativo | Tentei criar conta com dono `005bJ00000hBJmYQAW` | Vai para o rodízio | A plataforma recusa criar conta com dono inativo (`INACTIVE_OWNER_OR_USER`); não há como montar o cenário sem inativar um dono existente, o que seria alterar usuário. O Lead sem conta foi para o rodízio (não prova o caso) | não executado |
| T10 | UF vazia | 1 Lead sem UF com CNPJ da conta A; 1 sem UF e sem CNPJ | Com conta: dono X; sem: `Leads_Triagem` | Com conta: dono `…piKAaQAM`. Sem conta: fila `Leads Triagem` (`00GHa000006b8pgMAA`) | passou |
| T11 | Fila regional sem elegível | 1 Lead RS sem CNPJ, `Leads_Sul` só com o membro inativo | Fica na fila | Dono = fila `Leads Sul (PR, SC, RS)` | passou |
| T12 | Caixa desmarcada | 1 Lead SP sem cabeçalho de regra | Dono = criador | Dono = `…piKAaQAM` (o usuário de execução) | passou |
| T13 | Interruptor e `RodizioAtivo__c` | (a) `RodizioAtivo=false`, `DistribuicaoAtiva=true`: transferir Lead para `Leads_MG`. (b) `DistribuicaoAtiva=false`: criar Lead com CNPJ da conta A e transferir para `Leads_MG` | (a) fica na fila; (b) nada acontece, nem dono da conta | (a) Lead na fila (Owner.Type = Queue). (b) Lead na fila, sem dono da conta | passou |
| T14 | Falha na gravação por elegível sem leitura | Não há perfil assim identificado na dev; não criei | Lead fica na fila e é salvo | n/a | não executado (declarado como o design prevê) |
| T15 | `Comercial - Analista` cria o Lead pela tela | O job só executa como o usuário de teste (Administrador); não há como personificar o analista sem mexer em usuário | Distribui sem erro de acesso | sem evidência | não executado (precisa de sessão desse perfil: QA ou o cliente) |
| T16 | Isolamento | `COUNT()` antes/depois e `AsyncApexJob` agregado | Account, Opportunity, Order iguais; nenhum job novo de `SendAccountToProtheus`/`UpdateAccountCompanyInfo` | Account 2 → 2, Opportunity 0 → 0, Order 0 → 0. `AsyncApexJob`: `UpdateAccountCompanyInfo` 11 → 11, `SendAccountToProtheus` 279 → 279. Contas de teste criadas com `TriggerUtility.bypassTrigger` e apagadas | passou |
| T17 | Versões | Deploy report `0AfHa00000EJO09KAH`; query de `ApexClass` e `Flow` | 3 `ApprovalProcess`, `LeadAssignmentService`, Flow antigo sem mudança; nenhuma classe nova | O deploy tem 13 componentes e nenhum é `ApprovalProcess` nem `ApexClass`. `LeadAssignmentService` e `Lead_AfterInsert_AplicaRegraAtribuicao` v1 (Active) com última modificação em 2026-11-15, anteriores ao build. As 13 classes criadas nos últimos 3 dias são de 15/11 (MeetingSummary, LeadAssignment, CommercialSignal), de outras demandas. v2 do Flow ativa e v1 do Flow antigo intacta; regra v1 inativa e v2 ativa. A leitura direta dos 3 processos de aprovação (retrieve) estourou o tempo na sessão e `ProcessDefinition` não é consultável | passou (parcial: processos de aprovação só pelo deploy report) |
| T18 | Lead convertido | Lead MG criado e convertido em conta de teste (sem Oportunidade, com bypass da `AccountTrigger`); depois tentei trocar o dono | Flow entra e sai sem erro | Conversão com sucesso, Flow ativo sem erro. A troca de dono do Lead convertido é recusada pela plataforma (`CANNOT_UPDATE_CONVERTED_LEAD`), então a entrada do Flow por troca de dono não ocorre nem é possível exercitar | passou (parcial) |

### FALHA 1 da rodada 1 (`Get_Membros`): corrigida
Reteste T1: o Lead SP saiu da fila e recebeu dono. Em T3, 0 `FLOW_ELEMENT_FAULT` em 400 Leads. A ordenação por `UserOrGroupId` no `Get_Membros` funciona.

## O que ficou sem prova e quem prova
- **T3b e T15:** precisam de sessão de usuário com `PS_Integracao_DistribuicaoLead` e de um `Comercial - Analista`, o que a verificação não pode atribuir. Provar na QA (roteiro) ou com o cliente.
- **T9:** a plataforma não aceita o cenário em registro novo; só ocorre se um dono de conta for inativado depois. O XML do Flow filtra o dono por `IsActive` e `UserType`.
- **T14:** sem perfil sem leitura de Lead identificado na dev.
- **T6b:** só na QAS.
- **Campo `DIST_SequenciaRodizio__c`:** sem permissão de campo para o usuário de execução (por desenho), então não consegui ler o número sequencial; a prova da alternância é pelo dono.

## O que pode ter saído da org
Nada. Os Leads de teste não chamam sistema externo; as contas de teste foram criadas com `TriggerUtility.bypassTrigger = true` (sem Protheus nem BrasilAPI); a conversão do T18 usou o mesmo bypass. `AsyncApexJob` de `SendAccountToProtheus` e `UpdateAccountCompanyInfo` sem aumento (11 e 279, antes e depois). Nenhum e-mail, nada no Marketing Cloud.

## Observação para a homologação (premissa PA-24, R5)
Com a fórmula `MOD`, chegada periódica concentra: no T7 (SP, MG, SP, MG com 2 elegíveis) cada região foi inteira para um único vendedor; no T3, MG idem. Em sequência de um só tipo de região o rodízio alterna (T2). A troca para a sequência de Weyl é a mudança de uma fórmula (`fxIdx`), seção 1.5 do design.
