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
- Asserts no resultado, não só "não lançou exceção".
- Cobertura mínima de 85% por classe, com a classe `<Classe>Test` dedicada.

## Jobs e agendamento

- Classe `Schedulable` se prova no teste, agendando dentro de `Test.startTest`.
- Não deixe job agendado na dev: classe com job pendente não aceita deploy e a validação
  do PR fica vermelha (EPLAST-33). Se agendou para conferir, desagende e diga no plano.
- O usuário que agenda roda o job. Se o job precisa de um permission set da demanda,
  escreva isso no plano; sem ele, o job falha em silêncio.

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
