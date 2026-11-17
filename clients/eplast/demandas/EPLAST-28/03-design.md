# EPLAST-28 — Design: alertas de oportunidade parada ou sem acompanhamento

**Cliente:** Eplast · **Etapa:** 3 (desenho, arquiteto) · **Rodada:** refeita em 2026-11-15 pela regra 4 da conta
**Org confirmada (`sf org list`):** `sbx-eplast-dev` (Sandbox, Connected). Só leitura de metadata e contagens agregadas; nenhum deploy, DML ou anonymous Apex.
**Entradas:** `01-analise.md` (aprovada em 2026-11-15), `02-recon.md` (com complemento do arquiteto ao fim), `comentarios-do-card.md`, `assessment.md` (achados 1, 2, 4, 6, 9, 10), `rodada-anterior/03-design.md` (referência, não decisão), RAG (EPLAST-31, EPLAST-47).

**Bloqueio por pergunta de negócio (regra 4c):** nenhum. Todas as decisões sem resposta do cliente estão na seção 8 como premissas assumidas.
**Ponto para o arquiteto humano decidir no gate (não é bloqueio):** a solução cria um **Custom Metadata Type novo** (seção 4.1). É configuração, não objeto de negócio, e segue o precedente da EPLAST-47 (`ScheduledFlowOpportunitySetting__mdt`), mas é tipo novo na org e, pela regra do squad, mudança de modelo de dados é aceite humano. Nenhum campo é criado em Opportunity, Account, Order ou Task.

**Estimativa de esforço:** 16–24 h
O que mudou em relação à análise (14–22 h): sobe 2 h no piso e no teto porque (1) o design acrescenta a carga inicial configurável (P16) e o log de dono inativo em objeto existente (P15), e (2) o teste em QA exige dados sintéticos com datas no passado (campos de auditoria, seção 10), mais duas sessões de QA por ser automação agendada. Não há Apex: o teto não sobe pela descida de nível que a análise previa.

---

## 1. Decisão

**Flow agendado (Schedule-Triggered Flow) diário sobre Opportunity aberta, que envia Custom Notification ao dono (e ao gestor, se ligado), com parâmetros em Custom Metadata e log em `IntegrationLog__c`.** Não grava em Opportunity, Account, Order, OrderItem, Task ou Event.

Nível: **declarativo (2)**.

### 1.1 Por que não configuração pura (nível 1)
- **Relatório + assinatura de relatório** (ex.: partir de `Neglected Open Opportunities`, que existe na dev; filtros não lidos). A assinatura repete o envio a cada execução enquanto a oportunidade estiver parada (contraria CA-05), cada vendedor teria de assinar o próprio relatório, o filtro relativo não lê o prazo configurável (P4) e não há escalonamento ao gestor (CA-08) nem log de dono inativo (CA-09). Não atende.
- **Tópico do `SFAgent2`** ("Insights Comerciais e Acompanhamento", que "identifica oportunidades paradas"). É sob demanda: só responde quando o vendedor pergunta. O pedido é proativo. Não há configuração do agente que dispare aviso sozinho.
- **Flows `agentic_feed`** citados na rodada anterior: 0 na dev (recon). Não se reaproveita o que não foi confirmado.

### 1.2 Por que Flow e não Apex
A regra é um filtro (aberta), uma conta de datas, uma comparação com o parâmetro e uma notificação. O Flow agendado processa em lotes e agrupa ações e Get Records por lote. Nenhum critério da skill `salesforce-doutrina` para descer a Apex se aplica: sem rollback complexo, sem callout, sem recursão, sem leitura das Tasks filhas (P3 decidiu usar `LastActivityDate`), e o volume de produção não foi informado (P13). Apex só traria custo numa org com cobertura de 10% (achado 2). Por isso CA-12 **não se aplica** nesta demanda.

### 1.3 Quando desce para Apex (fica registrado, não é o caminho)
Desce para `Schedulable` + `Batchable` (cada classe com `<Classe>Test` e 85%) se: (a) o cliente pedir para ignorar Tasks automáticas (filtrar Tasks por origem, P3), (b) pedir resumo único por dono em vez de um aviso por oportunidade, ou (c) o volume de oportunidades abertas em produção passar de 150.000 (cerca de 60% do limite diário de interviews de Flow agendado, que é o maior entre 250.000 e 200 por licença; valor da documentação oficial, conferir no build). Qualquer um deles volta ao gate de design.

