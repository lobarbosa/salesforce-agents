**Status do design:** pronto para gate

# EPLAST-34 — Design: resumos para reuniões comercial, GDD, S&OP e Board

**Org consultada:** `sbx-eplast-dev` (Sandbox, conectada; única org listada em `sf org list`). Só leitura: metadata e contagens agregadas. Nada foi alterado na org e nada foi feito no Marketing Cloud.
**Base:** `01-analise.md` (aprovada em 2026-11-15, aprovação em lote; as premissas da análise devem ser conferidas neste gate, conforme `comentarios-do-card.md`), `02-recon.md`, skills `salesforce-doutrina` e `padrao-entrega`, `assessment.md` (só os achados que tocam a demanda). A rodada anterior (`rodada-anterior/03-design.md`) foi usada só como checklist: ela parava em perguntas que a regra 4 da conta agora resolve como premissa.

## 0. Confirmações feitas nesta etapa (complementam o recon)

| Ponto | Resultado | Comando (resumo) |
|---|---|---|
| Qual `OrderTrigger` é do CPQ | `OrderTrigger` com `NamespacePrefix = SBQQ` e outro com namespace nulo (custom). Mesmo padrão em Account (`AccountBefore` = SBQQ, `AccountTrigger` = custom) e Opportunity (`OpportunityBefore` e `OpportunityAfter` = SBQQ, `OpportunityTrigger` = custom). Todos Active | `ApexTrigger` (tooling) com `NamespacePrefix` |
| Campos padrão usados | Opportunity: `AccountId`, `StageName`, `Amount`, `CloseDate`, `IsClosed`, `IsWon`, `OwnerId`, `CurrencyIsoCode`. Order: `AccountId`, `OwnerId`, `EffectiveDate`, `Status`, `TotalAmount`, `CurrencyIsoCode`. Todos existem (fecha a incerteza 6 do recon) | `FieldDefinition` (tooling) |
| Moeda | Multimoeda ligada, mas 1 só moeda ativa: `BRL`, corporativa. 0 `DatedConversionRate` | `CurrencyType`; `COUNT() FROM DatedConversionRate` |
| Campo de equipe, regional, canal, meta, carteira ou segmento | **Nenhum** campo com esses rótulos em Opportunity, Order, Account ou User (fecha a incerteza 7 do recon) | `FieldDefinition` por `Label LIKE` |
| Papéis | 2 `UserRole` na org | `COUNT() FROM UserRole` |
| Conta pessoal | Não habilitada (`Account.IsPersonAccount` não existe) | `FieldDefinition` |
| `SFAgent2` | `BotDefinition` tipo `InternalCopilot`, `AgentType = AgentforceEmployeeAgent`. **As 4 `BotVersion` estão `Inactive` na dev** | `BotDefinition`; `BotVersion` |
| Ações do `SFAgent2` | 14 `GenAiFunctionDefinition` sem namespace, **todas `standardInvocableAction`** (`queryRecordsWithAggregate`, `queryRecords`, `identifyRecordByName`). Nenhuma ação custom, nenhuma sobre agregação fixa por recorte | `GenAiFunctionDefinition` (tooling) |
| PromptFlows de Opportunity | `Opportunity_PromptFlow_DadosOportunidade` e `Opportunity_PromptFlow_CotacaoPrimaria`: `ProcessType = PromptFlow`, versão 1, Active. São grounding de um registro, não agregação | `Flow` (tooling) |
| `CustomerSummaryService` | Existe, Active, com `CustomerSummaryServiceTest`. É o contrato do resumo **por cliente** (EPLAST-23 / `eplast-ent-10`) e, pelo cabeçalho da própria classe, falha de modo explícito enquanto as decisões daquela demanda estão pendentes | `ApexClass` (nome e linhas de comentário) |
| `PS_Comercial_ResumoClienteAgente` | Existe, concede acesso só a `CustomerSummaryService`, 0 atribuições | `SetupEntityAccess`; `PermissionSetAssignment` |
| Licenças | `Salesforce` 14 de 14 usadas. `Agentforce Coworker` 0 de 100.000 usadas | `UserLicense`; `PermissionSetLicense` |
| API do projeto | `sourceApiVersion` 67.0 (org em 68.0) | `sfdx-project.json` |

