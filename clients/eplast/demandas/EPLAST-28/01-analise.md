# EPLAST-28 — Alertas de oportunidade parada ou sem acompanhamento

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** 1 (análise, ba-discovery) · **Rodada:** refeita em 2026-11-15 pela regra 4 da conta
**Org confirmada (`sf org list`):** `sbx-eplast-dev` (Sandbox, Connected, Org Id `00DHa000006vfMLMAY`). Nenhuma escrita feita; só metadata e contagens.
**Entradas lidas:** `demanda.md`, `comentarios-do-card.md` (incluindo as orientações de 2026-11-13 e a decisão de 2026-11-15), `contrato.md`, `rodada-anterior/01-analise.md` (perguntas já levantadas), `rodada-anterior/02-recon.md` (achados de Opportunity e Flows), `assessment.md` (via RAG, resumo e achados 1, 2, 6 e 10), RAG do cliente (EPLAST-33, EPLAST-47).

**Status:** análise pronta para validação humana. Nenhuma pergunta de regra de negócio ficou sem decisão. Todas as decisões tomadas sem resposta do cliente estão na seção "Premissas assumidas", com evidência e como mudar.

---

## 1. Resumo do pedido

Alertar automaticamente o responsável por uma oportunidade quando ela ficar parada ou sem acompanhamento além do prazo. Origem: Solicitação de Proposta Konecta, item "alertas automáticos sobre oportunidades paradas ou sem acompanhamento" (Onda 3, Comercial, ainda não contratada no `contrato.md`).

## 2. Contexto de negócio

A Eplast quer que oportunidades não fiquem paradas sem que alguém perceba. Hoje a org não tem alerta desse tipo: a sandbox de dev não tem registros de Opportunity nem de Task (contagem 0 confirmada em 2026-11-15), então não há comportamento atual a preservar, e o volume de produção não foi consultado (regra de dado real).

## 3. Objetivo

Que o dono de cada oportunidade aberta receba um aviso interno do Salesforce quando ela passar do prazo sem atividade e sem mudança de estágio, sem que o alerta altere a oportunidade, a conta ou o pedido.

## 4. Escopo

**Dentro:**
- Detecção de oportunidades abertas paradas, por job agendado (leitura).
- Notificação interna no Salesforce para o dono (e, se configurado, o gestor).
- Parâmetros do prazo e do destinatário em metadata configurável.

**Fora (nesta demanda):**
- E-mail, SMS, WhatsApp, Chatter ou qualquer disparo de marketing. Tudo que for mensagem sai pelo Marketing Cloud (regra 2 da conta); a dependência de Marketing Cloud, se algum dia existir, vira passo de quem opera o Marketing Cloud, não desta demanda.
- Criação de Task, reatribuição de dono ou qualquer escrita em Opportunity, Account ou Order.
- Agente, tópico ou ação novos no SFAgent2 (ver premissa P11 e critério CA-10).
- Score de lead ou oportunidade (EPLAST-26, em outra frente).

**Escopo contratual:** a Onda 3 não está no `contrato.md`. Pela decisão do responsável pela conta (2026-11-13, card, e regra 1 da conta), a demanda segue análise, design e build sem pendência por onda. Não é tratado como bloqueio nem como pergunta ao cliente.

## 5. Regras de negócio e como foram resolvidas

Cada pergunta do card (2026-11-13) e cada lacuna da rodada anterior está abaixo. Ordem da regra 4: (a) o que a org mostra, confirmado por `sf`; (b) padrão da plataforma ou do squad; (c) pergunta aberta só se errar for caro.