## 2. Como funciona

```
[Agendamento diário 07:00, horário da org]   (livre: 02:00, 06:00, 15:47 e 17:36 já ocupados — recon, complemento)
 Flow Opportunity_Scheduled_AlertaParada
  start: Opportunity, IsClosed = false
  Get Records: AlertaOportunidadeParadaSetting__mdt, DeveloperName = 'Default'
  Decisão Ativo__c = false        -> fim (chave geral)
  fórmulas:
    RefAtividade = BLANKVALUE(LastActivityDate, DATEVALUE(CreatedDate))
    RefEstagio   = DATEVALUE(BLANKVALUE(LastStageChangeDate, CreatedDate))
    Referencia   = conforme RegraParada__c:
                     AtividadeEEstagio -> a mais recente das duas (padrão)
                     SoAtividade       -> RefAtividade
                     SoEstagio         -> RefEstagio
    DiasParado   = TODAY() - Referencia
    Alertar      = DiasParado = DiasSemAcompanhamento__c
                   OU (TODAY() = DataCargaInicial__c E DiasParado >= DiasSemAcompanhamento__c)
  Decisão Alertar = false         -> fim
  Decisão $Record.Owner.IsActive = false
        -> Create IntegrationLog__c (ResponseStatus__c = 'DONO_INATIVO', RequestBody__c = Id da oportunidade) -> fim
  monta destinatários: OwnerId
        + Owner.ManagerId, se NotificarGestor__c = true, ManagerId preenchido, gestor ativo e diferente do dono
  Send Custom Notification (tipo Oportunidade_Parada, alvo = Id da oportunidade)
        fault -> Create IntegrationLog__c (ResponseStatus__c = 'FALHA_NOTIFICACAO', mensagem do fault)
  nenhum Update / Delete; nenhum Create fora de IntegrationLog__c
```

Texto da notificação (P9): título "Oportunidade parada há {DiasParado} dias"; corpo "{Nome da oportunidade} · {Nome da conta} · Estágio: {StageName} · sem atividade nem mudança de estágio desde {Referencia}". Sem valor, e-mail, telefone ou dado de contato.

### 2.1 Deduplicação sem estado (CA-05, P10)
O alerta sai **no dia em que `DiasParado` é igual ao prazo**, não "maior ou igual". No dia seguinte a condição já é falsa, sem gravar marcador na oportunidade. Nova atividade ou mudança de estágio move a `Referencia`, e o ciclo recomeça sozinho. Custo: um dia sem execução do job perde os alertas daquele dia (risco R4); a mitigação operacional é a `DataCargaInicial__c` (P16).

### 2.2 Carga inicial (P16)
Sem ela, oportunidades que já estão paradas além do prazo no dia do go-live nunca alertariam (só alertam ao cruzar exatamente N). `DataCargaInicial__c` faz uma varredura única: no dia configurado, alerta todas com `DiasParado >= N`. Vazia, não faz nada.

## 3. Item a item: o que reaproveita e o que cria (regra 3)

| Item da análise | Reaproveita | Cria | Por que o existente não atende |
|---|---|---|---|
| Detectar oportunidade parada (CA-01 a CA-04) | Campos padrão `LastActivityDate`, `LastStageChangeDate`, `CreatedDate`, `IsClosed`, `OwnerId` (confirmados por `FieldDefinition`) | Flow `Opportunity_Scheduled_AlertaParada` | Nenhuma automação existente avalia parada; `ScheduledFlowOpportunity` calcula ranking de conta (descrição do Flow, EPLAST-47). Relatório `Neglected Open Opportunities` não notifica (1.1). |
| Notificar o dono (CA-02, CA-07) | Mecanismo padrão de Custom Notification | `CustomNotificationType` `Oportunidade_Parada` | O único tipo existente é `Novo_Pedido`, de outro propósito; reaproveitá-lo misturaria avisos e preferências de notificação do usuário. |
| Prazo, regra, gestor e chave geral configuráveis (P2, P4, P6) | Padrão de CMDT de parâmetros por Flow com registro `Default`, já usado na EPLAST-47 (`ScheduledFlowOpportunitySetting__mdt`) | CMDT `AlertaOportunidadeParadaSetting__mdt` + registro `Default` | `ScheduledFlowOpportunitySetting__mdt` é do Flow de ranking; acoplar os dois faria um deploy de um mudar o outro. |
| Log de dono inativo (CA-09) e falha de envio | `IntegrationLog__c` e o padrão da EPLAST-47 (`ScheduledFlowOpportunity` grava falhas nele, com `IntegrationAction__c` = nome do Flow) | Nada | Atende como está. 0 triggers e 0 Flows de gravação nele (complemento do recon). |
| Escalonar ao gestor (CA-08) | `User.ManagerId` (hierarquia padrão) | Nada além do parâmetro `NotificarGestor__c` | — |
| Assistente / linguagem natural (CA-10) | `SFAgent2`, tópico "Insights Comerciais e Acompanhamento" | **Nada** | Não se cria agente, tópico nem ação. O alerta complementa o tópico (P11). |
| Score (EPLAST-26) | — | Nada | Fora do escopo (P12). |

