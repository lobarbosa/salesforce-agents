# 02 — Recon: SOMOSAGILITY-30 — Total de despesas realizadas só na aprovação final da SR

**Org:** `sbx-somos-agility-dev`, tipo Sandbox, status Connected (`sf org list`, única org listada). Só leitura. Retrieve de componentes foi feito em diretório temporário e apagado. Nenhum registro lido, só metadata e `COUNT()`.
**Contexto:** `comentarios-do-card.md` só traz a aprovação do gate de análise. **Nenhuma pergunta P1 a P9 da análise foi respondida.** Sem preferências de cliente para o design.

## 1. O que já cobre o pedido

| Item | Estado confirmado | Cobre o pedido? | Prova |
|---|---|---|---|
| Flow `Atualiza_valor_total_de_despesas_realizadas_no_projeto` | Ativo, AutoLaunchedFlow, RecordAfterSave CreateAndUpdate em `Lancamento_de_Despesas__c`. Versão ativa = última (`301Ha000014xO5rIAE`) | Parcial: é o ponto único de cálculo, mas o filtro inclui as etapas pendentes. Lógica (filtro, soma, tipos de quilometragem) vem da análise, que leu o XML. Não reli neste recon | `sf data query` em FlowDefinitionView |
| Relatório, painel, agente Agentforce, processo de aprovação sobre o total | **Não procurei** | Incerto | ver seção "não consegui confirmar" |

Não achei segunda automação que escreva `Total_de_despesas_realizadas__c`: o campo não aparece nas classes e triggers retrievados (seção 3). Os dois Flows after-save de Lançamento retrievados também não o citam. Isso não cobre Flows de Projeto nem Rollup Helper (ver seção 6).

## 2. O que será tocado

| Objeto / campo | Tipo | Descrição (help text) | Prova |
|---|---|---|---|
| `PPM_Project__c.Total_de_despesas_realizadas__c` | currency, não fórmula, gravado pelo Flow | não | `sf sobject describe` |
| `Lancamento_de_Despesas__c.Relacionado_ao_Projeto__c` | reference | não | describe |
| `Lancamento_de_Despesas__c.Solicitacao_de_Reembolso__c` | reference | não | describe |
| `Lancamento_de_Despesas__c.Valor_da_Despesa__c` | currency, editável | não | describe |
| `Lancamento_de_Despesas__c.Valor_da_Kilometragem__c` | currency, **fórmula** | não | describe |
| `Lancamento_de_Despesas__c.Status_da_SR__c` | string, **fórmula** (a análise registrou `TEXT(Solicitacao_de_Reembolso__r.Status_de_Aprovacao_e_Etapas__c)`; não reli a fórmula) | não | describe |
| `Solicitacao_de_Reembolso__c.Status__c` | picklist, label "Status do Reembolso" | não | describe |
| `Solicitacao_de_Reembolso__c.Status_de_Aprovacao_e_Etapas__c` | picklist, "Status de Aprovação e Etapas" | não | describe |

Os valores das duas picklists estão na análise (seção 5); não os reconfirmei neste recon.
Consequência direta: `Status_da_SR__c` é fórmula sobre a SR. Mudar a etapa da SR não dispara o Flow de Lançamento sozinho: só dispara se o Lançamento for regravado (ver seção 3).

## 3. Automação concorrente

**Em `Lancamento_de_Despesas__c`** (mesmo objeto e evento do Flow alvo)

| Componente | Tipo | Observação | Prova |
|---|---|---|---|
| `Atualiza_valor_total_de_despesas_realizadas_no_projeto` | Flow after-save C/U | alvo | FlowDefinitionView |
| `atualizaAprovadorReembolso` | Flow after-save C/U | não cita o Total (retrieve + grep) | idem |
| `sincroniza_campos` | Flow after-save C/U | não cita o Total (retrieve + grep) | idem |
| `TrgLancamentoDeDespesas` | Apex trigger, ativo | corpo não lido | `sf data query` em ApexTrigger |
| `RHX_Lancamento_de_Despesas` | trigger do Rollup Helper, ativo | chama `performTriggerRollups` para este objeto. Se há rollup gravando o Total, não confirmei | retrieve do trigger |
| Validation rules | 15 ativas, quase todas "Nao_Pode_KM" por pessoa, mais `KM_IDA_Alimentacao` e `KM_GC_Valor_Despesa` | afetam a massa de teste de quilometragem | query em ValidationRule |

**Em `Solicitacao_de_Reembolso__c`**

| Componente | Observação | Prova |
|---|---|---|
| `Atualiza_o_status_de_aprovacao_e_etapas_da_SR` (after-save, Update) | grava `Status_de_Aprovacao_e_Etapas__c` e `Status__c` na SR | retrieve do Flow |
| `Status_Etapa_Aprova_o_Gestor`, `Email_Gestor_4` (before-save C/U) | não lidos | FlowDefinitionView |
| `TrgSolicitacaoReembolso` | delega a `SolicitacaoReembolsoTriggerHandler` (classe e teste existem) | retrieve e query em ApexClass |
| `SolicitacaoReembolsoBO.updateLancamentosDespesas` | **confirma PV-4**: depois da SR mudar, busca os Lançamentos da SR com projeto preenchido e faz `Database.update(lancamentos, false)`, o que dispara o Flow alvo. Tem trava de recursão por `Id::Status_de_Aprovacao_e_Etapas__c` por transação | leitura de `SolicitacaoReembolsoBO.cls` |

