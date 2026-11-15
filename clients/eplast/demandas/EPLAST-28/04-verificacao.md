**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast, Org Id 00DHa000006vfMLMAY), conferida com `sf org list`: única org conectada, não é produção. Nome com "qa" não é bloqueio (regra 5 da conta).

# EPLAST-28 — Verificação (reverificação, 2026-11-15)

O preflight diz "Etapa que vai rodar: build", mas esta sessão é a verificação; tratada como reverificação. O plano de build abre com `**Resultado do build:** concluído`. O comentário do card de 2026-11-15 10:51 confirma que a verificação anterior não reprovou.

## Resumo
A construção existe na dev como descrita e a revisão estática passa de novo. O comportamento do alerta (CA-01 a CA-09 e CA-11) **continua sem prova de execução**. Nenhum caso executado falhou, então não é reprovação.

## Por que ficou sem prova
- O Flow `Opportunity_Scheduled_AlertaParada` é Schedule-Triggered. Tentei dispará-lo na dev por Apex anônimo (`Flow.Interview.createInterview(...).start()`). Aceitou sem erro, mas a org não tem nenhuma Opportunity aberta (contagem agregada 0), e o Apex não injeta registro no `$Record` de um Flow agendado. O resultado não prova nenhum critério e não conto como execução. Não apareceu nenhum `IntegrationLog__c` novo causado por mim (os 4 logs de hoje são "Consulta CNPJ", das 13:26 UTC, anteriores a esta sessão).
- Não existe forma legítima de rodar o job sobre registros sintéticos antes do disparo agendado (próximo: 2026-11-16T10:00Z, 07:00 da org). Debug de Flow só existe na interface.
- Também não existe `clients/eplast/fixtures/` neste branch (ls devolve erro), então não há script de fixture a reutilizar. Criar Account (CNPJ fictício, `TriggerUtility.bypassTrigger`, autorizado no card de 2026-11-15 18:15) e Opportunity com `CreatedDate` de 14 dias atrás só serve se alguém puder rodar o job depois. Não criei esses dados, para não deixar registro na dev sem como provar nada hoje.
- O alerta só sai com `DiasParado` igual a 14 exato (ou na carga inicial), então o teste precisa de dado datado e do disparo do job.

## O que uma pessoa precisa fazer para provar
1. Criar, na dev ou na QA pela esteira, Account `TESTE EPLAST-28` (CNPJ fictício válido, com bypass) e Opportunities `TESTE EPLAST-28 ...` com dono que passe nas validation rules (campo "ID Usuário Protheus"), `CreatedDate` ou Task concluída datada em hoje menos 14 dias. Para CA-09 usar como dono o usuário inativo `005bJ00000hBJmYQAW`; o ativo é `005bJ00000piKAaQAM` (ambos Administrador do sistema, perfil não alterado).
2. Rodar o Flow (debug na interface ou esperar o disparo das 07:00) e conferir notificação, `IntegrationLog__c` e contagens e `LastModifiedDate` de Opportunity, Account, Order, Task e Event antes e depois (CA-06; fragilidade do achado 1 do assessment).
3. Para a automação agendada, duas sessões (arma e confere depois do horário).
4. Conferir na documentação oficial os limites de notificação personalizada e de interviews diários antes da carga inicial (o builder também não conferiu).

## Tabela de casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Build existe | Query Tooling no Flow por DeveloperName | Versão ativa | `Opportunity_Scheduled_AlertaParada` v1, Active, AutoLaunchedFlow | passou |
| V2 | P4, P6 (parâmetros) | Revisão do metadata do CMDT no branch (`git diff --stat`) | CMDT com 5 campos e registro `Default` | 5 campos e `Default` presentes no diff | passou |
| V3 | CA-07 (canal) | Query Tooling em `CustomNotificationType` | Tipo `Oportunidade_Parada` | 1 registro | passou |
| V4 | CA-06 (estático) | grep no XML: recordUpdates, recordDeletes, emailSimple, emailAlert, apex | 0 ocorrências | 0 | passou |
| V5 | CA-07 (estático) | grep de `customNotificationAction` | Única ação de saída | 2 linhas (abertura e fechamento da tag); sem e-mail | passou |
| V6 | Agendamento | Query em `CronTrigger` | Diário 07:00 | WAITING, `0 0 7 ? * * *`, próximo 2026-11-16T10:00Z | passou |
| V7 | CA-10 | `git diff --stat main...HEAD -- force-app` | Nenhum agente criado ou alterado | 9 arquivos, todos CMDT, notificação e o Flow; nenhum GenAi | passou |
| V8 | CA-12 | n/a | Sem Apex | Nenhum Apex no diff | n/a |
| C0 | Disparo sob demanda | Apex anônimo `Flow.Interview...start()` na dev | Avaliar oportunidades | Aceito sem erro; 0 Opportunity e sem `$Record`; sem efeito observável | não executado |
| C1 | CA-01 | Não exercitado (0 Opportunity) | Fechada não alerta | Start filtra `IsClosed = false` (só XML) | não executado |
| C2 | CA-02 | Não exercitado | Dono notificado com o texto do design | — | não executado |
| C3 | CA-03 | Não exercitado | Sem notificação | — | não executado |
| C4 | CA-04 | Não exercitado | Alerta com CreatedDate | — | não executado |
| C5 | CA-05 | Não exercitado | Sem repetição | — | não executado |
| C6 | CA-06 (runtime) | Não exercitado | Contagens e LastModifiedDate iguais | — | não executado |
| C7 | CA-08 | Não exercitado | Gestor só com a chave ligada | — | não executado |
| C8 | CA-09 | Contagem de `IntegrationLog__c` com DONO_INATIVO ou FALHA_NOTIFICACAO | Log por dono inativo | 0 (Flow nunca rodou sobre registro) | não executado |
| C9 | CA-11 | Não exercitado | Sem erro de governador | — | não executado |

## Dados de teste
Nenhum criado, nenhum alterado. Nenhum usuário modificado (só consulta de Id). Nada a apagar. O job agendado do Flow (`Opportunity_Scheduled_AlertaParada-1`) é da construção e foi mantido; é agendamento nativo de Flow, não job Apex, e não bloqueia deploy de classe.

## O que pode ter saído da org
Nada. Nenhum registro criado por esta verificação. A tentativa de start por Apex não gerou notificação nem log.

## Premissas exercitadas
P1 a P18 do `03-design.md` seguidas; nenhuma foi motivo de reprovação. Nenhuma foi exercitada em runtime (P2, P3, P6 e P10 dependem do disparo do job).
