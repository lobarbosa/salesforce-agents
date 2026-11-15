**Verificação:** aprovada
**Org de teste:** sbx-eplast-dev

# EPLAST-34 — Verificação do build

`sf org list`: única org conectada é `sbx-eplast-dev` (Sandbox, Connected). Todos os comandos usaram `--target-org sbx-eplast-dev`. Nada em QA, produção ou Marketing Cloud. Nenhuma metadata alterada.

## Como foi exercitado
- Teste Apex reexecutado: `sf apex run test -n MeetingSummaryServiceTest --code-coverage` (Run Id `707Ha00001DzS4B`): 10 testes, 100% de aprovação, `MeetingSummaryService` com 93% de cobertura.
- Anonymous Apex só de leitura chamando `MeetingSummaryService.resumir` para COMERCIAL, GDD, SOP, BOARD e um tipo inválido.
- Conversa ponta a ponta com o `SFAgent2` publicado (v5 ativa) por `sf agent preview start/send/end`. Os registros do agente e das ações são reais. A dev não tem dado de negócio.
- Contagens agregadas antes e depois. Nenhum registro foi criado por mim: a dev tem 0 Account, 0 Opportunity, 0 Order e 0 EmailMessage. Os dados `TESTE-EPLAST34` existem só dentro do teste Apex e são revertidos ao fim. Não há nada a apagar e nada ficou.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | CA-02 números | Teste Apex `deveGerarComercialGddSopBoardComDados` e `deveSomarBulkDe200...` (base sintética, 200 + 200) | Contagem e total conferem com a base, em pt-BR | Passou (`3 oportunidade(s)`, `R$ 3.000,00`; `200 oportunidade(s), R$ 2.000,00`) | passou (prova no teste Apex; não conferido contra relatório padrão na dev, que não tem dado) |
| C2 | CA-03 corte e origem | Anonymous Apex nos 4 tipos | `dataHoraCorte` preenchida, rodapé "Dados ate ...", origem `Objeto.Campo` em cada seção | 4 de 4 com corte e rodapé. Texto traz `(Opportunity.StageName, Opportunity.Amount)` etc. | passou |
| C3 | CA-04 seções por tipo | Anonymous Apex e conversa com o agente | COMERCIAL 2 seções, GDD 2, SOP 2, BOARD 3, sem seção de outro tipo | COMERCIAL: etapa e vendedor. GDD: oportunidades e pedidos por conta. SOP: pedidos por status e total. BOARD: pipeline, pedidos por vendedor e total geral | passou |
| C4 | CA-01 acesso negativo | Teste `deveInformarSemAcessoParaUsuarioSemLeituraDeOpportunityEOrder` (`runAs`, perfil `Minimum Access - Salesforce`) | `SEM_ACESSO` e mensagem, sem dado | Passou: COMERCIAL e BOARD voltam `SEM_ACESSO` | passou |
| C5 | CA-01 caso misto (lê Opportunity, não lê Order) | Não há usuário sintético possível (licença 14/14, apontado pelo builder) | PARCIAL por falta de Order | Não exercitado | não executado |
| C6 | CA-05 sem gravação | Contagem de Account, Opportunity e Order antes e depois de anonymous Apex e de 7 mensagens ao agente | Sem mudança | 0, 0, 0 antes e depois. `MAX(LastModifiedDate)` de Opportunity nulo. Classe sem DML (confere no plano) | passou |
| C7 | CA-05 agendamentos (cuidado do design) | `AsyncApexJob` e `FlowInterview` com `CreatedDate` desde o início da sessão | Nenhum `ScheduledFlowOpportunity`, `OrderScheduledFlow` ou `AccountUpdateEconomicGroup` na janela | `AsyncApexJob` desses nomes: 0. `FlowInterview` na janela: 0. Único job não agendado é o `TestRequest` desta verificação | passou |
| C8 | CA-06 sem envio | `EmailMessage` antes e depois, anonymous Apex e agente | Contagem igual, sem callout | 0 antes e 0 depois. A classe não tem e-mail, callout ou async (plano de build) | passou |
| C9 | CA-07 dado pessoal | Regex de e-mail e de CPF no texto dos 4 tipos e do inválido | Nenhum padrão | `email=false` e `cpf=false` em 5 de 5. Texto só tem agregados por etapa, status, conta ou vendedor | passou |
| C10 | CA-08 falha | Anonymous Apex com tipo inválido (XPTO). Teste `deveDevolverListaVaziaOuErroSemExplodir` | `ERRO`, sem resumo parcial, sem gravação | `ERRO`, 59 caracteres, sem rodapé de resumo. Teste Apex passou | passou |
| C11 | CA-09 sem agente novo | `BotDefinition` e `GenAiPlannerDefinition` | 1 Bot; nenhum planner de outro nome | 1 Bot. 5 planners, todos `SFAgent2_v1` a `v5` (a v5 veio de outras demandas em 15/11, divergência 1 do plano) | passou |
| C12 | R4 roteamento ponta a ponta | Preview com 4 frases (comercial, GDD, S&OP, Board) | O agente chama `ResumoReuniao` e mostra o texto como veio | 4 de 4 devolveram o texto da ação com os títulos, a origem dos campos e o rodapé "Dados ate 15/11/2026 07:14". O agente só acrescentou uma pergunta de continuação no fim. Números não reescritos (resumos vazios, "Nenhum registro") | passou |
| C13 | R4 regressão das ações padrão | Preview: "pedidos por status", "últimos pedidos", "conta por CNPJ" | Continuam respondendo pelas ações existentes, sem cair no resumo | Os 3 responderam pela ação padrão ("não há pedidos...", "conta não encontrada"), sem texto de resumo de reunião | passou |
| C14 | Cobertura Apex | Run `707Ha00001DzS4B` | 85% ou mais, sem falha | 93%, 10 de 10 | passou |

## Limites da prova (não impedem a aprovação)
- A dev não tem dado de negócio. A exatidão dos números foi provada só pelos testes Apex com base sintética. Na dev, a conversa e a chamada direta mostram o ramo `VAZIO`. A conferência contra relatório padrão e o ramo com valores via agente ficam para a QA.
- C5 (perfil que lê Opportunity e não lê Order) não foi exercitado. O ramo `PARCIAL` está coberto no teste só por volume excedido e por `SEM_ACESSO` total.
- Não foi criado dado na dev por causa dos triggers de Account (BrasilAPI e Protheus, callout). O teste Apex isola isso com bypass só na fixture.
- A v5 foi alterada no lugar. O `.agent` do repositório não traz a ação (divergência 3 do plano). Isso é risco de implantação, não falha do build.

## O que pode ter saído da org
Nada. Nenhum registro foi criado, nenhum e-mail enviado, nenhuma chamada externa. Os 7 turnos do preview geraram só sessão de agente, sem registro de negócio.
