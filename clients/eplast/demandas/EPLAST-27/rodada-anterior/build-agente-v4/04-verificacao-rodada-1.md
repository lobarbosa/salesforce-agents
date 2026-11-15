**Verificação:** reprovada
**Org de teste:** `sbx-eplast-dev` (alias `sbx-eplast-dev`, sandbox, `sf org list` em 2026-11-15: Connected)

# Verificação — EPLAST-27: Próxima melhor ação por cliente

Só a dev. Nada em QA nem em produção. Nada do que o builder construiu foi alterado. O Flow foi exercitado por Apex anônimo (`Flow.Interview`) e pela API de ações (`/actions/custom/flow/Account_Agente_ProximaAcao`). O agente não pôde ser exercitado (ver "Lacunas").

## Resumo
- A regra de decisão do Flow está correta: ordem NODATA, A1, A2, A3, NONE, limiar por Custom Metadata, sem gravação, sem e-mail e sem dado pessoal.
- **Falha 1 (bloqueante):** com a configuração padrão (`RestrictToOwner__c = true`), o dono da conta recebe `NOT_OWNER` na própria conta. Na prática o vendedor nunca recebe sugestão.
- O agente (ativação da v4, permission set, licença) ficou inconclusivo. O `agentGraph` **não** foi regenerado com a ação.

## Contenção do risco R2 (Protheus) antes de criar massa
- `comentarios-do-card.md` não traz autorização para disparar a cadeia Protheus. Por isso o envio foi contido, não autorizado.
- `AccountTrigger` e `OpportunityTrigger` leem `TriggerUtility.bypassTrigger` (`TriggerUtility__mdt.TriggerExecution.BypassTrigger__c`). Estava `false`. Pela própria configuração da solução, coloquei `true` (deploy do registro na dev), criei a massa e testei. Ao final restaurei `false` (conferido por SOQL) e o arquivo no git voltou ao original (`git status` sem alteração em `force-app`).
- Os Flows de Account e Opportunity ativos que consultei na metadata não têm callout nem e-mail (criam Task e EconomicGroup__c, CPQ interno). O Protheus só é chamado pelos handlers de trigger, que estavam desviados.
- Evidência: `IntegrationLog__c` = 0 antes, durante e depois (COUNT agregado).

## Massa sintética (todos com nome `TESTE EPLAST-27 ...`)
7 contas (NODATA, A1, A2, A3, NONE, OTHER, RISKA), 7 oportunidades (record type Industria, para passar as validation rules), 4 tarefas concluídas com data passada (para `LastActivityInDays`), 1 `Branch__c` e 1 `PaymentTerms__c` fictícios. Endereço, e-mail e telefone sintéticos (`example.invalid`) só para satisfazer validation rules. Estado conferido por SOQL antes de executar: A1 risco E e oportunidade com 45 dias sem atividade; A2 sem risco, oportunidade com 45 dias e última compra 2026-08-16 (Inactive true); A3 sem risco, sem oportunidade aberta, última compra 2026-08-16; NONE oportunidade com 5 dias e compra 2026-11-05; RISKA risco `A`, oportunidade com 45 dias; NODATA e OTHER sem oportunidade e sem compra.
Para criar as oportunidades as contas ficaram temporariamente com outro usuário da dev como dono (a validation rule exige ID Protheus no dono). Depois voltaram ao usuário de teste. A conta OTHER ficou com o outro usuário. Esse usuário não foi alterado.

