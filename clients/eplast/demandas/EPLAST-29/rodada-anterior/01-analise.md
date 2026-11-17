# EPLAST-29 · Análise — Ações por linguagem natural no assistente de IA

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** analise · **Autor:** ba-discovery (rascunho para validação humana)
**Fonte:** `demandas/EPLAST-29/demanda.md` (texto do consultor, não reescrito aqui)

---

## 0. Pendência de escopo contratual (antes de qualquer design)

A própria demanda registra: "Onda 3 · Comercial — ainda não contratada no projeto atual (Ondas 1–2)". O `contrato.md` confirma: Ondas 1 e 2 contratadas (120 h), Onda 3 (Comercial) "ainda não contratada" [contrato.md].

Este BA não decide se a onda foi contratada. **Pergunta ao humano (consultor / gestor de conta):** existe aditivo ou autorização comercial para esta demanda entrar em esteira, ou ela está sendo registrada em backlog como antecipação de escopo futuro? A resposta não muda esta análise, mas precisa existir antes do gate de design. Caso análogo já foi levantado no mesmo ponto em EPLAST-27 [demandas/EPLAST-27/01-analise.md, pergunta 1].

---

## 1. Contexto de negócio

- A demanda faz parte da Solicitação de Proposta Konecta para implantação de IA no Salesforce Sales e Marketing da Eplast. Item: criação de tarefas, registros, e-mails e mensagens a partir de comandos em linguagem natural no assistente de IA.
- O histórico mostra que **já existe um assistente de IA na conta**: a Onda 2 (projeto-piloto) entregou "Ativação e configuração do Agentforce no perímetro do piloto" (`eplast-ent-07`, concluído) e "Consulta rápida ao CRM via assistente de IA" (`eplast-ent-08`, concluído). Os agentes "Quais clientes precisam de acompanhamento hoje?" e "Resumo completo de um cliente" (`eplast-ent-09` e `eplast-ent-10`) foram construídos fora da esteira [contrato.md].
- Consequência: não está claro se EPLAST-29 é **extensão** do assistente já ativado (novas ações sobre a mesma plataforma) ou um **assistente novo**. Isso muda a arquitetura e é a primeira pergunta abaixo.

## 2. Objetivo

Permitir que o usuário comercial, dentro do assistente de IA, peça em linguagem natural a criação de uma tarefa, de um registro, de um e-mail ou de uma mensagem, com o Salesforce executando a ação correspondente **somente depois de o usuário ver o resumo do que será gravado e confirmar**.

Objetivo mensurável ainda não definido (pendente, ver Q9).

## 3. Regra de negócio

Declarado na demanda:
- Criação de tarefas, registros, e-mails e mensagens por comando em linguagem natural no assistente.

Não declarado — tratado como **suposição pendente** (não é regra validada):
- **RN-1 (pendente):** toda gravação disparada pelo assistente exige confirmação explícita do usuário antes de persistir.
- **RN-2 (pendente):** envio de e-mail ou mensagem nunca sai sem ação humana separada; no mínimo, a ação gera rascunho.
- **RN-3 (pendente):** a ação respeita as permissões do usuário que pediu (objeto, campo e registro). O assistente não eleva privilégio.
- **RN-4 (pendente):** cada registro criado guarda quem pediu e de qual conversa veio (rastreabilidade).
- **RN-5 (pendente):** comando ambíguo (mais de um registro candidato, campo obrigatório faltando) não grava; pede esclarecimento.

## 4. Critérios de aceite (Gherkin)

Os critérios abaixo são testáveis, mas os termos entre colchetes dependem das respostas da seção 6. Não são finais até o humano responder.

