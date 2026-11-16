**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# Verificação — EPLAST-27 (correção da instrução do agente, SFAgent2 v14)

Org conectada (`sf org list`): alias `sbx-eplast-dev`, tipo Sandbox, status Connected. QA da esteira e produção não tocadas. Marketing Cloud não tocado.

## Por que inconclusiva
O que a correção muda é o comportamento do agente na conversa: a mensagem da ação chegar íntegra e o agente não recomendar ação fora da devolvida. Isso só se exercita conversando com a v14. A v14 está **inativa** (v13 ativa) e o `sf agent preview start -n SFAgent2` abre sempre o agente publicado, ou seja, a v13. O comando não tem flag para escolher versão inativa. Ativar a v14 é passo separado, fora do build e fora da minha autorização, e alterar o que o builder entregou para testar não é permitido. Não rodei a conversa contra a v13, porque isso provaria a versão antiga e não a mudança. Por isso não criei massa de teste nem fiz DML na dev (0 Account `TESTE EPLAST-27` antes e depois).

## O que foi conferido (estático, sem DML)
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Build entregue | `SELECT VersionNumber, Status FROM BotVersion WHERE BotDefinition.DeveloperName='SFAgent2'` | v14 existe inativa, v13 ativa | 14 Inactive, 13 Active, 12 Inactive | passou |
| V2 | Planner da v14 | `GenAiPlannerDefinition` LIKE 'SFAgent2%' | `SFAgent2_v14` presente | v1 a v14 presentes | passou |
| V3 | Instrução corrigida | Leitura de `instruction2_EPLAST27_v14` no bundle da branch (deploy Succeeded segundo o plano) | Apresentar mensagem na íntegra; nunca recomendar fora da devolvida; dado insuficiente = parar; continuação repete ou rechama; NOT_OWNER não revela dados | Texto traz as cinco regras, incluindo "NUNCA recomende acao fora do que a acao devolveu" e "sem sugerir 'contato inicial'" | passou (texto), não exercitado |
| V4 | Campo `message` x `result` | Leitura de `output/schema.json` da ação `ProximaAcaoCliente_EPLAST27_v14` | Saída lida pelo planner | Propriedades `message` (displayable, usada pelo planner) e `actionCode` (usada pelo planner). A instrução diz "mensagem devolvida pela ação", sem citar nome de campo; `result` do design não existe e não faz falta | passou (schema) |
| V5 | Ações das demais demandas preservadas | Listagem das ações locais da v14 | Ações de 27, 29, 34 e 46 mantidas | ProximaAcaoCliente, IdentificarConta, ConsultarPedidos, AgregacaoPedidos, ResumoReuniao, CriarTarefa, IdentificarRegistro, SugestaoCampanha presentes | passou |
| V6 | Cenários de aceite A1, A2, A3, NONE, NODATA, NOT_OWNER na conversa, 3 vezes cada | não executado (v14 inativa) | Resposta traz a mensagem da ação; sem ação fora de A1 a A3 | sem evidência | não executado |
| V7 | Mensagem íntegra e regra de não recomendar fora da devolvida | não executado | Idem | sem evidência | não executado |
| V8 | A consulta não grava, sem comunicação, sem dado pessoal | não executado | Idem | sem evidência | não executado |

## O que ficou sem prova e o que uma pessoa precisa fazer
1. Ativar a `SFAgent2` v14 na dev (passo manual de quem ativa), rodar a fixture `fixtures/conta-oportunidade-proxima-acao.apex` (etapa SELLER e etapa MASSA) e conversar por `sf agent preview start -n SFAgent2` com cada conta C1 a C6, pelo nome, ao menos 3 vezes por cenário, conferindo que a resposta traz o texto da ação. Atenção especial a C5 (NODATA): a resposta deve ser "Dados insuficientes: ..." e parar, sem "contato inicial".
2. Se o defeito persistir com a v14, investigar o mapeamento do output do Flow para a ação, como o plano já prevê.
3. Depois, apagar a massa (Case antes das Accounts) e devolver `ProtheusSellerId__c`, conforme o cabeçalho da fixture.

## Dados de teste e usuário
Nenhum dado criado. Nenhuma alteração no usuário de execução. Uma sessão de preview aberta contra o agente publicado (v13) e encerrada, sem enviar mensagem.

## O que pode ter saído da org
Nada. Nenhum registro criado, nenhuma chamada externa.
