**Resultado do build:** concluído

# EPLAST-29 · Plano de build (rodada 2: v7 em cima da v6 da EPLAST-27)

Org de build: `sbx-eplast-dev` (única em `sf org list`, sandbox, conectada). Branch `feature/EPLAST-29`. Nada tocado em produção, QA ou Marketing Cloud. Nenhum objeto, campo ou Apex novo.

## Por que v7 e não v5
O design fala em "v5", mas na org a numeração mudou: v1 a v6 existem; a v5 (build anterior desta demanda, ativa) e a v6 (EPLAST-27, inativa, sem o tópico `acoes_comerciais`). Versão ativa não aceita deploy e a v6 é de outra demanda, então a versão nova desta demanda é a **v7** (próxima livre, confirmada por `SELECT VersionNumber, Status FROM BotVersion`). Onde o design diz "v5", leia "v7". Base: a v6 da EPLAST-27 (comparei o script e o bundle: v5 e v6 só diferem pelo tópico `acoes_comerciais` e pela transição `go_to_acoes_comerciais` no roteador), logo a v7 = v6 + `acoes_comerciais`.

## Componentes
| Tipo | API name | Estado | Observação |
|---|---|---|---|
| GenAiPlannerBundle | `SFAgent2_v7` | criado, deploy Succeeded | Insights (4 ações, incluindo `ProximaAcaoCliente` da EPLAST-27) copiados sem mudança; roteador com `go_to_acoes_comerciais`; tópico novo `acoes_comerciais` |
| BotVersion | `SFAgent2.v7` | criado, ligado ao planner `SFAgent2_v7` | v4, v5 e v6 intactas |
| Tópico local | `acoes_comerciais` (GenAiPlugin `acoes_comerciais_EPLAST29_v7`) | dentro do bundle | Ações `IdentificarRegistro` (padrão `identifyRecordByName`, leitura, sem confirmação) e `CriarTarefa` (Flow `Task_Agente_CriarTarefa`, confirmação obrigatória) |
| Flow | `Task_Agente_CriarTarefa` | **reaproveitado, sem mudança** | Versão ativa na dev (301Ha000016Tf4LIAS), vinda do build anterior; não precisou de versão nova |
| PermissionSet | `PS_Comercial_AssistenteAcoes` | **reaproveitado, sem mudança** | Já existe na dev |

Arquivos: `force-app/main/default/genAiPlannerBundles/SFAgent2_v7/` e `force-app/main/default/bots/SFAgent2/v7.botVersion-meta.xml`. O script do agente (Agent Script) é o mesmo da v5, que já tinha o tópico e não cita número de versão.

Descrições: tópico, instruções e ações mantêm as descrições do build anterior.

## Decisões de implementação (desvios do design)
1. **Nomes globais com sufixo `_v7`.** GenAiPlugin e GenAiFunction são globais na org e o deploy com o mesmo nome falha por duplicidade (aprendido no build anterior). Todos os itens copiados e os do tópico novo ganharam `_v7` (ex.: `CriarTarefa_EPLAST29_v7`). `localDeveloperName` e script não mudam.
2. **R7 resolvido.** A forma aceita (ação local com alvo de Flow e `isConfirmationRequired`) foi confirmada: o deploy do bundle passou. O risco de ação de Flow em bundle não existe mais; já havia `ProximaAcaoCliente` (Flow).
3. **`deploy validate` exige rodar testes** (a CLI não aceita `NoTestRun`); o validate do bundle rodou os testes locais da org e só falhou em cobertura geral (67%), por testes pré-existentes quebrados da Protheus, sem erro em componente nosso. O deploy foi feito com `deploy start --test-level NoTestRun`, só na dev.
4. **Graph (`agentGraph/*_graph.json`) não gerado para a v7**: artefato derivado, como na v5. Conferir no Agent Builder que o tópico `acoes_comerciais` aparece.
5. **Arquivos da v6 (EPLAST-27) não entram neste commit.** Foram baixados só para ler a base; ficam fora do PR.
6. **Dependência para outras orgs:** o bundle v7 referencia o Flow `Account_Agente_ProximaAcao` (EPLAST-27). Na QA, EPLAST-27 e esta demanda precisam chegar na ordem certa (R3 do design: a base passa a ser a v7).

