# EPLAST-29 · Análise — Ações por linguagem natural no assistente de IA

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** analise · **Autor:** ba-discovery (rascunho para validação humana)
**Fonte:** `demandas/EPLAST-29/demanda.md` (texto do consultor, não reescrito aqui) e `demandas/EPLAST-29/comentarios-do-card.md` (orientações de 2026-11-13 e decisão de 2026-11-15 de refazer pela regra 4)
**Org conectada nesta sessão:** `sbx-eplast-dev` (sandbox, `IsSandbox = true`, instância `eplast--qa.sandbox.my.salesforce.com`, API 68.0). Nenhuma org de produção foi tocada. Nenhum dado de registro foi lido: só metadata e contagens agregadas.
**Rodada anterior:** `demandas/EPLAST-29/rodada-anterior/01-analise.md` foi usada como referência de perguntas, não como decisão.

---

## 1. Resumo

O pedido: o usuário comercial, dentro do assistente de IA, cria tarefa, registro, e-mail ou mensagem por comando em linguagem natural. A org já tem o assistente: o agente `SFAgent2` (confirmado por `sf`). Ele hoje só lê. Esta análise fecha o escopo pelas regras da conta e pela org:

- **Estende o `SFAgent2`**, não cria agente novo (regra 3).
- **Escrita mínima: criar Task** vinculada a um registro, com confirmação do usuário antes de gravar.
- **E-mail e mensagem não saem do CRM.** Pela regra 2 da conta, o disparo é do Marketing Cloud. O assistente gera o conteúdo e o grava como atividade; o envio fica com quem opera o Marketing Cloud ou com o usuário.
- **Account, Opportunity e Order ficam fora deste build.** A org tem automação concorrente nesses três objetos (assessment, achado 1), e o mapa de ordem de execução está abaixo na seção 5. Só se abre essa frente em demanda própria.

Complexidade: **M** (justificativa na seção 9).

## 2. Objetivo

Reduzir o trabalho de registro manual do vendedor: ele pede a ação ao assistente e confirma o resumo antes de gravar. Métrica de negócio não definida pelo cliente (premissa P9). O aceite deste build é funcional, com registros sintéticos em QA.

## 3. Regra de negócio

Declarado na demanda:
- Criar tarefas, registros, e-mails e mensagens por comando em linguagem natural no assistente.

Declarado nas orientações da conta (2026-11-13) e na regra da conta:
- Escopo autorizado independentemente da onda (regra 1). **Não é pendência.**
- Marketing (e-mail, mensagem, campanha, jornada, nutrição) é disparado pelo Marketing Cloud. No CRM fica o que alimenta o MC (regra 2).
- Não sobrepor o que existe (regra 3).

Resolvido pela regra 4 (ver seção 8, premissas assumidas): confirmação antes de gravar, recusa sem gravação, ambiguidade sem gravação, sem elevação de privilégio, rastreabilidade de quem pediu.

## 4. Critérios de aceite (Gherkin)

Todos usam registros sintéticos (`REG-TESTE-01`, `REG-TESTE-DUP`) criados na sandbox de QA. Nenhum dado real de cliente entra no teste (guardrail 2). Os termos entre colchetes são preenchidos pelo arquiteto no design, não por suposição aqui.

