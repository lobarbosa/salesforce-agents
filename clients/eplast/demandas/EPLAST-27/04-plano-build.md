**Resultado do build:** concluído

# Plano de build — EPLAST-27: Próxima melhor ação por cliente (refeito sobre a v5)

Org: `sbx-eplast-dev` (`sf org list`: única org, Sandbox, Connected; username `projetos@konectabr.com.eplast2.qa`). QA e produção não tocadas. Nada ativado.

## O que a org já tinha (conferido por sf em 2026-11-15)
- Flow `Account_Agente_ProximaAcao`: v1 Obsolete, **v2 Ativa**. O retrieve da v2 confere com o do repositório (mesmo conjunto de elementos, incluindo a correção `CASESAFEID` da dona da conta; só muda a formatação do XML). A regra do design não mudou, então **não criei versão nova do Flow** e não editei a ativa.
- Agente `SFAgent2`: BotVersion v1 a v4 Inactive, **v5 Active**. A v5 já traz a ação `ProximaAcaoCliente_EPLAST27_v5` (alvo o Flow) e a descrição de escopo do tópico com "próxima ação", mas **não traz a instrução** de uso da ação (seção 3.3 do design). O planner `SFAgent2_v6` não existia.
- `NextBestActionSetting__mdt` (+ registro `Default`) e `PS_Comercial_ProximaAcao`: já no repositório, construídos nas rodadas anteriores. Não alterados.

## O que foi criado
| Componente | Detalhe | Caminho |
|---|---|---|
| `GenAiPlannerBundle` `SFAgent2_v6` (planner v6, inativo) | Cópia da v5 retrieved da dev, com sufixo `_v6` em tópicos, ações e pastas; **mais uma instrução** no tópico `insights_comerciais_1790e90ae9fbdc8_v6`: `instruction2_EPLAST27_v6` (identificar a conta com `IdentificarConta`, chamar `ProximaAcaoCliente`, mostrar a `message` sem acrescentar nem combinar ações, `NOT_OWNER` não consulta a conta por outra ação). Descrição preenchida. | `force-app/main/default/genAiPlannerBundles/SFAgent2_v6/` |

Deploy na dev concluído (`sf project deploy start`, bundle `SFAgent2_v6`); confirmado por tooling query que o planner `SFAgent2_v6` existe. A v5 continua ativa e intacta (a v4 do repositório, editada nas rodadas anteriores, não foi mexida agora).

Nada em Account, Opportunity, Order ou Task; nenhum Apex, trigger, LWC, e-mail ou Marketing Cloud (achado 1 do assessment não é piorado: só leitura).

## O que foi tocado no SFAgent2 e colisão com EPLAST-29 e EPLAST-34
- Tocado: só a instrução nova do tópico `insights_comerciais` (ação `ProximaAcaoCliente` e descrição do tópico já vinham na v5).
- A v6 é cópia da v5, então **carrega as ações de EPLAST-34 (`ResumoReuniao`, instrução `instruction1_EPLAST34`) e de EPLAST-29 (tópico `acoes_comerciais_EPLAST29` com `IdentificarRegistro` e `CriarTarefa`)** sem alteração de conteúdo. Para a v6 ficar independente da v5, o tópico e as ações da EPLAST-29 ganharam sufixo `_v6` (`acoes_comerciais_EPLAST29_v6` etc.).
- Colisão possível: se EPLAST-29 ou EPLAST-34 criarem o seu próprio planner v6 ou editarem o mesmo tópico, uma sobrescreve a outra. A ordem de ativação precisa partir de uma única v6 que contenha as três mudanças; quem ativar deve conferir isso.

## Versões e ativação
- Criado: planner `SFAgent2_v6`, inativo. **Ativação é passo separado e não foi feita.**
- Ao consultar `BotVersion`, não apareceu v6: o deploy do bundle criou o planner, não uma BotVersion. Quem ativar precisa criar/associar a BotVersion v6 ao planner (passo manual no Agentforce Builder; não confirmei se a ferramenta faz isso sozinha).
- Flow: v2 segue ativa, sem versão nova.

## Fica para a verificação (o `verificador` testa)
- Flow v2 na dev: A1, A2, A3, NONE, NODATA, NOT_OWNER e risco fora da lista (rodada 1 e 2 anteriores já passaram na maior parte; massa fictícia atravessa a cadeia Protheus, usar o desvio já documentado).
- Agente: conferir que o planner `SFAgent2_v6` existe, está inativo, contém `ProximaAcaoCliente_EPLAST27_v6` e a instrução `instruction2_EPLAST27_v6`, e que a v5 segue ativa. Resposta real do agente (C15) exige ativar a v6, licença Agentforce (I3) e concessão do agente ao `PS_Comercial_ProximaAcao`, que não é metadata confirmada: segue inconclusivo se esses passos manuais não forem feitos.

## Branch e commit
Branch `feature/EPLAST-27`; commit `EPLAST-27: criar planner v6 do SFAgent2 com instrução da próxima ação`; PR aberto contra `main`, sem merge.
