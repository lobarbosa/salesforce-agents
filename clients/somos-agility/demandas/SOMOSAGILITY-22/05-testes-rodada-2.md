**Veredito:** reprovado
**Org de teste:** `sbx-somos-agility-qa`

# 05 — Testes: SOMOSAGILITY-22 (QA, rodada 2)

Org confirmada com `sf org list`: única conectada, `sbx-somos-agility-qa` (Sandbox, Connected). Deploy da esteira em `05-deploy-qa.md` (`0AfHa00000EIaPyKAL`, Succeeded, commit `ed6c0d89`). Preflight sem bloqueios.

Motivo do veredito: o critério principal (enviar um Job para aprovação grava "Pendente") continua sem evidência. Critério principal não executado é reprovado pela regra da esteira. Não é defeito comprovado na construção.

## Retestes da rodada anterior
- FALHA 1 (envio não exercitável): **não corrigida**. Repeti o envio e deu o mesmo erro (ver abaixo).
- FALHA 2 (pedido de 30/10: tornar "Classificação gerencial" e "Denominação" obrigatórias na aprovação): **não corrigida**. `05-deploy-qa.md` segue sem componente que implemente isso, e o plano de build não o registra. Aguarda decisão de escopo no gate.

## Falhas

### FALHA 1 (crítica) — Não há como enviar um Job de teste para aprovação na QA
- Reproduzir: Apex anônimo na QA insere 1 Job `TESTE SOMOSAGILITY-22 qa 2` (campo `Observa_o__c`) e chama `Approval.process` com `ProcessSubmitRequest`.
- Obtido: `NO_APPLICABLE_PROCESS, Não foi encontrado nenhum processo de aprovação aplicável`. Status ficou `Não Enviado`. Job apagado (conferência: 0 registros com o texto de teste).
- Esperado: envio aceito e status `Pendente`.
- Causa provável: os critérios de entrada dos processos ativos (`Aprova_o_JOB` e `JOB_de_solicitacoes_de_investimento`) comparam o campo Criado por com nomes de pessoas e grupos específicos do cliente; o usuário de execução da QA não está entre eles. `CreatedById` não é gravável, e alterar nome de usuário ou usar login-as está fora do que o QA pode fazer.
- Para o próximo build/arquiteto: fornecer um usuário de teste sintético, listado nos critérios de entrada, registrado no `CLAUDE.md` do cliente (hoje o campo está em branco); ou definir aprovação manual do envio em homologação pelo financeiro. Mesmo bloqueio da verificação em dev.

### FALHA 2 (média) — Pedido do cliente de 30/10 não verificável
Ver "Retestes". Precisa de decisão no gate: entra no escopo ou não.

## Casos
| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C0 | Componentes do deploy existem na QA | `sf data query` em ProcessDefinition, Report, Dashboard; leitura do workflow versionado | Todos presentes | `JOB_de_solicitacoes_de_investimento` e `Aprova_o_JOB` Active; Report `JOBs_de_Investimento_HsY`: 1; Dashboard `sFQeqnPANgKWxQuaSnWRYtxzKhCxCL`: 1. Ação `Status_Qualificacao` grava `Pendente` (workflow versionado) | passou |
| C1 | Envio inicial muda status para "Pendente" | Apex anônimo, ver FALHA 1 | `Pendente` | `NO_APPLICABLE_PROCESS`, `Não Enviado` | não executado |
| C2 | Aprovar leva a "Aprovado" | Depende de C1 | Aprovado | — | não executado |
| C3 | Rejeitar leva a "Rejeitado"; reenvio volta a "Pendente" | Depende de C1 | — | — | não executado |
| C4 | `Status_Previs_o_de_Gastos__c` não muda no envio | Depende de C1 | Sem alteração | — | não executado |
| C5 | Relatório não perde Jobs; rosca = linhas | Contagem agregada na QA (referência) | Total do relatório = total na janela | QA com 1274 Jobs: Aprovado 977, Rejeitado 82, Não Enviado 34, Pendente 13, Recall 1, sem valor 167. Total do relatório não aferido sem abrir tela com dado real | não executado |
| C6 | Dashboard bate com relatório | Exige tela com dado real | Contagens iguais | Não aberto (guardrail LGPD) | não executado |
| C7 | Nenhum dado de cliente nos testes | Só contagens agregadas e 1 Job sintético, apagado | Nenhum dado real | Atendido | passou |

## Riscos do assessment
Oportunidade (31 automações): não tocada. Cobertura Apex 40%: a construção não tem Apex. Perfil por pessoa: é justamente o que bloqueia o envio (critérios por criador).

## O que pode ter saído da org
Criado e apagado 1 Job de teste; o envio falhou antes de iniciar processo, sem e-mail de aprovação nem chamada externa. Nenhum job agendado. Nenhuma alteração de usuário, permission set ou perfil.

## Tela
`qa_browser_*` não usado: a QA tem dado real copiado (1274 Jobs) e relatório e dashboard só existem com ele. Sem capturas.