```gherkin
Funcionalidade: Criação de Task por comando em linguagem natural no SFAgent2

  Cenário AC-1: criar tarefa com confirmação
    Dado que o usuário de teste [usuário com acesso ao SFAgent2 e criação de Task] está logado na sandbox de QA
    E existe o registro sintético REG-TESTE-01
    E a contagem de Task vinculada a REG-TESTE-01 é N
    Quando digita "criar tarefa de follow-up para REG-TESTE-01 com vencimento em <data>"
    Então o assistente mostra resumo com assunto, registro relacionado, responsável e vencimento
    E a contagem de Task vinculada a REG-TESTE-01 continua N
    Quando o usuário confirma
    Então a contagem de Task vinculada a REG-TESTE-01 é N+1
    E a Task nova tem ActivityDate igual à data informada, WhatId igual ao REG-TESTE-01 e OwnerId igual ao usuário

  Cenário AC-2: recusa do resumo não grava nada
    Dado o mesmo comando de AC-1
    Quando o usuário recusa o resumo
    Então a contagem de Task vinculada a REG-TESTE-01 é N

  Cenário AC-3: registro ambíguo não grava
    Dado que existem dois registros sintéticos com o nome REG-TESTE-DUP
    Quando o usuário pede "criar tarefa para REG-TESTE-DUP"
    Então o assistente lista os dois candidatos com identificador
    E nenhuma Task é gravada até o usuário escolher um deles

  Cenário AC-4: usuário sem permissão é recusado sem vazar dado
    Dado um usuário de teste sem permissão de criação em Task
    Quando pede a criação de tarefa para REG-TESTE-01
    Então a ação é recusada com mensagem de permissão
    E a contagem de Task não muda
    E a mensagem não mostra nomes nem campos de registros que o usuário não enxerga

  Cenário AC-5: campo obrigatório faltando não grava parcialmente
    Dado um pedido de tarefa sem o campo obrigatório que o design definir
    Quando o usuário confirma sem informar o campo
    Então o assistente pergunta o campo faltante
    E nenhuma Task parcial é gravada

  Cenário AC-6: pedido de envio de e-mail ou mensagem não envia pelo CRM
    Dado o comando "enviar e-mail de proposta para o contato de REG-TESTE-01"
    Quando o usuário confirma
    Então a contagem de EmailMessage da sandbox não muda
    E a Task de atividade criada guarda o texto do e-mail como rascunho no campo de descrição
    E o assistente informa que o envio é feito fora do CRM, pelo canal definido na premissa P3

  Cenário AC-7: pedido fora do escopo não grava
    Dado o comando "criar oportunidade para REG-TESTE-01"
    Quando o usuário pede a criação
    Então o assistente recusa e informa que a criação de Opportunity não está disponível nesta versão
    E nenhum registro de Opportunity, Account ou Order é criado ou alterado

  Cenário AC-8: rastreabilidade
    Dado uma Task criada pelo assistente
    Então CreatedById é o usuário que fez o pedido
    E a descrição da Task contém a marca "Origem: assistente de IA" (premissa P8)

  Cenário AC-9: não quebra o que já existe
    Dado a versão do SFAgent2 com a mudança instalada na QA
    Quando o usuário pergunta "quais clientes precisam de acompanhamento hoje?" e pede a consulta de pedidos já existente
    Então as respostas são as mesmas da versão anterior, na mesma base sintética
    E o subagente insights_comerciais continua com as 3 ações atuais (IdentificarConta, ConsultarPedidos, AgregacaoPedidos)
```

Observações de processo (checklist, não Gherkin):
- Contagens antes e depois são feitas por SOQL agregado (`COUNT`), sem retornar registro.
- Nenhum print de tela com registro real.

## 5. Impacto em Account, Opportunity e Order (ordem de execução mapeada)

Antes de aceitar qualquer demanda nova nesses objetos, o assessment pede o mapa de ordem. A análise de metadata desta sessão (`sf`) mostra:

| Objeto | Triggers Apex (ativas) | Flows record-triggered ativos | Validation rules (aggregate) |
|---|---|---|---|
| Account | `AccountBefore` (SBQQ, before) e `AccountTrigger` (custom, API 58) | `AccountTriggered` (Account, after save); `UpdateParentAccountUsedLimit` (Account, after save) | não contado por objeto nesta sessão |
| Opportunity | `OpportunityBefore` e `OpportunityAfter` (SBQQ) e `OpportunityTrigger` (custom, API 59) | `OpportunityFlow` (Opportunity, after save); `Oportunidade_Industria` (Opportunity, after save) | 16 |
| Order | `OrderTrigger` (SBQQ) e `OrderTrigger` (custom, mesmo nome) | `Order` (Order, after save); `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo...` (Order, before save) | 23 |
| Task | nenhuma | `TaskCreatedOrUpdated` (Task, after save, create e update) | 0 |