| # | Pergunta | Resolução | Fonte |
|---|---|---|---|
| R1 | O que é "parada" e "acompanhamento" | Ver P2 | (a) campos padrão `LastActivityDate` e `LastStageChangeDate` confirmados por `sf sobject describe` em Opportunity |
| R2 | Prazo: único ou por estágio | Ver P4 | (b) prazo único em metadata configurável; por estágio fica para depois |
| R3 | Canal e frequência | Ver P5 | (b) notificação interna padrão da plataforma; regra 2 da conta exclui e-mail de disparo |
| R4 | Destinatários e escalonamento | Ver P6 | (b) dono; gestor fica desligado por padrão |
| R5 | Ação além da notificação | Ver P7 | (a) recon: criar Task dispara `TaskCreatedOrUpdated`, que atualiza Account e realimenta o próprio critério (achado 3 do recon) |
| R6 | Oportunidades elegíveis | Ver P8 | (b) `IsClosed` padrão; (a) 11 estágios abertos e 2 fechados confirmados no recon |
| R7 | Conteúdo do alerta e LGPD | Ver P9 | (b) notificação só para usuário interno da org; sem canal externo |
| R8 | Volume de produção | Ver P13 | Não consultado de propósito (dado real fora do contexto). Não muda a arquitetura: job em lote serve para qualquer volume |
| R9 | Sobreposição com eplast-ent-09 ("Quais clientes precisam de acompanhamento hoje?") | Ver P11 | `contrato.md`: entregável da Onda 2, construído fora da esteira. Não há código dele no `force-app` local |
| R10 | Sobreposição com EPLAST-26 (score) | Ver P12 | Fora do escopo desta demanda; sem dependência na v1 |
| R11 | Campos de referência | `LastActivityDate` e `LastStageChangeDate` existem (confirmado por `sf`). Nenhum campo novo | (a) campos padrão; nenhum campo custom criado, logo nenhum precisa de `Description` (achado 4 do assessment) |
| R12 | Ambiente de build e QA | Ver riscos, seção 7 | Achado 6 do assessment, reconfirmado em 2026-11-15 |

## 6. Critérios de aceite (Gherkin)

Cada cenário é testável em sandbox de QA com dados sintéticos. Os valores de prazo são o padrão configurado (P4), não constantes de código.

```gherkin
CA-01 Elegibilidade
  Dado uma oportunidade aberta (IsClosed = false) com dono ativo
  Quando o job diário de alerta roda
  Então a oportunidade é avaliada
  E uma oportunidade fechada (ganha ou perdida) nunca gera alerta

CA-02 Parada por falta de atividade e de mudança de estágio
  Dado uma oportunidade aberta cujo LastActivityDate é anterior a N dias
  E cujo LastStageChangeDate é anterior a N dias (N = prazo configurado, padrão 14)
  Quando o job roda
  Então o dono recebe uma notificação interna
  E a notificação mostra nome da oportunidade, nome da conta, estágio atual e dias sem atividade

CA-03 Oportunidade com atividade recente não alerta
  Dado uma oportunidade aberta com LastActivityDate dentro de N dias
  Quando o job roda
  Então nenhuma notificação é gerada para ela, mesmo que o LastStageChangeDate seja antigo

CA-04 Oportunidade sem atividade alguma
  Dado uma oportunidade aberta sem nenhuma atividade (LastActivityDate nulo)
  E criada há mais de N dias
  Quando o job roda
  Então ela é tratada como parada e o dono recebe a notificação
  E a data de criação é usada como referência quando não há atividade

CA-05 Sem repetição diária
  Dado uma oportunidade já notificada que continua parada
  Quando o job roda no dia seguinte
  Então nenhuma nova notificação é enviada para ela
  E uma nova notificação só volta a sair depois de nova atividade ou mudança de estágio seguida de novo período de N dias

CA-06 Leitura pura nos objetos de negócio
  Dado que o job executou em lote sobre oportunidades paradas
  Quando a execução termina
  Então nenhum registro de Opportunity, Account, Order ou OrderItem foi criado, alterado ou excluído pelo alerta
  E nenhuma Task ou Event foi criada pelo alerta
  (verificação: LastModifiedDate e contagens iguais antes e depois, em QA)

CA-07 Só canal interno
  Dado que o alerta foi disparado
  Quando a notificação chega ao usuário
  Então ela aparece somente no Salesforce, para o dono
  E nenhum e-mail, SMS, mensagem ou chamada ao Marketing Cloud é feito pelo alerta

CA-08 Gestor desligado por padrão
  Dado a configuração de escalonamento para gestor desligada
  Quando o job alerta uma oportunidade parada
  Então apenas o dono é notificado
  E, com a configuração ligada, o gestor direto do dono também é notificado

CA-09 Dono inativo
  Dado uma oportunidade parada cujo dono está inativo
  Quando o job roda
  Então nenhuma notificação é enviada a esse dono
  E a oportunidade é registrada no log da execução como "dono inativo", sem reatribuição

CA-10 Sem agente novo nem sobreposição
  Dado o design da solução
  Quando o arquiteto fecha o desenho
  Então o documento de design diz, item a item, o que reaproveita e o que cria
  E não cria agente, tópico ou ação no SFAgent2 ou qualquer outro agente
  E se a definição de "parada" diferir da de eplast-ent-09, a diferença está registrada e aprovada no gate de design

CA-11 Volume em lote
  Dado uma carga sintética em QA com N oportunidades abertas paradas (N definido no plano de teste)
  Quando o job roda
  Então termina sem erro de limite de governador
  E gera uma notificação por oportunidade elegível, sem duplicar

CA-12 Cobertura de teste (só se houver Apex)
  Dado uma classe Apex criada para o alerta
  Quando o pipeline de testes roda
  Então a classe tem cobertura de no mínimo 85% e classe de teste dedicada <Classe>Test
```

