**Resultado do build:** concluído

# EPLAST-34 — Plano de build: resumos para reuniões Comercial, GDD, S&OP e Board

**Org usada:** `sbx-eplast-dev` (única listada em `sf org list`, Connected; é a sandbox de DEV da esteira, confirmação do Leonardo em 15/11 no card). Nada em QA, produção ou Marketing Cloud.
**Branch:** `feature/EPLAST-34`. **Decisão:** código (Apex invocável), conforme `03-design.md` seção 1.

## Arquivos criados e alterados

| Arquivo | O que é |
|---|---|
| `force-app/main/default/classes/MeetingSummaryService.cls` (+meta, API 67.0) | `@InvocableMethod resumir`, `with sharing`, só leitura. 4 tipos (COMERCIAL, GDD, SOP, BOARD), SOQL agregado `WITH USER_MODE`, status por seção OK/VAZIO/SEM_ACESSO/VOLUME_EXCEDIDO, status geral OK/PARCIAL/SEM_ACESSO/ERRO, texto pt-BR com origem de cada número e rodapé "Dados até dd/mm/aaaa hh:mm". Constantes: top 20 contas (PD-02), período máximo 366 dias (PD-10), teto 40.000 linhas (PD-06). Sem DML, callout, e-mail, async |
| `force-app/main/default/classes/MeetingSummaryServiceTest.cls` (+meta) | 10 métodos de teste (ver abaixo) |
| `force-app/main/default/permissionsets/PS_Comercial_ResumoReuniao.permissionset-meta.xml` | Acesso só à classe `MeetingSummaryService`; nenhuma permissão de objeto ou campo (PD-11) |
| `force-app/main/default/genAiPlannerBundles/SFAgent2_v5/` | Bundle recuperado da dev e alterado: ação `ResumoReuniao_EPLAST34_v5` (tipo `apex`, alvo `MeetingSummaryService`) ligada ao tópico existente `insights_comerciais_1790e90ae9fbdc8_v5`, mais a instrução `instruction1_EPLAST34_v5` (chamar a ação para pedido de resumo de reunião e mostrar o texto como veio, sem recalcular número, PD-09). Schemas de entrada (`tipo`, `dataInicio`, `dataFim`) e saída (`textoResumo` exibível, `status`, `dataHoraCorte`) em `localActions/.../ResumoReuniao_EPLAST34_v5/` |

Nenhum agente, tópico, Flow, objeto, campo, relatório ou Custom Metadata novo. Ações padrão (`AgregacaoPedidos`, `ConsultarPedidos`, `IdentificarConta`) e `ProximaAcaoCliente_EPLAST27_v5` não foram tocadas. `CustomerSummaryService` e seu permission set não foram tocados.

## Deployado na dev

- `ApexClass` `MeetingSummaryService` e `MeetingSummaryServiceTest`; `PermissionSet` `PS_Comercial_ResumoReuniao`; `GenAiPlannerBundle` `SFAgent2_v5`. Confirmado na org: `GenAiFunctionDefinition` `ResumoReuniao_EPLAST34_v5` (`apex`) e `GenAiPluginInstructionDef` `instruction1_EPLAST34_v5` existem; o retrieve posterior do bundle mostra a ação ligada ao tópico.
- Chamada direta do invocável por anonymous Apex na dev (só leitura; dev não tem dado): COMERCIAL, GDD e SOP voltam `OK` com 2 seções; BOARD volta `OK` com 3 seções.

## Divergências do design (a pedido de R7 e R2, registradas)

1. **Versão do planner: v5, não v4.** O design partiu de "4 versões, todas inativas, estender a v4". Na hora do build a dev já tinha a **v5, Ativa**, criada em 15/11 09:55 por outras demandas (traz `ProximaAcaoCliente_EPLAST27_v5` e o tópico `acoes_comerciais_EPLAST29`); a v4 está Inativa. Pela PD-07 ("versão mais recente"), a ação foi ligada na **v5**. Ativar a v4 teria desligado o trabalho das outras demandas.
2. **Ativação.** Versão ativa não aceita deploy ("o agente está ativo"). Na dev fiz `sf agent deactivate SFAgent2`, deploy do bundle e `sf agent activate SFAgent2 --version 5`. **Resultado: v5 Ativa de novo; v1 a v4 Inativas, como antes.** A v4 não foi ativada. Houve uma janela curta com o agente inativo na dev.
3. **O que a próxima demanda deve saber (R7):** o planner alterado por esta demanda é o `SFAgent2_v5` (editado no lugar, não é versão nova). O `agentScript/SFAgent2_v5_definition.agent` do repositório é cópia do retrieve e **não** traz a ação nova; o que vale é o bundle XML e a org. Se alguém reimplantar a partir do `.agent`, a ação some.
4. **QA ainda não medido:** estado do agente na sandbox de QA não foi consultado (fora do escopo do build). O passo de QA confere qual versão está ativa lá antes de levar o bundle.

## Testes Apex (sbx-eplast-dev)

