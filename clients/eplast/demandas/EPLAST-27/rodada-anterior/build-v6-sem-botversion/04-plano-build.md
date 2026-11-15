**Resultado do build:** concluído

# Plano de build — EPLAST-27: Próxima melhor ação por cliente (v6 só com a 27)

Org: `sbx-eplast-dev` (`sf org list`: única org, Sandbox, Connected; username `...eplast2.qa`, que é a "QA" da Eplast, regra 5 da conta). QA da esteira e produção não tocadas. Nada ativado.

## O que a org já tinha (conferido por sf em 2026-11-15)
- Flow `Account_Agente_ProximaAcao`: v1 Obsolete, **v2 Ativa**. A regra do design não mudou nesta rodada, então **não criei versão nova do Flow** e não editei a ativa (conferido na rodada anterior que o retrieve da v2 confere com o repositório).
- Agente `SFAgent2`: BotVersion v1 a v4 Inactive, **v5 Active** (não tocada). Planner `SFAgent2_v6` já existia na dev, criado na rodada "v6 misto" com conteúdo das EPLAST-29 e 34.
- `NextBestActionSetting__mdt` (+ registro `Default`), `PS_Comercial_ProximaAcao` e o Flow: já no repositório, construídos em rodadas anteriores. Não alterados.

## O que foi criado
| Componente | Detalhe | Caminho |
|---|---|---|
| `GenAiPlannerBundle` `SFAgent2_v6` (planner v6, inativo) | Cópia de `genAiPlannerBundles/SFAgent2_v4` do repositório (v4 da QA mais a ação da EPLAST-27), renomeada para `_v6`: tópicos, ações, instruções e pastas ganharam sufixo `_v6` para a v6 não colidir com tópicos de outras versões. Ação `ProximaAcaoCliente_EPLAST27_v6` (alvo o Flow `Account_Agente_ProximaAcao`) e **instrução nova** `instruction2_EPLAST27_v6` no tópico `insights_comerciais_1790e90ae9fbdc8_v6` (seção 3.3 do design: identificar a conta com `IdentificarConta`, chamar `ProximaAcaoCliente`, mostrar a `message` sem acrescentar nem combinar, `NOT_OWNER` não consulta a conta por outra ação). Descrição preenchida. | `force-app/main/default/genAiPlannerBundles/SFAgent2_v6/` |

Instrução da decisão B (card, 15/11 18:01):
1. v6 = v4 do repositório renomeada + instrução da seção 3.3: feito.
2. Nada da EPLAST-29 nem da EPLAST-34 na v6 (sem `acoes_comerciais`, `IdentificarRegistro`, `CriarTarefa`, `ResumoReuniao`): conferido por retrieve da dev. A v6 tem 4 tópicos (router, ambiguous, insights_comerciais, off_topic).
3. `genAiPlannerBundles/SFAgent2_v4` removido do force-app desta branch (`git rm`): a v4 está ativa na QA e não vai no pacote.
4. v6 implantada inativa na dev (Deploy ID `0AfHa00000EHzNBKA1`, Succeeded); a v5 ativa não foi tocada.

Nada em Account, Opportunity, Order ou Task; nenhum Apex, trigger, LWC, e-mail ou Marketing Cloud (achado 1 do assessment não é piorado: só leitura).

## O que foi tocado no SFAgent2 e risco de colisão (EPLAST-29 e EPLAST-34)
- Tocado: só o planner `SFAgent2_v6` (novo) com a ação da 27 e a instrução da 27. As ações `ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta` e os outros tópicos vêm da v4 sem alteração de conteúdo.
- Pela ordem 27 → 29 → 34: a EPLAST-29 parte da v6 e cria a v7; a EPLAST-34 parte da v7 e cria a v8. Se alguma delas partir de outra base, uma sobrescreve a outra.
- Resíduo na dev: o deploy sobrescreveu o planner `SFAgent2_v6`, mas os tópicos `_v6` da rodada mista (`acoes_comerciais_EPLAST29_v6`, `ResumoReuniao_EPLAST34_v6` e instruções) podem continuar como plugins órfãos na dev; a v6 atual não os referencia (os `GenAiPluginDefinition` consultados na dev mostram só `acoes_comerciais_EPLAST29`, da v5, e os 4 tópicos `_v6`). Não removi nada.

## Versões e ativação
- Criado: planner `SFAgent2_v6`, inativo. **Ativação é passo separado e não foi feita** (na QA exige autorização no card).
- Não apareceu BotVersion v6: o deploy criou o planner, não uma BotVersion. Quem ativar precisa criar/associar a BotVersion v6 ao planner (passo manual no Agentforce Builder; não confirmei se a ferramenta faz isso sozinha).
- Flow: v2 segue ativa, sem versão nova.

## Fica para a verificação (o `verificador` testa)
- Flow v2 na dev: A1, A2, A3, NONE, NODATA, NOT_OWNER e risco fora da lista. Massa fictícia atravessa a cadeia Protheus (R2); usar os scripts de `fixtures/` e o desvio já documentado. Usuário de teste: conta da Konecta (resolver o Id na org).
- Agente: conferir que o planner `SFAgent2_v6` existe, está inativo, tem só os 4 tópicos, contém `ProximaAcaoCliente_EPLAST27_v6` e `instruction2_EPLAST27_v6`, sem nada de 29/34, e que a v5 segue ativa. Resposta real do agente exige ativar a v6, licença Agentforce (I3) e concessão do agente ao permission set, que não é metadata confirmada: sem isso o item fica inconclusivo.

## Branch e commit
Branch `feature/EPLAST-27`; commit `EPLAST-27: criar planner v6 do SFAgent2 só com a próxima ação e remover a v4 do pacote`.
