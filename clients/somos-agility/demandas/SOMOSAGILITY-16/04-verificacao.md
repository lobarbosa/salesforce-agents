**Verificação:** inconclusiva
**Org de teste:** `sbx-somos-agility-dev`

# SOMOSAGILITY-16 — Verificação

Org confirmada com `sf org list`: `sbx-somos-agility-dev` (Sandbox, Connected). Só leitura de metadata e contagens agregadas. Nenhum DML, deploy ou Apex anônimo; nenhum dado de teste criado, então não há nada a apagar. Nenhum destinatário lido.

## Conferência dos pontos do plano

- Plano diz que a mudança é humana, em produção, e não há metadata a construir: **procede**. `04-plano-build.md` registra "Nenhum" componente, e a remoção do destinatário foi feita pela UI em produção, fora da esteira.
- Plano diz que a FALHA 1 da rodada 1 (sem evidência antes/depois, critérios 1 a 4) não é corrigível nesta etapa: **procede**. O "antes" não foi guardado e o guardrail #1 impede a esteira de ler a assinatura de produção. Nada que o builder faça gera essa prova.
- Plano diz que a assinatura de produção não existe na dev: **procede em parte**. O relatório existe na dev com o mesmo Id do critério (`00O4z0000057ssKEAQ`, nome "Leads Semanais", pasta "Leads"), mas não tem agendamento: 0 jobs de relatório agendado (`CronTrigger`, `JobType='A'`) com esse nome. A dev tem 16 jobs de relatório agendado no total, nenhum deste relatório.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Pré-condição: relatório existe na dev | `SELECT COUNT(Id) FROM Report WHERE Id='00O4z0000057ssK' OR Name='Leads Semanais'` | 1 | 1 (Id `00O4z0000057ssKEAQ`, pasta Leads) | passou |
| V2 | Pré-condição: agendamento existe na dev | `SELECT COUNT(Id) FROM CronTrigger WHERE CronJobDetail.JobType='A' AND CronJobDetail.Name LIKE '%Leads Semanais%'` | 1 ou mais | 0 | passou (como fato; impede V3 a V6) |
| V3 | 1: destinatário removido deixa de receber | Não executado: sem assinatura na dev para consultar | Destinatário não consta | Sem dado | não executado |
| V4 | 2: lista dos demais inalterada | Não executado: o "antes" nunca foi registrado | Contagem antes = depois menos 1 | Sem dado | não executado |
| V5 | 3: relatório continua agendado e ativo | Não executado na dev: o agendamento de produção não existe aqui | Agendamento ativo | Na dev, 0 agendamentos | não executado |
| V6 | 4: registro antes/depois no projeto | Conferido no plano de build | Contagem antes/depois e papel/perfil registrados | Só o "depois" (3 restantes) por relato no card; "antes" ausente | não executado |
| V7 | 5: nenhuma escrita em produção pelo agente | Nenhum comando contra produção; só a dev, só leitura | Nenhuma escrita | Confirmado | passou |

## O que ficou sem prova

Critérios 1 a 4 (e a parte de agendamento ativo do critério 3). Motivo: a mudança ocorreu em produção, que a esteira não pode ler, e o estado "antes" não foi guardado. Criar um agendamento na dev para simular exigiria alterar um relatório que não criei, e o resultado não provaria o que foi feito em produção.

Para provar, uma pessoa precisa:
1. O executor registrar no card, sem nomes, e-mails ou prints de dados: data/hora, contagem de destinatários antes e depois, papel/perfil de cada restante, e confirmação de que o usuário removido não consta mais.
2. A consultora informar se existe a contagem do "antes".
3. O gate humano decidir entre aguardar essa evidência ou aceitar formalmente a declaração do executor, registrando os critérios 1 a 4 como "sem prova independente".

## O que pode ter saído da org

Nada. Nenhum registro foi criado e nenhuma automação foi disparada.
