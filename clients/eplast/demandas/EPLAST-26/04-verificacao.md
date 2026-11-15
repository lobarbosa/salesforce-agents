**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-26 — Verificação do build (score e faixa de prioridade)

**Org conectada:** `sf org list` mostrou só `sbx-eplast-dev` (Sandbox, Connected, Org Id final `...vfMLMAY`). Todos os comandos usaram `--target-org sbx-eplast-dev`. Nada em QA nem em produção.

## Divergências da esteira registradas
- O `00-preflight.md` dizia "Etapa que vai rodar: build". A etapa desta sessão é verificação.
- O preflight dizia "nenhum componente da demanda no repositório". Isso é falso. `git diff main...HEAD -- force-app` lista 12 componentes: 4 campos, 3 list views, 1 permission set, 2 layouts e 2 FlexiPages. Todos batem com o `04-plano-build.md`.
- Outras demandas nos mesmos componentes: o diff de `Opportunity_Record_Page`, `Lead-Lead Layout` e dos demais arquivos alterados só tem linhas adicionadas, nenhuma removida. Não há sobrescrita do que EPLAST-30 e EPLAST-35 possam alterar. O conflito de merge textual entre os PRs não foi testado.

## Resultado em uma frase
Lead: tudo o que dá para exercitar na dev passou. Opportunity: a fórmula não foi executada, porque a criação de uma Opportunity exige uma fixture que não montei. Por isso a verificação é inconclusiva e não aprovada.

## Dados de teste
Criei 4 Leads com `TESTE EPLAST-26` no nome e na empresa. Todos foram apagados e a contagem de Lead na dev voltou a 0. Lead não tem trigger, Flow nem callout (recon e consulta ao `ApexTrigger`), então nada saiu da org. Não alterei o usuário de execução.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| L1 | Lead com setor, origem e Contatado: Alta | Criei Lead A (Alimentos, Campanha, Contatado) e consultei por SOQL | 100, Alta | 100, Alta | passou |
| L2 | Lead só com setor: Baixa | Lead B (Alimentos, sem origem, Aberto - Não contatado) | 30, Baixa | 30, Baixa | passou |
| L3 | Lead sem setor e sem origem: sem faixa | Lead C (sem setor, sem origem, Contatado) | 0, "Sem dados suficientes" | 0, Sem dados suficientes | passou |
| L4 | Mudança de status atualiza score | Lead D criado com setor, origem e Aberto (score 60, Média); depois `Status='Contatado'` | 100, Alta | 60 e Média no início; 100 e Alta depois | passou |
| S1 | Campos somente leitura | `sf sobject describe` de Lead e Opportunity; `sf data update` de `PriorityScore__c=5` no Lead D | updateable=false; escrita recusada | Os 4 campos com `updateable=false`, `createable=false`, `calculated=true`. A escrita foi recusada ("Unable to create/update fields: PriorityScore__c") | passou |
| V1 | Lista de Leads ordena por score | REST `listviews/<id>/describe` e `results` da vista `Leads_Abertos_Prioridade`; SOQL `ORDER BY PriorityScore__c DESC` | Colunas ordenáveis; 100, 30, 0 | Score e faixa com `sortable=true`. A vista devolveu os 4 Leads de teste. A ordem 100, 100, 30, 0 vem do SOQL equivalente, porque o clique na coluna só existe na interface | passou (ordenação por clique na tela não executada) |
| V2 | Lista de Opportunity filtra por faixa Alta | Confirmei que as 3 list views existem na dev (`ListView`) e o filtro por `PriorityBand__c` no metadata do deploy | Vista existe e filtra | As 3 vistas existem. Sem Opportunity para exercitar o filtro | não executado |
| O1 | Opportunity Probability 90, valor, 30 dias, origem: score 96 | Tentei criar Opportunity sem Conta (`TESTE EPLAST-26 O1`) | Registro criado | Recusada por 8 validation rules (endereço, CNAE, razão social, e-mail, telefone, loja, ID Protheus do dono, conta obrigatória). Nada foi criado | não executado |
| O2 | Opportunity: prazo 61 dias (40), Qualificação (4), encerrada ("Encerrada"), 60 dias, 55% (22), vencida | Dependem da mesma fixture que O1 | Cada valor do `01-analise.md` e do `03-design.md` seção 8 | Sem execução | não executado |
| O3 | Fórmulas de Opportunity | Comparei a fórmula do repositório com a seção 4.2 do design (grep das linhas de `ROUND`, `TODAY` e `IsClosed`) | Idêntica ao design | Idêntica. É conferência de texto, não de execução | não executado (só leitura de fórmula) |
| M1 | Sem trigger, Flow nem Apex em Lead e Opportunity | `git diff --name-status main...HEAD -- force-app` | Nenhum ApexTrigger, Flow ou classe | 12 itens: 4 campos, 3 list views, 1 permission set, 2 layouts, 2 FlexiPages. Nenhum trigger, Flow ou classe | passou |
| M2 | Sem chamada externa nem e-mail criados | Mesmo diff | Sem Named Credential, callout, email alert ou Flow de e-mail | Nenhum desses tipos no diff | passou |
| P1 | Permission set concede leitura | `PermissionSetAssignment` por `PS_Comercial_ScorePrioridade`; leitura dos campos pelo usuário da esteira | Existe e está atribuído | 1 atribuição; o usuário da esteira leu `PriorityScore__c` e `PriorityBand__c` nas consultas acima | passou |
| T1 | Campos nas telas (seção "Prioridade") | Conferi no diff os campos `readonly` em `Lead_Record_Page`, `Opportunity_Record_Page` e nos 2 layouts. Não abri a tela | Campos presentes | Presentes nos 4 arquivos. Renderização na tela não verificada | não executado |
| R1 | Regressão de Opportunity | Exige criar e alterar Opportunity | Automações existentes sem erro novo | Sem execução | não executado |

