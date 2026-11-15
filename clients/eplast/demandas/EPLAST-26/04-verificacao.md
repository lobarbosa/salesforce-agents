**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-26 — Verificação (reverificação) do score e da faixa de prioridade

Org conferida com `sf org list` antes de qualquer comando: só `sbx-eplast-dev` (Sandbox, Connected, Org Id final `...vfMLMAY`, usuário `...eplast2.qa`). Ela é a "QA" da Eplast e a dev da esteira (regra 5 do `CLAUDE.md` do cliente); não é motivo de bloqueio. Nada foi feito na QAS, em produção ou no Marketing Cloud. `force-app/` não foi alterado.

## Resumo

- Lead: todos os critérios exercitados na dev passaram, com evidência. Faltam só o lead convertido (PD-05) e a tela.
- Opportunity: **não exercitada**. A dev tem 0 Account e 0 Opportunity, e a fixture exige uma cadeia que não dá para montar sem alterar registro que não criei (ver "O que ficou sem prova"). O defeito não está provado nem descartado. Por isso o veredito é inconclusiva, não reprovada.
- Nenhum caso executado falhou.

## Divergência do preflight

O `00-preflight.md` diz etapa "build" e "a demanda ainda não tem componentes no repositório". No disco os componentes existem e `04-plano-build.md` abre com `**Resultado do build:** concluído`. Conferi no disco `PriorityScore__c` e `PriorityBand__c` nas pastas de campos de Lead e Opportunity, e na org por `FieldDefinition` (4 campos, todos fórmula, `IsCalculated` = true). O preflight está desatualizado; não reconstruí nada.

## Outras demandas nos mesmos componentes

- EPLAST-30 (`Opportunity_Record_Page`) e EPLAST-35 (`Lead-Lead Layout`): no workspace só há `demanda.md` e `status.yaml` da EPLAST-30, e nada da EPLAST-35. Sem plano de build delas, **não consegui comparar** as alterações. O risco é de merge: a EPLAST-26 acrescenta a seção "Prioridade" (2 campos) no layout do Lead e na FlexiPage da Opportunity. Quem mergear depois precisa conferir que a seção não se perdeu e que o arquivo não foi sobrescrito inteiro. Nada executado aqui prova ou descarta conflito.

## Premissas assumidas (validar na homologação)

Aplicadas como decididas no design, sem reprovar por elas: PD-01 sem prefixo; PD-02 pesos literais na fórmula; PD-03 fechamento vencido não pontua; PD-04 `ROUND`; PD-05 lead convertido conta como contatado; PD-06 Lead "Fechado - Não convertido" sem faixa especial; PD-07 acesso por permission set `PS_Comercial_ScorePrioridade`; PD-08 list views para todos os usuários internos. Pesos e faixas (PA-13) são o ponto que mais tende a mudar.

## Casos

Dados de teste: 5 Leads `TESTE EPLAST-26 L1` a `L5` (Company `TESTE EPLAST-26`, valores fictícios), criados por `sf data create record`. Todos apagados ao fim.

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| L1 | Lead com setor, origem e Contatado: Alta | Criado L1 (Sector, LeadSource, Status Contatado); consulta de `PriorityScore__c`, `PriorityBand__c` | 100 / Alta | 100 / Alta | passou |
| L2 | Só setor, Aberto: Baixa | Criado L2 (Sector, sem origem, Aberto - Não contatado) | 30 / Baixa | 30 / Baixa | passou |
| L3 | Sem setor e sem origem: sem faixa | Criado L3 (Contatado, sem Sector nem origem) | 0 / Sem dados suficientes | 0 / Sem dados suficientes | passou |
| L4 | Alteração de status reflete ao reabrir | Criado L4 (Sector, origem, Aberto): 60 / Média. `sf data update record` Status = Contatado e nova consulta | 60 / Média, depois 100 / Alta | 60 / Média, depois 100 / Alta | passou |
| L5 | Borda: só origem (sem setor) | Criado L5 (origem, sem Sector, Aberto) | 30 / Baixa (design: origem vale 30, abaixo de 40) | 30 / Baixa | passou |
| L6 | Campos somente leitura (API) | `sf data update record` com `PriorityScore__c=5` em L1; `describe`: `createable` e `updateable` = false nos 2 campos de Lead | Escrita recusada | "Unable to create/update fields: PriorityScore__c" | passou |
| L7 | List view ordena por score | REST `listviews/00BHa00000ApBi1MAF/results` com `orderBy=PriorityScore__c DESC`; `describe` das colunas | 100, 100, 30, 30, 0; colunas ordenáveis | `['100.0','100.0','30.0','30.0','0.0']`; `PriorityScore__c` e `PriorityBand__c` com `sortable` = true; a vista trouxe os 5 leads de teste | passou (via API, não por clique na tela) |
| L8 | Lead convertido mantém 100 / Alta (PD-05) | `Database.convertLead` em Apex anônimo com savepoint e rollback | 100 / Alta após conversão | A conversão falhou antes: "Erro de validação em Conta: CNPJ incompleto ou inválido" (validation rule da Account). Nada persistiu (rollback) | não executado |
| O1 | Opportunity Alta (96) | Contagens agregadas na dev | 96 / Alta | Dev tem 0 Opportunity (`COUNT` = 0); sem registro não há o que medir | não executado |
| O2 | Prazo 61 dias não ganha ponto (40 / Média) | idem | 40 / Média | idem | não executado |
| O3 | Baixa (Prob 10, sem valor, 200 dias): 4 | idem | 4 / Baixa | idem | não executado |
| O4 | Encerrada: faixa Encerrada, score 0 | idem | 0 / Encerrada | idem; 0 registros fechados | não executado |
| O5 | Bordas PD-03/PD-04: 60 dias, vencida, 55% = 22 | idem | ponto em 60 dias; vencida sem ponto; 22 | idem | não executado |
| O6 | List views de Opportunity: filtro Alta | `describe` da vista `00BHa00000ApBi3MAF` | Consulta filtra `IsClosed=false` e `PriorityBand__c='Alta'` | Consulta da vista: `WHERE IsClosed = false AND PriorityBand__c = 'Alta'`. Resultado com registros não exercitado (0 Opportunity) | não executado (definição conferida) |
| O7 | Campos somente leitura (Opportunity) | `describe`/`FieldDefinition` | Fórmula, não gravável | Os 2 campos de Opportunity são fórmula (`IsCalculated` = true). Escrita por DML não tentada | não executado (metadata conferida) |
| X1 | Sem trigger, Flow ou Apex novo em Lead/Opportunity | Triggers na org: `ApexTrigger` de Lead e Opportunity; `04-plano-build.md` | Nenhum novo | Lead: nenhum trigger. Opportunity: `OpportunityAfter`, `OpportunityBefore`, `OpportunityTrigger`, todos anteriores. Plano diz "só declarativo". Não comparei com o diff do PR | passou (parcial, o diff do PR não foi revisado aqui) |
| X2 | Permission set atribuído e funcionando | Contagem de `PermissionSetAssignment` de `PS_Comercial_ScorePrioridade` | 1 (usuário da esteira) | 1; os campos apareceram nas consultas como esse usuário | passou |
| R1 | Regressão: testes Apex de Opportunity | `sf apex run test --tests FlowOpportunityControllerTest` | Passam | 2 de 2, 100% | passou (só essa classe; não rodei "antes e depois") |
| R2 | Regressão: criar e alterar Opportunity com automações | Não executado | Cotação criada, sem erro novo | Sem Opportunity possível (ver abaixo) | não executado |
| T1 | Seção "Prioridade" nas páginas, ordenação por clique | Não há interface | Seção visível e somente leitura | Metadata conferida pelo build; tela não exercitada | não executado |

