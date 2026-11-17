**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-29 · Testes na QA (SFAgent2 v7, tópico `acoes_comerciais`)

Org confirmada com `sf org list`: única conectada, `sbx-eplast-qa` (Org Id 00DHa000006vZtmMAE, sandbox QAS). Nada em produção nem no Marketing Cloud. Nenhum registro foi criado, lido ou alterado nesta rodada.

## Falhas

### FALHA 1 (crítica) — a v7 do SFAgent2 está implantada na QA, mas inativa; o agente ativo (v4) não tem a funcionalidade
- **Reproduzir:** `sf agent preview start -o sbx-eplast-qa -n SFAgent2` e enviar "criar tarefa de follow-up para TESTE EPLAST-29 Conta Inexistente com vencimento em 2026-12-01" (conta inexistente, para nada ser gravado).
- **Obtido:** o agente respondeu "Não é possível criar tarefas ou registros diretamente. Minha função é analisar históricos de pedidos...". Esse é o comportamento da v4. `SELECT VersionNumber, Status FROM BotVersion WHERE BotDefinition.DeveloperName='SFAgent2'` na QA: v1, v2, v3, v6 e v7 Inactive; **v4 Active**.
- **Esperado:** com a entrega instalada, o assistente mostra o resumo da tarefa (assunto, registro, responsável, vencimento) e pede confirmação (AC-1).
- **Causa provável:** o deploy da esteira (`05-deploy-qa.md`, deploy `0AfHa00000EI7CfKAL`) cria a v7 inativa e a ativação é passo separado; ninguém a ativou na QA. Como o preview e o usuário só alcançam a versão ativa, AC-1 a AC-8 não podem ser exercitados. Ativar a v7 é mudança de configuração que o QA não faz. Para o próximo ciclo: a v7 precisa estar ativa na QA (ou a esteira/arquiteto definir quem ativa) antes da sessão de QA. Atenção: EPLAST-27 e EPLAST-34 também mexem no `SFAgent2` e a v6 (EPLAST-27) está inativa, então a ativação da v7 deve ser combinada com essas demandas.

## Conferência do pacote
| Componente | Evidência | Status |
|---|---|---|
| `BotVersion` v7 do SFAgent2 | existe na QA (Id 0X9Ha0000004dnZKAQ), Inactive | existe, inativa |
| Flow `Task_Agente_CriarTarefa` | existe, Active, versão 1 | existe |
| Permission set `PS_Comercial_AssistenteAcoes` | existe (Id 0PSHa000002DO6bOAG) | existe |
| Bundle `SFAgent2_v7` | não lido item a item; a v7 existe como BotVersion | não conferido em detalhe |

## Casos
| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | AC-1 | pedir tarefa por linguagem natural | resumo e confirmação | agente ativo (v4) recusou criar tarefa | não executado (v7 inativa) |
| C2 | AC-2 | recusar o resumo | nada gravado | sem tópico na v4 | não executado |
| C3 | AC-3 | registro homônimo | lista candidatos | idem | não executado |
| C4 | AC-4 | usuário sem permissão | recusa sem vazamento | só há usuários administradores da Konecta (`005bJ00000hBJmYQAW` inativo, `005bJ00000piKAaQAM` ativo); sem usuário comum | não executado |
| C5 | AC-5 | campo faltando | pergunta o campo | sem tópico na v4 | não executado |
| C6 | AC-6 | pedir e-mail | Task com rascunho, sem EmailMessage | sem tópico na v4 | não executado |
| C7 | AC-7 | pedir Oportunidade | recusa | v4 recusa tudo; não prova a regra da v7 | não executado |
| C8 | AC-8 | rastreabilidade | CreatedById e marca | sem Task criada | não executado |
| C9 | AC-9 | consultas existentes | iguais à versão anterior | v4 segue respondendo como antes (a v4 é a anterior) | não executado para a v7 |
| C0 | pré-condição | v7 ativa na QA | Active | Inactive | falhou |

Na dev, `04-verificacao.md` (inconclusiva) registrou AC-1, 2, 3, 5, 6, 7, 8 passando com a v7 ativa. Isso não substitui a prova na QA.

## O que pode ter saído da org
Nada. A única sessão de preview usou conta inexistente; consulta de Task `TESTE EPLAST-29` com `Follow-up` = 0. Nenhum Marketing Cloud, e-mail ou chamada externa.

## Mudanças de usuário/permissão
Nenhuma (nenhum permission set atribuído a mim, nenhuma opção ligada).