```gherkin
Funcionalidade: Criação de registro por comando em linguagem natural no assistente de IA

  # Depende de Q1, Q2 e Q4
  Cenário: criar tarefa a partir de comando com confirmação
    Dado que o usuário "[perfil a definir]" está logado na sandbox de QA
    E existe um registro de teste sintético "[objeto]" chamado "REG-TESTE-01"
    Quando digita "criar tarefa de follow-up para REG-TESTE-01 com vencimento em [data]"
    Então o assistente mostra resumo com assunto, registro relacionado, responsável e vencimento
    E nenhuma Task é gravada antes da confirmação
    Quando o usuário confirma
    Então existe exatamente 1 Task nova com ActivityDate igual à data informada, WhatId igual ao REG-TESTE-01 e OwnerId igual ao usuário

  # Depende de RN-1
  Cenário: recusa do resumo não grava nada
    Dado o mesmo comando do cenário anterior
    Quando o usuário recusa o resumo
    Então a contagem de Task do registro permanece igual ao valor anterior à conversa

  # Depende de RN-5
  Cenário: registro ambíguo não grava
    Dado que existem dois registros de teste com o mesmo nome "REG-TESTE-DUP"
    Quando o usuário pede "criar tarefa para REG-TESTE-DUP"
    Então o assistente lista os dois candidatos com identificador
    E nenhuma Task é gravada até o usuário escolher um deles

  # Depende de RN-3 e Q5
  Cenário: usuário sem permissão é recusado sem vazar dado
    Dado um usuário "[perfil sem permissão]" sem acesso de criação ao objeto alvo
    Quando pede a mesma criação
    Então a ação é recusada com mensagem de permissão
    E nenhum registro é criado
    E a mensagem não exibe campos ou nomes de registros que o usuário não pode ver

  # Depende de RN-5 (campos obrigatórios)
  Cenário: campo obrigatório faltando não grava parcialmente
    Dado um comando de criação de "[objeto com campo obrigatório]" sem o campo obrigatório
    Quando o usuário confirma sem informar o campo
    Então o assistente pergunta o campo faltante
    E nenhum registro parcial é gravado

  # Depende de Q3 e RN-2 (somente se e-mail/mensagem entrar no escopo)
  Cenário: pedido de envio gera rascunho e não envia
    Dado o comando "enviar e-mail de proposta para o contato de REG-TESTE-01"
    Quando o usuário confirma o rascunho
    Então existe um rascunho associado ao registro
    E nenhum e-mail é enviado (sem registro de envio no objeto de e-mail)

  # Depende de RN-4
  Cenário: rastreabilidade da criação
    Dado uma Task criada pelo assistente
    Então CreatedById é o usuário que fez o pedido
    E o registro da conversa do assistente é localizável a partir da Task [mecanismo a confirmar]

  # Condicional a Q2 (só se Account, Opportunity ou Order entrarem no escopo)
  Cenário: criação de Order ou Account pelo assistente não contorna a automação existente
    Dado que a ação cria um registro de "[Account/Order]" de teste
    Quando a criação é confirmada
    Então a execução de triggers e Flows do evento segue a ordem mapeada no recon
    E a integração com o ERP só dispara conforme o fluxo já existente, sem chamada extra gerada pela ação
    E o teste roda com stub ou ambiente de integração de QA, nunca com integração real
```

