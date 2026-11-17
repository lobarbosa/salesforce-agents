**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa` (eplast--qas, Partial Copy; Id da org 00DHa000006vZtmMAE, Connected em `sf org list`)

# EPLAST-29 · Testes na QA, rodada 3

Existem `05-testes-rodada-1.md` e `05-testes-rodada-2.md` (ambas reprovadas). Esta rodada reteste a FALHA 4 da rodada 2 e, por consequência, as FALHAS 1 a 3 e o AC-4.

## Falhas

### FALHA 5 (crítica) — a SFAgent2 v17 continua ausente na QA (repetição da FALHA 4)
- Reproduzir: `sf data query -o sbx-eplast-qa -q "SELECT VersionNumber, Status FROM BotVersion WHERE BotDefinition.DeveloperName='SFAgent2' ORDER BY VersionNumber DESC LIMIT 5"`.
- Obtido: v16 Active; v15, v14, v13 e v10 Inactive. **Não existe v17.** O `05-deploy-qa.md` (deploy `0AfHa00000EJR9JKAX`, Succeeded, commit `e22bff79`, 2026-11-17T16:07Z) lista só o custom metadata type e seu registro, o Flow e o permission set, e diz "nenhum arquivo de agente foi implantado nesta rodada; BotVersion SFAgent2.v16 já ativa". `force-app/main/default/bots/SFAgent2/v17.botVersion-meta.xml` existe na branch.
- Esperado: v17 na QA (inativa), para o QA ativá-la e retestar as FALHAS 1 a 3.
- Causa provável: o passo de deploy da esteira (`scripts/implantar-build-qa.sh`, `scripts/pacote_sem_versao_ativa.py`, alterados e ainda não commitados na árvore desta sessão) continua pulando `BotVersion` e `GenAiPlannerBundle` quando já há versão ativa. É preciso que ele inclua `BotVersion SFAgent2.v17` e `GenAiPlannerBundle SFAgent2_v17` como versão inativa. O QA não implanta, então não contornei.
- Efeito: com a v16 ativa, os defeitos da rodada 1 permanecem (afirma "criado" sem chamar a ação; grava "sem descrição"; resumo completo só depois do "sim"). Não repeti os casos na v16: o resultado seria o da rodada 1.

### Sem prova (bloqueia o aceite): AC-4 usuário sem permissão
A QA só tem usuários Administrador do sistema; a regra 6 do cliente proíbe alterar perfil ou permissão do usuário de teste. Fica para a homologação com usuário comum, com e sem `PS_Comercial_AssistenteAcoes`.

## Retestes da rodada anterior
| Falha | Situação |
|---|---|
| FALHA 4 (v17 ausente na QA) | **não corrigida**: repete-se como FALHA 5 |
| FALHA 1 (crítica, "criado" sem a ação) | não corrigida na QA (v17 ausente) |
| FALHA 2 (média, "sem descrição" gravado) | não corrigida na QA (v17 ausente) |
| FALHA 3 (branda, resumo antes da confirmação) | não corrigida na QA (v17 ausente) |
| AC-4 | não executado (sem usuário não administrador) |

## Conferência de componentes do `05-deploy-qa.md` (consultas na org)
| Componente | Evidência | Status |
|---|---|---|
| Flow `Task_Agente_CriarTarefa` | Tooling `Flow`: v1 a v3 Obsolete, v4 Active, v5 Draft | existe (v5 Draft é a do deploy; v4 ativa desde a rodada 1) |
| `AssistenteTarefaSetting__mdt` e `PS_Comercial_AssistenteAcoes` | listados no deploy Succeeded | não reconsultados nesta rodada; sem uso sem o agente v17 |
| BotVersion SFAgent2 v16 | Active | existe |
| BotVersion SFAgent2 v17 | ausente (e não consta no deploy) | **falta** (FALHA 5) |

Não ativei nem alterei nada. Estado final: Flow v4 Active; SFAgent2 v16 Active (era v16 antes). Sem alteração no usuário de execução.

## Casos
AC-1 a AC-9: não executados nesta rodada pelo mesmo motivo. Resultados da rodada 1 (v16) ficam como evidência daquela rodada, não valem para a v17. Critérios principais (AC-1, AC-5, AC-6) sem prova na versão da demanda: reprovado.

## O que pode ter saído da org
Nada: nenhuma conversa com o agente, nenhum DML, e-mail ou chamada externa. Os dados sintéticos `REG-TESTE` da rodada 1 continuam na QA (limpeza: `fixtures/lead.apex`). Sem capturas de tela.

## Para a próxima rodada
1. Esteira: implantar `BotVersion SFAgent2.v17` e `GenAiPlannerBundle SFAgent2_v17` na QA como inativa.
2. QA: ativar a v17 e retestar FALHAS 1 a 3 e AC-1 a AC-9.
3. Homologação: AC-4 com usuário comum.