Cascata confirmada: SR muda de etapa, a BO regrava os Lançamentos, o Flow alvo recalcula o projeto. O handler que chama a BO não foi lido, então não sei em quais transições (insert, update, rejeição, Recall) ela é chamada. Isso decide se CA-04 e CA-05 funcionam sem tocar a BO.
`DML parcial (allOrNone=false)`: falha de uma validation rule do Lançamento (por exemplo as de KM) ao regravar não derruba a transação da SR, e o total pode ficar desatualizado em silêncio. A BO registra o erro; não vi para onde.

**Em `PPM_Project__c`** (alvo da gravação do Flow)

| Componente | Observação | Prova |
|---|---|---|
| `PPMProjectTrigger` ativo, `PPMProjectBO` | corpo não lido. Roda a cada gravação do total | query em ApexTrigger e ApexClass |
| Flows ativos do Projeto | 17 after-save e 2 scheduled, pela análise (não reli) | análise seção 7 |
| Validation rules | 36 ativas no Projeto (Freezing, Atraso, Status, Contrato etc.). A query foi cortada em 50 linhas, então a contagem é do que apareceu. Podem bloquear a gravação do total quando o projeto está em certos status | query em ValidationRule |

## 4. Volume e dados de teste

| Objeto | `COUNT()` na dev | Prova |
|---|---|---|
| `Lancamento_de_Despesas__c` | 0 (incluindo com projeto preenchido) | `sf data query` COUNT() |
| `Solicitacao_de_Reembolso__c` | 0; o GROUP BY por etapa não devolveu linhas | idem |
| `PPM_Project__c` | 0; nenhum com total > 0 | idem |

A dev não tem dados. A saída do `sf` para COUNT() mostrou só "Total number of records retrieved: 0", sem o valor da contagem, então interpreto como vazio, coerente com o GROUP BY sem linhas. Os testes precisam criar a massa. Não há dado histórico na dev para avaliar o backfill (P8). Isso só se mede na produção, que o agente não toca.

## 5. Permissões

| Item | Estado | Prova |
|---|---|---|
| Permission sets não ligados a perfil com acesso de leitura a `PPM_Project__c` | 9 encontrados (a lista veio em LIMIT 15). Escrita em `Gerente_de_Opera_es_PRJ` e `Projeto_DSA_Oportunidade`. Os demais só leem | query em ObjectPermissions |
| Entradas de perfil com acesso a `Solicitacao_de_Reembolso__c` | 48 | COUNT em ObjectPermissions |
| Permission set assignments na org | 720 | COUNT() |
| OWD, FLS do Total, perfis que veem o campo | **não consultei** | |

## 6. Riscos do assessment que tocam esta demanda

| Risco | Estado atual confirmado | Toca? |
|---|---|---|
| 31 automações em Oportunidade / 24 no mesmo evento | Oportunidade não é objeto desta demanda. Aqui há 3 Flows after-save em Lançamento, mais 2 triggers | Não diretamente. A ordem de execução entre Flow e triggers de Lançamento continua indefinida |
| Cobertura Apex 40% | Existem `SolicitacaoReembolsoBOTest`, `LancamentoDespesasBOTest`, `PPMProjectBOTest` e `SolicitacaoReembolsoTriggerHandlerTest`, todos API v48. Cobertura de cada classe **não medida** | Sim: a regra vive em Flow, sem Apex. Se a BO mudar, a meta é 85% |
| Classes pré-v33 | As classes envolvidas estão na v48, fora do risco | Não |
| Process Builder | A análise não achou PB nos três objetos. Não reconsultei | Não, sem reconfirmação |
| Rollup Helper e DLRS | `RHX_Lancamento_de_Despesas` está ativo. Pode haver rollup concorrente no Projeto | Sim, a confirmar |
| Perfil por pessoa | 48 entradas de perfil em SR. Massa de QA precisa de usuários dos perfis que veem o campo | Sim, para QA |

## O que não consegui confirmar

1. Se há relatório, painel, agente Agentforce ou processo de aprovação que use o total (não procurei).
2. Se há rollup do Rollup Helper (ou DLRS) gravando `Total_de_despesas_realizadas__c`. Só vi que o trigger `RHX_` existe; a configuração do rollup não foi consultada.
3. Se algum dos 17 Flows after-save do Projeto, `PPMProjectBO` ou `TrgLancamentoDeDespesas` lê ou grava o Total. Só retrievei os 2 Flows de Lançamento e os Flows/classes listados.
4. Em quais transições a SR chama `updateLancamentosDespesas` (código do `SolicitacaoReembolsoTriggerHandler` não lido). Define se Rejeição e Recall recalculam o total.
5. Para onde vai o erro quando o `Database.update` parcial da BO falha.
6. A cobertura Apex por classe, OWD, FLS do campo Total e quem vê o campo (P9).
7. A contagem exata: a saída do `sf` não exibiu o número, só "0 registros".
8. As picklists e a fórmula de `Status_da_SR__c` não foram relidas; valem como na análise.
9. Todas as perguntas de negócio P1 a P8 (campo de situação, Pendente - Operações, quilometragem, Aprovado volta atrás, SOMOSAGILITY-10, projeto sem despesa, backfill) seguem sem resposta no card. Nenhuma foi decidida aqui.