## 4. Componentes

### 4.1 Criar
Nomes pela skill `padrao-entrega` (o `CLAUDE.md` da Eplast não define convenção nem prefixo de campo). Todo componente sai com `Description` citando EPLAST-28 (achado 4). API 68.0 (versão da org, recon), não a v59 dos Flows antigos (achado 9).

| Tipo | API name | Descrição / conteúdo |
|---|---|---|
| Flow (Schedule-Triggered, diário 07:00) | `Opportunity_Scheduled_AlertaParada` | Alerta diário ao dono quando uma oportunidade aberta completa N dias sem atividade nem mudança de estágio. Não grava em objetos de negócio; só registra em IntegrationLog__c dono inativo e falha de envio. Parâmetros em AlertaOportunidadeParadaSetting__mdt. EPLAST-28 |
| CustomNotificationType | `Oportunidade_Parada` | Aviso interno (desktop e mobile) de oportunidade aberta parada além do prazo. EPLAST-28 |
| Custom Metadata Type | `AlertaOportunidadeParadaSetting__mdt` | Parâmetros do Flow Opportunity_Scheduled_AlertaParada. Registro Default. EPLAST-28 |
| Campo CMDT | `Ativo__c` (Checkbox, padrão true) | Chave geral: desligado, o Flow não avalia nada |
| Campo CMDT | `DiasSemAcompanhamento__c` (Number 3,0; valor 14) | Prazo N em dias (P4) |
| Campo CMDT | `RegraParada__c` (Picklist restrita: `AtividadeEEstagio`, `SoAtividade`, `SoEstagio`; valor `AtividadeEEstagio`) | Qual data define a parada (P2) |
| Campo CMDT | `NotificarGestor__c` (Checkbox, false) | Inclui o gestor direto (P6) |
| Campo CMDT | `DataCargaInicial__c` (Date, vazio) | Dia da varredura única de oportunidades já paradas (P16) |
| Registro CMDT | `AlertaOportunidadeParadaSetting.Default` | Valores acima |

`IntegrationLog__c` gravado pelo Flow: `IntegrationAction__c` = `Opportunity_Scheduled_AlertaParada`; `ResponseStatus__c` = `DONO_INATIVO` ou `FALHA_NOTIFICACAO`; `ExecutionDate__c` = agora; `RequestBody__c` = Id da oportunidade (e, na falha, a mensagem do fault). Nunca nome, e-mail ou valor.

### 4.2 Alterar / depreciar
**Nenhum.** Não se altera `OpportunityTrigger`, `OpportunityTriggerHandler`, `OpportunityTriggerHelper`, `OpportunityFlow`, `Oportunidade_Industria`, `ScheduledFlowOpportunity`, `TaskCreatedOrUpdated`, `IntegrationLog__c`, o relatório `Neglected Open Opportunities` nem o `SFAgent2`. Não se liga `TriggerUtility__mdt` (bypass global).

### 4.3 Layouts
Nenhum. Notificação aparece no sino e no app móvel.

## 5. Ordem de execução, governador e escala

### 5.1 Conflito de automação (achado 1)
**Opportunity tem hoje `OpportunityTrigger` (custom, Active, IsValid=false), `OpportunityBefore` e `OpportunityAfter` (SBQQ, este IsValid=false) e os Flows after-save `OpportunityFlow` e `Oportunidade_Industria` no mesmo evento, além do agendado `ScheduledFlowOpportunity`. A ordem entre eles não está mapeada (recon).**

