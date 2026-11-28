---
name: integracao
description: Como desenhar, construir e testar integração do Salesforce com sistema externo dentro da esteira — credencial, tratamento de erro, repetição, limites e prova sem chamar o sistema real. Use em design, build, verificação e QA de demanda que faz ou recebe chamada de outro sistema.
---

# Integração

Integração é onde a esteira tem menos controle: metade do comportamento está num sistema
que as sandboxes não alcançam. O design precisa dizer, antes do build, o que será provado
na sandbox e o que só o cliente confere do lado dele.

## Design

Para cada chamada, uma linha:

| Item | O que escrever |
|---|---|
| Direção | O Salesforce chama, ou é chamado |
| Gatilho | Evento de registro, botão, agendamento, evento de plataforma |
| Síncrono ou não | Chamada a sistema externo a partir de gravação de registro é sempre assíncrona |
| Volume | Quantas chamadas no pior caso de uma transação e por dia |
| O que vai e o que volta | Campos, sem exemplo com dado real |
| Erro | O que acontece em cada falha (tabela abaixo) |

**Credencial.** Sempre por Named Credential (com External Credential), chamada como
`callout:<Nome>/caminho`. A documentação prevê o mesmo nome de Named Credential com endereço
diferente em cada org, e o mesmo código implantado em todas: é o que deixa a sandbox apontar
para o ambiente de teste do outro sistema sem mudar o pacote ("Named Credentials as Callout
Endpoints",
https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-callouts-named-credentials.html,
lida em 2026-11-28). Nunca endereço,
usuário, senha ou token em classe, em Flow, em Custom Metadata, em Custom Setting ou em
artefato da demanda. A esteira não cria nem preenche credencial: é passo humano, listado em
"Pré-requisitos" com dono. Sandbox aponta para o ambiente de teste do outro sistema; se só
existe o de produção, a chamada real não se testa na esteira, e isso vai escrito.

**Erro.** O design responde, para cada um:

| Falha | O que o desenho precisa dizer |
|---|---|
| Tempo esgotado | Repete? Quantas vezes, com que intervalo? |
| Resposta de erro do outro lado | Onde fica registrado, e quem é avisado |
| Resposta inesperada (campo ausente, formato diferente) | Trata como erro; não grava pela metade |
| Chamada repetida | A operação é idempotente? Qual chave evita duplicar do outro lado? |
| O outro sistema fora do ar por horas | Onde as mensagens esperam, e como se reprocessa |

Falha de integração nunca é silenciosa: fica num registro de log consultável, com o que
foi tentado, sem dado pessoal no texto.

**Limites.** Conferidos no Apex Developer Guide, "Callout Limits and Limitations"
(https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-callouts-timeouts.html)
e "Execution Governors and Limits"
(https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-gov-limits.html),
lidas em 2026-11-28:

| Limite | Valor |
| --- | --- |
| Chamadas por transação | 100 |
| Tempo de espera padrão de cada chamada | 10 s (ajustável de 1 ms a 120 s) |
| Espera somada de todas as chamadas da transação | 120 s |
| Tamanho da requisição ou da resposta | 6 MB síncrono, 12 MB assíncrono, e conta no heap |

- **Não se faz chamada depois de operação pendente na mesma transação**: DML, job
  assíncrono (`@future`, Batch), Apex agendado ou envio de e-mail. Chame antes, ou leve a
  chamada para um Queueable com `Database.AllowsCallouts`.
- Apex agendado não faz chamada síncrona ("Apex Scheduler",
  https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-scheduler.html).
- Em modo somente leitura da org (manutenção da Salesforce), a chamada sai mas a gravação
  seguinte falha; `System.getApplicationReadWriteMode()` diz o modo (mesma página de limites
  de chamada). Integração que grava a resposta trata esse caso como erro reprocessável.

## Build

- Código: uma classe que só fala com o sistema externo, separada da regra de negócio, para
  o teste trocar a resposta.
- Teste unitário com resposta simulada (`HttpCalloutMock`): sucesso, erro do outro lado,
  tempo esgotado e resposta malformada. Teste Apex não faz chamada real.
- Declarativo: ação externa em Flow tem caminho de falha tratado, como qualquer ação
  (`.claude/skills/construir-flow/SKILL.md`).
- Entrada recebida de fora é desconfiada: valide tipo, tamanho e obrigatórios antes de
  gravar.
- Entrada recebida de fora passa pelas **regras de duplicidade** do objeto. Regra com ação
  "Allow" e alerta devolve erro pela API e **não grava**, até a chamada repetir com
  `allowSave` verdadeiro no `DuplicateRuleHeader`; com "Block", recusa sempre. Fonte:
  Metadata API, `DuplicateRule`
  (https://developer.salesforce.com/docs/platform/api-metadata/references/meta-types/metadata-duplicaterule.html,
  lida em 2026-11-28). O design diz qual dos dois o sistema de origem deve fazer, e o recon
  lista as regras ativas do objeto (`DuplicateRule.IsActive`).
- No plano de build, seção "Integração": Named Credential usada, o que precisa ser
  preenchido à mão em cada sandbox, e o que não pôde ser exercitado.

## Verificação e QA

Dado de teste que dispara integração está autorizado na esteira, com o menor número de
registros e tudo marcado como teste. Antes de criar o registro, leia pela metadata o que a
cadeia chama.

- **Prove o lado do Salesforce**: a chamada foi montada com os campos certos, a resposta
  simulada foi tratada, o erro ficou registrado. Evidência é o registro de log ou o
  resultado do teste, não "integração funcionando".
- **Chamada real**: só se a sandbox aponta para ambiente de teste do outro sistema. Liste
  em "O que pode ter saído da org" cada chamada feita e o que ela criou do outro lado.
- **Sem ambiente de teste do outro lado**: a falha é de origem `ambiente`, não de
  construção (`.claude/skills/provar-criterio/SKILL.md`). O ponta a ponta vai para "O que
  o cliente confere", com o passo a passo.
- Teste o caminho de erro de propósito: é o que mais falha em produção e o que menos se
  testa.

## Nunca

- Credencial, token ou endereço de produção em qualquer arquivo da demanda.
- Corpo de requisição ou resposta com dado real em log, artefato ou captura.
- Apontar sandbox para o sistema de produção do cliente para "testar de verdade".