## O que ficou sem prova

**Opportunity (O1 a O7, R2).** A dev tem 0 Account e 0 Opportunity. Criar uma Opportunity exige:

- Account com CNPJ válido, CNAE, Razão Social, e-mail, telefone, Loja e endereço de cobrança.
- Dono da Account com `ProtheusSellerId__c`. O usuário da esteira não o tem, e preenchê-lo seria alterar registro que não criei.
- Registros de apoio: Filial (`Branch__c`), Forma e Condição de Pagamento, catálogo de preços.

Testei isso em Apex anônimo com savepoint e rollback. A inserção da Account falhou em "CNPJ incompleto ou inválido" e a da Opportunity listou as validation rules, entre elas CNAE, Razão Social, e-mail, telefone, Loja, `ID Usuário Protheus` do dono e Conta obrigatória. Nada foi gravado.

**Cadeia de automação.** Pela metadata, `OpportunityFlow` (ativo, RecordAfterSave, criar e atualizar) chama `CreateQuoteCPQController` (Apex, sem callout no corpo) e a ação `submit` (aprovação). Cria e atualiza Quote, Order e Task. A integração Protheus tem classes próprias (`SendAccountToProtheus`, `SendOrderToProtheus`); não confirmei se a inserção de Account ou Opportunity as aciona. Por isso não montei a fixture completa.

**Lead convertido (L8).** Exige Lead com dado que passe pela validação de CNPJ da Account. Não criei Account com CNPJ para não disparar a cadeia da Account, que inclui `SendAccountToProtheus`.

**Para provar:**

- Uma pessoa com acesso à dev cria, ou autoriza a criação de, o conjunto mínimo de dados de apoio: usuário-dono com `ProtheusSellerId__c` fictício, Filial, Forma e Condição de Pagamento, catálogo de preços e uma Account sintética com CNPJ de teste.
- Confirmar antes qual endpoint o Protheus usa na dev.
- Com isso, repetir O1 a O5, R2 e L8. Cada caso tem esperado definido na tabela e na seção 4 de `01-analise.md`.
- Alternativa: executar os Testes 5 a 9 do `05-roteiro-cliente.md` na homologação.
- Conferir por clique na tela a ordenação por coluna e a seção "Prioridade" nas FlexiPages. Conferir quais páginas Lightning e apps usam `Opportunity_Record_Page_Three_Column`, que não foi alterada.

## O que pode ter saído da org

Nada. Os 5 Leads criados não disparam trigger de Lead (nenhum existe). Não foi criada Account, Opportunity, cotação, pedido nem log de integração. Os testes em Apex anônimo com Account, Opportunity e conversão de Lead terminaram em `Database.rollback`, e as inserções falharam na validação. Nenhuma chamada externa foi registrada por mim; também não consultei logs de integração.

## Limpeza

- 5 Leads `TESTE EPLAST-26 L1` a `L5` apagados (`sf data delete record`, 5 sucessos); `COUNT(Lead)` = 0 depois. Os registros apagados ficam na lixeira da org até ela ser esvaziada (comportamento padrão do Salesforce).
- Nenhum job Apex agendado foi criado nem encontrado (consulta de `AsyncApexJob` pendente = 0).
- Arquivos temporários em `/tmp/v26` (fora do repositório): retrieve de `OpportunityFlow` e `Oportunidade_Industria`, descartados.

## B0 e pendência de administrador

- B0 (dev x QA): resolvido pelo card de 15/11 (duas orgs distintas, Org Id da dev termina em `...vfMLMAY`). Não é pendência.
- Atribuir `PS_Comercial_ScorePrioridade` aos usuários reais da PD-07, por ambiente. Sem isso os campos ficam invisíveis. Está com o administrador.