## 1. Decisão

**Código (Apex invocável) exposto como ação nova do `SFAgent2`, dentro do tópico existente `insights_comerciais`.** Nenhum agente novo, nenhum tópico novo, nenhum Flow novo, nenhuma gravação em registro, nenhum envio.

- Uma classe `MeetingSummaryService` com um `@InvocableMethod` que recebe o tipo de reunião (`COMERCIAL`, `GDD`, `SOP`, `BOARD`) e, opcionalmente, data inicial e final. Calcula os números por SOQL agregado (`COUNT`, `SUM ... GROUP BY`) em `WITH USER_MODE`, numa classe `with sharing`, e devolve um texto pronto em pt-BR, com seções fixas por tipo, data e hora de corte, e o objeto e campo de origem de cada número.
- Uma ação de agente (`GenAiFunction`) `ResumoReuniao`, que aponta para o invocável, ligada ao tópico `insights_comerciais` da versão mais recente do planner (`SFAgent2_v4`). As instruções do tópico ganham a regra: para pedido de resumo de reunião, chamar `ResumoReuniao` e mostrar o resultado como veio, sem recalcular nem reescrever números.

### Por que não o nível acima

| Nível | Por que não atende |
|---|---|
| **Configuração** (relatório, painel, assinatura) | Não entrega o resumo pelo `SFAgent2` (regra 3 da conta, CA-09), não monta texto com data de corte e origem por número (CA-03) e não restringe um pedido a "exatamente as seções do tipo" (CA-04). Relatório também foi caro de construir por metadata nesta conta (achado EPLAST-39, skill `salesforce-doutrina`). |
| **Configuração do agente** (só instruir o tópico a usar a ação padrão `AgregacaoPedidos` / `queryRecordsWithAggregate`) | A ação padrão monta a consulta a partir da frase do usuário: filtro, agrupamento e campo ficam a cargo do modelo. Isso viola PA-03 (o modelo não decide número) e não garante CA-03 nem CA-04. A ação padrão continua no tópico para perguntas livres; ela só não serve de motor do resumo. |
| **Declarativo** (Flow autolaunched como ação, ou prompt template com grounding por Flow) | Flow não tem `GROUP BY` nem agregação no banco: o total por etapa, por dono, por conta e por status exigiria trazer cada registro e somar em laço. O custo de CPU e heap cresce com o número de registros, não com o número de grupos, e o volume de produção é desconhecido (dev tem 0). A doutrina manda descer para Apex nesse caso ("volume alto com risco de limite" e "necessidade de teste unitário determinístico sobre a regra"). Prompt template ainda faria o modelo reescrever os números, contra PA-03. Os dois PromptFlows existentes são de um registro e não servem de base. |

Precedente na conta: o mesmo desenho (agente de funcionário + classe invocável `with sharing`, `WITH USER_MODE`, status por seção OK/VAZIO/SEM_ACESSO) está no contrato de `CustomerSummaryService` (cabeçalho da classe, confirmado na org). Este design repete o padrão, sem herdar a classe nem o bloqueio dela.

## 2. Reaproveita × cria (regra 3)