Observação de processo (testável por checklist, não por Gherkin): todos os registros usados em teste são sintéticos. Dado real de cliente não entra no teste (guardrail #2).

## 5. O que a demanda NÃO diz

1. Qual plataforma de assistente: Agentforce já ativado no piloto, Einstein Copilot ou outra.
2. Se é extensão do assistente existente (`eplast-ent-07/08`) ou um assistente novo.
3. Quais tipos de registro: somente Task/Event, ou também Account, Opportunity, Order, Lead, Case, Contact.
4. Se e-mail e mensagem são **enviados** ou só **rascunhados**, e por qual canal (e-mail do próprio Salesforce, cliente de e-mail do usuário, WhatsApp, Marketing Cloud Connect, outro).
5. Quem são os usuários: todo o time comercial, só vendedor, gestor também. Qual perfil ou permission set.
6. Se a confirmação é sempre obrigatória ou se ações de baixo risco (ex.: criar tarefa) podem ser diretas.
7. Como o assistente resolve referência a registro ("o cliente X"): busca por nome, por código, por seleção na página.
8. O que acontece em erro de regra de validação ou de integração.
9. Métrica de sucesso e critério de aceite de negócio (quantas ações, tempo economizado, taxa de erro tolerada).
10. Volume e latência esperados.
11. Requisitos de LGPD para e-mail e mensagem (retenção do conteúdo, quem pode ler o histórico da conversa).
12. Se há orçamento de créditos de IA ou licença Agentforce disponível para os usuários do piloto e para a sandbox de QA.
13. Se a demanda inclui treinamento e adoção dos usuários (provavelmente Onda 5, não contratada).

## 6. Perguntas para o humano responder antes do design

Ordem por impacto na arquitetura:

- **Q1 (bloqueante):** plataforma e relação com o assistente já ativado (extensão ou novo) — seção 1.
- **Q2 (bloqueante):** quais objetos o assistente pode criar. Se a resposta incluir Account, Opportunity ou Order, o risco de automação concorrente e de integração com o ERP entra no escopo do design (ver seção 7).
- **Q3 (bloqueante):** e-mail e mensagem são enviados ou rascunhados, e por qual canal. Se envolver Marketing Cloud Connect, a Onda 4 (Marketing) também não está contratada — ver seção 0.
- **Q4:** a confirmação é sempre obrigatória?
- **Q5:** quais perfis e permission sets recebem a ação.
- **Q0 (contratual):** aditivo ou autorização para a Onda 3 — seção 0.

Demais perguntas (Q6 a Q13 da seção 5) podem ser respondidas no design.

## 7. Riscos do assessment que tocam esta demanda

Fonte: `assessment.md` (saúde geral vermelho, sbx-eplast-dev, 2026-09-30). Só entra o que efetivamente toca o pedido.

| Achado (assessment) | Severidade | Toca EPLAST-29? | Por quê |
|---|---|---|---|
| #1 Automação concorrente em Account, Opportunity e Order | alta | **Condicional a Q2** | Só se o assistente criar ou alterar Account, Opportunity ou Order. Criar Task ou Event não aparece no inventário do assessment; a presença de automação concorrente em Task não foi verificada (confirmar no recon). |
| #2 Cobertura de teste Apex de 10%, cadeia Protheus sem teste | alta | **Condicional a Q2** | Se Account ou Order forem criados pela ação, os caminhos de integração (`SendAccountToProtheus`, `SendOrderToProtheus`, `OrderTriggerHandler`) podem ser acionados sem rede de teste. O caminho exato de disparo não foi confirmado. |
| #3 Validation Rules de Order (9 regras de campo obrigatório com mensagem genérica) | média | **Condicional a Q2** | Se o assistente criar Order, precisa preencher campos obrigatórios ou tratar a mensagem de erro. A mensagem genérica "Este campo precisa ser preenchido" não serve ao usuário do assistente. |
| #4 68,6% dos campos custom sem descrição | média | **Sim, parcialmente** | Assistentes usam a descrição do campo para entender e preencher dados. Sem descrição, o preenchimento tende a errar. Vale descrever os campos que o assistente for usar. |
| #5 Convenção de classe de teste | média | **Só se houver Apex** | Se o design exigir Apex, a classe de teste segue `<Classe>Test`. |
| #6 Alias `sbx-eplast-dev` apontando para sandbox que se identifica como QA | média | **Sim** | A homologação desta demanda depende de dev e QA serem ambientes distintos. Enquanto o achado não for confirmado, o teste pode competir com outro ambiente. Bloqueante para confiar na homologação. |
| #7 e #8 perfis duplicados (Comercial, Comercial - Analista, Comercial - Analistas, Comercial Padrão) | baixa / média | **Sim, indiretamente** | Quem recebe a ação depende de qual perfil é o vigente (Q5). |
| #9 Classes Apex em API v58–v64 | baixa | **Só se editar Apex existente** | Subir API antes de editar, com regressão. |
| #10 `OrderTrigger` com nome duplicado | baixa | **Só se Order entrar** | Ambiguidade de nome em log e stack trace. |
| "Não pôde ser medido": OWD e sharing não confirmados | — | **Sim** | Criação de registro pelo assistente depende de OWD e regras de compartilhamento. Não sabemos o OWD dos objetos envolvidos. Confirmar no recon. |
| "Não pôde ser medido": dados de produção e volume | — | **Sim** | A sandbox de dev está vazia (0 Account/Contact/Opportunity). Não dá para testar com volume real, e não se deve inferir volume daqui. |
| Licença Salesforce 14/14 usadas na sandbox | — | **Sim** | Pode impedir criar usuários de teste com o perfil comercial. Confirmar antes do build. |

## 8. Premissas a validar (todas pendentes)

- **P1 (PENDENTE):** o assistente é o Agentforce já ativado no piloto. Confirmar com Q1.
- **P2 (PENDENTE):** o escopo mínimo é criação de Task (e, se houver, Event) com confirmação. Confirmar com Q2 e Q4.
- **P3 (PENDENTE):** e-mail e mensagem entram como rascunho, sem envio automático. Confirmar com Q3.
- **P4 (PENDENTE):** teste de QA em dados sintéticos, sem integração real com o Protheus.
- **P5 (PENDENTE):** o recon (etapa 2) confirma os objetos, campos, perfis e OWD antes de qualquer referência ao design. Nenhum objeto citado nesta análise está confirmado via `sf` ainda.
- **P6 (PENDENTE):** a licença e os créditos de IA estão disponíveis para os usuários de teste.

## 9. Complexidade

**G (provisório).** Justificativa: plataforma de assistente indefinida, possível toque em Account, Opportunity e Order com integração ERP e automação concorrente, e requisitos de confirmação e permissão ainda não definidos. Se Q2 restringir a Task e Event com confirmação e sem envio, cai para **M**.

## 10. Estimativa de esforço

**Estimativa de esforço:** 40–80 h

Premissas que mais pesam na faixa:
- Escopo restrito a Task e Event com confirmação e rascunho de e-mail (limite inferior). Se Account, Opportunity ou Order entrarem, o limite superior sobe por causa do mapeamento de automação e dos testes da cadeia Protheus (assessment #1 e #2).
- Plataforma já ativada (Agentforce no piloto). Se for plataforma nova, a faixa sobe.
- Sandbox de QA disponível e com licença para usuários de teste (P6). Atraso aqui estende a homologação.
- Faixa larga porque as perguntas Q1 a Q3 não estão respondidas. O arquiteto refina no design.

---

## Próximo passo

Responder as perguntas Q0 a Q5 (seções 0 e 6) e confirmar as premissas P1 a P6. Depois disso o recon (etapa 2) confirma objetos e campos na org de dev antes do design.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
