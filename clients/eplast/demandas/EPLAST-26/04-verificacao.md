**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (`sf org list`: Sandbox, Connected, Org Id 00DHa000006vfMLMAY; usuário omitido por ser dado pessoal)

# EPLAST-26 — Verificação do build

Só a dev foi tocada. Nada em QA, produção ou Marketing Cloud. Nenhum arquivo de metadata alterado. Dados de teste: 5 Leads sintéticos `TESTE EPLAST-26 L1..L5` (Company `TESTE EPLAST-26`), lidos só pelos campos da entrega e apagados ao fim (`SELECT COUNT() FROM Lead` = 0 depois).

## Resultado em resumo

Nenhum caso executado falhou. Lead, permissões, list views e revisão de metadata passaram. **Os cenários de Opportunity (score e faixa) não foram executados**: ficam sem prova de execução (ver "O que ficou sem prova"). Por isso a verificação é inconclusiva, não aprovada.

## Casos

| Caso | Critério (análise, seção 4) | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| L1 | Lead setor + origem + Contatado | `sf data create record` (Sector Alimentos, LeadSource Evento, Contatado); SOQL em `PriorityScore__c`, `PriorityBand__c` | 100, Alta | 100, Alta | passou |
| L2 | Lead só com setor | Sector preenchido, sem origem, "Aberto - Não contatado" | 30, Baixa | 30, Baixa | passou |
| L3 | Lead sem setor e sem origem | Só Status Contatado | 0, Sem dados suficientes | 0, Sem dados suficientes | passou |
| L4 | Alteração de status | Lead setor+origem "Aberto - Não contatado"; depois `sf data update record` Status=Contatado | 60 Média, depois 100 Alta | 60 Média, depois 100 Alta | passou |
| L5 | Extra: só origem, não contatado | LeadSource preenchido apenas | 30, Baixa | 30, Baixa | passou |
| L6 | Lead convertido mantém score (PD-05) | Não criado: conversão cria Account/Contact/Opportunity e dispara a cadeia de Opportunity. Fórmula conferida no metadata do design (`OR(ISPICKVAL(Status,"Contatado"), IsConverted)`) | 100, Alta | — | não executado |
| O1 | Opp Probability 90 / valor / 30 dias / origem | Não criada (ver abaixo) | 96, Alta | — | não executado |
| O2 | Opp 50 / valor / 61 dias / sem origem | idem | 40, Média | — | não executado |
| O3 | Opp 10 / valor 0 / 200 dias | idem | 4, Baixa | — | não executado |
| O4 | Opp encerrada (4 fases) | idem | Encerrada, 0 | — | não executado |
| O5 | PD-03 (vencida), 60 dias, PD-04 (55% = 22) | idem | sem ponto de prazo; com ponto; 22 | — | não executado |
| O-F | Fórmulas de Opportunity (leitura estática) | Tooling `CustomField.Metadata` na dev, `Opportunity.PriorityScore__c` e `PriorityBand__c` | Fórmula igual à seção 4.2 do design | Fórmula idêntica (ROUND, BLANKVALUE, janela 0 a 60 dias, IsClosed, faixas 70/40) | passou (só leitura de metadata; não substitui O1 a O5) |
| S1 | Campos somente leitura | `sf data update record -v "PriorityScore__c=5"` em Lead; describe | Escrita recusada | `Unable to create/update fields: PriorityScore__c...`; describe: `calculated=true`, `updateable=false` (score e faixa) | passou (Lead; Opportunity pelo mesmo tipo fórmula, sem DML) |
| P1 | Permission set | Query em `FieldPermissions` do `PS_Comercial_ScorePrioridade`; `PermissionSetAssignment` | 4 campos só leitura; 1 atribuição | 4 linhas, `PermissionsRead=true`, `PermissionsEdit=false`; 1 atribuição | passou |
| V1 | Lista ordena por score (Lead) | REST `listviews/<id>/describe` e `/results?orderBy=PriorityScore__c DESC` na `Leads_Abertos_Prioridade` | Coluna ordenável; ordem decrescente | `PriorityScore__c` e `PriorityBand__c` com `sortable=true`; resultados 100, 100, 30, 30, 0. SOQL `ORDER BY PriorityScore__c DESC` igual | passou (ordenação pela API da list view; clique na tela não exercitado) |
| V2 | Lista filtra por faixa (Opportunity) | REST describe da `Oportunidades_Prioridade_Alta` | Filtro por faixa Alta | Query: `WHERE IsClosed = false AND PriorityBand__c = 'Alta'`; colunas de score e faixa presentes | passou (query compilada); sem Opportunity para ver linhas |
| V3 | `Oportunidades_Abertas_Prioridade` | REST describe | Filtro `IsClosed = false`, colunas de score e faixa | Confirmado; `results` size 0 (org sem Opportunity) | passou |
| R1 | Sem trigger, Flow ou Apex | `git diff main --stat -- force-app` | Só campos, layouts, FlexiPages, list views e permission set | 12 arquivos, todos esses tipos; nenhum ApexClass, ApexTrigger ou Flow | passou |
| R2 | Sem callout, e-mail ou integração externa | Revisão do diff dos 12 arquivos | Nenhuma Named Credential, Flow ou e-mail | Nenhum (o único acerto de busca foi `xmlns`) | passou |
| R3 | Regressão de Opportunity e testes Apex | Não executado | Automações e testes como antes | — | não executado |
| N1 | Taxa de ganho por faixa | Critério de negócio pós go-live (R5 do design) | Não testável | — | não executado |