| Item | Decisão | Por quê |
|---|---|---|
| Bot `SFAgent2` | **Reaproveita** | Regra 3. Nenhum bot ou planner de outro nome (CA-09) |
| Planner `SFAgent2_v4` e tópico `insights_comerciais` | **Altera**: liga a ação nova e acrescenta instruções de resumo de reunião | É o tópico de negócio "Insights Comerciais"; os demais são padrão (`agent_router`, `GeneralFAQ`, `off_topic`, `ambiguous_question`). Versões v1 a v3 não são tocadas |
| Ações `AgregacaoPedidos`, `ConsultarPedidos`, `IdentificarConta`, `QueryRecords_*` | **Reaproveita sem alterar** | Seguem atendendo pergunta livre. Teste de regressão de roteamento (seção 8) |
| `CustomerSummaryService`, `CustomerSummaryServiceTest`, `PS_Comercial_ResumoClienteAgente` | **Não toca** | Resumo por cliente (`eplast-ent-10`, PA-02). Estender a classe herdaria o bloqueio da EPLAST-23 e misturaria contratos |
| `Opportunity_PromptFlow_DadosOportunidade`, `Opportunity_PromptFlow_CotacaoPrimaria` | **Não toca** | Grounding de um registro, não agregação |
| Relatórios (380) e painéis (20) | **Não cria nem altera** | Nenhum cobre o pedido (recon). CA-02 é conferido contra a base sintética (PD-08) |
| Classe `MeetingSummaryService` | **Cria** | Motor de agregação dos 4 recortes |
| Classe `MeetingSummaryServiceTest` | **Cria** | Cobertura mínima de 85% (CA-10, achado 2) |
| `GenAiFunction` `ResumoReuniao` | **Cria** | Ação nova no tópico existente |
| Permission set `PS_Comercial_ResumoReuniao` | **Cria** | Acesso de classe Apex à `MeetingSummaryService`. Não reusa `PS_Comercial_ResumoClienteAgente`, que é de outro contrato (PD-11) |
| Campos, objetos, Custom Metadata, Flows, triggers, layouts | **Nenhum** | Sem mudança de modelo de dados; nada a escalar como decisão sênior |

Nomes seguem a skill `padrao-entrega` (`<Dominio><Papel>`, `PS_<Area>_<Funcao>`) e o padrão em inglês já usado na org (`CustomerSummaryService`). O `CLAUDE.md` da conta não define convenção própria.

## 3. Conteúdo de cada recorte (contrato do invocável)

Entrada: `tipo` (obrigatório), `dataInicio` e `dataFim` (opcionais; sem eles, mês corrente, PA-06). Saída: `status` geral (`OK`, `PARCIAL`, `SEM_ACESSO`, `ERRO`), `textoResumo` e `dataHoraCorte`. Cada seção leva status próprio: `OK`, `VAZIO`, `SEM_ACESSO` ou `VOLUME_EXCEDIDO`.

| Tipo | Seções (exatamente estas, CA-04) | Consultas agregadas |
|---|---|---|
| Comercial | (1) Oportunidades abertas com fechamento no período, por etapa; (2) mesmas, por vendedor | `Opportunity WHERE IsClosed = false AND CloseDate` no período: `COUNT(Id)`, `SUM(Amount)` `GROUP BY StageName`; idem `GROUP BY OwnerId, Owner.Name` |
| GDD | (1) Oportunidades abertas por conta; (2) pedidos no período por conta. As 20 maiores contas por valor, mais a linha "demais contas" | `Opportunity ... GROUP BY AccountId, Account.Name ORDER BY SUM(Amount) DESC LIMIT 20` mais total; `Order WHERE EffectiveDate` no período, idem |
| S&OP | (1) Pedidos no período por status; (2) total do período | `Order WHERE EffectiveDate` no período: `COUNT(Id)`, `SUM(TotalAmount)` `GROUP BY Status`; total |
| Board | (1) Pipeline aberto por vendedor; (2) pedidos no período por vendedor; (3) total geral. Sem nome de conta | `Opportunity` aberta `GROUP BY OwnerId, Owner.Name`; `Order` `GROUP BY OwnerId, Owner.Name` |

- Cada número sai com origem (`Opportunity.Amount`, `Order.TotalAmount`, `Opportunity.StageName` etc.) e o rodapé traz "Dados até dd/mm/aaaa hh:mm" (CA-03).
- Valores em `BRL`, formato pt-BR (CA-02, PD-03).
- Nenhum campo de Contact, Lead, e-mail, telefone ou documento é consultado (CA-07, PA-09). Conta pessoal não está habilitada, então `Account.Name` é nome de empresa.
- Board exige leitura de Opportunity **e** Order; se faltar uma, a seção correspondente sai `SEM_ACESSO` e o status geral é `PARCIAL`, com a mensagem visível (CA-01, CA-08).
- Antes de cada seção, um `COUNT()` verifica o volume. Acima do teto (PD-06), a seção sai `VOLUME_EXCEDIDO` com mensagem para reduzir o período, em vez de estourar o limite de linhas, que não é capturável.
- Período informado maior que o teto (PD-10) é recusado com mensagem, sem consulta.
- Qualquer exceção capturada vira `status = ERRO` e texto de erro, sem resumo parcial apresentado como completo (CA-08). A classe não faz DML, callout, `@future`, Queueable nem envio de e-mail (CA-05, CA-06, CA-10).