Como a solução lida: **não entra nessa ordem**. Não é disparada por gravação de Opportunity e não grava em Opportunity, Account, Order ou Task; portanto não aciona trigger, Flow record-triggered nem validation rule desses objetos. O mapa completo da ordem de execução de Opportunity não é pré-requisito desta demanda e continua pendente para quem gravar nela. O único DML é em `IntegrationLog__c`, que não tem trigger nem Flow de gravação (confirmado). O que quebraria essa garantia, e por isso está fora: criar Task, gravar marcador na oportunidade ou trocar o agendamento por gatilho de gravação.

**Onde a cadeia aparece: na carga de teste.** Criar Opportunity e Task sintéticas em QA passa por toda a cadeia (16 validation rules, triggers, `OpportunityFlow` que grava em Order/Quote/Account/Task, `TaskCreatedOrUpdated` que atualiza Account). Mesmo tratamento da EPLAST-31 (RAG, `demandas/EPLAST-31/03-design.md`): mínimo de registros, sem bypass global, e o QA confirma para onde aponta a integração Protheus antes de criar Order indireta. `IsValid=false` em `OpportunityTrigger`/`OpportunityAfter` pode fazer a criação falhar com erro de compilação; se falhar, é achado de ambiente para o humano, não defeito do alerta.

Convivência com outros agendados: 07:00 não coincide com nenhum dos 4 Flows agendados (recon, complemento). Transações separadas; o alerta não disputa lock porque não grava nos mesmos registros.

### 5.2 Governador
- **Muitos registros:** uma interview por oportunidade aberta por dia. Get Records do CMDT é agrupado por lote e consulta de CMDT não consome o limite de SOQL. Envio de notificação e Create do log são agrupados por lote de interviews. Teto: limite diário de interviews de Flow agendado (1.3).
- **Um pai com muitos filhos (SOMOSAGILITY-10):** não se aplica como cascata. O Flow não grava em pai nem em filho; o custo por oportunidade é constante, não importa quantas Tasks ela tenha (lê o campo agregado `LastActivityDate`, não as Tasks). Um dono com muitas oportunidades recebe muitos avisos, mas cada um é ação de lote, não transação extra.
- **Notificações:** a plataforma limita notificações personalizadas por hora na org. O valor não foi conferido nesta sessão (não respondo de memória); o build confere na documentação oficial e registra no `04-plano-build.md`. O ponto crítico é o dia da carga inicial (P16).
- Critério de volta ao design: medição em QA acima de 70% de qualquer limite no volume de teste (skill `salesforce-doutrina`).

### 5.3 Contexto de execução
Flow agendado roda em contexto de sistema. Lê `$Record.Owner.IsActive`, `$Record.Owner.ManagerId` e `$Record.Owner.Manager.IsActive` (Opportunity.OwnerId é só User). `TODAY()` segue o fuso da org.

## 6. Permissões
- **Nenhum permission set ou perfil novo ou alterado.** O destinatário não precisa de permissão para receber Custom Notification enviada por Flow; o build confirma isso em dev e, se a plataforma exigir, volta ao gate com um `PS_Comercial_AlertaParada` (não criado de antemão).
- Ao abrir a notificação, vale o compartilhamento: o dono enxerga a própria oportunidade. O gestor só abre se o compartilhamento lhe der acesso (hierarquia de papéis não é a mesma coisa que `ManagerId`); ver R5.
- Manutenção do CMDT: só administrador (Customize Application). Achados 7 e 8 (perfis) não são tocados.

## 7. Preparação do Sales Cloud para o Marketing Cloud
**Não se aplica.** O alerta é aviso interno a usuário do Salesforce sobre a carteira dele; não é comunicação com cliente, lead, campanha, público ou nutrição. Não se lê nem se grava nada do `et4ae5`, não há envio de e-mail, SMS ou mensagem (CA-07), e nada é feito no Marketing Cloud. Se o cliente pedir aviso por e-mail, a análise de canal volta ao design e segue a regra 2 da conta.

## 8. Premissas assumidas (validar na homologação)

Herdadas da análise (P1 a P13), conferidas neste design (a aprovação da análise foi em lote, comentário de 2026-11-15):

