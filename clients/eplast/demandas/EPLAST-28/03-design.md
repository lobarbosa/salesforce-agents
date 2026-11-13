# EPLAST-28 — Design: alertas de oportunidade parada ou sem acompanhamento

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 3 (Comercial), **não contratada**
**Org de referência:** `sbx-eplast-dev` (sandbox confirmada, recon de 2026-11-10 em `02-recon.md`)
**Status deste design:** **arquitetura decidida, parâmetros de negócio NÃO FECHADOS.** Não libera build sozinho (seção 0).

---

## 0. Antes de tudo: o que este aceite libera e o que não libera

> **BLOQUEIO CONTRATUAL SEM DECISÃO REGISTRADA.** A Onda 3 (Comercial) não está contratada.
> `contrato.md` confirma que o escopo contratado é só Ondas 1 e 2 (120 h, fim previsto 2026-11-30). A seção 6 da
> análise pediu uma decisão humana entre (a) aditivo, (b) voltar para backlog ou (c) autorização explícita para
> análise e design antecipados **sem build**. O gate da análise foi aprovado, mas **nenhuma das três saídas está
> registrada** em `comentarios-do-card.md` nem em `gates.md`. Este agente não decide isso.
>
> **Aceitar este design NÃO libera o build** enquanto a decisão contratual não estiver registrada e os quatro
> parâmetros bloqueantes da seção 3 não estiverem respondidos. Se a saída for (c), este documento é o entregável
> final da etapa e a demanda deve parar aqui.

O que dá para decidir com segurança hoje, e está decidido abaixo: a forma da solução (agendada, somente-leitura,
fora da ordem de execução de Opportunity), o nível da plataforma e quando ele muda, os componentes, os riscos e o
que fica fora. O que depende de resposta do negócio fica marcado como **PENDENTE**, com a opção recomendada e o
impacto de cada alternativa.

## 1. Decisão

**Flow agendado (Schedule-Triggered Flow) em Opportunity, somente-leitura, que envia Custom Notification ao dono.**
Roda uma vez por dia sobre as oportunidades abertas, calcula os dias desde a data de referência e notifica **apenas
no dia em que a parada atinge o limite**. Não grava nada em Opportunity, Task ou Account.

Nível: **declarativo (2)**. Há uma condição de descida para Apex (seção 1.3), que só vale se o negócio escolher
certas respostas.

### 1.1 Por que não configuração pura (nível 1)

Avaliei duas opções nativas:

- **Relatório "minhas oportunidades paradas" + assinatura de relatório com condição.** Não exige automação nenhuma
  e é a opção mais barata. Mas não atende a análise como ela foi aprovada: a assinatura **repete** o envio a cada
  execução enquanto a oportunidade estiver parada (contraria a RN-3, "o alerta não se repete"), cada vendedor
  precisa assinar o próprio relatório, só sai por e-mail ou notificação de relatório (não pelo registro), e não tem
  escalonamento. **Se o negócio responder que quer um resumo diário por e-mail e aceitar a repetição, esta opção
  passa a ser a recomendada** e o esforço cai bastante (seção 9).