## 4. Ordem de execução dos objetos tocados

A solução **só lê** Account, Opportunity e Order. SOQL não dispara trigger, validation rule nem Flow record-triggered. Ela não entra em nenhum ponto da ordem de execução da plataforma (validação de sistema → before-save Flows → before triggers → validation rules → gravação → after triggers → after-save Flows → commit).

Mapa atual, para registro e para o caso de uma demanda futura gravar nesses objetos (triggers com namespace confirmados nesta etapa; Flows e eventos do recon):

| Objeto | Before-save Flow | Before trigger | Validation rules ativas | After trigger | After-save Flow | Agendado |
|---|---|---|---|---|---|---|
| Account | — | `SBQQ.AccountBefore`, `AccountTrigger` (custom) | 6 | `AccountTrigger` (custom) | `AccountTriggered`, `UpdateParentAccountUsedLimit` | `AccountUpdateEconomicGroup` |
| Opportunity | — | `SBQQ.OpportunityBefore` | 16 | `OpportunityTrigger` (custom), `SBQQ.OpportunityAfter` | `Oportunidade_Industria`, `OpportunityFlow` | `ScheduledFlowOpportunity` |
| Order | `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p` | `SBQQ.OrderTrigger`, `OrderTrigger` (custom, só update) | 17 | idem | `Order` | `OrderScheduledFlow` |

**Risco de ordem de execução existente (achado 1): em Account, Opportunity e Order há mais de um trigger e mais de um Flow no mesmo evento, e a plataforma não garante a ordem entre triggers do mesmo objeto e fase. Esta demanda não grava, então não depende dessa ordem nem a altera.** Só a criação de dado sintético (PA-13) passa por essa cadeia, e ela acontece fora da solução, na preparação do teste.

**CA-05 e os Flows agendados:** `ScheduledFlowOpportunity`, `OrderScheduledFlow` e `AccountUpdateEconomicGroup` podem gravar sem ação do usuário (corpo não lido no recon). Para o teste de CA-05 não dar falso positivo, a comparação de contagem e `LastModifiedDate` é feita só sobre os registros `TESTE-EPLAST34`, e o verificador confere que nenhum agendamento rodou na janela do teste (`AsyncApexJob`/`FlowInterview` agregados) ou repete a medição.

## 5. Governador e escala

| Limite | Uso previsto | Margem |
|---|---|---|
| SOQL síncronas (100) | Até 10 por geração (Board, o mais pesado: 2 `COUNT()` + 3 agregadas + totais) | Folgada |
| Linhas de consulta (50.000) | `SUM` em SOQL conta cada linha agregada. `COUNT()` sem `GROUP BY` conta 1. Teto de 40.000 linhas somadas por geração (PD-06), checado antes de cada seção | Protegido pelo teto |
| Linhas de agregação com `GROUP BY` (2.000 sem `queryMore`) | Etapas e status são poucos; vendedores ≤ 14 licenças completas; conta limitada a `LIMIT 20` | Folgada |
| CPU (10 s) | A soma é feita no banco. Apex só formata dezenas de grupos | Folgada |
| Heap (6 MB) | Texto de dezenas de linhas | Folgada |
| DML (150) | 0 | — |

- **Um pai com muitos filhos (achado SOMOSAGILITY-10):** não se aplica. A classe não lê `OrderItem` nem `OpportunityLineItem`; usa `Order.TotalAmount`, já consolidado pela plataforma. Um pedido com 500 itens custa o mesmo que um com 1. Não há gravação em cascata nem Flow disparado.
- **Muitos registros:** o custo cresce com as linhas agregadas dentro do período. O teto e o período máximo (PD-06, PD-10) mantêm a geração longe do limite. O volume de produção é desconhecido (dev 0, QA não medida). Se o QA medir mais de 70% de algum limite com volume realista, o design volta para revisão (critério da doutrina).
- **Teste unitário:** `MeetingSummaryServiceTest` cria lote de 200 Opportunities e 200 Orders sintéticos, com fixture que preenche todo campo exigido pelas 16 e 17 validation rules ativas, e não usa `SeeAllData=true`.