Comando: `sf apex run test -o sbx-eplast-dev -n MeetingSummaryServiceTest --code-coverage` (Run Id `707Ha00001Dzhej`).

- **Resultado:** Passed, 100% de aprovação, 0 falhas.
- **Cobertura de `MeetingSummaryService`: 93%** (mínimo 85%). Linhas não cobertas: ramos de `QueryException` dentro de cada seção (o `isAccessible()` já corta antes) e alguns ramos de `VOLUME_EXCEDIDO` das seções 2 do GDD, S&OP e Board.
- Cobertura agregada da org: 25% (achado 2 do assessment; esta demanda não a piora).

| Método | Cenário | Asserts principais |
|---|---|---|
| `deveGerarComercialGddSopBoardComDados` | feliz, 4 tipos | status OK, `3 oportunidade(s)`, `R$ 3.000,00`, rodapé "Dados ate", `dataHoraCorte`, Board sem nome de conta, seção "3) Total geral" |
| `deveSomarBulkDe200OportunidadesE200Pedidos` | bulk 200 + 200 | `200 oportunidade(s), R$ 2.000,00`, `200 pedido(s)`, consultas ≤ 20 |
| `deveMostrarDemaisContasQuandoHaMaisQueOTop` | 22 contas, top 20 | linha `Demais contas: 2 registro(s)` |
| `deveRespeitarPeriodoInformado` | período fora, só início, só fim | `[VAZIO]`, "Nenhum registro no periodo.", contagens |
| `deveRecusarTipoInvalidoPeriodoInvertidoEPeriodoLongo` | negativo | `ERRO` para tipo inválido, nulo, período invertido e período > 366 dias |
| `deveDevolverListaVaziaOuErroSemExplodir` | negativo | lista nula/vazia devolve vazia; exceção inesperada vira `ERRO`, sem resumo parcial |
| `deveSinalizarVolumeExcedido` | teto | `PARCIAL`, `VOLUME_EXCEDIDO`, "Reduza o periodo" |
| `deveFormatarMoedaEmPtBr` | formato | `R$ 1.234.567,89`, `-R$ 10,50`, `R$ 0,00` |
| `deveInformarSemAcessoParaUsuarioSemLeituraDeOpportunityEOrder` | permissão (`runAs`, perfil `Minimum Access - Salesforce`) | COMERCIAL e BOARD voltam `SEM_ACESSO` com mensagem "nao tem acesso de leitura a Opportunity" |

Notas do teste:
- Sem `SeeAllData`. Dados `TESTE-EPLAST34` criados no teste e revertidos no fim.
- Fixture liga `TriggerUtility.bypassTrigger = true` **só no teste** (o trigger custom de Account faz consulta de CNPJ na BrasilAPI e envio ao Protheus por Queueable, com callout, e o Flow de Oportunidade estoura limite com inserts em laço). A classe testada não usa o bypass. CNPJ sintético com dígitos válidos; duplicate rule liberada na fixture; mock `MockBrasilAPISearchCNPJErrorResponse`.
- Order: o status inicial vem do primeiro valor da picklist (restrita), sem `Name` (Order não tem o campo acessível).
- Não foi possível provar na sandbox o caso "Comercial Padrão lê Opportunity e não lê Order" (PARCIAL por falta de Order): não há usuário sintético possível (licença `Salesforce` 14/14, R5). O ramo é coberto por `PARCIAL` de volume e por SEM_ACESSO total; o caso misto fica para a verificação.

## Premissas do design aplicadas (sem pendência)

PD-01 vendedor por `OwnerId`; PD-02 top 20 mais "Demais contas"; PD-03 BRL sem conversão; PD-04 aberta = `IsClosed = false` com `CloseDate` no período; PD-05 todos os status de pedido por `EffectiveDate`; PD-06 teto 40.000; PD-07 versão mais recente do planner (v5, ver divergência 1); PD-08 conferência contra base `TESTE-EPLAST34`; PD-09 texto mostrado como veio; PD-10 366 dias; PD-11 permission set próprio. Nenhuma foi bloqueio.

## Pontos para a verificação e para o gate

- **Roteamento (R4) não provado nesta etapa.** O build prova a lógica (teste Apex e chamada direta) e que a ação está ligada ao tópico; **não** foi feita conversa ponta a ponta com o agente (as frases dos 4 tipos e a regressão das ações padrão ficam para o `verificador`). O usuário que testa precisa de acesso ao agente e do `PS_Comercial_ResumoReuniao`; nenhuma atribuição foi feita no build.
- O metadado exibível da saída (`copilotAction:isDisplayable`) foi marcado no texto; se o modelo ainda reescrever números, a regra é ajustar a instrução do tópico (PD-09), sem mudar a classe.
- Dívida identificada (fora do escopo, não tocada): `OrderTrigger`/`AccountTrigger` custom com nome duplicado (achado 10), cobertura de 25% da org e automações concorrentes em Opportunity/Order (achado 1).