- **Templates `agentic_feed` (`Custom_Stale_Opp`, "Create Custom Recommendations").** Estão na org como templates
  inativos. Não consegui fazer retrieve nem ler o que fazem, e não sei se a licença permite ativá-los
  (`02-recon.md`, seção 5). Não dá para recomendar o que não foi lido (guardrail #3). Fica como pergunta ao
  consultor: se houver um recurso nativo de "oportunidade parada" licenciado, ele vem antes deste Flow.

### 1.2 Por que Flow e não Apex

A regra base é simples: um filtro (aberta), uma conta de dias, uma comparação e uma notificação por registro. O Flow
agendado processa as oportunidades em lotes e agrupa a ação de notificação por lote, o que resolve a escala no
cenário base sem código. Apex aqui só traria custo: a org tem 10% de cobertura (achado 2) e cada classe nova vira mais
uma `<Classe>Test` para manter.

### 1.3 Quando desce para Apex (Schedulable + Batch)

O build passa a ser Apex **se qualquer uma destas respostas vier assim**:

| Resposta do negócio | Por que o Flow não serve |
|---|---|
| Item 1: "acompanhamento" exige filtrar o tipo de atividade (ex.: ignorar as Tasks automáticas de `Oportunidade_Industria`/`OpportunityFlow`, contar só Task concluída pelo dono) | precisa ler as Tasks filhas de cada oportunidade. No Flow isso vira um Get Records por oportunidade; em Apex é uma consulta agregada por `WhatId` no lote |
| Item 3: canal em **resumo por dono** (uma mensagem com N oportunidades) | o Flow agendado roda uma interview por registro e não agrupa por dono; o Batch agrupa no `execute`/`finish` |
| Item 8: volume de produção acima do teto seguro do Flow agendado (seção 5) | o limite diário de interviews de Flow agendado passa a ser um risco |

Nesse caso o desenho vira `OpportunityStaleAlertScheduler` (Schedulable) → `OpportunityStaleAlertBatch`
(Database.Batchable, consulta só campos de metadata do registro) → `OpportunityStaleAlertService` (regra e envio via
`Messaging.CustomNotification`), cada um com `<Classe>Test` e cobertura mínima de 85%. A forma continua a mesma:
agendada e somente-leitura.

## 2. Como a solução funciona (forma base)

```
[Agendador diário, horário a definir]
   └─ Flow Opportunity_Scheduled_AlertaParada
        start: Opportunity, IsClosed = false   (+ filtros de elegibilidade, item 6)
        fórmula DiasParado = TODAY() - <data de referência>     ← item 1, PENDENTE
        fórmula Limite     = <N para este registro>              ← item 2, PENDENTE
        Decisão: DiasParado = Limite ?
           sim → Send Custom Notification
                   tipo: Oportunidade_Parada
                   destinatário: OwnerId                        ← item 4, PENDENTE
                   alvo: Id da oportunidade (abre o registro)
                   texto: nome da oportunidade + dias parada     ← item 7, PENDENTE
           [opcional, item 4] DiasParado = Limite + N2 → notifica gestor
        nenhum Update / Create / Delete
```

### 2.1 Deduplicação sem gravar estado (RN-3 e "novo acompanhamento zera")

Para não repetir o alerta, a forma comum seria marcar na oportunidade "alerta enviado". Isso grava em Opportunity e
entra na cadeia do achado 1. A alternativa adotada **não guarda estado**: notifica só quando `DiasParado` é **igual**
ao limite, e não "maior ou igual".

- No dia N a oportunidade gera um alerta. No dia N+1 não gera mais, sem precisar lembrar de nada.
- Se houver novo acompanhamento, a data de referência anda e a contagem recomeça sozinha. Isso atende o cenário
  "novo acompanhamento zera a parada" da análise.
- Reenvio periódico, se o negócio quiser (item 3), é `MOD(DiasParado - Limite, FREQ) = 0`, ainda sem estado.

**Custo dessa escolha:** se o job não rodar num dia (falha, manutenção da plataforma), os alertas daquele dia
**não são recuperados**. Para recuperar seria preciso guardar estado, ou seja, um campo novo em Opportunity (que
cai no achado 1) ou um objeto de log (mudança de modelo de dados). As duas coisas são decisão de arquiteto sênior
(seção 4.3). Recomendo aceitar a perda e monitorar a execução do job (R7).

### 2.2 Data de referência recomendada (item 1, PENDENTE)

| Opção | Campo | Prós | Contras |
|---|---|---|---|
| **A (recomendada, se aceita)** | `LastActivityDate` | padrão, filtrável, já reflete Task e Event | as Tasks automáticas de `Oportunidade_Industria` e `OpportunityFlow` podem contar como acompanhamento; efeito a medir em teste |
| B | `LastStageChangeDate` | não é afetado por Task automática | mede avanço de funil, não contato com o cliente |
| C | o mais recente entre A e B | aproxima "nada aconteceu" | regra mais difícil de explicar ao vendedor |
| D | atividade filtrada por tipo/autor | o mais fiel ao conceito | **desce para Apex** (seção 1.3) |
| ~~E~~ | ~~`LastModifiedDate`~~ | — | **descartada**: Flows e integração gravam em Opportunity, então "modificado" não quer dizer "acompanhado" |

## 3. Parâmetros de negócio: PENDENTES (bloqueiam o build)

Nenhum destes tem resposta registrada. O design deixa um lugar para cada um, mas **não escolhe o valor**.

| # (análise §5) | Pergunta | Lugar no design | Opção que o design recomenda | Impacto se a resposta for outra |
|---|---|---|---|---|
| 1 | O que é "parada" / "acompanhamento" | fórmula `DiasParado` | opção A (`LastActivityDate`) | D desce para Apex (+8 a 12 h) |
| 2 | "Prazo combinado": valor único ou por estágio / record type | fórmula `Limite` | valor único | por estágio ou record type pede tabela de parâmetro → seção 4.3 |
| 3 | Canal e frequência | ação do Flow | Custom Notification (sino e app móvel), evento único | e-mail: ação Send Email e decisão de LGPD sobre o conteúdo (item 7); resumo diário: Apex ou relatório; Teams/Slack/Marketing Cloud: **fora do escopo** (Marketing Cloud é Onda 4, não contratada) |
| 4 | Destinatários e escalonamento | destinatário da notificação | só o dono | gestor: ver R5. **Na sandbox, 0 usuários ativos têm `ManagerId`** e só existem 2 papéis, então o escalonamento por hierarquia não tem de onde ler hoje |

Também precisam de resposta antes do build, mas não mudam a arquitetura: 5 (só avisa ou também cria Task → ver R3,
o design recomenda **não** criar Task), 6 (elegibilidade: o design assume excluir fechadas pelo `IsClosed`; Quote ativa
e record types ficam a confirmar), 7 (texto: o design propõe só o nome da oportunidade e os dias parada, **sem
valor**), 8 (volume de produção), 9 e 10 (sobreposições, seção 7).

## 4. Componentes

### 4.1 Criar (forma base, Flow)

| Tipo | API name proposto | Descrição (vai na metadata, achado 4) |
|---|---|---|
| Flow (Schedule-Triggered) | `Opportunity_Scheduled_AlertaParada` | Alerta diário ao dono quando uma oportunidade aberta atinge N dias sem acompanhamento. Somente leitura: não grava em nenhum objeto. EPLAST-28 |
| CustomNotificationType | `Oportunidade_Parada` | Notificação de oportunidade aberta que atingiu o limite de dias sem acompanhamento (EPLAST-28). Desktop e mobile |

Os nomes seguem a skill `padrao-entrega` (`<Objeto>_<Gatilho>_<Proposito>`), porque o `CLAUDE.md` da Eplast não
define convenção própria. O Flow sai em API atual (v68), não na v59 dos Flows existentes (achado 9).

### 4.2 Criar (só se descer para Apex, seção 1.3)

`OpportunityStaleAlertScheduler`, `OpportunityStaleAlertBatch`, `OpportunityStaleAlertService` e as três
`<Classe>Test` correspondentes: `OpportunityStaleAlertSchedulerTest`, `OpportunityStaleAlertBatchTest`,
`OpportunityStaleAlertServiceTest`. Seguem `<Classe>Test`, não `Test<Classe>` (achado 5). Nesse caminho o Flow da
seção 4.1 não é criado; o tipo de notificação continua.

### 4.3 Depende de decisão de arquiteto sênior (NÃO decidido aqui)

> **Mudança de modelo de dados: escalar ao humano.** Os itens abaixo só aparecem se o negócio pedir. O agente não
> decide nenhum deles.

- **Tabela de parâmetros** (Custom Metadata Type, ex. `AlertaOportunidadeParada__mdt` com estágio ou record type e
  dias), se o prazo variar por estágio ou record type (item 2). Um Custom Metadata é configuração deployável, não
  dado de cliente, mas é um tipo novo na org.
- **Estado do alerta**, se o negócio exigir recuperar alertas perdidos ou garantir "uma única vez" mesmo com falha
  do job: campo em Opportunity (cai no achado 1, **não recomendado**) ou objeto de log (objeto novo).
- **Campo próprio de "último acompanhamento"** em Opportunity, se nenhum campo padrão servir. **Não recomendado**:
  alguém teria que mantê-lo atualizado, e isso é automação nova gravando em Opportunity.

### 4.4 Alterar / depreciar

**Nenhum.** Não se altera `OpportunityTrigger`, `OpportunityTriggerHandler`, `OpportunityFlow`,
`Oportunidade_Industria`, `ScheduledFlowOpportunity` nem `TaskCreatedOrUpdated`. Não se liga
`TriggerUtility__mdt.BypassTrigger__c` (vale para a org inteira).

## 5. Ordem de execução, governador e escala

### 5.1 Conflito de automação (achado 1)

**Opportunity já tem cinco automações no mesmo evento de gravação (`OpportunityBefore` e `OpportunityAfter` do
SBQQ, `OpportunityTrigger` custom, `OpportunityFlow` sem critério de entrada e `Oportunidade_Industria`), além de
um Flow agendado (`ScheduledFlowOpportunity`).** Esse risco existe e não vem desta demanda.

**A solução não entra nessa ordem de execução**, porque não é disparada por gravação de Opportunity e não grava em
Opportunity. Não aciona triggers, Flows record-triggered nem validation rules. Por isso o mapeamento completo da
ordem de execução de Opportunity, que o assessment recomenda, **não é pré-requisito desta demanda**. Ele continua
pendente para quem vier gravar em Opportunity (ex.: EPLAST-26, se gravar score).

O que quebraria essa garantia, e por isso está fora do escopo: criar Task (R3), gravar marcador de alerta na
oportunidade (seção 4.3) ou trocar o agendamento por um gatilho record-triggered.

Convivência com `ScheduledFlowOpportunity`: são transações separadas e o novo Flow não grava nada, então não há
disputa de lock. Mesmo assim, o build agenda o novo Flow em horário diferente para os logs não se misturarem.

### 5.2 Governador

- **Por interview (um registro):** duas fórmulas, uma decisão, uma ação. Sem Get Records e sem DML. SOQL e DML do
  Flow ficam perto de zero; a ação de notificação é agrupada por lote pelo runtime.
- **Muitos registros:** o Flow agendado processa em lotes. O teto relevante é o **limite diário de interviews de
  Flow agendado**, e o valor exato vem da documentação oficial vigente, não de memória. O builder confirma esse
  número antes do build e registra em `04-plano-build.md`. **Volume seguro declarado:** enquanto as oportunidades
  abertas em produção ficarem abaixo de ~70% desse teto, o Flow serve. Acima disso o design volta para revisão
  (seção 1.3).
- **CPU, cenário "um pai com muitos filhos" (achado SOMOSAGILITY-10):** na forma base não há leitura de filhos. A
  data de referência é campo do próprio registro, então uma oportunidade com 500 Tasks custa o mesmo que uma com
  zero. O caso análogo aqui é **um dono com muitas oportunidades vencendo no mesmo dia**: o problema é de excesso
  de notificações, não de CPU (R4). Se o item 1 virar a opção D (ler Tasks), aí o cenário de filhos aparece, e o
  Batch Apex agrega as Tasks por `WhatId` uma vez por lote, nunca uma consulta por oportunidade.
- **Teste de carga do QA:** dois cenários. (a) 200+ oportunidades abertas de donos diferentes, com metade no dia
  limite; (b) 1 dono com 150 oportunidades no dia limite. O critério é o mesmo da doutrina: se passar de 70% de
  qualquer limite, o design volta para revisão.

### 5.3 Contexto de execução

O Flow agendado roda como usuário de processo automatizado, em contexto de sistema. Lê todas as oportunidades
abertas, independente de compartilhamento, e envia a notificação para o dono, que já enxerga o próprio registro.
Ninguém recebe acesso novo.

## 6. Permissões

- **Perfis e permission sets: nenhuma alteração** na forma base. O destinatário da Custom Notification não precisa
  de permissão extra para receber, e o alvo é um registro que ele já possui.
- O escalonamento ao gestor (item 4), se confirmado, pode levar o gestor a abrir um registro que ele não enxerga
  hoje: a hierarquia de papéis é quase vazia (2 papéis). Nesse caso o build precisa revisar o compartilhamento.
  Mudança de compartilhamento é decisão humana.
- No caminho Apex, as classes rodam no job agendado e não precisam de acesso por perfil.

## 7. Sobreposições que o humano precisa resolver

- **`SFAgent2` / `eplast-ent-09` (contratado, fora da esteira).** O tópico "Insights Comerciais e Acompanhamento"
  do agente já descreve "identificar oportunidades paradas". As 4 versões estão inativas nesta sandbox. Hoje o
  agente responde quando o vendedor **pergunta**, e o alerta **avisa** sem ninguém perguntar. Recomendação: tratar
  como complemento e usar **a mesma definição de "parada"** (item 1) nos dois. Se o agente e o alerta discordarem
  sobre o que é parada, o vendedor perde a confiança nos dois. Mesmo achado já registrado em
  `[demandas/EPLAST-27/03-design.md]`.
- **EPLAST-26 (scoring).** Se o score entrar como critério de prioridade do alerta, ou se a EPLAST-26 gravar em
  Opportunity, as duas demandas precisam ser desenhadas juntas. Este design não depende da EPLAST-26 e não grava
  nada que ela leria.

## 8. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Escopo sem contrato** (Onda 3) | **alta** | bloqueia o build até haver decisão registrada (seção 0). Não é risco técnico, mas é o que mais pesa |
| R2 | Tasks automáticas (`Oportunidade_Industria`, `OpportunityFlow`) zeram a parada sem acompanhamento real | **alta** | decisão no item 1. O QA mede o efeito sobre `LastActivityDate` com Task aberta, concluída e com data futura antes de fechar a regra |
| R3 | **Criar Task como ação do alerta** dispara `TaskCreatedOrUpdated` → atualiza Account → aciona a cadeia de Account do achado 1, e ainda realimenta o critério de parada | **alta** se pedido | fora do escopo recomendado. Se o negócio exigir, volta para design |
| R4 | Excesso de notificações para um dono com carteira grande | média | evento único por parada (seção 2.1). Se o volume for alto, a resposta é resumo diário (Apex ou relatório) |
| R5 | Escalonamento sem hierarquia: 0 usuários ativos com `ManagerId` e 2 papéis na sandbox | média | escalonamento fica fora até o cliente dizer de onde vem o gestor e confirmar que o dado existe em produção |
| R6 | **Alias de dev aponta para sandbox "qa"** (achado 6) e `sbx-eplast-qa` não está conectada | média | o build não começa sem o humano confirmar onde constrói e onde testa. Sem isso, dev e QA podem ser a mesma org |
| R7 | Alerta perdido se o job falhar num dia (sem estado, seção 2.1) | baixa | aceitar e monitorar a execução do Flow agendado. Recuperação exige estado (seção 4.3) |
| R8 | Fixture de teste esbarra nas 16 validation rules de Opportunity, algumas dependentes da Account e do dono da Account | média | o plano de build lista os campos exigidos por cada regra. Fixture sintética, só em sandbox |
| R9 | Cobertura Apex em 10% (achado 2) | baixa na forma base / média no caminho Apex | forma base não tem Apex. No caminho Apex: `<Classe>Test` ≥ 85% por classe, rodar `sf apex run test --code-coverage`. A demanda não piora a cobertura, mas também não a recupera |
| R10 | Templates `agentic_feed` podem duplicar a função se alguém os ativar | baixa | pergunta ao consultor (seção 1.1) |

### 8.1 Como o design trata cada achado do assessment

| Achado | Aplica? | Como é tratado |
|---|---|---|
| 1 — automação concorrente em Opportunity | **sim** | solução agendada e somente-leitura, fora da ordem de execução (seção 5.1). R3 bloqueia a única ação que reintroduziria o risco |
| 2 — cobertura 10% | sim | forma base sem Apex; no caminho Apex, 85% por classe (R9) |
| 3 — validation rules de Order | não | não toca Order |
| 4 — campos sem descrição | sim | nenhum campo novo na forma base; todo componente sai com descrição (seção 4.1) |
| 5 — `Test<Classe>` | sim, no caminho Apex | `<Classe>Test` (seção 4.2) |
| 6 — alias dev/qa | **sim** | R6, pré-condição de build |
| 7, 8 — perfis | não | nenhuma alteração de perfil |
| 9 — API version antiga | sim | componente novo em v68; nenhuma classe existente é editada |
| 10 — `OrderTrigger` duplicado | não | não toca Order |

## 9. O que NÃO será feito nesta demanda

- Build de qualquer coisa enquanto a decisão contratual (seção 0) e os itens 1 a 4 (seção 3) estiverem pendentes.
- Gravar em Opportunity, Task ou Account. Criar Task de follow-up (R3).
- Canal Marketing Cloud, Teams ou Slack (Marketing Cloud é Onda 4, não contratada).
- Escalonamento ao gestor, até haver fonte de gestor confirmada (R5).
- Mapeamento e consolidação da ordem de execução de Opportunity (achado 1), que fica como demanda própria.
- Alterar o agente `SFAgent2` ou integrar o alerta a ele.
- Ativar os templates `agentic_feed`.
- Corrigir os Flows existentes. Observação que fica para outra demanda: `ScheduledFlowOpportunity` tem uma decisão
  rotulada "Dia 1" que compara o dia com 14, e duas Tasks de `Oportunidade_Industria` têm `OwnerId` fixo no Flow.
  Nada disso é escopo aqui.
- Curadoria de descrição dos campos existentes.

## 10. Estimativa refinada

**Estimativa de esforço:** 16–40 h

O que mudou em relação à análise (24–56 h):

- **O mínimo caiu de 24 para 16 h.** A análise colocou o mapeamento da ordem de execução de Opportunity dentro da
  faixa. O recon mostrou que uma solução agendada e somente-leitura não depende desse mapeamento (seção 5.1), então
  ele sai. O mínimo cobre a forma base: Flow agendado, Custom Notification, valor único de N, `LastActivityDate`,
  sem escalonamento, mais o teste de carga em dois cenários e a fixture que satisfaz as 16 validation rules.
- **O máximo caiu de 56 para 40 h.** Os campos padrão de referência existem e nenhum campo novo é necessário. O
  máximo cobre o caminho Apex (Batch com resumo por dono ou filtro de atividade, 3 classes + 3 testes a 85%) com
  prazo por estágio via Custom Metadata, se o humano aprovar a seção 4.3.
- **Fica fora da faixa:** escalonamento ao gestor (depende de dado que a sandbox não tem), criar Task (R3), canal
  externo além de e-mail e a decisão contratual. Se o negócio aceitar relatório com assinatura (seção 1.1), o esforço
  fica perto de 4 a 8 h, abaixo desta faixa.

## 11. Pré-condições para liberar o build (checklist do humano)

1. Decisão contratual da análise §6 registrada no card: (a), (b) ou (c). Se for (b) ou (c), não há build.
2. Respostas aos itens 1 a 4 da seção 3. Com elas, o arquiteto confirma Flow ou Apex. Se as respostas caírem na
   seção 1.3 ou na 4.3, este design volta para revisão antes do build.
3. Volume de oportunidades abertas em produção, informado pelo cliente (item 8). Ninguém consulta produção.
4. Confirmação de qual sandbox é dev e qual é QA (R6), com `sbx-eplast-qa` conectada.
5. Aprovação da estimativa pelo cliente no Squad OS, conforme a regra do card.

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o build. O aceite libera a
arquitetura. O build continua bloqueado pela decisão contratual e pelos parâmetros pendentes (seções 0 e 11).