## 6. Impacto em permissões

- **Cria** `PS_Comercial_ResumoReuniao`: acesso à classe `MeetingSummaryService`. Nenhuma permissão de objeto ou campo: o resumo mostra só o que o perfil já lê (`WITH USER_MODE`, PA-07).
- **Não altera perfis.** Os perfis que leem Opportunity e Order (`Gerente de soluções`, `Gerente do contrato`, `Comercial`, `Comercial - Analista`, `Comercial - Analistas`) recebem o resumo completo. `Comercial Padrão` lê Opportunity e não lê Order: recebe Comercial completo e S&OP como `SEM_ACESSO`, GDD e Board como `PARCIAL`.
- OWD de Opportunity é `Read` (público leitura): quem tem permissão de objeto vê o total de todos os vendedores. Isso é o comportamento atual da org, não uma abertura nova.
- **Acesso ao agente:** o `SFAgent2` é agente de funcionário; o usuário que testa precisa do acesso ao agente (licença `Agentforce Coworker`, 0 de 100.000 usadas) e do `PS_Comercial_ResumoReuniao`. A atribuição a usuários finais é passo da homologação, não do build.

## 7. Riscos do assessment que tocam a demanda

| Achado | Aplica-se? | Tratamento |
|---|---|---|
| 1 — automação concorrente em Account, Opportunity e Order | Só para a criação de dado sintético | A solução só lê; não toca trigger nem Flow (seção 4). Nenhum bypass (`TriggerUtility__mdt`) é ligado |
| 2 — cobertura Apex de 10% | Sim, para a classe nova | `MeetingSummaryServiceTest` com ≥ 85% da classe nova, cenários de acesso negado, vazio, volume excedido e erro. A cobertura agregada da org não muda por esta demanda e segue sendo risco de deploy futuro em produção, fora da esteira |
| 3 — validation rules de Order (assessment fala em 23; `sf` confirma 17 ativas, número adotado) | Só no dado de teste | Fixture e dado sintético satisfazem as 17 de Order e as 16 de Opportunity |
| 4 — campos sem descrição (assessment 153; recon 148 nos três objetos, número adotado) | Não | A solução usa só campos padrão (seção 0). Nenhum campo custom é lido ou criado |
| 5 — convenção de classe de teste | Sim | `MeetingSummaryServiceTest` |
| 6 — alias de dev com instância "qa" | **Sim, para o build e o QA** | Ver R1. Não é pergunta de negócio e não bloqueia o desenho |
| 8 — 33 perfis, comerciais duplicados | Indireto | Nenhum perfil alterado; o acesso vai por permission set |
| 9 — classes custom em API antiga | Sim | Classe nova na API do projeto (67.0) |
| 10 — `OrderTrigger` com nome duplicado | Não altera | Namespace confirmado (seção 0). A solução não toca trigger; o renome recomendado pelo assessment fica fora |