- [x] **P1 — Escopo da Onda 3.** Mantida (regra 1 da conta).
- [x] **P2 — Definição de parada.** Mantida: sem atividade (`LastActivityDate`) E sem mudança de estágio (`LastStageChangeDate`) há N dias; usa a mais recente das duas. Como mudar: `RegraParada__c` no CMDT, sem deploy.
- [x] **P3 — Tasks automáticas contam.** Mantida. Evidência: `LastActivityDate` não distingue origem. Efeito medido em QA (seção 10). Como mudar: descida para Apex (1.3a), volta ao design.
- [x] **P4 — Prazo único de 14 dias.** Mantida, em `DiasSemAcompanhamento__c`. Por estágio fica para evolução (exigiria registros por estágio no CMDT).
- [x] **P5 — Canal e frequência.** Mantida: Custom Notification, avaliação diária, um aviso por episódio.
- [x] **P6 — Gestor desligado por padrão.** Mantida, em `NotificarGestor__c`. Evidência nova: 0 usuários ativos com `ManagerId` na dev; ligar só faz efeito depois de preencher o gestor.
- [x] **P7 — Só avisa, não cria Task.** Mantida (evita `TaskCreatedOrUpdated` e a cadeia de Account).
- [x] **P8 — Elegíveis: todas as abertas.** Mantida (`IsClosed = false`, todos os record types).
- [x] **P9 — Conteúdo do aviso.** Mantida: nome da oportunidade, nome da conta, estágio, dias, link.
- [x] **P10 — Sem campo de controle em Opportunity.** Mantida (dedup pela igualdade, 2.1).
- [x] **P11 — Complementa o SFAgent2.** Mantida e reforçada: o tópico "Insights Comerciais e Acompanhamento" identifica oportunidades paradas sob demanda, mas a instrução lida não define prazo nem critério (complemento do recon). Decisão: a definição deste alerta (P2/P4) passa a ser a referência; alinhar o tópico a ela é ajuste de instrução do `SFAgent2` em demanda própria, se o cliente quiser. Como mudar: o cliente informa a regra do agente e o CMDT é ajustado.
- [x] **P12 — Score fora.** Mantida.
- [x] **P13 — Volume não consultado em produção.** Mantida; limiar de descida a Apex em 1.3c.

Novas, do design:

- [x] **P14 — Horário do job: 07:00 (horário da org), diário.** Pergunta: quando o aviso deve chegar? Decisão: antes do expediente, fora dos horários já ocupados. Evidência: (a) `CronTrigger` mostra 02:00, 06:00, 15:47 e 17:36 ocupados. Como mudar: reagendar o Flow (Setup), sem deploy de lógica.
- [x] **P15 — "Log da execução" (CA-09) = registro em `IntegrationLog__c`.** Pergunta: onde fica o registro de dono inativo? Decisão: um `IntegrationLog__c` por oportunidade, com `ResponseStatus__c = DONO_INATIVO` e o Id. Evidência: (a) a org já usa esse objeto como log de automação agendada (`ScheduledFlowOpportunity`, EPLAST-47). `Logs_Delete_Records` apaga registros com mais de 30 dias; **não confirmei que o objeto dele é `IntegrationLog__c`** — se for, o log dura 30 dias. Como mudar: trocar o status ou o destino no Flow.
- [x] **P16 — Carga inicial configurável.** Pergunta: oportunidades já paradas no go-live alertam? Decisão: sim, uma vez, no dia de `DataCargaInicial__c`; começa vazia e quem libera o go-live preenche. Evidência: (b) padrão mais simples sem gravar estado. Como mudar: deixar vazia (sem varredura).
- [x] **P17 — Dono inativo não redireciona.** Pergunta: avisar outra pessoa? Decisão: não; só registra (CA-09). Evidência: (b) análise e padrão. Como mudar: ligar `NotificarGestor__c` não muda isso; redirecionar seria evolução.
- [x] **P18 — Gestor recebe só se ativo e diferente do dono.** Evidência: (b) evita aviso duplicado e envio a usuário inativo. Como mudar: no Flow.

Nenhum item `- [ ]`: não há caso 4(c).

