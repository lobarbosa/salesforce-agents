**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev` (alias; Sandbox, Org Id 00DHa000006vfMLMAY, Connected; única org em `sf org list`)

# EPLAST-35: Verificação do build (rodada 3, reteste depois da rodada 1)

Nada tocado em QA, QAS, produção ou Marketing Cloud. Dado de teste só sintético (`TESTE EPLAST-35`). Usuário de teste: `005bJ00000piKAaQAM` (ativo, Administrador do sistema; o outro `Projetos@konectabr…` `005bJ00000hBJmYQAW` está inativo). Segundo e terceiro elegíveis: `005bJ000004gGVxQAM` (Comercial - Analista) e `005bJ00000F1pMVQAZ`. Nenhuma alteração de perfil, papel ou permission set de usuário. Nenhum permission set atribuído, nenhum "Marketing User" ligado.

## Resumo
O rodízio, que nunca tinha rodado com sucesso, agora roda: o `Get_Membros` corrigido funciona (Flow v3 Active). Dono da conta (CNPJ com e sem máscara, duplicado, UF vazia), rodízio, região RJ/ES, fila sem elegível, caixa desmarcada, transferência manual, interruptor e lote de 200 passaram. **Ressalva importante (R5, T3 e T7):** com `MOD`, quando os Leads de uma mesma região chegam em passo regular, um só vendedor recebe todos. É o comportamento previsto pelo design (T7 é "evidência, não reprovação"); a troca para a fórmula de Weyl em `fxIdx` resolve. Casos T3b, T9, T14, T15 e T18 não puderam ser exercitados (motivos na tabela).

## Estado conferido na DEV (efeito sobre a EPLAST-38)
| Item | Estado conferido |
|---|---|
| Flow `Lead_AfterSave_DistribuiDonoRodizio` | v1 Obsolete, v2 Obsolete, **v3 Active** (Tooling) |
| Regra de Lead (retrieve) | `Distribuicao_Regional_Leads` (v1 da EPLAST-38) `active=false`; `Distribuicao_Regional_Leads_v2` `active=true` |
| `DistribuicaoLeadSetting.Padrao` | `DistribuicaoAtiva__c = true`, `RodizioAtivo__c = true`, `RespeitarDonoConta__c = true` |
| Efeito sobre a EPLAST-38 | A v1 deixou de ser a regra ativa; todo Lead novo na DEV passa pela v2 (RJ e ES juntos em `Leads_RJ_ES`) e pelo Flow. Não alterei a v1 nem a regra. Quem homologa a 38 verá essa distribuição (decisão do responsável, 17/11). |
| Flow antigo `Lead_AfterInsert_AplicaRegraAtribuicao` | Ativo, sem mudança. `LeadAssignmentService` última modificação 2026-11-15, sem mudança |

O Flow antigo e a regra v2 coexistiram sem erro em todos os casos. O campo `DIST_SequenciaRodizio__c` não é legível pelo meu usuário (sem permissão de campo, como construído), então não li a sequência.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | Lead sem conta em fila regional com elegíveis recebe dono | Apex anônimo, 1 Lead `State=SP`, cabeçalho de regra padrão; `Leads_SP` com 2 membros diretos | Dono = membro, não a fila | Dono `005bJ00000piKAaQAM` (User). `LeadHistory`: criado, atribuído à fila `Leads SP`, depois Owner fila → usuário. A regra não reaplicou depois do Update do Flow (PA-29 confirmada) | passou |
| T2 | Alternância entre elegíveis | 4 execuções, 1 Lead MG cada, `Leads_MG` com 2 membros, sem Lead no meio | A, B, A, B | `…gGVx`, `…KAaQ`, `…gGVx`, `…KAaQ` | passou |
| T3 | Lote de 200, 3 regiões (RS, SP, RJ), 3 elegíveis em `Leads_Sul`; medição | `Database.insert` de 200 com cabeçalho, regiões em ciclo i%3; limites lidos com `Limits` na mesma transação | Todos com dono; sem erro de limite; cada elegível recebe | 200/200 salvos, todos com dono (usuário). **SOQL 6/100, DML 2/150 (400 linhas de 10.000), CPU 2.151/10.000 ms (21,5%), heap 37.951 bytes**. Mas: os 67 Leads RS foram todos para um só elegível (`…gGVx`) porque o passo do auto number (3) coincide com `k=3`. Variante T3v com regiões em ordem irregular (período 7): 200/200 com dono, RS 30/27/29 entre os 3 elegíveis, CPU 1.901 ms, SOQL 6 | passou (limites e dono) com ressalva de concentração (R5, ver T7) |
| T3b | Lote por usuário com `PS_Integracao_DistribuicaoLead`, sem cabeçalho | Não executado: o PS é da EPLAST-38, não da demanda, e já tem 1 atribuição; não posso atribuí-lo ao meu usuário | Todos com dono | Sem evidência | não executado |
| T4 | RJ e ES vão para `Leads_RJ_ES` | 1 Lead RJ e 1 Lead ES, `Leads_RJ_ES` com 2 membros | Em `Leads_RJ_ES` ou com um membro dela; nenhum em `Leads_RJ`/`Leads_ES` | RJ dono `…gGVx`, ES dono `…KAaQ` (ambos membros de `Leads_RJ_ES`); histórico passou por `Leads_RJ_ES` | passou |
| T5 | Dono da conta pelo CNPJ, UF de outra região | Contas de teste F (CNPJ só dígitos) e G (com máscara), dono `…gGVx`; 2 Leads RS com máscara, CNPJ de F, em execuções separadas | Dono = dono da conta, não rodízio | Os dois com dono `…gGVx` (o rodízio em RS com 3 membros trocaria de dono) | passou |
| T6 | Máscara no Lead e só dígitos na conta, e o inverso | Lead com máscara × conta F (dígitos); Lead com dígitos × conta G (máscara); 2 de cada, intercalados | Dono = dono da conta nos dois | Os 4 Leads com dono `…gGVx` | passou |
| T6b | Só QAS | Não se aplica na DEV | n/a | n/a | não executado (só QAS) |
| T7 | Lote SP, MG alternados (40), 2 elegíveis em cada | `Database.insert` de 40 com cabeçalho | Registrar distribuição (evidência R5) | SP: 20 Leads para `…gGVx`, 0 para o outro. MG: 20 para `…KAaQ`, 0 para o outro. Concentração total com `MOD` e passo regular | passou (como evidência; recomenda-se avaliar Weyl) |
| T8 | CNPJ em 2 contas com donos diferentes vai para o rodízio | Contas C e D (mesmo CNPJ, donos `…KAaQ` e `…gGVx`); 3 Leads RS seguidos, CNPJ duplicado | Rodízio | Donos `…gGVx`, `…F1pMV`, `…KAaQ`: rotação entre os 3 membros de `Leads_Sul`, inclusive `…F1pMV`, que não é dono de nenhuma conta | passou |
| T9 | Conta casada cujo dono é inativo | Conta com dono inativo não pode ser criada (`INACTIVE_OWNER_OR_USER`) e não alterei usuário | Rodízio | Sem evidência | não executado |
| T10 | UF vazia: com conta e sem conta | Lead sem `State` com CNPJ de F; Lead sem `State` e sem CNPJ | Com conta: dono da conta. Sem: `Leads_Triagem` | Com conta: dono `…gGVx`. Sem conta: fila `00GHa000006b8pgMAA` (Leads_Triagem) | passou |
| T11 | Fila regional sem elegível (só inativo) | Lead `State=GO`; `Leads_CO` só com o membro inativo `…hBJmY` | Fica na fila | Dono `00GHa000006b8pZMAQ` (Leads_CO) | passou |
| T12 | Tela, caixa desmarcada | 2 Leads MG sem cabeçalho de regra | Dono = criador | Ambos `…KAaQ` (criador); sem alternância | passou |
| T13 | Transferência manual redistribui; interruptores | Update do dono de Lead para `Leads_MG`: (a) com tudo ligado; (b) `RodizioAtivo__c=false`; (c) `DistribuicaoAtiva__c=false` (deploy temporário só do registro do CMDT, a partir de cópia em /tmp; valores originais restaurados e conferidos: true/true) | (a) redistribui; (b) fica na fila; (c) nada acontece | (a) `LeadHistory`: Owner → `Leads MG` → usuário. (b) Owner = fila `Leads_MG`. (c) Owner = fila `Leads_MG` e Lead novo com CNPJ de conta (que iria ao dono da conta) ficou em fila: Flow inerte | passou |
| T14 | Falha de gravação: elegível sem leitura de Lead | `COUNT` de `ObjectPermissions` de perfil com Lead sem leitura na DEV = 0 | Se não houver perfil assim, declarar | Sem perfil assim; caminho de falha só visto na verificação 1 (Get_Membros caía em `Fim_Falha` e o Lead ficou na fila sem erro) | não executado |
| T15 | `Comercial - Analista` cria o Lead pela tela | Não executável: o job roda como o usuário de teste e não posso me passar por outro usuário nem alterar o dele | Distribui sem erro | Sem evidência. Os Leads distribuídos para `…gGVx` foram atribuídos pelo Flow sem erro de acesso, mas isso não substitui o caso | não executado |
| T16 | Isolamento | `COUNT()` antes e depois (dados de teste apagados); `AsyncApexJob` de `SendAccountToProtheus`/`UpdateAccountCompanyInfo` | Iguais | Account 2 → 2, Opportunity 0 → 0, Order 0 → 0; jobs 290 → 290. Contas de teste criadas com `TriggerUtility.bypassTrigger` | passou |
| T17 | Versões | `sf org list metadata -m ApprovalProcess`; Tooling `ApexClass`; Flow antigo; Apex criado hoje | 3 processos e `LeadAssignmentService` sem mudança; v2 ativa e v1 inativa; sem classe nova | 3 processos: `Opportunity.FinancialAnalysis` (mod. 2024-09-04), `Order.LiberationFinancial` (2025-01-29), `Quote.AssignPricing` (2026-08-31), todos anteriores a esta demanda. `LeadAssignmentService` 2026-11-15. Flow antigo Active. Regra v2 ativa e v1 inativa. `ApexClass` criada hoje = 0 | passou |
| T18 | Lead convertido com troca de dono | Lead convertido (`Database.convertLead` com desvio do trigger de Account) e depois Update de `OwnerId` | Flow entra e sai sem erro | A conversão passou sem erro com o Flow ativo. A troca de dono é recusada pela plataforma (`CANNOT_UPDATE_CONVERTED_LEAD`) antes do Flow: o cenário não existe na plataforma | não executado (cenário impossível; conversão sem erro) |

## Reteste da rodada 1
A falha da verificação 1 (`Get_Membros` caindo no caminho de falha): **corrigida**. T1, T2, T3 e T7 mostram o rodízio atribuindo dono. A falha da QAS (cadeia inalcançável) é estado de Setup, tratado pelo build (Flow ativo, v2 ativa, interruptor ligado) e confirmado acima.

## Pontos para o gate
1. **Concentração com `MOD` (R5):** T3 (ciclo regular) e T7 deram um só vendedor por região. Com ordem irregular, T3v distribuiu bem. Se o cliente espera alternância em lote regular, trocar `fxIdx` pela fórmula de Weyl (alternativa já prevista no design).
2. **Sem prova:** T3b, T9, T14, T15, T18. Para provar: T3b com um usuário que já tem `PS_Integracao_DistribuicaoLead`; T15 por alguém com perfil `Comercial - Analista` criando um Lead pela tela; T9 precisa de conta cujo dono ficou inativo depois (só pelo cliente); T14 só se existir perfil sem leitura de Lead.
3. Tempo de CPU do lote de 200: 21,5% do limite (abaixo de 70%); SOQL 6; DML 2.

## Fixture
`clients/eplast/fixtures/lead_rodizio_dono_conta.apex` ajustado e provado: ações `preparar`, `filas` (membros em `Leads_MG`/`SP`/`RJ_ES`, `Leads_Sul` com 3, `Leads_CO` só inativo), `limparfilas` e `limpar`. DML de conta e de membro de fila vão em execuções separadas (MIXED_DML); conta com dono inativo não é criável. Contas F e G (dono segundo usuário) e os Leads dos casos foram criados por scripts avulsos em /tmp e não entraram no arquivo; a ação `leads` do fixture não foi usada.

## O que pode ter saído da org
Nada saiu. Contas de teste usaram `TriggerUtility.bypassTrigger` (sem Protheus nem BrasilAPI); `AsyncApexJob` de Protheus/BrasilAPI sem variação (290 antes e depois). O Flow não envia e-mail. Nada no Marketing Cloud.

## Estado final e limpeza
| Item | Antes | Depois |
|---|---|---|
| Leads `TESTE EPLAST-35` (cerca de 490) | 0 | **0** |
| Contas e contatos de teste (incluindo a conta da conversão do T18) | 0 | **0** |
| Membros diretos das filas `Leads_*` | 0 | **0** |
| `DistribuicaoLeadSetting.Padrao` | true/true/true | true/true/true (restaurado depois dos deploys temporários de T13) |
| Regra v2 ativa, v1 inativa; Flow v3 Active | idem | idem (não alterado por mim) |
| Permission set / Marketing User / campos do usuário de teste | n/a | nenhum alterado |