## Casos executados

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | A1 tem prioridade sobre A2 | Flow na conta A1 (risco E + oportunidade 45 dias), `RestrictToOwner=false` | A1 | `A1`: "Tratar risco da conta: o cadastro está com risco E, ..." | passou |
| C2 | A2 cita estágio | Conta A2 (sem risco, oportunidade 45 dias, compra antiga), `RestrictToOwner=false` | A2 com o estágio, A2 antes de A3 | `A2`: "Retomar oportunidade parada: há uma oportunidade em Qualificação sem atividade há 45 dias." | passou |
| C3 | A3 | Conta A3 (compra há 91 dias, sem oportunidade aberta), `RestrictToOwner=false` | A3 | `A3`: "Reativar cliente sem compra recente: ..." | passou |
| C4 | NONE | Conta NONE (oportunidade 5 dias, compra há 10 dias), `RestrictToOwner=false` | "Nenhuma ação prioritária" | `NONE`: "Nenhuma ação prioritária no momento." | passou |
| C5 | NODATA sem erro técnico | Conta NODATA (sem oportunidade, sem compra), `RestrictToOwner=false` | "Dados insuficientes" | `NODATA`: "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." | passou |
| C6 | Valor de risco fora da lista não gera A1 | Conta RISKA (risco A, oportunidade 45 dias), `RestrictToOwner=false` | A2, não A1 | `A2` | passou |
| C7 | Conta de outro vendedor não revela dados | Conta OTHER (dono = outro usuário) e conta com Id inexistente, `RestrictToOwner=false` | Sem dado da conta | OTHER devolveu `NODATA` (a restrição estava desligada para este teste, ver C8); Id inexistente devolveu `NOT_OWNER` com mensagem neutra | passou (parte do Id inexistente) |
| C8 | Dono vê a sugestão na própria conta (config padrão) | `RestrictToOwner=true` (valor entregue), dono da conta = usuário que executa. Apex anônimo e API de ações, contas NODATA, A1, A2, A3, NONE, RISKA | Resultado da regra (NODATA, A1, A2...) | **`NOT_OWNER` em todas** ("Esta conta não está na sua carteira.") | **falhou** |
| C9 | Conta de outro vendedor, config padrão | `RestrictToOwner=true`, contas com dono diferente do usuário que executa (todas, antes de devolver a posse; e OTHER) | `NOT_OWNER` sem dado | `NOT_OWNER` neutro | passou (mas é o mesmo resultado de C8, então não prova a comparação) |
| C10 | Consulta não grava nada | Snapshot de MAX(LastModifiedDate) e COUNT de Account, Opportunity e Task; 10 execuções do Flow na conta A2 e uma rodada em todas as contas; depois novo snapshot | Nenhuma alteração; sem DML | Datas e contagens idênticas antes e depois. Em 10 execuções: `dml=0 email=0 callouts=0` (Limits no Apex). O Flow não tem `recordCreates`, `recordUpdates` nem `actionCalls` | passou |
| C11 | Sem comunicação pelo CRM | Metadata do Flow e contadores de e-mail e callout do C10 | Sem e-mail alert, Apex de e-mail nem envio | `email=0`, `callouts=0`; Flow sem ação de e-mail. Marketing Cloud não tocado | passou |
| C12 | Sem dado pessoal na resposta | Campos lidos pelo Flow (metadata) e saídas | Só `actionCode` e `message`; sem CPF, e-mail ou telefone | Saídas só `actionCode` e `message`. Campos lidos: Id, Name, OwnerId, Risk__c, LastPurchase__c, Inactive__c (conta); Id, StageName, LastActivityInDays (oportunidade). As mensagens obtidas não trazem esses dados. `Name` é lido mas não aparece nas mensagens | passou |
| C13 | Limiar muda sem deploy de código | Registro CMDT `Default` com `StaleOpportunityDays__c` = 60 (deploy do registro, não de código; depois voltou a 30). Conta A2 (oportunidade com 45 dias), `RestrictToOwner=false` | A2 deixa de ser sugerida | Com 60: conta A2 devolveu `A3` (não A2); RISKA devolveu `NONE`. Com 30 voltava A2 (C2). A1 manteve-se por regra de risco | passou |
| C14 | Mesma regra para os demais consumidores (EPLAST-28, eplast-ent-11) | Não há esses consumidores construídos | n/a | n/a | não executado |
| C15 | Agente responde com a ação | Ver "Lacunas" | Resposta do SFAgent2 | n/a | não executado |

C1 a C6 foram exercitados com `RestrictToOwner__c` temporariamente `false` no registro `Default`, por causa da Falha 1, para poder provar a regra. O registro foi restaurado (30, `E`, `true`) e conferido por SOQL.

### FALHA 1 — Dono da conta recebe `NOT_OWNER` na própria conta com a configuração padrão
- **Como reproduzir:** na dev, com `NextBestActionSetting.Default` como entregue (`RestrictToOwner__c = true`), crie uma conta cujo dono é o usuário que executa e rode o Flow `Account_Agente_ProximaAcao` com `recordId` da conta. Fiz por `Flow.Interview.createInterview(...).start()` e por `POST /services/data/v67.0/actions/custom/flow/Account_Agente_ProximaAcao` com `{"inputs":[{"recordId":"<Id>"}]}`. Dono confirmado por SOQL (`OwnerId` = Id do usuário que executa, sem username no artefato).
- **Obtido:** `actionCode = NOT_OWNER`, "Esta conta não está na sua carteira." em todas as 6 contas, nas duas formas de chamada. Interview da API de ações com `Flow__InterviewStatus: Finished`, sem erro.
- **Esperado:** com dono igual ao usuário, seguir a regra (NODATA, A1, A2, A3 ou NONE). O mesmo Flow, com `RestrictToOwner__c = false`, devolve o resultado correto, então a leitura da conta, as oportunidades e a regra estão certas. O erro está na decisão `CheckOwner` (`GetAccount.OwnerId NotEqualTo $User.Id`).
- **Causa provável:** a comparação de `OwnerId` com `$User.Id` no elemento `CheckOwner` dá "diferente" mesmo com o mesmo usuário (formato do Id ou tipo da comparação no Flow). Não investiguei além disso porque corrigir é do builder. Como efeito, o vendedor nunca recebe sugestão pela configuração padrão. O C9 não distingue isso do caso de outro dono, e o teste de dono diferente só prova o negativo.
- **Observação para o builder:** testar o positivo com usuário dono diferente do administrador exige executar como esse usuário. Aqui foi o mesmo usuário nas duas chamadas e o resultado foi o mesmo.

