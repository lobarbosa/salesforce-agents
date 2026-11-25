# Automação que só roda por agendamento (QA em duas fases)

Guia do agente `qa`. Leia quando a demanda entrega Flow agendado, job Apex agendado ou
qualquer automação que não dispara à mão, e sempre que `05-testes.md` já existir com
`**Veredito:** aguardando execução`.

Fluxo ou job agendado não dispara à mão, e a sua sessão acaba antes do horário dele. Não
reprove por isso. Deixar a automação rodar na sandbox de QA está autorizado pela mesma regra,
e o teste é feito em duas sessões:

**Fase 1 — armar** (quando `05-testes.md` não existe ou não está aguardando execução):
1. Registre o estado de antes, só por contagens agregadas (por exemplo, quantidade de
   registros por valor do campo que a automação grava, e quantidade de linhas de histórico).
2. Arme para **daqui a 5–10 minutos** (decisão de 2026-11-16; antes era até 1 hora):
   enquanto você espera, nenhuma outra demanda do cliente entra na sandbox de QA, e a
   EPLAST-33 segurou a QA por 50 minutos com um job que disparava em 20. Use o primeiro
   horário que a plataforma aceita a partir de 5 minutos à frente. Não espere o horário de produção da automação. Conforme o que a solução oferece:
   - **parâmetro de configuração da própria solução** (dia ou hora de execução num
     registro de configuração): implante na sandbox de QA só esse registro alterado;
   - **job Apex que a solução agenda** (`Schedulable`): agende-o na QA com um cron para
     daqui a 5–10 minutos, por Apex anônimo com `--target-org` explícito;
   - **Flow agendado** (horário de início no próprio Flow): implante na QA só esse Flow com
     o horário de início trocado para daqui a 5–10 minutos, nada mais nele.

   São as únicas implantações que você faz, sempre com `--target-org` explícito na sandbox de
   QA. Não commite nenhuma delas: a esteira descarta e, ao fim da sessão de conferência,
   reimplanta o build original. Calcule o horário no fuso da org, não no da sessão, e confira na org
   (`CronTrigger.NextFireTime`) que a próxima execução ficou onde você quis.
3. Calcule, com as mesmas contagens agregadas, o resultado esperado depois da execução.
4. Grave `05-testes.md` abrindo com `**Veredito:** aguardando execução`, a linha
   `**Org de teste:**` e `**Conferir depois de:** <data e hora em UTC>` (o disparo armado
   mais 10 minutos, sem margem maior; job em lote que encadeia outro pode somar 5), e nele
   o estado de
   antes, o que foi alterado para armar, o esperado e como desfazer.

**Fase 2 — conferir** (quando `05-testes.md` existe com `aguardando execução`):
1. Se ainda não passou do horário de `Conferir depois de`, a esteira já reimplantou a
   configuração original: arme de novo e mantenha `aguardando execução`.
2. Se passou: a org ainda está como você armou (decisão de 2026-11-16, achado EPLAST-28:
   reimplantar antes da sessão recriava o agendamento e apagava o `PreviousFireTime`).
   Confira que a automação rodou (`CronTrigger.PreviousFireTime` e `TimesTriggered` do
   arme, `AsyncApexJob`, log ou histórico), compare as contagens de depois com o esperado e
   leia o histórico do campo. Não desfaça o arme: a esteira reimplanta o build original
   logo depois da sua sessão.
   Job Apex que você agendou na fase 1: aborte-o e, se o design pede agendamento na QA,
   agende-o de novo no horário do design, dizendo isso no roteiro.
3. Reescreva `05-testes.md` com o veredito final, `aprovado` ou `reprovado`, e a evidência
   de antes e depois por caso. Automação que não rodou no horário é falha, não espera.

Se o `CLAUDE.md` do cliente ou o card proibirem a execução, não arme: os casos ficam "não
executado".
