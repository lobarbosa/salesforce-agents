**Resultado do build:** concluído

# Plano de build — EPLAST-27: Próxima melhor ação por cliente (v6 com BotVersion)

Org: `sbx-eplast-dev` (`sf org list`: única org, Sandbox, Connected; é a "QA" da Eplast, regra 5 da conta). QA da esteira e produção não tocadas. Nada ativado.

## Escopo desta rodada
O gate devolveu o build porque a v6 tinha o planner `SFAgent2_v6`, mas não tinha a BotVersion v6, e sem ela a versão não pode ser ativada para o teste do assistente. Acrescentei só a BotVersion v6; o resto da v6 não foi alterado.

## Componentes criados
| Componente | Detalhe | Caminho |
|---|---|---|
| `BotVersion` `SFAgent2.v6` (inativa) | Cópia da v5 (rótulos, diálogo de boas-vindas, variáveis, idioma pt_BR) com `fullName` `v6` e `conversationDefinitionPlanners/genAiPlannerName` = `SFAgent2_v6`. Conferido por query: v1 a v4 Inactive, **v5 Active (intocada)**, **v6 Inactive**. | `force-app/main/default/bots/SFAgent2/v6.botVersion-meta.xml` |
| `Bot` `SFAgent2` (arquivo de apoio) | Retrieve da própria org, sem edição, incluído só porque o deploy de BotVersion exige o Bot pai no projeto. O deploy o reportou como "Changed" mas o conteúdo é o da org. | `force-app/main/default/bots/SFAgent2/SFAgent2.bot-meta.xml` |

Deploy: Deploy ID `0AfHa00000EI0EPKA1`, Succeeded (BotVersion v6 + bundle `SFAgent2_v6` inalterado).

## Já existia e não foi alterado (rodadas anteriores)
- Planner `SFAgent2_v6` (4 tópicos; ação `ProximaAcaoCliente_EPLAST27_v6`; instrução `instruction2_EPLAST27_v6` do design 3.3), sem nada da EPLAST-29 e 34. Reimplantado idêntico junto com a BotVersion.
- Flow `Account_Agente_ProximaAcao`: v1 Obsolete, **v2 Ativa**. Regra do design não mudou: sem versão nova, ativa não editada.
- `NextBestActionSetting__mdt` + registro `Default` (30 / `E` / restrito ao dono) e `PS_Comercial_ProximaAcao`.
- Ações `ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta`, v1 a v5 do agente.
- Nada em Account, Opportunity, Order, Task, Apex, trigger, e-mail ou Marketing Cloud.

## Ligação com o design
- 3.3 (ação e tópico do `SFAgent2`) e P11 (versão do agente): a v6 agora é uma versão completa (BotVersion + planner), pronta para ativar.
- 3.2 e 3.1: Flow e CMDT inalterados. Seção 5: permission set inalterado.
- Decisão B (card, 15/11): v6 parte da v4 do repositório; a 29 e a 34 partem da v6.

## Versões e ativação
- Criada: BotVersion `v6` inativa. **Ativação é passo separado e não foi feita** (na QA exige autorização no card). A v5 segue ativa.
- Ativar a v6 desativa a v5 (uma ativa por vez); as capacidades da v5 que não estão na v6 deixam de valer. Quem ativar decide isso.
- Flow: v2 segue ativa.

## Fica para o verificador
- BotVersion v6 existe, Inactive, ligada ao planner `SFAgent2_v6`; v5 Active; v1 a v4 Inactive.
- Planner v6: 4 tópicos, ação `ProximaAcaoCliente_EPLAST27_v6` e `instruction2_EPLAST27_v6`, sem 29/34.
- Flow v2 (já provado na rodada anterior): A1, A2, A3, NONE, NODATA, NOT_OWNER, risco fora da lista, sem gravação. Usuário de teste: Id `005bJ00000piKAaQAM` (ativo, Administrador do sistema). Fixture: `fixtures/conta-oportunidade-proxima-acao.apex`.
- Resposta real do assistente só com a v6 ativada, licença Agentforce (I3) e concessão do agente ao permission set (não é metadata confirmada); sem isso fica inconclusivo.

## Branch e commit
Branch `feature/EPLAST-27`; commit `EPLAST-27: criar BotVersion v6 inativa ligada ao planner SFAgent2_v6`.