Leitura para este build:
- **Task** não tem trigger Apex, mas tem um Flow after-save ativo. Toda Task criada pelo assistente dispara `TaskCreatedOrUpdated`. O que esse Flow faz não foi lido nesta etapa: fica para o recon confirmar antes do design.
- **Order** e **Opportunity** têm duas triggers no mesmo evento (SBQQ e custom), mais Flows after-save. Pela documentação da plataforma, a ordem entre triggers do mesmo objeto e fase não é garantida, e entre Apex e Flow também não é fixa. A ordem exata **não está provada** e não é possível provar só com metadata. Mapear com trace de debug exige registros sintéticos em dev, e a sandbox de dev está sem dados (0 Task, sem Account/Opportunity/Order com dados de negócio).
- O nome `OrderTrigger` aparece duas vezes (assessment, achado 10, confirmado). Ambiguidade de log e stack trace.
- Integração com ERP (Protheus, achado 2 do assessment): o assessment não confirmou o caminho exato de disparo. Não é tocada por este escopo, já que Order e Account ficam fora.

**Decisão deste build:** nenhuma DML em Account, Opportunity ou Order. O único objeto gravado é Task. Se a conta quiser criar esses registros pelo assistente, é demanda própria, com o mapa de ordem e teste de integração antes do design (premissa P2).

## 6. O que já existe na org (confirmado por `sf`)

- **Agente `SFAgent2`** (`BotDefinition`, `AgentType = AgentforceEmployeeAgent`, `Type = InternalCopilot`). É o único agente da org. Confirmado.
- **Planner `SFAgent2_v4`** (retrieve de metadata, sem alteração na org). Subagentes: `agent_router`, `off_topic`, `ambiguous_question` e `insights_comerciais`. O último tem 3 ações, todas de leitura e todas mapeadas para ações padrão: `identifyRecordByName` (nome local `IdentificarConta`), `queryRecords` (nome local `ConsultarPedidos`) e `queryRecordsWithAggregate` (nome local `AgregacaoPedidos`). Não há ação de escrita hoje.
- **Não confirmado:** qual versão do planner está ativa. Objetos de versão de bot não são consultáveis pela API de dados. O recon confirma por outro caminho (setup ou metadata do bot).
- **Permission set `PS_Comercial_ResumoClienteAgente`** existe (custom). Nesta sandbox, a contagem de atribuições era zero na rodada anterior. Reconfirmar no recon.
- **Flows de Task:** `TaskCreatedOrUpdated` (ativo). Ver seção 5.
- **Marketing Cloud Connect instalado:** 12 Flows `MCC_*` ativos. Confirma que o disparo de marketing existe no MC, fora do CRM (regra 2). Sem Apex de e-mail confirmado nesta sessão.
- **Templates de e-mail:** 42 (agregado). Não lidos individualmente.
- **Licenças:** `Salesforce` (completa) 14 de 14 usadas, confirmado agora. Criar usuário de teste com licença completa **não é possível** nesta sandbox. Ver premissa P6.
- **Licenças de Agentforce no catálogo** (`PermissionSetLicense`, agregado): `Agentforce Coworker` com 0 de 100.000 usadas; `Agentforce Service Agent Builder` com 0 de 10.000 usadas. Atribuição a usuário de teste não confirmada.
- **Precedente de design em outra demanda:** `demandas/EPLAST-33/03-design.md` (D1) decidiu somente leitura sobre Account, Opportunity, Order, OrderItem, Product2 **e Task**. Esta demanda cria Task, então o arquiteto precisa decidir essa exceção de forma explícita, com a razão.
- **Coordenação:** `demandas/EPLAST-27/04-plano-build.md` (B1) já aponta que mudar o `SFAgent2` sem coordenação duplica trabalho com as demandas `eplast-ent-09/10/11`. Esta demanda altera o mesmo agente.

## 7. Riscos do assessment que tocam esta demanda

Foto de 2026-09-30. Cada item foi conferido agora quando possível.

