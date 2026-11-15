**Resultado do build:** concluído

# EPLAST-34 — Plano de build: resumos para reuniões Comercial, GDD, S&OP e Board

**Org confirmada:** `sf org list` mostra uma única org, `sbx-eplast-dev` (Sandbox, Connected, Org Id `00DHa000006vfMLMAY`). É a dev da esteira (regra 5 da conta). Todos os comandos usaram `-o sbx-eplast-dev`. Nada em QA, produção ou Marketing Cloud. Nenhum anonymous Apex nem DML de dados nesta sessão.
**Branch:** `feature/EPLAST-34`. **Decisão:** código (Apex invocável) exposto como ação nova do `SFAgent2`, no tópico existente `insights_comerciais` (`03-design.md`, seção 1).
**Motivo desta rodada:** a rodada anterior ligou a ação editando a `SFAgent2_v5` no lugar. Hoje a dev tem v1 a v7, com a **v7 ativa** (EPLAST-27 e EPLAST-29 criaram v6 e v7). A regra é versão nova, inativa, sem editar a que está em uso. Esta rodada criou a **v8**.

## Avisos do preflight tratados

| Aviso | Tratamento |
|---|---|
| EPLAST-27 e EPLAST-29 também mexem em `SFAgent2` | A v8 parte da **v7 ativa** (baixada da org), então carrega `ProximaAcaoCliente_EPLAST27` e o tópico `acoes_comerciais_EPLAST29` (com `CriarTarefa` e `IdentificarRegistro`) sem alteração de conteúdo. Só os sufixos `_v7` viraram `_v8`. A única diferença da v8 para a v7 é a ação `ResumoReuniao_EPLAST34_v8` e a instrução `instruction1_EPLAST34_v8` no tópico `insights_comerciais`. As outras duas demandas, se continuarem, devem partir da v8 e criar a v9 |
| Versão ativa não aceita deploy | v7 não foi tocada nem desativada. v8 implantada nova |
| Classes sem job pendente | Reconferido: 0 `AsyncApexJob` pendente de `MeetingSummary*`. Não agendei nada |

## Versões e ativação

| Item | Estado agora (dev) | Passo seguinte |
|---|---|---|
| `SFAgent2` `BotVersion` v7 (`GenAiPlannerBundle SFAgent2_v7`) | **Ativa, intocada** | Sai quando a v8 entrar |
| `SFAgent2` `BotVersion` v8 (`GenAiPlannerBundle SFAgent2_v8`) | **Criada, Inativa** (confirmado: v7 Active, v8 Inactive) | **Ativação na dev é do `verificador`**, para testar ponta a ponta: `sf agent activate -o sbx-eplast-dev --api-name SFAgent2 --version 8`. Isso desativa a v7. Registrar na verificação que v8 entrou e v7 saiu |
| `SFAgent2_v5` | Inativa. A ação `ResumoReuniao_EPLAST34_v5` da rodada anterior continua nela (foi editada no lugar naquela rodada; não mexi mais) | Nenhum. Fica como histórico. Não ativar a v5 |
| Classes `MeetingSummaryService` e `MeetingSummaryServiceTest`, permission set `PS_Comercial_ResumoReuniao` | Já na dev desde a rodada anterior, sem mudança de código nesta | — |

**Desfazer:** `sf agent activate ... --version 7` reativa a v7 (e desativa a v8). A v8 pode ficar inativa sem efeito. O permission set não está atribuído a ninguém.
**QA:** estado do agente na QA não foi consultado (fora do build). O passo de QA confere qual versão está ativa lá antes de levar a v8 e registra qual entrou e qual saiu.

## Componentes

| Componente | Situação |
|---|---|
| `force-app/main/default/classes/MeetingSummaryService.cls` (+meta, API 67.0) | Já existia da rodada anterior, não alterada. `@InvocableMethod`, `with sharing`, só leitura, SOQL agregado `WITH USER_MODE`, 4 tipos, status por seção e geral, rodapé "Dados até". Sem DML, callout, e-mail ou async |
| `.../classes/MeetingSummaryServiceTest.cls` (+meta) | Já existia, não alterada. 10 testes |
| `.../permissionsets/PS_Comercial_ResumoReuniao.permissionset-meta.xml` | Já existia, não alterado. Só acesso à classe (PD-11) |
| `.../genAiPlannerBundles/SFAgent2_v8/` | **Novo.** Ação `ResumoReuniao_EPLAST34_v8` (tipo `apex`, alvo `MeetingSummaryService`, sem confirmação) ligada ao tópico `insights_comerciais_1790e90ae9fbdc8_v8`, mais a instrução de usar a ação e mostrar o texto como veio, sem recalcular número (PD-09). Schemas de entrada (`tipo`, `dataInicio`, `dataFim`) e saída (`textoResumo`, `status`, `dataHoraCorte`) copiados da v5. Confirmado na org: `GenAiPlannerDefinition SFAgent2_v8` e `GenAiFunctionDefinition ResumoReuniao_EPLAST34_v8` existem |
| `.../bots/SFAgent2/v8.botVersion-meta.xml` | **Novo.** `BotVersion` v8 apontando para o planner `SFAgent2_v8`; cópia da v7 só com nome e planner trocados. Sem ele o planner v8 existe, mas não aparece como versão do agente |
| `.../bots/SFAgent2/SFAgent2.bot-meta.xml` | Baixado da org sem edição; o deploy do `BotVersion` exigiu o `Bot` junto. A org mostrou "Changed" (reaplicação do mesmo conteúdo). v7 permaneceu Ativa depois |