## Pendências do builder, tentadas aqui

1. **Ordenação por score**: resolvida via API da list view (V1). Clique na coluna, na tela, não foi exercitado.
2. **`Opportunity_Record_Page_Three_Column`**: tentei por Tooling (`ProfileActionOverride`) e a consulta não retornou utilizável. Existem 2 FlexiPages de Opportunity (`Opportunity_Record_Page` e `_Three_Column`). **Inconclusivo**: o administrador deve conferir no Setup (Gerenciador de Apps / ativação da página) se a Three_Column está atribuída.
3. **Dev x QA**: só o alias dev está conectado (Org Id 00DHa000006vfMLMAY). Sem o Org Id do alias QA não há comparação. **Inconclusivo**: a esteira de QA deve comparar os dois Org Ids antes de implantar.

## Observação (não é falha)

- No deploy, `PriorityScore__c` tem precisão 18, escala 0 (o design citava 3 casas inteiras). Não muda resultado: o máximo é 100.
- O layout `CPQ Opportunity Layout` não foi alterado (pacote gerenciado), como o builder registrou.

## O que ficou sem prova (o que uma pessoa precisa fazer)

- **Score e faixa de Opportunity (O1 a O5) e lead convertido (L6)**: não criei Opportunity. Criar Opportunity nesta org passa por 16 validation rules e dispara `OpportunityFlow` (cotação CPQ, possível aprovação) e, pelo histórico, a cadeia pode chegar à integração Protheus. `comentarios-do-card.md` não traz autorização por escrito do responsável para disparar essa cadeia na dev, então não disparei. Para provar: o responsável pela conta autorizar por escrito o teste (e o endpoint da sandbox ser confirmado), ou o QA executar a fixture da seção 8 do design com o menor número de registros, todos com `TESTE EPLAST-26` no nome, e apagá-los ao fim.
- Regressão de Opportunity e classes de teste Apex existentes: dependem da mesma fixture e do QA.
- Cliques de interface (ordenação na tela, aparição da seção "Prioridade" na página): não exercitáveis daqui.

## O que pode ter saído da org

Nada. Só Leads sintéticos foram criados (Lead não tem trigger, Flow nem integração, conforme `02-recon.md`/design seção 5) e foram apagados. Nenhum registro de Opportunity, cotação, pedido ou log de integração foi criado.

## Dados de teste

Criados e apagados: 5 Leads `TESTE EPLAST-26 L1..L5`. Nada ficou.
