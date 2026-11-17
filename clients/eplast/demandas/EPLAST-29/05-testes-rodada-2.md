**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa` (eplast--qas, Partial Copy; Id da org 00DHa000006vZtmMAE, Connected em `sf org list`)

# EPLAST-29 · Testes na QA, rodada 2 (correções da rodada 1)

Rodada 2: existe `05-testes-rodada-1.md` (reprovada). Esta sessão reteste as FALHAS 1 a 3 e o AC-4. Não foi possível exercitar nenhuma correção, porque o que corrige as falhas não está na QA (FALHA 4).

## Falhas

### FALHA 4 (crítica) — a SFAgent2 v17, que corrige as FALHAS 1 a 3, não foi implantada na QA
- Reproduzir: `sf data query -o sbx-eplast-qa -q "SELECT VersionNumber, Status FROM BotVersion WHERE BotDefinition.DeveloperName='SFAgent2' ORDER BY VersionNumber DESC LIMIT 4"`.
- Obtido: v16 Active, v15, v14 e v13 Inactive. **Não existe v17.** O `05-deploy-qa.md` (deploy `0AfHa00000EJGhrKAH`, Succeeded) lista só o registro de configuração, o Flow, o PS e o custom metadata type; diz "agente já ativo na QA desde a rodada anterior, não reimplantado (v16)". Ele não traz `BotVersion` v17 nem `GenAiPlannerBundle SFAgent2_v17`, embora ambos estejam em `force-app` (`bots/SFAgent2/v17.botVersion-meta.xml`, `genAiPlannerBundles/SFAgent2_v17`) e o `04-plano-build.md` diga que o release deve levar a v17.
- Esperado: v17 existente na QA, ativada pelo QA antes do teste (regra de versão nova de agente), para reteste das FALHAS 1 a 3.
- Causa provável: o passo de deploy da esteira considerou o agente "já implantado" por haver uma versão ativa (v16) e pulou o bundle novo. Corrigir o passo de deploy para incluir `BotVersion v17` e `GenAiPlannerBundle SFAgent2_v17`. Eu não implanto (regra do QA).
- Efeito: com a v16 ativa, os defeitos da rodada 1 permanecem (afirma "criado" sem chamar a ação; grava "sem descrição"; resumo completo só depois do "sim"). Não repeti os casos na v16, o resultado seria o da rodada 1.

### Sem prova (bloqueia o aceite): AC-4 usuário sem permissão
A QA continua só com usuários "Administrador do sistema" (conforme rodada 1). Regra 6 do cliente proíbe alterar perfil/permissão do usuário de teste. Fica para a homologação com usuário comum, com e sem `PS_Comercial_AssistenteAcoes`.

## Retestes da rodada anterior
| Falha | Situação |
|---|---|
| FALHA 1 (crítica, "criado" sem a ação) | não corrigida na QA: correção (v17) não implantada |
| FALHA 2 (média, "sem descrição" gravado) | não corrigida na QA: idem |
| FALHA 3 (branda, resumo antes da confirmação) | não corrigida na QA: idem |
| AC-4 | não executado (sem usuário não administrador) |

## Conferência de componentes do `05-deploy-qa.md` (consultas na org)
| Componente | Evidência | Status |
|---|---|---|
| Flow `Task_Agente_CriarTarefa` | Tooling `Flow`: v1 a v3 Obsolete, **v4 Active**, v5 Draft (a v5 veio do deploy desta rodada; a v4 já estava ativa desde a rodada 1) | existe |
| BotVersion SFAgent2 v16 | Active | existe |
| BotVersion SFAgent2 v17 | ausente | **falta** (FALHA 4) |
Não ativei nem alterei nada nesta rodada. Estado final: Flow v4 Active; SFAgent2 v16 Active (v15 Inactive). Sem alteração no usuário de execução.

## Casos
Os casos de AC-1 a AC-9 da rodada 1 (A1 a A12 em `05-testes-rodada-1.md`) não foram repetidos: o pacote do agente é o mesmo da rodada 1 e o Flow não mudou de conteúdo. Os que passaram na rodada 1 seguem como evidência daquela rodada (AC-1 com ressalva da FALHA 3, AC-2, AC-3, AC-5, AC-7, AC-8, AC-9 parcial); AC-6 só com pedido completo; AC-4 não executado. Nada foi comprovado de novo nesta rodada.

## Outras demandas no mesmo agente
EPLAST-27, 34 e 46 (aguardando homologação) também mexem na SFAgent2; a v17 traz as ações delas sem mudança (conforme plano de build, conferido só por grep). Nada delas foi testado ou alterado aqui.

## O que pode ter saído da org
Nada: nenhuma conversa com o agente, nenhum DML, nenhum e-mail ou chamada externa nesta rodada. Os dados sintéticos `REG-TESTE` da rodada 1 (leads e contas) continuam na QA para o reteste (apagar: ver `fixtures/lead.apex`). Sem capturas de tela (nada a mostrar).

## Para a próxima rodada
1. Esteira: implantar `BotVersion v17` e `GenAiPlannerBundle SFAgent2_v17` na QA (como versão inativa).
2. QA: ativar a v17, retestar FALHAS 1 a 3 e A6 sem data/texto.
3. Homologação: AC-4 com usuário comum.