## Lacunas (o que ficou sem prova) — agente SFAgent2 e Agentforce
- As 4 versões do bot `SFAgent2` estão `Inactive` na dev (`BotVersion`). Ninguém atribuiu `PS_Comercial_ProximaAcao` (0 `PermissionSetAssignment`). O permission set tem 1 permissão de Flow (`FlowDefinition`) e nenhuma concessão do agente (já declarado pelo builder). Sem ativar a v4 e sem licença/concessão de Agentforce não há como conversar com o agente por `sf`. **Não consegui provar:** que o assistente chama a ação a partir de uma pergunta de próxima ação; que perguntas variadas ("oportunidades paradas", "quais clientes precisam de acompanhamento") não caem nas instruções antigas; que a resposta traz só a mensagem do Flow.
- **`agentGraph` não regenerado:** na dev, o bundle `SFAgent2_v4` tem `ProximaAcaoCliente` no `.agent` decodificado (instrução "PRÓXIMA AÇÃO POR CLIENTE", alias da ação e `target: "flow://Account_Agente_ProximaAcao"`) e nos `localActions/.../ProximaAcaoCliente_EPLAST27` (entrada `recordId`, saídas `message` e `actionCode`). O `SFAgent2_v4_graph.json` decodificado não contém a ação (0 ocorrências). Provavelmente o grafo só se regenera ao ativar ou publicar a versão. O risco R6 permanece: o `.agent` ainda traz instruções antigas (STEP 7 e ACOMPANHAMENTO DE CARTEIRA, com limiar de 15 dias para "oportunidade parada", diferente dos 30 dias do CMDT). Só dá para provar testando o agente ativo.
- **O que uma pessoa precisa fazer para provar:** ativar a v4 do SFAgent2 na dev, conceder o agente ao `PS_Comercial_ProximaAcao` (licença de Agentforce), atribuir o permission set a um vendedor de teste e a dois contas dele e de outro, conferir que o grafo passou a ter a ação, e repetir C1 a C6 e as perguntas variadas pelo assistente. Isso só depois de a Falha 1 ser corrigida.
- C14 (EPLAST-28 e eplast-ent-11): consumidores ainda não existem; o Flow é reutilizável por ser autolançado e com saídas `actionCode` e `message`.

## O que pode ter saído da org
Nada. A cadeia Protheus estava desviada (`bypassTrigger = true` durante a massa). `IntegrationLog__c` = 0 antes e depois. Nenhum e-mail, callout ou registro de integração. Os contadores de callout e e-mail foram zero nas 10 execuções do Flow.

## Limpeza
- Apaguei: 7 contas, 7 oportunidades, 15 tarefas (4 criadas por mim + 11 criadas pelos Flows da org ao criar as contas e oportunidades), 7 `EconomicGroup__c` (criados pelos Flows, nome começando `TESTE EPLAST-27`), o `Branch__c` e o `PaymentTerms__c` fictícios. Conferido por COUNT: Account 0, Opportunity 0, Task 0, Branch__c 0, PaymentTerms__c 0, `IntegrationLog__c` 0, contas `TESTE EPLAST-27%` 0.
- A dev não tinha Account, Opportunity nem Task antes da massa (COUNT 0 em Account e Opportunity); restam 9 `EconomicGroup__c` com outro nome, que não são meus e não foram tocados.
- Restaurado: `TriggerUtility.TriggerExecution.BypassTrigger__c = false`; `NextBestActionSetting.Default` = 30, `E`, `true`. Os dois registros foram implantados a partir do conteúdo do git; `git status` não mostra alteração em `force-app`.
- Resíduo possível: fora da massa, a lixeira (`Recycle Bin`) da dev guarda os registros apagados até expirar.