## 9. Riscos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Ordem de execução de Opportunity não mapeada e triggers com IsValid=false (achado 1).** | Alta para a org, baixa para esta solução | A solução não grava nesses objetos (5.1). Afeta só a carga de teste; erro de compilação ali é achado de ambiente. |
| R2 | **Dev e QA podem ser a mesma sandbox (achado 6):** instância do alias de dev se chama `eplast--qa`. | Média | Antes da sessão de QA, comparar Org Id das duas (`sf org display`). Se forem a mesma, o humano decide antes do deploy de QA; o Flow agendado ativo em dev já estaria rodando "em QA". |
| R3 | Tasks automáticas (`Oportunidade_Industria`, `OpportunityFlow`) mascaram parada (P3). | Média | Medido em QA: oportunidade criada por esses Flows recebe Task e pode não alertar. Resultado vai ao cliente na homologação. |
| R4 | Dia sem execução perde alertas (dedup sem estado). | Média | Log de falha em `IntegrationLog__c`; reexecução manual via `DataCargaInicial__c` (realerta todas as paradas, aceito). |
| R5 | Gestor sem acesso ao registro ao abrir o aviso. | Baixa | Desligado por padrão; testar com `NotificarGestor__c` ligado em QA. |
| R6 | Volume de avisos no dia da carga inicial (limite horário de notificações). | Média | Build confere o limite oficial; QA mede com carga sintética. |
| R7 | Teste exige datas no passado (`CreatedDate`, `LastStageChangeDate`). | Média | Seção 10. |
| R8 | Cobertura Apex de 10% (achado 2). | Não se aplica | Sem Apex nesta demanda; não piora nem melhora. |
| R9 | Campos sem descrição (achado 4), API antiga (achado 9), `OrderTrigger` duplicado (achado 10). | Não se aplica | Todo componente novo sai com descrição e API 68.0; Order não é tocado. |

## 10. Plano de build (alto nível) e critérios que o QA exercita

**Build (`builder-declarativo`, branch `feature/EPLAST-28`, só `sbx-eplast-dev`):**
1. CMDT `AlertaOportunidadeParadaSetting__mdt` com 5 campos e registro `Default`.
2. `CustomNotificationType` `Oportunidade_Parada` (desktop e mobile).
3. Flow `Opportunity_Scheduled_AlertaParada` conforme seção 2, com fault path, ativo, diário 07:00.
4. Revisão estática no PR: o XML do Flow não tem `recordUpdates` nem `recordDeletes`, e `recordCreates` só em `IntegrationLog__c`.
5. Conferir na documentação oficial o limite horário de notificações e o limite diário de interviews; registrar no plano.
6. `04-verificacao.md`: debug do Flow em dev com registro sintético (se a dev aceitar a criação), ou declarar inconclusivo o que não conseguiu exercitar.

**Dados de teste (nota para build e QA):** a dev tem 0 Opportunity e 0 Task. A carga sintética precisa passar nas 16 validation rules de Opportunity (conta com endereço, CNAE, razão social, e-mail, telefone, loja, vendedor Protheus no dono; filial, forma e condição de pagamento; catálogo de preço), todos valores fictícios. Para datas no passado: `CreatedDate` exige "Definir campos de auditoria na criação do registro" habilitado em QA; `LastActivityDate` vem de Task concluída com data passada. O QA confirma se `LastStageChangeDate` nasce vazio na criação; se nascer preenchido, usa `RegraParada__c = SoAtividade` e `N` ajustado para exercitar cada ramo. Os registros sintéticos são apagados pelo QA ao fim.

**Automação agendada:** duas sessões de QA (arma e confere depois das 07:00), conforme fluxo canônico.

**Casos que o QA deve exercitar:**
- CA-01: fechada (ganha e perdida) não alerta; aberta é avaliada.
- CA-02: parada exatamente em N alerta o dono, com o texto da seção 2.
- CA-03: atividade recente e estágio antigo não alerta (regra `AtividadeEEstagio`).
- CA-04: sem atividade, criada há N dias, alerta.
- CA-05: segunda execução não repete; nova Task reinicia a contagem.
- CA-06 (**fragilidade do achado 1**): contagens e `LastModifiedDate` de Opportunity, Account, Order, OrderItem, Task e Event iguais antes e depois da execução; só `IntegrationLog__c` cresce.
- CA-07: nenhum e-mail enviado (log de e-mail da org) nem chamada ao Marketing Cloud.
- CA-08: com `NotificarGestor__c` ligado e `ManagerId` preenchido num usuário de teste, gestor recebe; desligado, não.
- CA-09: dono inativo não recebe; `IntegrationLog__c` com `DONO_INATIVO`; dono não muda.
- CA-10: nenhum agente, tópico ou ação novo (comparar `GenAiPluginDefinition` e `GenAiFunctionDefinition` antes e depois).
- CA-11: carga com várias oportunidades e donos diferentes; sem erro de limite, um aviso por elegível; medir percentual dos limites.
- Extra: `DataCargaInicial__c` = hoje alerta as paradas além de N uma vez; `Ativo__c = false` não alerta nada; efeito das Tasks automáticas (R3) registrado.
- CA-12: não se aplica (sem Apex).