## 7. Premissas assumidas (validar na homologação)

Cada item é uma decisão tomada sem resposta do cliente, com a pergunta, a decisão, a evidência e como mudar. Todos entram como resolvidos. Nenhum é pendência.

- [x] **P1 — Escopo da Onda 3.** Pergunta: a demanda pode seguir sem a onda contratada? Decisão: sim, segue análise, design e build. Evidência: decisão do responsável pela conta (2026-11-13, card; regra 1 da conta). Como mudar: não se aplica; só volta se o responsável revogar a orientação.

- [x] **P2 — Definição de "parada" e "acompanhamento".** Pergunta: o que conta como parada e como acompanhamento? Decisão: **acompanhamento** = qualquer atividade registrada (`LastActivityDate`). **Parada** = sem atividade E sem mudança de estágio (`LastStageChangeDate`) há N dias. Evidência: (a) os dois campos padrão existem em Opportunity (`sf sobject describe`, confirmado em 2026-11-15). Quando não há atividade, usa-se a data de criação (CA-04). Como mudar: trocar a regra de parada por um parâmetro na metadata do alerta, sem reescrever o job. Se o cliente quiser só atividade manual, ver P3.

- [x] **P3 — Tasks automáticas contam como acompanhamento.** Pergunta: Tasks criadas por Flow (não pelo vendedor) devem contar? Decisão: contam, porque `LastActivityDate` não distingue a origem e não há campo de origem na Task. Evidência: recon (achado 2) mostra que `Oportunidade_Industria` cria até 5 Tasks automáticas e `OpportunityFlow` cria Task; a org não tem campo de origem. Efeito: uma oportunidade com Task automática recente pode não alertar mesmo sem contato real. Como mudar: exigir campo de origem na Task (novo campo custom, com `Description`) e filtrar; isso é um desenho próprio e entra no design se o cliente discordar. Teste em QA deve medir esse efeito (recon, risco 2), não supor.

- [x] **P4 — Prazo único e valor inicial de 14 dias.** Pergunta: qual o prazo e se é único ou por estágio? Decisão: prazo único N = 14 dias, em metadata configurável (Custom Metadata). Por estágio fica para evolução. Evidência: (b) não há prazo na org a reaproveitar (nenhum parâmetro de Opportunity encontrado no recon); 14 dias é o valor mais simples de explicar e de ajustar, sem constante no código. Como mudar: alterar o registro de metadata, sem deploy de código. Por estágio exigiria nova tabela de parâmetros.

- [x] **P5 — Canal e frequência.** Pergunta: e-mail, Chatter, Teams, Marketing Cloud? Decisão: notificação interna do Salesforce (Custom Notification Type), uma vez por episódio de parada, avaliada uma vez por dia. Evidência: (b) padrão da plataforma; regra 2 da conta impede e-mail de disparo dentro do CRM, e Marketing Cloud não é canal de alerta interno. Como mudar: o cliente pode pedir digest diário em vez de evento; a troca é de agendamento, não de arquitetura. Se pedir e-mail, o desenho vai ao Marketing Cloud, como passo de quem opera o Marketing Cloud.

- [x] **P6 — Destinatário e escalonamento.** Pergunta: só o dono? Gestor? Decisão: dono sempre. Gestor direto (hierarquia padrão, `ManagerId` do usuário) só se a configuração estiver ligada; começa desligada. Evidência: (b) padrão simples; não há regra de escalonamento na org para reaproveitar. Como mudar: ligar a configuração, sem deploy. Níveis acima do gestor direto ficam fora da v1.

- [x] **P7 — Ação além da notificação.** Pergunta: só avisa, ou cria Task de follow-up? Decisão: só avisa. Não cria Task nem altera registro. Evidência: (a) recon achado 3: criar Task dispara `TaskCreatedOrUpdated`, que atualiza a Account e aciona a cadeia de Account do assessment (achado 1); a Task nova também mudaria o próprio critério de parada. Como mudar: criar Task seria uma demanda separada, desenhada junto com a cadeia de Account.