| Achado | Status confirmado agora | Toca EPLAST-29? | Por quê |
|---|---|---|---|
| #1 Automação concorrente em Account, Opportunity e Order | confirmado (seção 5) | **Não neste escopo** (Task only). Vira bloqueio se a conta pedir Account/Opportunity/Order | Mapa da seção 5 |
| #2 Cobertura Apex de 10%, cadeia Protheus sem teste | não reconfirmado nesta sessão | **Baixo** | Sem Apex novo previsto. Se o design precisar de Apex, aplica `<Classe>Test` e 85% por classe |
| #3 Validation rules de Order (23) | confirmado (contagem 23) | **Não** | Order fica fora |
| #4 Campos custom sem descrição (68,6%) | não reconfirmado | **Sim** | O assistente usa o nome e a descrição do campo para preencher. Descrever os campos de Task que o assistente preencher (assunto, vencimento, descrição, responsável) |
| #6 Alias `sbx-eplast-dev` apontando para sandbox com nome de QA | **confirmado agora**: `instanceUrl` `eplast--qa.sandbox`, usuário com sufixo `.qa`, `IsSandbox = true`. `sf org list` não mostra alias de QA nesta sessão | **Sim, é bloqueante para a homologação** | Se dev e QA forem a mesma sandbox, o build e o roteiro de QA competem no mesmo ambiente. Não é pergunta de negócio: ver seção 10 |
| #7 e #8 perfis comerciais duplicados | não reconfirmado | **Sim, indiretamente** | Quem recebe o acesso ao agente depende do perfil vigente (premissa P5) |
| #10 `OrderTrigger` com nome duplicado | confirmado | **Não** | Order fica fora |
| "Não pôde ser medido": OWD e compartilhamento | não medido | **Sim** | Afeta o que o usuário enxerga no AC-4. Recon confirma |
| "Não pôde ser medido": volume e dados de produção | confirmado: 0 Task na dev | **Sim** | Sem volume de teste na dev. Não inferir volume daqui (premissa P10) |
| Licença Salesforce completa 14/14 | **confirmado agora** | **Sim** | Impede criar usuário de teste com licença completa (premissa P6) |

## 8. Premissas assumidas (validar na homologação)

Cada decisão abaixo resolve uma pergunta que a rodada anterior deixou em aberto, pela ordem da regra 4: o que a org mostra, depois o padrão, na opção mais simples e mais fácil de mudar. Todas estão resolvidas com evidência. Se a Eplast discordar, o campo "Como mudar" diz o que refazer.

- [x] **P1 — Plataforma e relação com o assistente (Q1 da rodada anterior).**
  - **Pergunta:** a ação é de um assistente novo ou extensão do que já existe?
  - **Decisão:** extensão do `SFAgent2`, com uma nova ação de escrita (criar Task) no subagente `insights_comerciais` ou em subagente próprio de ações comerciais. A escolha entre os dois é do arquiteto.
  - **Evidência:** `sf` confirma o agente `SFAgent2` como único agente da org, com planner `SFAgent2_v4` e 3 ações de leitura (seção 6). Regra 3 da conta manda estender.
  - **Como mudar:** se a Eplast quiser um agente separado, o arquiteto reavalia e a coordenação com EPLAST-27/28 vira um item próprio.

- [x] **P2 — Quais registros o assistente grava (Q2 da rodada anterior).**
  - **Pergunta:** "registros" inclui Account, Opportunity, Order, Lead, Case, Contact?
  - **Decisão:** só **Task**, vinculada a um registro existente por `WhatId`. Event, Account, Opportunity e Order ficam fora.
  - **Evidência:** Account, Opportunity e Order têm automação concorrente (seção 5, assessment achado 1). O precedente EPLAST-33 (D1) e o EPLAST-27/34 seguem a mesma linha de não gravar nesses objetos sem mapa de ordem. Task tem 0 trigger Apex e 1 Flow after-save, o caso de menor risco.
  - **Como mudar:** demanda própria para Account/Opportunity/Order, com mapa de ordem e teste de integração antes do design.

- [x] **P3 — E-mail e mensagem: enviados ou rascunhados, e por qual canal (Q3 da rodada anterior).**
  - **Decisão:** o assistente **não envia** e-mail nem mensagem pelo CRM. Ele gera o texto e grava como Task de atividade (rascunho no campo de descrição). O envio fica fora do CRM: pelo Marketing Cloud, quando for marketing, ou pelo canal do próprio usuário, quando for atendimento individual. A escolha é do desenho de Marketing Cloud, que o CRM não controla.
  - **Evidência:** regra 2 da conta (tudo de marketing sai pelo MC; sem Flow com e-mail alert nem Apex de e-mail no CRM). MC Connect instalado (12 Flows `MCC_*` ativos). Nenhuma ação de envio existe hoje no agente.
  - **Como mudar:** se a Eplast quiser envio 1:1 pelo Salesforce (EmailMessage), vira item de design próprio, com gate, e precisa confirmar com quem opera o MC que não há duplicidade de disparo.

