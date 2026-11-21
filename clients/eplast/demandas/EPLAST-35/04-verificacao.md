**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev (alias confirmado por `sf org list`: Sandbox, Connected, Org Id 00DHa000006vfMLMAY; única org listada)

# EPLAST-35: Verificação do build (rodada 3, distribuição de Leads sem Apex), reteste

Nada tocado em QA, QAS, produção ou Marketing Cloud. Nada implantado. Usuário de teste (conta de serviço Konecta, ativo, Administrador do sistema): `005bJ00000piKAaQAM`. Segundo elegível (perfil Comercial - Analista): `005bJ000004gGVxQAM`. Terceiro elegível (só em `Leads_Sul`): `005bJ00000F1pMVQAZ`. Inativo (só em `Leads_CO`, T11): `005bJ00000hBJmYQAW`. Nenhum perfil, permissão, papel ou opção de usuário foi alterado; não criei TraceFlag (as medições vêm de `Limits` dentro do próprio Apex anônimo).

## Resumo
- A FALHA 1 da rodada anterior (Get_Membros) **foi corrigida**: o rodízio roda de ponta a ponta (T1, T2, T4, T7, T3).
- Estado da DEV encontrado (não alterado por mim): Flow `Lead_AfterSave_DistribuiDonoRodizio` v3 Active (v1 e v2 Obsolete); regra v2 ativa, v1 inativa (declarado no plano; a v2 foi exercitada e distribuiu RJ e ES em `Leads_RJ_ES`); CMDT `Padrao` com `DistribuicaoAtiva__c = true`, `RodizioAtivo__c = true`, `RespeitarDonoConta__c = true`.
- **Lote de 200: dentro dos limites com folga** (SOQL 6/100, DML 2/150, CPU 1.458 a 1.867 ms de 10.000, cerca de 15% a 19%; limite de corte 70% = 7.000 ms). Saída declarativa da seção 4 do design não é necessária.
- Ficaram **sem prova**: T3b, T6b, T9, T14, T15 e as partes de T13 que exigem trocar o CMDT (interruptor e `RodizioAtivo=false`). Motivo de cada um na tabela. Por isso `inconclusiva` e não `aprovada`; nenhum caso executado falhou.
- Observação para quem homologa: a classe `LeadAssignmentServiceTest` falha (2 de 7) **enquanto houver membro direto ativo em fila `Leads_*`** (risco já registrado pelo builder, plano seção "ajuste do teste"). Com os meus membros de teste presentes falhou; depois que os removi, 7 de 7 passaram. Não é defeito do build; é uma armadilha para o QA e a QAS: remover membros de teste ao fim.