## O que ficou sem prova
1. **Fórmula de Opportunity (O1, O2, V2, R1).** A dev tem 0 Opportunity. Criar uma exige uma Conta sintética com endereço de cobrança, CNAE, razão social, e-mail, telefone e loja, além de filial, forma e condição de pagamento, catálogo de preços e o ID Protheus no usuário de execução (EPLAST-36). Criar a Conta aciona `AccountTrigger.fillAccountWithCNPJInfo`, que chama a BrasilAPI. A Opportunity aciona `OpportunityTrigger`, `OpportunityBefore`, `OpportunityAfter`, `Oportunidade_Industria` e `OpportunityFlow` (cotação CPQ e possível análise financeira). Não montei essa fixture nesta sessão: tentei só a criação mínima, que a plataforma recusou. Portanto não afirmo que a fórmula esteja certa nem errada. O resultado esperado, caso a caso, está na seção 8 do `03-design.md`.
2. **Tela.** Clique na coluna de score, seção "Prioridade" nas páginas e `Opportunity_Record_Page_Three_Column` (não alterada, conforme B3 do plano).
3. **Lead convertido (PD-05)** e **Lead "Fechado - Não convertido" fora da vista (PD-06)**: não criei esses casos.
4. **Regressão Apex** (`FlowOpportunityControllerTest` e outras): não executada.
5. **Layout `Opportunity-CPQ Opportunity Layout`:** não alterado, por ser de pacote gerenciado (desvio já declarado no plano).

## O que uma pessoa precisa fazer para provar
Montar, na dev, a Conta e a Opportunity sintéticas com `TESTE EPLAST-26` no nome. Os passos: preencher o ID Protheus do usuário de execução com valor sintético e devolver o valor de antes; consultar `PriorityScore__c` e `PriorityBand__c` para os valores da seção 8 do design; apagar os registros e conferir a cotação CPQ criada pelo `OpportunityFlow`. Alternativa: os Testes 5 a 9 do `05-roteiro-cliente.md` na homologação.

## O que pode ter saído da org
Nada saiu. Foram criados e apagados 4 Leads, que não têm cadeia de automação. A tentativa de criar a Opportunity foi recusada antes de gravar, então nenhum registro, cotação ou log de integração foi criado. Nenhuma Conta foi criada, portanto nenhuma chamada à BrasilAPI.

## Limpeza
Todos os Leads de teste foram apagados e a contagem de Lead na dev voltou a 0. Opportunity continua em 0. Nenhum job agendado.
