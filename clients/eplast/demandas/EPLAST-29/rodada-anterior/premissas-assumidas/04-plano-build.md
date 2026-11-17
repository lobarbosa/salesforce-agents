**Resultado do build:** concluído

# EPLAST-29 · Plano de build (rodada 3: v12 acumulada, a partir da v10)

Org de build: `sbx-eplast-dev` (única em `sf org list`, sandbox, conectada). Branch `feature/EPLAST-29`. Nada tocado em produção, QA ou Marketing Cloud. Nenhum objeto, campo ou Apex novo.

## Por que v12, a partir da v10
Decisão vinculante do responsável (2026-11-16, fim do `03-design.md`): versões acumuladas. Na dev existem v1 a v11 (conferido por `SELECT DeveloperName, Status FROM BotVersion`); a v8 estava ativa. A v10 (EPLAST-27, com ações de 27, 29, 34 e 46) é a base; a v11 anterior desta demanda partia da v7 e não tem as ações de 34 e 46, por isso não serve de base. Onde o design diz "v5", leia "v12".

## Componentes
| Tipo | API name | Estado | Observação |
|---|---|---|---|
| GenAiPlannerBundle | `SFAgent2_v12` | criado, deploy Succeeded na dev | Cópia da v10 baixada da dev (todos os nomes `_v10` viram `_v12`), com a única mudança de conteúdo abaixo |
| BotVersion | `SFAgent2.v12` | criado, ligado ao planner `SFAgent2_v12` | v1 a v11 intactas na org |
| Tópico local | `acoes_comerciais` (`acoes_comerciais_EPLAST29_v12`) | dentro do bundle | Ações `IdentificarRegistro` (leitura) e `CriarTarefa` (Flow `Task_Agente_CriarTarefa`, confirmação obrigatória) |
| Flow | `Task_Agente_CriarTarefa` | reaproveitado, sem mudança | Versão ativa na dev; nenhuma alteração, logo sem versão nova |
| PermissionSet | `PS_Comercial_AssistenteAcoes` | reaproveitado, sem mudança | Já existe na dev (concede agente e Flow, PD-6) |

## Única mudança de conteúdo da v12 (em relação à v10)
Instruções do tópico `acoes_comerciais` reforçadas, textos iguais aos da v11 (correção da FALHA 1 e FALHA 2 da rodada 2 de QA):
- `DATA`: sem data (ou "sem data"), não monta resumo nem diz que criou; sugere uma data e continua pedindo.
- `CONFIRMAÇÃO`: depois do "sim" ao resumo, chama `CriarTarefa` na mesma resposta; sem dado obrigatório, não chama e pede o dado.
- `RESULTADO`: nunca diz que a tarefa foi criada sem ter chamado `CriarTarefa` e recebido `Sucesso` verdadeiro.
Conferido por grep: as 3 frases novas estão no bundle v12. Nada das outras demandas foi removido: `insights_comerciais` mantém as 6 ações da v10 (`AgregacaoPedidos`, `IdentificarConta`, `ConsultarPedidos`, `ProximaAcaoCliente` EPLAST-27, `ResumoReuniao` EPLAST-34, `SugestaoCampanha` EPLAST-46).

## Pacote: só a v12
Removidos da branch: `genAiPlannerBundles/SFAgent2_v7`, `genAiPlannerBundles/SFAgent2_v11`, `bots/SFAgent2/v7.botVersion-meta.xml` e `v11.botVersion-meta.xml` (a v7 já está na QA e não aceita reimplante). A v10 foi baixada só para servir de base e não entra no commit; `SFAgent2.bot-meta.xml` baixado também foi descartado (sem mudança real).

## Decisões de implementação
1. Nomes globais com sufixo `_v12` (GenAiPlugin e GenAiFunction são globais; mesmo nome falha por duplicidade). `localDeveloperName` e Agent Script não mudam.
2. Deploy com `sf project deploy start --test-level NoTestRun`, só na dev, apenas bundle v12 e BotVersion v12.
3. Graph (`agentGraph/*_graph.json`) não gerado: artefato derivado.
4. Dependência para outras orgs: o bundle v12 referencia os Flows de EPLAST-27 (`Account_Agente_ProximaAcao`), 34 e 46 (conferidos no bundle da v10). Na QA, a ordem é EPLAST-46 (v9), EPLAST-27 (v10), esta (v12); a v12 fica ativa ao final.

## Versões e ativação
- Dev: `SFAgent2` v12 **ativada** (`sf agent activate`, "SFAgent2 v12 activated") para a verificação; é a única ativa (conferido por query). Rollback: reativar a v8.
- QA: ativação pelo fluxo de release, não aqui.