## Casos (T1 a T18)
Todos os Leads criados por Apex anônimo com `useDefaultRule = true` (equivale à caixa marcada na tela), um por execução quando o caso é de Lead único. Todos têm `Company = 'TESTE EPLAST-35'` e nome `TESTE EPLAST-35 ...`. Dono lido por consulta aos registros de teste.

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | Lead sem conta em fila regional com elegíveis recebe vendedor | 1 Lead UF SP, `Leads_SP` com 2 elegíveis (teste e Comercial) | Dono = membro, não a fila; histórico fila para vendedor | Dono `005bJ00000piKAaQAM` (membro). Transações do insert: SOQL 6, DML 2, CPU 98 ms. `LeadHistory` do Lead de T12/T13 mostra Konecta2 para fila e fila para usuário (mesmo mecanismo) | passou |
| T2 | Alternância em Leads seguidos | 4 Leads UF MG, cada um em execução separada, 2 elegíveis | Alterna A, B, A, B | Comercial, teste, Comercial, teste (alterna) | passou |
| T3 | Lote de 200, 3 regiões, 3 elegíveis numa delas | 200 Leads numa só inserção, ordenados por região (SP 67, MG 67, RS 66), `Leads_Sul` com 3 elegíveis | Todos com dono, cada elegível recebe, sem erro de limite | 0 erros. SP 33/34, MG 34/33, RS 22/22/22 entre os 3 elegíveis. **SOQL 6/100, DML 2/150, linhas DML 400/10.000, CPU 1.458 ms/10.000, heap 38 KB** | passou |
| T3 (variante periódica) | Mesmo lote, regiões intercaladas SP, MG, RS, SP... | 200 Leads numa inserção | Evidência de R5 (não é reprovação, T7) | 0 erros, SOQL 6, DML 2, CPU 1.867 ms. SP e MG repartidos (33/34), mas **os 66 de RS foram todos para um só vendedor** (`005bJ00000piKAaQAM`): período 3 com 3 elegíveis, `MOD(n, 3)` constante. É o caso ruim da seção 1.5 do design | passou (R5 registrado) |
| T3b | Lote por usuário com `PS_Integracao_DistribuicaoLead`, sem cabeçalho, caminho assíncrono | Não há como usar outro usuário; atribuir o permission set a mim não está autorizado (é da EPLAST-38, não desta demanda). Lote de 200 sem cabeçalho como o usuário de serviço: não distribui (Flow antigo só age com a custom permission `Lead_DistribuicaoAutomaticaViaApi`); 200 ficaram com o criador. Suíte `LeadAssignmentServiceTest` (7 testes, inclui lote de 200) rodou: 7 de 7 com a org limpa | Todos com dono depois do assíncrono; medições | Caminho assíncrono pela integração **não exercitado**. A parte da classe passa na suíte | não executado |
| T4 | RJ e ES vão para `Leads_RJ_ES` | 1 Lead UF RJ e 1 UF ES, `Leads_RJ_ES` com 2 membros | Nenhum em `Leads_RJ` ou `Leads_ES`; dono = membro da fila nova | RJ: `005bJ000004gGVxQAM`; ES: `005bJ00000piKAaQAM` (ambos membros de `Leads_RJ_ES`) | passou |
| T5 | CNPJ de conta com dono X, UF de outra região | Conta E (dono Comercial, CNPJ só dígitos), 3 Leads UF RS com o CNPJ mascarado, execuções separadas. Antes, 3 Leads RS com o mesmo CNPJ quando a conta E não existia caíram no rodízio de `Leads_Sul` (3 vendedores diferentes) | Dono = X (3 de 3), não rodízio de `Leads_Sul` | 3 de 3 com dono `005bJ000004gGVxQAM` (dono da conta E). O controle sem conta mostrou rodízio de 3 | passou |
| T6 | Máscara em um lado, só dígitos no outro | Conta E só dígitos x Lead com máscara (T5, dono = X). Conta F com máscara, dono Comercial, x 3 Leads só dígitos | Dono = X nos dois sentidos | Os 2 sentidos devolveram o dono da conta (`005bJ000004gGVxQAM`, 3 de 3 no sentido inverso) | passou |
| T6b | Só na QAS: contagens de CNPJ | Fora da DEV | Registrar 3 contagens | Não executável aqui | não executado |
| T7 | Lote intercalado SP, MG (40) | 40 Leads numa inserção, 2 elegíveis em cada fila, fórmula `MOD` | Registrar distribuição | **SP: 20 para `005bJ00000piKAaQAM`, 0 para o outro. MG: 20 para `005bJ000004gGVxQAM`, 0 para o outro.** Concentração total de R5. Transação: SOQL 6, DML 2, CPU 360 ms | passou (evidência para o cliente, conforme o design; a decisão `MOD` x Weyl continua do gate) |
| T8 | CNPJ em 2 contas com donos diferentes | Contas C (dono teste) e D (dono Comercial), mesmo CNPJ; 4 Leads UF MG, um por execução | Não usa dono de conta; vai ao rodízio | Donos: teste, Comercial, teste, Comercial (alterna entre os 2 membros de `Leads_MG`; não fixou em um dono de conta) | passou |
| T9 | Conta casada com dono inativo | Plataforma recusa conta com dono inativo (`INACTIVE_OWNER_OR_USER`, nota do fixture); não dá para montar por insert | Rodízio | Não montado | não executado |
| T10 | UF vazia, com e sem conta | Lead sem UF e sem CNPJ; Lead sem UF com CNPJ da conta E (também antes da conta existir) | Com conta: dono = X. Sem conta: `Leads_Triagem` | Sem conta: dono = fila `Leads_Triagem`. Com conta (2 Leads): dono `005bJ000004gGVxQAM`. Com CNPJ e conta ainda inexistente: ficou em `Leads_Triagem` | passou |
| T11 | Fila regional sem elegível (só inativo) | 1 Lead UF GO, `Leads_CO` só com o membro inativo | Fica na fila | Dono = fila `Leads_CO` | passou |
| T12 | Caixa desmarcada | 1 Lead UF SP com `useDefaultRule = false` | Dono = criador | Dono `005bJ00000piKAaQAM` (criador) | passou |
| T13 | Transferência manual, `RodizioAtivo=false`, `DistribuicaoAtiva=false` | Transferência do Lead de T12 para `Leads_MG` (flags ligados). Os flags do CMDT só se mudam por deploy, que a tarefa proíbe | Transferência: redistribui. Flags: nada acontece | Transferência: dono passou de fila para membro (histórico: criador para fila, fila para `005bJ00000piKAaQAM`). Interruptor e `RodizioAtivo=false`: **não exercitados nesta rodada** (a rodada 1 provou o interruptor `false` com o antigo v1 do Flow, que já mudou) | passou (transferência); não executado (flags) |
| T14 | Falha na gravação (elegível sem leitura de Lead) | Só o usuário de serviço é usado; sem perfil de teste montado | Lead fica na fila, sem erro | Não montado | não executado |
| T15 | `Comercial - Analista` cria o Lead | Só o usuário de serviço pode ser usado; `System.runAs` não vale em Apex anônimo | Distribui sem erro de acesso | Não exercitado. Indício, não prova: o Flow roda em contexto de sistema e o elegível Comercial recebeu dono em T1 a T8 | não executado |
| T16 | Isolamento | Contagens antes e depois. `TriggerUtility.bypassTrigger` nas contas de teste | Account, Opportunity, Order iguais; nenhum job novo de Protheus | Opportunity 0/0, Order 0/0, Account 2 antes e **2 depois da limpeza** (6 de teste criadas e apagadas), `AsyncApexJob` de `SendAccountToProtheus` e `UpdateAccountCompanyInfo` **290 antes e 290 depois** | passou |
| T17 | Versões | `sf org list metadata` (campo `lastModifiedDate`) e Tooling | 3 `ApprovalProcess`, `LeadAssignmentService` e Flow antigo sem mudança; nenhuma classe nova | `ApprovalProcess`: `Opportunity.FinancialAnalysis` 2024-09-04, `Order.LiberationFinancial` 2025-01-29, `Quote.AssignPricing` 2026-08-31, todos anteriores ao build (17/11). `LeadAssignmentService` modificado em 2026-11-15 (anterior ao build). Flow antigo `Lead_AfterInsert_AplicaRegraAtribuicao` v1 Active, modificado em 2026-11-15. Flow novo: v1 e v2 Obsolete, v3 Active. `ApexClass` 1852 antes e depois. Regra v2 ativa e v1 inativa, como o plano registra | passou |
| T18 | Lead convertido com troca de dono | `convertLead` de um Lead de teste para a conta de teste F, sem oportunidade, dono do convertido diferente do atual | Flow entra e sai sem erro | Conversão com sucesso, sem erro; Lead ficou convertido | passou |