## 8. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R1 | `sbx-eplast-dev` aponta para instância com "qa" no usuário e `sbx-eplast-qa` não está conectada (achado 6, recon). Build e QA podem acabar na mesma org | **Alta** | O arquiteto humano confirma neste gate, ou a esteira confirma antes do deploy em QA, que as duas são orgs distintas. Não muda o desenho |
| R2 | **As 4 versões do `SFAgent2` estão inativas na dev.** Para testar ponta a ponta, o build precisa ativar uma versão (v4) na dev. O estado na QA não foi medido | **Alta** | Builder ativa só na dev e registra no plano de build. Ativação na QA fica para o passo de QA, conferindo antes qual versão está ativa lá. Se a ativação falhar, a verificação do agente é inconclusiva e a lógica é provada pelo teste Apex e por chamada direta do invocável |
| R3 | Deploy de metadata de agente (`GenAiPlannerBundle`, `GenAiPlugin`, `GenAiFunction`) é frágil: o retrieve do planner estourou o tempo no recon | Média | Builder faz retrieve só do planner v4 e do plugin do tópico. Se o deploy falhar duas vezes no mesmo item, liga a ação ao tópico pelo Agent Builder na dev e registra o passo manual no plano |
| R4 | O planner escolher a ação padrão `AgregacaoPedidos` em vez de `ResumoReuniao`, ou o modelo reescrever números | Média | Instrução explícita no tópico; saída da ação marcada para exibição direta na conversa, se o metadado da versão permitir (confirmar no build); teste de roteamento com as frases dos 4 tipos e regressão com 1 pergunta por ação existente |
| R5 | Licença `Salesforce` 14/14 usada: não há como criar usuário sintético de perfil sem leitura de Opportunity para o CA-01 ponta a ponta | Média | O negativo do CA-01 é provado em `MeetingSummaryServiceTest` com `System.runAs` e perfil restrito. Se o teste não conseguir criar o usuário, usa um usuário existente de perfil restrito só em `runAs`, sem ler dado dele. O positivo é provado pelo usuário técnico da esteira |
| R6 | Volume de produção desconhecido | Média | Teto e período máximo (PD-06, PD-10); reavaliação se o QA medir > 70% de limite |
| R7 | Concorrência no `SFAgent2`: EPLAST-26, 27, 28, 30, 31, 32 e 39 estão em backlog e podem tocar o mesmo agente | Baixa agora | Uma demanda por vez por cliente (guardrail 6). O plano de build registra a versão do planner alterada para a próxima demanda partir dela |
| R8 | Flows agendados gravarem durante o teste de CA-05 | Baixa | Comparação restrita a `TESTE-EPLAST34` (seção 4) |

## 9. Preparação do Sales Cloud para o Marketing Cloud

**Não se aplica.** A demanda gera resumo interno para reuniões de gestão. Não toca lead, origem, campanha, segmento, público, nutrição nem comunicação com cliente, e não envia nada (CA-06). Nenhum objeto ou campo `et4ae5` é usado ou criado (recon: 0 campos `et4ae5` em Account, Opportunity e Order). Se a Eplast quiser que o resumo seja enviado por e-mail, o envio é do Marketing Cloud (regra 2) e vira demanda própria, com esta seção desenhada nela.

## 10. Premissas assumidas (validar na homologação)

As premissas PA-01 a PA-15 da análise seguem valendo como estão. Como a aprovação da análise foi em lote, o arquiteto humano confere neste gate em especial PA-03 (números determinísticos), PA-07 (conteúdo de cada tipo) e PA-08 (sem meta e carteira). As premissas novas do design:

- [x] **PD-01 · O que é "equipe".** *Pergunta:* comercial e Board agregam por qual equipe? *Decisão:* por vendedor (`OwnerId`). *Evidência:* org — nenhum campo de equipe, regional ou canal em Opportunity, Order, Account ou User, e só 2 papéis (`sf`). *Como mudar:* se a Eplast definir equipe por papel ou por campo novo, troca-se o agrupamento numa constante da classe; o campo novo, se houver, é decisão de modelo de dados de outra demanda.
- [x] **PD-02 · Contas no GDD.** *Pergunta:* o GDD lista todas as contas? *Decisão:* as 20 maiores por valor, mais a linha "demais contas". *Evidência:* padrão de relatório "top N"; mantém o texto legível e o agrupamento abaixo do limite de 2.000 grupos. *Como mudar:* constante da classe.
- [x] **PD-03 · Moeda.** *Pergunta:* em que moeda somar? *Decisão:* `BRL`, sem conversão. *Evidência:* org — 1 moeda ativa, `BRL`, corporativa; 0 taxas datadas (`sf`). *Como mudar:* se outra moeda for ativada, a soma passa a usar `convertCurrency` e o texto mostra a moeda; ajuste na classe.
- [x] **PD-04 · O que é oportunidade "aberta".** *Decisão:* `IsClosed = false`, com `CloseDate` no período. *Evidência:* padrão da plataforma (é o filtro "Abertas" do relatório padrão). *Como mudar:* filtro na classe.
- [x] **PD-05 · Quais pedidos entram.** *Decisão:* todos os status, com `EffectiveDate` no período, agrupados por status. *Evidência:* padrão; não excluir nada evita escolher por conta da Eplast quais status valem, e o agrupamento deixa a separação visível. *Como mudar:* lista de status a excluir numa constante.
- [x] **PD-06 · Teto de volume.** *Decisão:* até 40.000 linhas agregadas por geração (80% do limite de 50.000); acima disso, a seção sai como volume excedido, pedindo período menor. *Evidência:* limite de governador (skill `salesforce-doutrina`). *Como mudar:* constante; se o volume real pedir mais, o design volta para avaliar processamento assíncrono.
- [x] **PD-07 · Versão do agente.** *Decisão:* estender o tópico `insights_comerciais` na versão mais recente (`SFAgent2_v4`) e ativá-la só na dev para teste. *Evidência:* org — 4 versões, todas inativas na dev (`sf`). *Como mudar:* a ação pode ser ligada a outra versão pelo Agent Builder, sem mudar a classe.
- [x] **PD-08 · Conferência do CA-02.** *Pergunta:* contra qual relatório conferir? *Decisão:* contra os valores conhecidos da base sintética `TESTE-EPLAST34` e um `COUNT`/`SUM` agregado restrito a ela; um relatório padrão de oportunidades pode ser usado na tela, sem criar relatório por metadata. *Evidência:* nenhum relatório da Eplast cobre o pedido (recon); custo de relatório por metadata (achado EPLAST-39). *Como mudar:* se a Eplast indicar um relatório de referência, ele passa a ser o comparativo no QA.
- [x] **PD-09 · Texto do agente.** *Decisão:* o agente mostra o texto da ação como veio, sem reescrever números; pode acrescentar uma frase de abertura. *Evidência:* PA-03. *Como mudar:* instrução do tópico.
- [x] **PD-10 · Período máximo.** *Decisão:* até 366 dias por pedido; o padrão é o mês corrente. *Evidência:* protege o limite de linhas (PD-06) e cobre a visão anual do Board. *Como mudar:* constante da classe.
- [x] **PD-11 · Permission set próprio.** *Decisão:* criar `PS_Comercial_ResumoReuniao` em vez de reaproveitar `PS_Comercial_ResumoClienteAgente`. *Evidência:* org — o existente dá acesso só a `CustomerSummaryService` (outro contrato, `eplast-ent-10`) e tem 0 atribuições; misturar os dois impediria liberar um sem o outro. *Como mudar:* pode ser incluído num grupo de permission sets comercial depois.

## 11. Bloqueios

Nenhum. Nenhuma pergunta cai no caso 3 da regra 4. O R1 (separação dev e QA) é de infraestrutura: precisa de confirmação humana antes do QA, mas não trava este desenho nem o build na dev.

## 12. O que NÃO será feito nesta demanda

- Resumo por cliente com contatos (`eplast-ent-10`, `CustomerSummaryService`).
- Agente, tópico ou bot novo; alteração das ações padrão existentes e das versões v1 a v3 do planner.
- Gravação em Account, Opportunity, Order ou qualquer objeto; campo, objeto ou Custom Metadata novo.
- Relatório ou painel por metadata.
- Envio de e-mail, mensagem ou qualquer coisa no Marketing Cloud.
- Agendamento, PDF, Word ou exportação.
- Meta, carteira ou pedido imputado (sem fonte na org, PA-08).
- Renome do `OrderTrigger` custom, alteração de trigger, Flow ou validation rule.
- Ativação do `SFAgent2` na QA ou em produção pelo build; atribuição do permission set a usuários finais.

## 13. Estimativa de esforço humano (refinada)

**Estimativa de esforço:** 40–64 h

O que mudou em relação à análise (40–72 h): o teto cai 8 h porque o recon e esta etapa confirmaram que não há relatório, painel, campo nem Flow a construir, e os perfis não mudam (acesso por um permission set). O piso se mantém porque entram três custos que a análise não via: ativação e deploy de metadata de agente com todas as versões inativas na dev (R2, R3), dado sintético que precisa passar por 16 e 17 validation rules e pelas cadeias de trigger do CPQ, e a prova do CA-01 sem licença livre (R5). Distribuição aproximada: classe e teste 18–26 h; ação, tópico e ativação do agente 8–14 h; dado sintético e verificação 8–12 h; apoio à homologação dos quatro públicos 6–12 h. Não inclui horas de agente nem espera do cliente.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