## Concorrência (00-preflight)
EPLAST-27, EPLAST-34 e EPLAST-46 também mexem no `SFAgent2`. Nada deles foi editado no lugar nem removido: a v12 é cópia da v10 com a mudança só no tópico desta demanda.

## Para a verificação
- Tópico `acoes_comerciais` na v12 ativa; teste sem tela com `sf agent preview start` / `send` / `end`.
- Casos da rodada 2: pedido sem data (não cria, pede a data); resumo confirmado seguido de chamada real de `CriarTarefa` e só então "criada" (conferir Task por contagem/Id, sem dado real); `Check In @` recusado; registro ambíguo; AC-4 (acesso negado, usuário de teste da Konecta, resolvido por Id na org); licença Agentforce (R9).
- `insights_comerciais` ainda com as 6 ações.

---

# Correções da verificação 1 (v13, a partir da v12)

Org: `sbx-eplast-dev` (única em `sf org list`). A v12 estava ativa e não foi editada: criada a **v13** (planner `SFAgent2_v13`, `BotVersion` `SFAgent2.v13`), cópia da v12 com nomes `_v13`. v1 a v12 intactas. Deploy Succeeded (`--test-level NoTestRun`). No pacote da branch ficam só os arquivos da v13 (v12 já está na dev e não aceita reimplante). Flow `Task_Agente_CriarTarefa` e PS `PS_Comercial_AssistenteAcoes`: sem mudança.

## FALHA 1 — agente diz "tarefa criada" sem chamar `CriarTarefa`
Causa: o texto mandava esperar um "sim" em texto antes de chamar a ação; o modelo tratava o "sim" como execução (ou como pedido de alteração) e nem sempre chamava a ação. Reforço só de texto (v11/v12) não bastou. Correção estrutural na v13, sem mudar a regra de negócio (nada é gravado sem aprovação do usuário):
- `CONFIRMAÇÃO`: com registro único, assunto e vencimento, o agente mostra o resumo e chama `CriarTarefa` **na mesma resposta**; a confirmação do usuário passa a ser o cartão de confirmação da própria ação (`isConfirmationRequired=true`, mantido). Se o usuário escrever "sim/confirmo" sem a ação ter sido chamada, chama agora; se pedir alteração, ajusta e chama de novo. Elimina o passo de "sim" em texto que causava o desvio.
- `RASCUNHO DE E-MAIL OU MENSAGEM`: remete à regra CONFIRMAÇÃO; o rascunho só existe como tarefa depois do retorno `Sucesso`.
- Descrição da ação `CriarTarefa`: dever de chamar assim que houver os dados, e de nunca informar criada sem `Sucesso`.
- `RESULTADO` e `DATA` (sem data, não monta resumo nem diz que criou) mantidas da v12.
Conferido por grep no bundle v13: as três frases novas presentes uma vez cada; `insights_comerciais` mantém as 6 ações (EPLAST-27, 34, 46 intactas).

## Observação não bloqueante (sim tratado como alteração)
Coberta pela mesma mudança: a ação é chamada sem depender do "sim" em texto.

## Premissa assumida (validar na homologação)
- **Pergunta:** o resumo em texto precisa de um "sim" antes do cartão? **Decisão:** não; o resumo e o cartão vêm juntos e o cartão é a confirmação. **Evidência:** a falha reproduzida em dev e QA (rodadas 1 e 2) e a ação com confirmação obrigatória da plataforma. **Para mudar:** voltar a exigir "sim" em texto na instrução `CONFIRMAÇÃO` (nova versão).

## Fora do alcance do build
- AC-4 (acesso negado) e comparação de AC-9 ficaram sem prova por falta de usuário não administrador na dev/QA; é limitação de ambiente (regra 6), não de construção. Registrado para o verificador/QA dizerem o que ficou sem prova.

## Versões e ativação (atualização)
- Dev: `SFAgent2` **v13 ativada** (`sf agent activate`, "SFAgent2 v13 activated"); única ativa (query). A v12, ativa antes, ficou Inactive. Rollback: reativar a v12 (ou a v8).
- QA: pelo fluxo de release (v13 acumulada sobre EPLAST-46 v9 e EPLAST-27 v10); não tocada aqui.

## Para a verificação
Repetir várias vezes cada caso (comportamento não determinístico): rascunho de e-mail com data no 1º turno, pedido sem data, "sim" solto sem ação chamada; conferir Task por contagem/Id e que nenhuma mensagem diz "criada" sem `Sucesso`.
