**Verificação:** inconclusiva
**Org de teste:** `sbx-somos-agility-dev`

# SOMOSAGILITY-16 — Verificação do build

Org confirmada com `sf org list`: `sbx-somos-agility-dev` (Sandbox, Connected). Nenhum DML, Apex anônimo, deploy ou dado de teste foi criado. Não há nada a apagar nem a desfazer.

## Por que inconclusiva

A construção não tem metadata. A mudança é a remoção de um destinatário na assinatura do relatório "Leads Semanais", feita por humano na UI em produção, fora da esteira (`04-plano-build.md`). O estado "depois" só existe em produção, e o guardrail #1 proíbe tocar nela. Não há como exercitar os critérios de aceite na dev. Isto não é defeito da construção.

## O que foi conferido na dev (só contagens agregadas)

| Consulta | Resultado |
|---|---|
| `SELECT COUNT(Id) FROM Report WHERE Id='00O4z0000057ssKEAQ'` | 1 |
| `SELECT COUNT(Id) FROM CronTrigger WHERE CronJobDetail.JobType='8'` (jobs de relatório agendado) | 1 |

Leitura: a dev tem um relatório com o mesmo Id e um job de relatório agendado. Isso não prova nada sobre a demanda, por dois motivos:
- A dev é cópia de um momento anterior. Ela não reflete a alteração feita em produção.
- Não confirmei que o job de relatório agendado pertence a este relatório. Também não li a lista de destinatários, porque ela traz identificação de pessoas (guardrail #2).

Não alterei a assinatura na dev. Fazer isso testaria uma ação manual em outra org, não a mudança entregue.

## Critérios de aceite (de `01-analise.md`)

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | Fabio Soto não consta mais nos destinatários | Nada exercitável na dev | Lista sem Fabio Soto | Estado de produção; sem acesso e sem evidência no card | não executado |
| 2 | Demais destinatários iguais ao "antes", menos Fabio Soto | Nada exercitável | Antes menos 1 = depois | O "antes" não foi registrado no card. O card cita 3 destinatários restantes (1 papel/grupo e 2 usuários), mas é relato sem prova independente | não executado |
| 3 | Relatório existe com o mesmo Id e agendamento ativo | Contagens acima, na dev | Relatório existe e continua agendado em produção | Só a dev foi conferida (1 relatório, 1 job agendado). Produção não foi conferida | não executado |
| 4 | Mapeamento sem dado pessoal (quantidade e papel/perfil) | Inspeção de `04-plano-build.md` | Contagem total e papel/perfil | O "antes" não foi registrado. Só há a contagem do "depois" (3) | não executado |
| 5 | Nenhuma escrita em produção pelo agente | Leitura do plano de build e de `sf org list` | Zero escrita em produção | Só a dev está conectada. O plano registra a ação como humana, no card. Sem log de sessões para conferir | passou (parcial: inspeção do plano e da org conectada) |

## O que ficou sem prova e o que uma pessoa precisa fazer

1. Que Fabio Soto saiu da assinatura em produção. Quem executou deve registrar em `05-testes.md`, sem nomes, e-mails nem prints de dados:
   - o Id do relatório conferido em produção;
   - a contagem de destinatários antes e depois;
   - o perfil ou papel dos destinatários restantes;
   - a data e hora da remoção;
   - a confirmação de que ele não consta mais.
2. Que o "antes" menos um é igual ao "depois". Falta a lista do "antes", que o plano diz estar com a consultora.
3. Que o relatório continua agendado para os demais. Alguém com acesso deve conferir em produção, ou confirmar a próxima execução semanal.
4. Rollback: reinscrever Fabio Soto na mesma assinatura, dependendo de a lista do "antes" estar guardada.

Esta etapa não encontrou falha na construção. A prova depende de ação e evidência humanas em produção.
