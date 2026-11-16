**Resultado do build:** concluído

# Plano de build — EPLAST-27: Próxima melhor ação por cliente (correção da instrução do agente)

Org: `sbx-eplast-dev` (`sf org list`: única org, Sandbox, Connected; é a "QA" da Eplast, regra 5 da conta). QA da esteira e produção não tocadas. Nada ativado. Fonte: `03-design.md`, seção "Decisão do responsável (2026-11-16)".

## Estado encontrado
- `SFAgent2` na dev: v1 a v13; **v13 ativa**. A v14 não existia. Nenhum DML.
- Flow `Account_Agente_ProximaAcao`: sem mudança (a regra não mudou; só a instrução do agente). Versão ativa mantida.
- Outras demandas no agente (EPLAST-29, 34, 46): nada removido nem editado; a v14 parte do retrieve da v13.

## Componentes criados
| Componente | Detalhe | Caminho |
|---|---|---|
| `GenAiPlannerBundle` `SFAgent2_v14` (inativo) | Retrieve da v13 da org, renomeado v13 para v14 (bundle, ações locais, funções). Mantém ações e instruções de 27, 29, 34 e 46 e a correção de confirmação de tarefa da 29. | `force-app/main/default/genAiPlannerBundles/SFAgent2_v14/` |
| `BotVersion` `SFAgent2.v14` (inativa) | Retrieve da v13 renomeada, ligada ao planner `SFAgent2_v14`. | `force-app/main/default/bots/SFAgent2/v14.botVersion-meta.xml` |

Deploy na `sbx-eplast-dev`: Succeeded. Conferido por query: v13 Active, v14 Inactive.

## Única mudança (instrução `instruction2_EPLAST27_v14`, tópico `insights_comerciais_1790e90ae9fbdc8`)
1. Depois de chamar `ProximaAcaoCliente`, apresentar sempre, na íntegra, a mensagem devolvida (inclusive "Dados insuficientes: ..."), sem resumir a título.
2. Nunca recomendar ação fora do que a ação devolveu; se não há dados suficientes, dizer isso e parar (sem "contato inicial" nem outra ação).
3. Em pergunta de continuação, repetir a mensagem da ação ou chamá-la de novo; nunca improvisar.
Mantidos: identificar a conta com `IdentificarConta`; `NOT_OWNER` não consulta a conta por outra ação.

## Pacote da branch
Somente a v14. A v10 (já na QA) foi removida da branch (`SFAgent2_v10` e `v10.botVersion`).

## Versões e ativação
- Ativação **não feita**. v14 inativa; v13 segue ativa na dev.
- Ao ativar a v14, deixa de valer a v13; a v14 contém tudo da v13. Quem criar versão seguinte deve partir da v14.

## Observação
O design cita o campo `result` na saída da ação; o schema da ação na org usa `message` (e `actionCode`). A instrução fala em "mensagem devolvida pela ação", valendo para qualquer dos dois nomes. Se o preview mostrar que o defeito persiste, investigar o mapeamento do output.

## Para a verificação
Conversar com a v14 sem tela (`sf agent preview start` / `send` / `end`), pedindo pelo nome da conta, ao menos 3 vezes por cenário, e conferir que a resposta traz a mensagem da ação e não inventa ação fora de A1 a A3. A v14 está inativa: o preview deve apontar a versão/planner v14.

Nada em Account, Opportunity, Order, Task, Apex, e-mail ou Marketing Cloud.