## Pendências do construtor
| Pendência | Resultado |
|---|---|
| Rodízio nunca exercitado com sucesso | Exercitado: T1, T2, T3, T4, T5, T6, T7, T8, T10, T11, T12, T13 (transferência), T16, T17, T18 passam. T3b, T6b, T9, T14, T15 e a parte dos flags de T13 sem prova |
| Membros de teste em `Leads_RJ_ES` e filas de teste pelo fixture | Montados (`filas`) e removidos (`limparfilas`). Fixture rodou sem correção; precisei de contas E e F extras (script de Apex anônimo no /tmp, com `DuplicateRuleHeader.allowSave`), porque um insert simples de conta com CNPJ novo caiu em `DUPLICATES_DETECTED`. O fixture não foi alterado |
| Lote de 200 (SOQL, DML, CPU) | SOQL 6/100, DML 2/150, CPU 1.458 a 1.867 ms/10.000. Muito abaixo de 70%. Saída da seção 4 do design não necessária |
| 3 processos de aprovação (T17) | Conferidos por `sf org list metadata -m ApprovalProcess`: nomes e datas de modificação anteriores ao build |

## Mudanças que fiz e o que ficou
- Usuário de execução: nenhuma mudança (sem permission set, sem Marketing User, sem campo de Protheus; as contas de teste e as filas não exigiram).
- Nenhum TraceFlag nem Debug Level criado.
- Dados de teste: 674 Leads (incluindo 1 convertido), 6 contas, 1 contato (da conversão) e 11 membros de fila, **todos apagados**. Conferido por contagem depois: Leads `TESTE EPLAST-35` 0, `Account` 2 (as 2 originais), contatos das contas de teste 0, `GroupMember` direto em filas `Leads_*` 0.
- Nenhum job Apex agendado criado.
- Estado da DEV deixado como encontrado: Flow v3 Active, regra v2 ativa, `DistribuicaoAtiva__c = true`.

## O que pode ter saído da org
Nada. As contas de teste foram criadas com `TriggerUtility.bypassTrigger`, sem `UpdateAccountCompanyInfo` nem `SendAccountToProtheus` (`AsyncApexJob` 290 antes e depois). A cadeia do Flow não chama sistema externo nem envia e-mail.

## O que ficou sem prova e o que uma pessoa precisa fazer
1. **T3b** (caminho assíncrono do usuário de integração, 200 Leads, sem cabeçalho): precisa de um usuário com `PS_Integracao_DistribuicaoLead`. Quem opera a QAS roda o lote como esse usuário e registra SOQL, DML e CPU.
2. **T15** (`Comercial - Analista` pela tela) e **T14** (elegível sem leitura de Lead): precisam de login do usuário Comercial e de um perfil de teste. Quem homologa faz pela tela.
3. **T13, interruptor e `RodizioAtivo=false`**: exigem trocar o CMDT `Padrao` (deploy ou Setup). O QA com a esteira pode desmarcar `DistribuicaoAtiva__c`, criar um Lead e conferir que o dono não muda, e depois fazer o mesmo com `RodizioAtivo__c`.
4. **T9** (dono inativo na conta): a plataforma não deixa criar a conta assim. Só se prova com uma conta existente cujo dono tenha sido inativado depois.
5. **T6b** (contagens de CNPJ): só na QAS, só contagem agregada.
6. Decisão do gate pendente sobre a fórmula (R5): T7 e a variante periódica de T3 mostram que `MOD(n, k)` concentra todo o lote num vendedor quando a chegada alterna regiões com período múltiplo de `k` (40 de 40 em cada região; 66 de 66 em RS). É o comportamento aceito no design; a troca para a fórmula de Weyl é uma fórmula do Flow.