## 11. O que NÃO será feito nesta demanda
- E-mail, SMS, WhatsApp, Chatter ou qualquer coisa no Marketing Cloud.
- Criar Task, reatribuir dono ou gravar em Opportunity, Account, Order, OrderItem, Task ou Event.
- Agente, tópico ou ação novos; ajuste de instrução do `SFAgent2` (P11).
- Prazo por estágio ou record type; filtro de Tasks por origem; resumo diário por dono.
- Mapeamento da ordem de execução de Opportunity e correção de `OpportunityTrigger`/`OpportunityAfter` com IsValid=false.
- Alterar o relatório `Neglected Open Opportunities` ou criar relatório/painel novo.
- Score de oportunidade (EPLAST-26).

## 12. Para o arquiteto humano conferir no gate
1. Aceitar o CMDT novo `AlertaOportunidadeParadaSetting__mdt` (mudança de modelo de dados de configuração, precedente EPLAST-47).
2. Aceitar o uso de `IntegrationLog__c` como log desta automação (P15).
3. Conferir as premissas P2, P3 e P16, as que mais mudam o que o vendedor recebe.
4. R2 (dev e QA possivelmente a mesma sandbox) resolvido antes da sessão de QA.

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

## Respostas do cliente (2026-11-17) — valem acima das premissas assumidas deste desenho

A Eplast respondeu por escrito ("Respostas Konecta/Eplast", recebido em 17/11) aos pontos que
este desenho tinha resolvido como premissa assumida. Registrado por Leonardo Barbosa, que
mandou redesenhar com as respostas. **Onde a resposta abaixo diverge de uma premissa deste
arquivo, vale a resposta.** O que o cliente marcou como "a validar" continua premissa, a
repetir no roteiro em "O que assumimos e você precisa confirmar". Os parâmetros ficam
configuráveis (pedido do cliente), sem deploy para ajustar. Reaproveite o que já foi
construído e passou no QA; mude só o que a resposta pede. Os artefatos de build e QA da
rodada anterior estão em `rodada-anterior/premissas-assumidas/` para consulta.

**Resposta do cliente (EPLAST-28 — alertas de oportunidade parada):**
- Definição: oportunidade aberta sem atividade comercial relevante registrada. Alterações
  administrativas e notificações automáticas **não reiniciam** o prazo. Sem atividade
  anterior, contar a partir da criação.
- Prazo: 7 dias corridos, único para todos os estágios, configurável.
- Destinatários: proprietário aos 7 dias; gestor a partir de 14 dias. A hierarquia ainda
  não está cadastrada: é preciso cadastrá-la ou definir alternativa de encaminhamento antes
  de ativar o alerta ao gestor.
- Ação: só notificar, sem criar tarefa. Sem repetição diária para a mesma ocorrência.
- Texto: apenas nome da oportunidade, dias sem atividade e link. Sem valor.
- Canal: notificação no Salesforce (sino e aplicativo). Sem e-mail nesta etapa.
- Quantidade de oportunidades abertas: a validar por levantamento em produção (fora da esteira).

**O que muda neste desenho:**
1. Prazo padrão de 14 para **7** dias (`DiasSemAcompanhamento__c`).
2. Regra de "parada": a mudança de estágio (`LastStageChangeDate`) **deixa de reiniciar** a
   contagem; vale a última atividade e, sem atividade, a data de criação.
3. Gestor: limiar próprio de **14 dias**, configurável, **desligado** até a hierarquia
   existir (hoje 0 usuários com gestor). Não inventar encaminhamento alternativo.
4. Texto do aviso: tirar nome da conta e estágio; ficam nome da oportunidade, dias e link.
5. "Notificações automáticas não reiniciam": a premissa P3 dizia que `LastActivityDate` não
   distingue tarefa automática. Diga o que é possível declarativamente (por exemplo, a data
   da última tarefa ou compromisso que não seja das automações conhecidas da org) e o que
   exigiria código. Se só código resolver, **não construa código**: deixe como limitação
   declarada, a validar na homologação.