- [x] **P4 — A confirmação é sempre obrigatória (Q4 e Q6).**
  - **Decisão:** toda gravação pelo assistente pede confirmação do resumo, inclusive criar Task.
  - **Evidência:** padrão da plataforma para ação de escrita em agente. Opção mais simples e a mais fácil de afrouxar depois.
  - **Como mudar:** se a Eplast aceitar criação direta para tarefas simples, a mudança é uma flag na ação, sem refazer o desenho.

- [x] **P5 — Quem recebe a ação (Q5).**
  - **Decisão:** usuários com acesso ao `SFAgent2` e criação de Task. Acesso ao agente pelo permission set existente `PS_Comercial_ResumoClienteAgente`, se o recon confirmar que ele cobre o agente. Se não cobrir, cria-se permission set novo. Nenhum perfil novo.
  - **Evidência:** permission set custom existe na org (seção 6). Regra 3 manda reaproveitar. Perfis comerciais duplicados (achado 7 e 8) são o motivo para não criar perfil novo.
  - **Como mudar:** se a Eplast quiser outro grupo de usuários, muda só a atribuição do permission set.

- [x] **P6 — Usuários de teste na QA (licença).**
  - **Decisão:** usar usuários existentes da sandbox que já tenham licença e perfil comercial, ou solicitar ao BASIS um usuário de teste com licença Salesforce Platform. Não criar usuário com licença completa, porque ela está 14 de 14.
  - **Evidência:** `UserLicense` confirmado agora (Salesforce 14/14). 22 usuários ativos na sandbox (agregado).
  - **Como mudar:** se a Eplast tiver licença disponível, cria-se usuário de teste normal. Não altera o desenho.

- [x] **P7 — Referência a registro (Q7).**
  - **Decisão:** reaproveitar a ação `identifyRecordByName` já existente no `insights_comerciais`. Se houver mais de um candidato, o assistente lista e pede escolha (AC-3). Nenhum critério novo de busca.
  - **Evidência:** ação já configurada no planner (seção 6). Regra 3.
  - **Como mudar:** se a busca precisar de código ou de página atual, o arquiteto ajusta a ação.

- [x] **P8 — Rastreabilidade (RN-4 da rodada anterior).**
  - **Decisão:** `CreatedById` já guarda quem pediu. A marca "Origem: assistente de IA" vai na descrição da Task. Não cria campo novo, para não afetar o assessment achado 4.
  - **Evidência:** comportamento padrão da plataforma para `CreatedById`. Campo custom só se o arquiteto justificar.
  - **Como mudar:** se a Eplast quiser campo próprio de origem, vira campo com descrição preenchida.

- [x] **P9 — Métrica de negócio (Q9).**
  - **Decisão:** o aceite deste build é funcional (AC-1 a AC-9). Métrica de negócio (tarefas criadas, tempo economizado) é medida depois do go-live com relatório existente, e não bloqueia a entrega.
  - **Evidência:** precedente EPLAST-26 (PA-10) e sandbox sem dados de negócio.
  - **Como mudar:** se a Eplast definir meta, entra na homologação como critério extra.

- [x] **P10 — Volume e latência (Q10).**
  - **Decisão:** não medidos. Premissa de uso de baixo volume, a ser confirmada na homologação.
  - **Evidência:** 22 usuários ativos na sandbox (agregado). Dev sem dados, então não há medição. Não inferir volume daqui.
  - **Como mudar:** se o volume for alto, o arquiteto revisa limites da ação.

- [x] **P11 — Retenção e LGPD das conversas e do conteúdo de e-mail (Q11).**
  - **Decisão:** o build não cria log próprio nem copia conteúdo para fora do Salesforce. O conteúdo fica só na Task. A retenção do histórico da conversa segue o padrão da plataforma para o agente. Não há dado real neste build (guardrail 2).
  - **Evidência:** guardrail 2 do squad. Padrão da plataforma. Nenhum componente de log novo.
  - **Como mudar:** se a Eplast exigir retenção específica, o item vai para o design e para o jurídico do cliente antes de produção. Não bloqueia QA com dado sintético.