- [x] **P8 — Oportunidades elegíveis.** Pergunta: excluir fechadas, com Quote do CPQ, ou tipos específicos? Decisão: exclui apenas fechadas (`IsClosed = true`). Não exclui por Quote do CPQ nem por Record Type; os 6 Record Types ficam dentro do escopo. Evidência: (a) `IsClosed` padrão; recon confirmou 11 estágios abertos e 2 fechados. Como mudar: filtro de Record Type em metadata se o cliente pedir.

- [x] **P9 — Conteúdo do alerta e LGPD.** Pergunta: quais campos aparecem? Decisão: nome da oportunidade, nome da conta, estágio, dias sem atividade, link para o registro. Sem e-mail, telefone ou dado de contato. Evidência: (b) notificação só para usuário interno da própria org, então o acesso segue o compartilhamento do Salesforce; não há canal externo. Como mudar: o cliente pode reduzir campos; o alerta não sai da org.

- [x] **P10 — Ação de escrita fora do alerta.** Pergunta: o alerta pode gravar algum campo de controle (ex.: "já alertado")? Decisão: não. A deduplicação (CA-05) sai da própria notificação e de uma consulta de atividade e mudança de estágio, sem campo novo em Opportunity. Evidência: (a) CA-06 e recon (achado 4 e a cadeia de Opportunity). Como mudar: se a deduplicação não for confiável em QA, a solução é um objeto de log próprio, não um campo em Opportunity; isso volta ao design.

- [x] **P11 — Sobreposição com eplast-ent-09.** Pergunta: o alerta complementa, substitui ou duplica o agente "Quais clientes precisam de acompanhamento hoje?" (Onda 2, construído fora da esteira)? Decisão: complementa. O alerta é proativo (job) e o agente é sob demanda (conversa). Não se cria agente novo (CA-10). A definição de parada deve ser a mesma do agente; quando a definição do agente for conferida, o design alinha. Evidência: (a) `contrato.md` lista o agente; o `force-app` local não tem o código dele. A org não foi lida para o tópico do agente nesta etapa: a regra 3 pede confirmação por `sf` no recon, e está marcada como verificação, não como pendência de negócio. Como mudar: se o recon mostrar que o agente já faz o alerta, a demanda vira ajuste no agente (regra 3 da conta).

- [x] **P12 — Sobreposição com EPLAST-26 (score).** Pergunta: o score de oportunidade entra como critério? Decisão: não, na v1. Evidência: fora do escopo desta demanda; o alerta usa só campos padrão de atividade e estágio. Como mudar: se o score virar critério, as duas demandas são desenhadas juntas, como alertava a rodada anterior.

- [x] **P13 — Volume.** Pergunta: quantas oportunidades abertas em produção e quantos alertas por dia? Decisão: não consultar produção. O job é desenhado em lote, e o teste de volume usa carga sintética em QA (CA-11). Evidência: regra de dado real (guardrail 2); a sandbox de dev tem 0 Opportunity. O número não muda a arquitetura, só o dimensionamento. Como mudar: o cliente informa o volume (só o número) pelo card; o design ajusta o lote.

**Estimativa de esforço:** 14–22 h
Premissas que mais pesam na faixa: (1) configuração declarativa do job agendado, notificação e metadata de parâmetros; (2) testes em QA com carga sintética e verificação de CA-06 (leitura pura); (3) revisão humana da regra de parada (P2 e P3) e homologação com o cliente. Sobe para o topo da faixa se o design pedir Apex em lote por volume, e cai para o piso se o job for só Flow agendado.

**Complexidade:** M. Um job agendado e uma notificação, sem escrita em objetos de negócio, mas com regra de parada que exige decisão humana e teste de efeito das Tasks automáticas.

## 8. Riscos do assessment que tocam o pedido