Nenhum Flow, objeto, campo, trigger, relatório ou Custom Metadata novo. `CustomerSummaryService` e `PS_Comercial_ResumoClienteAgente` não foram tocados. Ações padrão (`AgregacaoPedidos`, `ConsultarPedidos`, `IdentificarConta`) mantidas como na v7.

## Testes Apex (sbx-eplast-dev)

Comando: `sf apex run test -o sbx-eplast-dev -n MeetingSummaryServiceTest --code-coverage` (Run Id `707Ha00001E2t9Q`).

- **Resultado:** Passed, 100% de aprovação, 0 falhas (resumo do `sf`: 10 testes executados, 100% de aprovação; só 9 linhas de método apareceram na saída que li, e não identifiquei qual faltou na tabela).
- **Cobertura de `MeetingSummaryService`: 93%** (mínimo 85%). Não coberto: ramos de `QueryException` dentro das seções e alguns de `VOLUME_EXCEDIDO` das seções 2.
- Cobertura agregada da org: 43% nesta execução (achado 2 do assessment; esta demanda não a piora). Triggers de Account e Opportunity aparecem na lista porque o fixture dispara a cadeia deles; não foram alterados.
- Cenários: feliz (4 tipos), bulk 200 oportunidades e 200 pedidos, top 20 contas mais "Demais contas", período informado, negativos (tipo inválido, nulo, período invertido, > 366 dias, exceção vira `ERRO`), volume excedido, formato de moeda pt-BR, permissão com `System.runAs` (perfil `Minimum Access - Salesforce`: `SEM_ACESSO`). Sem `SeeAllData`; dado `TESTE-EPLAST34` criado dentro do teste e revertido. A pasta `fixtures/` do cliente não existe neste workspace, então o dado de teste é só o do teste Apex.

## Premissas do design usadas (sem pendência)

PD-01 vendedor por `OwnerId`; PD-02 top 20 mais "Demais contas"; PD-03 BRL sem conversão; PD-04 aberta = `IsClosed = false` com `CloseDate` no período; PD-05 todos os status de pedido por `EffectiveDate`; PD-06 teto 40.000 linhas; PD-07 versão do agente: o design dizia "v4", mas a mais recente hoje é a v7, então a ação entra na versão nova **v8** (divergência registrada, mesma intenção da premissa); PD-08 conferência contra a base `TESTE-EPLAST34`; PD-09 texto mostrado como veio; PD-10 período máximo 366 dias; PD-11 permission set próprio. Nenhuma virou bloqueio.

## Riscos do design tratados

- **R2 (versões do agente):** o cenário mudou (v7 ativa, não "4 inativas"). Solução: v8 inativa; ativação na dev fica com o verificador, passo registrado acima.
- **R3 (deploy frágil de agente):** funcionou na primeira tentativa para o planner. O `BotVersion` falhou duas vezes antes (sozinho, e por caminho de arquivo) e passou quando o `Bot` foi junto. Nenhum passo manual no Agent Builder.
- **R4 (roteamento e números reescritos):** instrução explícita no tópico e saída marcada como exibível. **Não provado nesta etapa.**

## O que o verificador testa na dev

1. Ativar a v8 (comando acima), registrando v8 entra e v7 sai.
2. Atribuir `PS_Comercial_ResumoReuniao` ao usuário que testa (nenhuma atribuição feita no build). Usuário de teste da conta: `005bJ00000piKAaQAM` (ativo, perfil Administrador do sistema). O `005bJ00000hBJmYQAW` está inativo. Não alterar perfil nem permissão deles além da atribuição do permission set de teste, se for o caso.
3. Conversa ponta a ponta (`sf agent preview`) com as frases dos 4 tipos: confere roteamento para `ResumoReuniao`, e não para `AgregacaoPedidos`, e que o texto vem sem número reescrito (R4).
4. Regressão das ações existentes: 1 pergunta de agregação, 1 de consulta, 1 de identificação de conta, 1 de próxima ação (EPLAST-27) e 1 de tarefa (EPLAST-29), para provar que a v8 não quebrou o que veio da v7.
5. Caso misto "lê Opportunity e não lê Order" (PARCIAL por falta de Order) segue sem prova na sandbox (licença `Salesforce` 14/14, R5); fica como incerteza.
6. CA-05: contagens agregadas de Account, Opportunity e Order antes e depois (a dev tem 0 registros de negócio). Existem 8 jobs agendados na org (`CronTrigger` em espera), que não são desta demanda.
7. Se a ativação falhar, a verificação do agente fica inconclusiva e a lógica já está provada pelo teste Apex.

## Dívida identificada (fora do escopo, não tocada)

- `SFAgent2_v5` foi editada no lugar na rodada anterior (contra a regra atual); fica como está, inativa.
- `OrderTrigger` e `AccountTrigger` custom com nome duplicado de trigger do CPQ (achado 10); cobertura Apex baixa da org (achado 2); automações concorrentes em Opportunity e Order (achado 1).
- O `agentScript/*.agent` dos bundles é cópia do retrieve e não carrega as ações; vale o XML do bundle e a org.