- [x] **P12 — Eventos e Event (escopo do "registro").**
  - **Decisão:** Event fica fora. Existe trigger `AdvRouteEvents` no namespace `maps` em Event, sem confirmação de efeito.
  - **Evidência:** `sf` (seção 5). Escopo mínimo.
  - **Como mudar:** demanda própria, depois de o recon confirmar o trigger.

- [x] **P13 — Licença de IA e créditos (Q12).**
  - **Decisão:** premissa de que a licença de Agentforce está disponível para o usuário de teste. Confirmar no recon antes do build.
  - **Evidência:** PSL `Agentforce Coworker` com 0 de 100.000 usadas (agregado). Atribuição não confirmada.
  - **Como mudar:** sem licença, o build segue, mas o teste de QA não roda.

## 9. Complexidade

**M.** Justificativa: a mudança é de um agente existente com uma ação de escrita em Task, sem Apex novo previsto. Sobe para G se a conta pedir Account, Opportunity ou Order, por causa das triggers concorrentes e da integração ERP.

## 10. Estimativa de esforço

**Estimativa de esforço:** 14–26 h

Premissas que mais pesam na faixa:
- Escopo Task-only, com confirmação e sem Apex (limite inferior). Se Account, Opportunity ou Order entrarem, a faixa sobe bastante e a estimativa não vale mais.
- Usuários de teste disponíveis (P6). Se o BASIS demorar, atrasa a homologação, não o build.
- Coordenação com as demandas EPLAST-27/28 no mesmo agente (seção 6). Pode somar 2–4 h.
- O que o `TaskCreatedOrUpdated` faz ainda não foi lido. Se ele tiver efeito relevante, o design soma tempo de teste.
- Faixa larga porque a execução ainda não tem recon nem design. O arquiteto refina.

## 11. O que a demanda NÃO diz (e como foi tratado)

1. Plataforma do assistente → resolvido (P1, `SFAgent2`).
2. Extensão ou assistente novo → resolvido (P1).
3. Tipos de registro → resolvido (P2, Task only).
4. E-mail e mensagem enviados ou rascunhados → resolvido (P3).
5. Perfis e permission sets → resolvido (P5).
6. Confirmação obrigatória → resolvido (P4).
7. Referência a registro → resolvido (P7).
8. Erro de validação e de integração → padrão: a mensagem da regra aparece para o usuário e nada é gravado parcialmente (AC-5). Erro de integração não se aplica, porque não há integração no escopo.
9. Métrica de sucesso → resolvido (P9).
10. Volume e latência → resolvido com premissa (P10).
11. LGPD de conversa e e-mail → resolvido com premissa (P11).
12. Licença de IA → premissa (P13).
13. Treinamento e adoção → fora desta análise. Sem decisão tomada aqui.

## 12. Pendências

Nenhuma pendência de caso 3 nesta análise. Todas as perguntas de regra de negócio foram resolvidas pela org ou pelo padrão e estão como premissa assumida (seção 8). Nenhum `- [ ]` foi aberto.

**Pré-requisito de ambiente (não é pergunta de negócio, e não bloqueia a análise):** confirmar se `sbx-eplast-dev` e `sbx-eplast-qa` são sandboxes distintas (assessment achado 6, ainda aberto: a `instanceUrl` do dev é `eplast--qa`). Isso deve ser resolvido antes de qualquer deploy para a QA (`05-deploy-qa.md`). Quem confirma é o BASIS do cliente ou a equipe de delivery. O agente não resolve isso sozinho.

## 13. O que ficou sem prova

- Ordem de execução entre triggers e Flows de Order e Opportunity (seção 5): não provada, só mapeada por tipo.
- Efeito do Flow `TaskCreatedOrUpdated`: não lido.
- Versão ativa do planner do `SFAgent2`: não confirmada pela API de dados.
- OWD e compartilhamento de Task: não medidos.
- Volume e latência: não medidos (sandbox sem dados).
- Alias de QA: não conectado nesta sessão, então não foi possível comparar dev e QA diretamente.

## 14. Próximo passo

Recon (etapa 2) confirma na dev: o que faz `TaskCreatedOrUpdated`, a versão ativa do planner, o permission set `PS_Comercial_ResumoClienteAgente` e o alcance dele no agente, e OWD de Task. Não avança para design antes da validação desta análise.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
