**Veredito:** reprovado
**Org de teste:** `sbx-somos-agility-qa`

# 05 — Testes: SOMOSAGILITY-22 (QA)

Org confirmada com `sf org list`: única conectada, `sbx-somos-agility-qa` (Sandbox, Connected). Deploy da esteira conferido em `05-deploy-qa.md` (`0AfHa00000EI0SvKAL`, Succeeded). Preflight sem bloqueios.

Motivo do veredito: o critério principal (enviar um Job para aprovação grava "Pendente") não pôde ser exercitado na QA. Critério principal não executado é reprovado pela regra da esteira. Não é defeito comprovado na construção.

## Falhas

### FALHA 1 (crítica) — Critério principal sem evidência: não há como enviar um Job de teste para aprovação na QA
- Reproduzir: Apex anônimo na QA insere 1 Job `TESTE SOMOSAGILITY-22 qa 1` (campo `Observa_o__c`) e chama `Approval.process`.
- Obtido: `NO_APPLICABLE_PROCESS, Não foi encontrado nenhum processo de aprovação aplicável`. Status ficou `Não Enviado`. Job apagado (conferência: 0 registros com o texto de teste).
- Esperado: envio aceito e status `Pendente`.
- Causa provável: os critérios de entrada dos processos ativos (`Aprova_o_JOB` e `JOB_de_solicitacoes_de_investimento`) dependem do usuário criador do Job (lista de usuários nomeados do cliente). O usuário de execução do QA não está na lista. Não alterei usuário nem criei Job como pessoa real.
- Para o próximo build/arquiteto: fornecer um usuário de teste sintético (ou autorização para ajustar um usuário de teste) que esteja nos critérios de entrada, registrado no `CLAUDE.md` do cliente. Mesmo bloqueio da verificação em dev (`04-verificacao.md`).

### FALHA 2 (média) — Pedido do cliente de 30/10 não verificável
- O comentário pede tornar obrigatórios "Classificação gerencial" e "Denominação" na aprovação. O plano de build não registra essa mudança e `05-deploy-qa.md` não lista nenhum componente que a implemente. Não testável; precisa de decisão no gate (entra no escopo ou não).

## Casos
| Caso | Critério (01-analise / 03-design) | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C0 | Componentes do deploy existem na QA | `sf data query` em ProcessDefinition, Report e Dashboard; retrieve do processo | Todos presentes | Processo `JOB_de_solicitacoes_de_investimento` Active, com `initialSubmissionActions` = `Status_Qualificacao` (FieldUpdate); relatório `JOBs_de_Investimento_HsY` e dashboard `sFQeqnPANgKWxQuaSnWRYtxzKhCxCL` existem. Workflow não consultado separadamente, mas a ação `Status_Qualificacao` resolve no processo | passou |
| C1 | Envio inicial muda status para "Pendente" | Apex anônimo, ver FALHA 1 | `Pendente` | `NO_APPLICABLE_PROCESS`, `Não Enviado` | não executado |
| C2 | Aprovar leva a "Aprovado" | Depende de C1 | Aprovado | — | não executado |
| C3 | Rejeitar leva a "Rejeitado"; reenvio volta a "Pendente" | Depende de C1 | — | — | não executado |
| C4 | `Status_Previs_o_de_Gastos__c` não muda no envio | Depende de C1 | Sem alteração | — | não executado |
| C5 | Relatório não perde Jobs; rosca = linhas | Contagem agregada na QA (referência) | Total do relatório = total na janela | QA tem 1274 Jobs; por status: Aprovado 977, Rejeitado 82, Não Enviado 34, Pendente 13, Recall 1, sem valor 167. Total exibido no relatório não aferido sem abrir tela (relatório mostra dado real) | não executado |
| C6 | Dashboard bate com relatório | Idem, exige tela com dado real | Contagens iguais | Não aberto (guardrail LGPD) | não executado |
| C7 | Nenhum dado de cliente nos testes | Só contagens agregadas e 1 Job sintético, apagado | Nenhum dado real | Atendido | passou |

## Riscos do assessment
Automação concentrada em Oportunidade (31): não se aplica, o objeto de Job não tem trigger. Cobertura Apex 40%: a construção não tem Apex. O objeto tem 2 processos de aprovação ativos; qual pega o envio depende dos critérios, não exercitado.

## O que pode ter saído da org
Criado e apagado 1 Job de teste. O envio falhou antes de iniciar processo: sem e-mail de aprovação nem chamada externa. Nenhum job agendado, nenhuma alteração de usuário.

## Tela
`qa_browser_*` não usado: a QA tem dado real copiado (1274 Jobs) e as telas do relatório e do dashboard só existem com ele.