## Versões e ativação
- Dev: `SFAgent2` v7 **ativada** (`sf agent activate`) para a verificação; v1 a v6 `Inactive`. A v5 era a ativa e tinha o mesmo comportamento. Rollback: ativar a v6 (sem o tópico novo).
- QA: ativação pelo fluxo de release, não aqui.

## Concorrência (00-preflight)
EPLAST-27 (aguardando_gate_build) e EPLAST-34 (aguardando_gate_design) também mexem no `SFAgent2`. Nada de outra demanda foi editado no lugar: a v6 não foi alterada, e o conteúdo da EPLAST-27 foi só copiado na v7. EPLAST-34 deve partir da v7.

## Para a verificação
- Tópico `acoes_comerciais` na v7 ativa; roteamento do pedido "crie uma tarefa..." para ele; `insights_comerciais` com as mesmas 4 ações da v6.
- Confirmação obrigatória antes de gravar; recusa de assunto `Check In @`; registro ambíguo; AC-4 (acesso negado) e licença Agentforce (R9).
- Pendências já conhecidas da rodada anterior: caminho de sucesso exige Account/Opportunity de teste (gatilho com callout Protheus, R8) e usuário `Comercial - Analista`; usar `fixtures/` e o usuário de teste da conta de serviço da Konecta (regra 6 do CLAUDE.md da Eplast, resolvido por consulta na org de dev).
- Premissas assumidas do design (seção 9) construídas como decididas; nada bloqueado.

## Correções da rodada 1
Org de build: `sbx-eplast-dev` (única em `sf org list`). QA não tocada. Nenhum componente novo ou alterado nesta sessão.

| Falha | Tratamento |
|---|---|
| FALHA 1 (crítica): v7 implantada na QA mas inativa; o agente ativo (v4) não tem `acoes_comerciais`, então AC-1 a AC-9 não rodaram | **Não é corrigível no build.** O bundle, o Flow e o PS chegaram à QA corretos (QA confirmou BotVersion v7, Flow ativo e PS). O que falta é ativar a versão na QA, passo separado que o builder não executa (builder não toca a QA; ativação é do release, conforme "Versões e ativação"). Ação necessária antes da nova sessão de QA: ativar na QA a versão do `SFAgent2` que contém `acoes_comerciais`, combinando com EPLAST-27 e EPLAST-34 (a v6 da EPLAST-27 está inativa e a v7 já a contém). |

### Estado da dev conferido nesta sessão (`sf`, só metadata)
- `BotVersion` do `SFAgent2` na dev: v1 a v7 Inactive, **v8 Active**, v9 Inactive. A numeração avançou depois do build da v7 (v8 em 2026-11-15 20:38 UTC e v9 em 2026-11-16 00:44 UTC; não criadas nesta sessão).
- `GenAiPluginDefinition` com `acoes_comerciais_EPLAST29` existe nas versões `_v7`, `_v8` e `_v9`: o tópico segue presente nas versões mais novas. Não abri o conteúdo da v8 e da v9 item a item; quem ativar na QA deve conferir qual versão leva a QA e que ela contém o tópico e as 4 ações de `insights_comerciais`.
- Flow `Task_Agente_CriarTarefa`: versão 1, Active, sem versão nova (nada a mudar no Flow).
- Dependência de ordem na QA: o bundle referencia o Flow `Account_Agente_ProximaAcao` (EPLAST-27); ativar só com ele presente.
- Para a rodada 2 de QA: AC-4 precisa de usuário comum sem o PS. A QA só achou administradores da Konecta; usar o usuário de teste da regra 6 do CLAUDE.md da Eplast (`projetos@konectabr.com%`) e, se for administrador, declarar que AC-4 fica sem prova em vez de simular.
