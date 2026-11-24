**Veredito:** reprovado
**Org de teste:** `sbx-somos-agility-qa`

# SOMOSAGILITY-16 — Testes na QA

Org confirmada com `sf org list`: `sbx-somos-agility-qa` (Sandbox, Connected). Não existe `05-deploy-qa.md` (a demanda não mudou metadata). Nenhum DML, deploy ou Apex anônimo foi feito. Nada a desfazer. Nada saiu da org.

## Falhas

### FALHA 1 (crítica) — Critérios de aceite principais sem prova
A mudança (remover Fabio Soto da assinatura de "Leads Semanais") foi feita por humano em produção, fora da esteira. A QA não reflete esse estado, e o guardrail #1 proíbe tocar em produção. Não há "antes" nem "depois" registrados no card nem em artefato. Os critérios 1 a 4 não têm evidência.
- Para reproduzir: tentar conferir a lista de destinatários na QA. Ela é cópia anterior e não representa a produção.
- Esperado: evidência do "antes" e do "depois" (contagens, perfil/papel, data/hora, confirmação de que o usuário não consta mais, sem nomes ou e-mails).
- Correção: o executor da mudança em produção deve registrar essa evidência (runbook passos 4 a 7 de `04-plano-build.md`) e a demanda ser reavaliada com ela; ou aceitar-se formalmente no gate que a prova é a declaração do executor.

## Casos (de `01-analise.md`)

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| 1 Fabio Soto fora dos destinatários | Sem acesso à produção | Lista sem Fabio Soto | Sem evidência | não executado |
| 2 Demais destinatários inalterados | Exige "antes" registrado | Antes menos 1 = depois | "Antes" não registrado; card cita 3 restantes, só relato | não executado |
| 3 Relatório existe e agendamento ativo | `SELECT COUNT() FROM Report WHERE Id='00O4z0000057ssKEAQ'` na QA; `SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.JobType='8'` | Relatório existe; job ativo | 1 e 1 na QA. Isso é a QA, não a produção, e não prova a assinatura | parcial, não prova o critério |
| 4 Mapeamento sem dado pessoal | Inspeção de artefato | Contagem + perfil/papel por destinatário | Nenhum mapeamento gravado; só contagem de restantes (3) no plano | não executado |
| 5 Nenhuma escrita em produção pelo agente | Revisão: nenhum deploy/DML nesta etapa; plano diz execução humana | Sem escrita de agente | Confirmado nesta sessão (só 3 consultas de contagem na QA) | passou |

Não foram feitas capturas de tela: a tela relevante só existe em produção com dados reais.
