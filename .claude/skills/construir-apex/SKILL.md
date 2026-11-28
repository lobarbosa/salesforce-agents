---
name: construir-apex
description: Checklist do desenvolvedor Apex para limites de plataforma, testes que passam em qualquer sandbox e jobs — a partir do que o QA já reprovou. Use na etapa de build com código, antes de escrever "Resultado do build: concluído".
---

# Apex que passa no QA

O teste unitário com 200 registros não pega tudo. Estes são os defeitos de código que
chegaram ao QA em demanda real, e como evitar cada um.

## Limites que o teste de bulk não mostra

- **Um job por registro.** Enfileirar um `Queueable` (ou chamar método `@future`) dentro do
  tratamento de cada registro funciona com um e estoura em lote: "Too many queueable jobs
  added to the queue: 51" (EPLAST-47, a execução inteira falhou). Enfileire **um** job com a
  lista de Ids, ou use Batch.
- **CPU síncrono com pai de muitos filhos.** Recalcular o pai a cada filho, em trigger,
  multiplica o trabalho pela cadeia de automações do pai (SOMOSAGILITY-10, 150 filhos).
  Agregue numa consulta só, uma vez por pai por transação; se o pior caso não cabe, vá para
  assíncrono.
- **Consultas somadas.** Sua classe roda na mesma transação dos Flows e triggers do objeto.
  Conte as consultas do caminho inteiro, não só as suas.
- **Dentro de job assíncrono, um `enqueueJob` só.** Em Batch ou Queueable, `System.enqueueJob`
  aceita **1** job por transação (50 no síncrono), e um Queueable encadeia **um** filho; em
  Batch e `@future` não se chama `@future`. Fonte: "Queueable Apex"
  (https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-queueing-jobs.html)
  e "Execution Governors and Limits"
  (https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-gov-limits.html),
  lidas em 2026-11-28.
- **Apex agendado roda com os limites síncronos** (100 consultas, 10 s de CPU), não com os
  assíncronos (mesma página de limites). Volume grande no agendado: o `execute` só dispara
  um Batch ou um Queueable.
- Escreva no plano de build o pior caso que você testou, com número.

## Testes que passam em qualquer sandbox

- **A fábrica de dados preenche tudo o que as validation rules do objeto exigem**, não só os
  campos da demanda. Validation rule ativa na QA e não na dev derrubou a suíte inteira
  (SOMOSAGILITY-10, 100% de falha na QA). Leia as regras ativas do objeto nas duas
  sandboxes antes de escrever a fábrica.
- Sem `SeeAllData=true`, sem depender de registro, usuário, fila ou configuração que exista
  só numa org. Usuário de teste se cria no teste.
- Resultado vazio é caso de teste: pai sem filho devolve `0`, não `null`, quando o critério
  fala em total (SOMOSAGILITY-10).
- Asserts no resultado, não só "não lançou exceção" (métodos da classe `Assert`).
- Cada ramo de condição exercitado, com entrada válida e inválida; bulk com pelo menos 20
  registros (o mínimo da documentação; a esteira pede o pior caso real); `System.runAs`
  para o perfil que de fato usa; não suponha Ids em ordem: use `ORDER BY`. Fonte: "Testing
  Best Practices"
  (https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-testing-best-practices.html,
  lida em 2026-11-28).
- Classe na API 67.0 ou mais roda em modo de usuário por padrão (skill `revisar-apex`): o
  teste com `System.runAs` do usuário comum é o que pega a permissão de campo que falta.
- Cobertura mínima de 85% por classe, com a classe `<Classe>Test` dedicada. A plataforma
  exige 75% do código da org, com todos os testes passando, para implantar em produção
  ("Testing and Code Coverage",
  https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-code-coverage-intro.html):
  os 85% são régua da esteira, acima da plataforma.

## Jobs e agendamento

- Classe `Schedulable` se prova no teste, agendando dentro de `Test.startTest`.
- Não deixe job agendado na dev: classe com job pendente não aceita deploy e a validação
  do PR fica vermelha (EPLAST-33). Se agendou para conferir, desagende e diga no plano. A
  documentação confirma: com job agendado ativo, a classe e as que ela referencia não se
  alteram pela interface; pela Metadata API só se a org permitir deploy com job pendente
  (configuração de deploy da org, que a esteira não altera). Fonte: "Apex Scheduler"
  (https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-scheduler.html,
  lida em 2026-11-28).
- No máximo **100** jobs de Apex agendados ao mesmo tempo na org, e agendamento no máximo de
  hora em hora: nunca agende a partir de trigger (mesma página).
- Apex agendado **não faz chamada externa síncrona**: a chamada vai num Queueable com
  `Database.AllowsCallouts` (mesma página).
- O usuário que agenda roda o job. A classe roda mesmo que ele não tenha acesso a ela, mas
  as permissões de objeto e campo dele valem em toda operação em modo de usuário (padrão na
  API 67.0). Se o job precisa de um permission set da demanda, escreva isso no plano; sem
  ele, o job falha em silêncio.

## Classe chamada por agente ou Flow

- Método invocável recebe o que o chamador mandar. Valide a entrada e devolva mensagem
  clara; não deixe estourar exceção para o agente interpretar.
- O retorno diz o que foi feito de fato (registro criado, com Id) ou que nada foi feito. É
  o que impede o agente de dizer "criado" sem ter criado (ver
  `.claude/skills/agentforce/SKILL.md`).

## Versão e escopo

- Classe em uso com mudança de comportamento vira classe nova; a troca de quem chama é o
  passo de ativação, registrado em "Versões e ativação".
- Não refatore fora do escopo. Dívida encontrada vai para `06-entrega.md`.

## Antes de escrever "concluído"

- [ ] Testes Apex rodados na sandbox de dev (com a org alvo explícita no comando), com
      cobertura por classe, e o resultado colado no plano.
- [ ] Pior caso de volume testado e escrito, com o limite que ele toca.
- [ ] Fábrica de dados conferida contra as validation rules das duas sandboxes.
- [ ] Nenhum job pendente na dev.
- [ ] Entrada inválida testada em todo método invocável.
