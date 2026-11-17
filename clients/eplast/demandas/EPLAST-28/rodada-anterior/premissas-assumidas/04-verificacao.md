**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

Org conferida com `sf org list`: alias `sbx-eplast-dev`, Org Id 00DHa000006vfMLMAY, Connected. Usuário de teste da conta (regra 6): dois Ids resolvidos, `005bJ00000hBJmYQAW` (inativo) e `005bJ00000piKAaQAM` (ativo). Não foram usados; não houve alteração de usuário, permission set nem Marketing User.

## Por que inconclusiva
1. A dev tem 0 Account e 0 Opportunity (contagens agregadas). Não existe `clients/eplast/fixtures/` no repositório, então não há script previsto de conta ou oportunidade.
2. O Flow é Schedule-Triggered. Não achei jeito legítimo de disparar um Flow agendado sob demanda na dev, e o Debug de Flow agendado não é executável por `sf`.
3. A correção desta rodada (rastro `ALERTA_ENVIADO`) está na versão 2, que está em Draft. Só a versão 1 está Active, e ela não tem o rastro. Ativar versão é passo separado e fora do meu papel.
4. Não montei fixture de Account e Opportunity: mesmo com dado, os pontos 2 e 3 impedem exercitar o Flow.

## Evidência obtida (sem execução do Flow)
- Versões do Flow `Opportunity_Scheduled_AlertaParada` (consulta a `FlowVersionView`): v2 Draft, v1 Active.
- `CronTrigger` `0 0 7 ? * * *`: 1 registro na dev (agendamento presente).
- `IntegrationLog__c` com `ALERTA_ENVIADO`, `DONO_INATIVO` ou `FALHA_NOTIFICACAO`: 0 registros. O Flow nunca rodou sobre oportunidade nesta org.
- Revisão estática do XML da v2 na branch: `recordUpdates` 0, `recordDeletes` 0, `recordCreates` 3 (o plano diz que são só em `IntegrationLog__c`; só contei os elementos, não conferi o objeto de cada um), `actionCalls` 1, `ALERTA_ENVIADO` 2 ocorrências, nenhuma referência a e-mail nem a `et4ae5`.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | CA-01 fechada não alerta, aberta é avaliada | Nada exercitável: 0 Opportunity na dev | — | — | não executado |
| 2 | CA-02 parada em N dias alerta o dono | Idem | — | — | não executado |
| 3 | CA-03 atividade recente não alerta | Idem | — | — | não executado |
| 4 | CA-04 sem atividade, criada há N dias, alerta | Idem | — | — | não executado |
| 5 | CA-05 sem repetição | Idem | — | — | não executado |
| 6 | CA-06 sem alteração de dados | Contagem de `recordUpdates` e `recordDeletes` no XML da v2 | 0 e 0 | 0 e 0 (só estático; sem prova de execução) | não executado |
| 7 | CA-07 sem e-mail nem Marketing Cloud | Busca por e-mail e `et4ae5` no XML | nenhuma | nenhuma (só estático) | não executado |
| 8 | CA-08 gestor | Sem dado nem execução | — | — | não executado |
| 9 | CA-09 dono inativo, `DONO_INATIVO` | Sem dado nem execução | — | — | não executado |
| 10 | CA-10 sem agente novo | Não consultei `GenAiPluginDefinition`. O plano diz que não há | — | — | não executado |
| 11 | CA-11 carga e limites | Sem dado; limites oficiais também não conferidos pelo build | — | — | não executado |
| 12 | CA-12 | Não se aplica (sem Apex), conforme o design | — | — | não executado |

## O que ficou sem prova e o que uma pessoa precisa fazer
- Que a v2 notifica e grava `ALERTA_ENVIADO`, e que a causa do sino vazio das rodadas de QA não é problema de entrega. Para provar: ativar a v2 numa org com oportunidades abertas (a QAS tem), esperar o disparo das 07:00 e consultar `IntegrationLog__c` (`ALERTA_ENVIADO`) junto com o sino do dono.
- CA-01 a CA-11, por execução. Para provar: uma fixture sintética de Account e Opportunity (`TESTE EPLAST-28`) na dev, com a v2 ativada, ou a execução agendada na QA.
- Limites de notificação e de interviews (design 5.2): ainda não conferidos, conforme o plano.

## Dados de teste
Nenhum criado e nada a apagar. Nenhuma alteração em usuário, nenhum job agendado por mim, nenhum registro lido além de contagens e campos técnicos.

## O que pode ter saído da org
Nada. Nenhum registro foi criado e nenhuma chamada externa foi feita.