- **Achado 1 — automação concorrente em Opportunity (vermelho).** O assessment registra `OpportunityTrigger`, triggers `OpportunityBefore` e `OpportunityAfter` do SBQQ, e os Flows `OpportunityFlow` e `Oportunidade_Industria` no mesmo evento. O alerta **não grava em Opportunity** (CA-06), então não entra nessa cadeia. Risco residual: se o design mudar e precisar gravar, a ordem de execução precisa ser mapeada antes. Pelo assessment, nenhuma demanda nova em Opportunity deve ser aceita sem esse mapa.
- **Achado 2 — Tasks automáticas (recon, não o assessment).** Afeta a definição de "acompanhamento" (P3). Medido em QA, não suposto.
- **Achado 6 — dev e QA com identidade "qa" (possível mesma sandbox).** Confirmado em 2026-11-15 pelo `sf org list`: o usuário de `sbx-eplast-dev` termina em `eplast2.qa`, e o Org Id da dev (`00DHa000006vfMLMAY`) é diferente do Org Id da QA registrado em demanda anterior (`00DHa000006vZtmMAE`, EPLAST-31, histórico). Isso indica sandboxes distintas, mas não foi reconferido nesta sessão porque a QA não está conectada aqui. Ação antes da etapa de QA: `sf org display` nas duas e comparação de Org Id. Não bloqueia a análise.
- **Achado 4 — campos custom sem descrição.** Não se aplica: nenhum campo custom é criado (R11). Se o design criar um campo (ex.: P3), ele sai com `Description`.
- **Achado 10 — nome de trigger duplicado (`OrderTrigger`).** Não toca a demanda: o alerta não lê nem grava Order. Registrado porque a regra de não sobrepor vale para Order também.
- **Regras de validação de Opportunity (16 ativas, segundo o recon).** Não bloqueiam o alerta, que não grava. Bloqueiam a criação de Opportunity de teste em QA; o plano de teste precisa usar registros que passem nelas.

**Divergências encontradas hoje, que o recon de etapa 2 precisa resolver** (o recon de 2026-11-11 está vencido pela regra de 7 dias):
- Os flows `agentic_feed` (`Custom_Stale_Opp`, `Custom_Stale_Opp_Action`, `Custom_Rcmd_Cleanup`), que a rodada anterior registrou como agendados e com nome de "recomendações de oportunidade parada", **não aparecem na dev agora** (consulta de `FlowDefinition` com namespace `agentic_feed` retornou 0, e busca por nome também). Pode ser que estejam só na QA, ou que tenham sido removidos. Como estes flows fazem o que a demanda pede, é o achado mais importante a confirmar: se existirem, a demanda pode ser ajuste deles (regra 3 da conta), não nova automação. Confirmar na QA antes do design.
- `OpportunityTrigger` aparece com `IsValid = false` na Tooling API (API 59). O assessment e o recon tratavam esse trigger como ativo. Confirmar no recon se está inativo ou inválido, porque muda a cadeia de Opportunity do achado 1.
- `SFAgent2` existe na dev como `GenAiPlannerBundle` (versões 1 a 4, criadas em 2026-11-10), conforme a regra 3 da conta. Os tópicos e ações não foram lidos nesta etapa.

## 9. Objetos e automações de Account, Opportunity e Order potencialmente afetados (a confirmar no recon)

- **Opportunity (leitura):** `LastActivityDate`, `LastStageChangeDate`, `StageName`, `IsClosed`, `OwnerId`, `CreatedDate`. Campos padrão, confirmados por `sf sobject describe`.
- **Task (leitura):** existência de atividade. Dev com 0 registros; efeito real só medido em QA.
- **Automações em Opportunity no mesmo evento:** `OpportunityTrigger` (validade a confirmar), `OpportunityBefore` e `OpportunityAfter` (SBQQ), `OpportunityFlow`, `Oportunidade_Industria`, `ScheduledFlowOpportunity` (agendado, lê Opportunity e grava em Account). Nenhuma delas deve ser alterada pelo alerta; o recon confirma a lista e a ordem.
- **Automações de Task:** `TaskCreatedOrUpdated` (atualiza Account a cada Task). O alerta não cria Task, então não dispara esse flow (CA-06).
- **Flows `agentic_feed` de recomendação de oportunidade parada:** a confirmar (ver seção 8). Potencial sobreposição total.
- **Account e Order:** nenhum objeto é lido ou gravado pelo alerta na v1. Ficam citados porque o assessment alerta que a cadeia de Account é disparada por Task (ver P7).
- **Agente SFAgent2 e eplast-ent-09:** sobreposição de conceito a verificar (P11).

## 10. Pendências em aberto

Nenhuma. Todas as perguntas da rodada anterior foram resolvidas pela regra 4, com evidência, e estão como premissas assumidas (`- [x]`). As verificações de org (flows `agentic_feed`, validade do `OpportunityTrigger`, tópicos do SFAgent2) são etapas de recon, não perguntas de negócio, e estão na seção 8.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
