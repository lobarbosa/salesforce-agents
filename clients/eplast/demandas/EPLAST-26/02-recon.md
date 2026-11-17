# EPLAST-26 — Recon da org (rodada 3: redesenho com as respostas do cliente de 17/11)

**Org:** `sbx-eplast-dev`, Sandbox, Connected (`sf org list`, nesta sessão, 2026-11-17). Só leitura. Só metadata e contagens agregadas; nenhum registro lido. Os retrieves foram feitos em diretório temporário, descartado.
**Insumos:** `01-analise.md`, `comentarios-do-card.md`, seção "Respostas do cliente (2026-11-17)" do `03-design.md`, `00-preflight.md`, regras 2 a 5 do `CLAUDE.md` da Eplast.
**O que mudou desde o recon de 15/11:** os campos de score já existem na dev (build da rodada anterior), há consumidores novos de `PriorityBand__c` (demandas 42 a 45) e há automação nova em Lead e Opportunity. Esta versão substitui o recon anterior, que ficou no histórico do git.

---

## 1. O que já cobre o pedido

| Elemento | O que existe na dev | Cobre o pedido novo? | Prova |
|---|---|---|---|
| `Lead.PriorityScore__c` (Number, fórmula) e `Lead.PriorityBand__c` (Text, fórmula) | Existem, da rodada anterior. Score: Setor 30 + Origem 30 + Status Contatado/convertido 40. Faixa: Alta, Média, Baixa, "Sem dados suficientes". Descrição e texto de ajuda preenchidos | Não: pesos e rótulos são os antigos. Os campos são o ponto de partida (alterar fórmula, não recriar) | `sf sobject describe -s Lead`; `sf project retrieve start -m CustomField:Lead.PriorityScore__c` e `...PriorityBand__c` (temp) |
| `Opportunity.PriorityScore__c` e `Opportunity.PriorityBand__c` | Existem, mesma estrutura. Score: Probabilidade x 0,4 + Valor>0 20 + Fechamento até 60 dias 20 + Origem 20; encerrada = 0. Faixa: Alta, Média, Baixa, "Encerrada" | Não: pesos e rótulos antigos | idem, objeto Opportunity |
| Equivalência org x repositório | Fórmulas iguais ao `force-app` da branch (diferem só no escape XML). Na `Opportunity.PriorityScore__c` a precisão no retrieve da org é 18 e no repositório é 3; não investiguei | Informativo | `diff` entre o retrieve e `force-app/main/default/objects/*/fields/Priority*` |
| List views da demanda | Lead `Leads_Abertos_Prioridade` (colunas score e faixa); Opportunity `Oportunidades_Abertas_Prioridade` e `Oportunidades_Prioridade_Alta` (esta filtra `PriorityBand__c equals Alta`) | Ajustar: o filtro "Alta" deixa de existir com AA/A | `grep` em `force-app/.../listViews` (repositório; não reconsultei na org) |
| Layouts e páginas | `Lead-Lead Layout` e `Opportunity-Opportunity Layout` com 2 referências aos campos cada; `Lead_Record_Page` e `Opportunity_Record_Page` com 4 | Reaproveitar; rótulos de campo não mudam | `grep -c` em `force-app` (repositório) |
| Permission set | `PS_Comercial_ScorePrioridade` com FLS de leitura dos 4 campos | Reaproveitar; mesmos API names | `grep` no `permissionset-meta.xml` do repositório |
| Classificação atual AA/A/B/C/D | **`Lead.Rating` ("Classificação", padrão) e `Account.Rating` têm as picklists `AA`, `A`, `B`, `C`, `D`**, os mesmos rótulos que o cliente pediu para as faixas. Não achei Flow nem trigger em Lead que grave `Rating` (Lead tem só 1 Flow, de atribuição, e 0 trigger). Quem escreve `Account.Rating` não foi apurado | Informativo para "validar compatibilidade com a classificação atual". Não afirmo que `Rating` seja a classificação a que o cliente se refere | `sf sobject describe -s Lead` / `-s Account` (picklistValues de `Rating`); seção 3 |
| `Account.Ranking__c` (picklist `MP, PP, P, M, G, GG, 3G`) | Classificação da conta por média de compras do ano; gravada pelo Flow agendado a partir de `RankingRange__mdt` (descrição do campo, EPLAST-47). Escala diferente (porte), não é prioridade | Não é score. Citado para o arquiteto não confundir | `sf sobject describe -s Account`; `CustomField.Description` (Tooling) |
| Campo Einstein | `Opportunity.Previs_o_Eintein__c` (double, sem descrição). Cliente: "a validar; não aposentar". Quem o alimenta segue desconhecido | Não tocar | Tooling `CustomField`; recon anterior |
| Padrão de parâmetro configurável | Custom metadata já usada na conta: `RankingRange__mdt` (`Ranking__c`, `SortOrder__c`, `UpperLimit__c`), `AlertaOportunidadeParadaSetting__mdt` (`Ativo__c`, `DiasSemAcompanhamento__c`, `NotificarGestor__c`, `RegraParada__c`, `DataCargaInicial__c`) e `ScheduledFlowOpportunitySetting__mdt` (citado pelo Flow `Opportunity_AfterSave_ClassificaConta`; não descrevi) | Candidato ao pedido "parâmetros configuráveis sem deploy" | `sf sobject describe -s <tipo>__mdt`; retrieve dos Flows |
| SFAgent2 | Existe (recon de 15/11: 4 tópicos e 3 ações, só em `insights_comerciais`: `ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta`). Nenhuma ação lê score. Não repeti nesta sessão | Não é pedido de assistente; sem extensão | recon de 15/11 (`GenAiPlannerBundle:SFAgent2_v4`) |
| Relatórios/painéis | Sem relatório de score na org; os de medição citados na análise seguem valendo. EPLAST-42 e 43 têm relatórios novos que usam `Lead.PriorityBand__c` (seção 6) | Ver seção 6 | `git grep` nas branches `origin/feature/EPLAST-4x` |

## 2. Critério a critério: qual campo representa na org

Esta é a lista pedida pelo desenho. "Confirmado" = o campo existe por `sf` e a descrição ou o contexto na org diz que representa o critério. "Candidato" = existe, mas a org não prova que representa o critério; não decidi por similaridade de nome. "Sem campo" = nada achado.

**Lead (peso máximo)**

| Critério (peso) | Campo na org | Situação | Prova |
|---|---|---|---|
| Potencial de compra mensal (30) | Nenhum em Lead. Existe `Account.VolumeByMonth__c` ("Volume/Mês", sem descrição), mas é da Conta e Lead não lê Account em fórmula. `Lead.AnnualRevenue`, `NumberOfEmployees` e `Industry` são padrão e não medem compra mensal | **Sem campo** em Lead | `FieldDefinition` por rótulo (Lead e Opportunity, 13 termos); `describe` de Lead e Account |
| Aderência da demanda ao portfólio (25) | Nenhum. `Lead.Sector__c` ("Setor") e `Subsector__c` ("Subsetor") existem, mas sem descrição: não provam aderência a portfólio | **Sem campo** (Setor é candidato, não confirmado) | idem; Tooling `CustomField.Description` |
| Prazo previsto para a primeira compra (20) | Nenhum | **Sem campo** | idem |
| Engajamento: resposta, reunião, solicitação de cotação (15) | `Lead.MKT_MC_Engajamento__c` (picklist `Sem engajamento`, `Baixo`, `Médio`, `Alto`) e `MKT_MC_EngajamentoData__c` (datetime). Descrição: "Engajamento devolvido pelo Marketing Cloud. Nao editar a mao." Mede engajamento do Marketing Cloud, não reunião nem pedido de cotação | **Candidato parcial**: existe e é o retorno do Marketing Cloud (EPLAST-45); não cobre "reunião" nem "cotação". Task/Event: 0 registros, sem como medir atividade | `sf sobject describe -s Lead` (descrição e picklist); `COUNT()` de Task e Event |
| Cadastro qualificado e contato com o decisor (10) | `CompanyDocument__c` (CNPJ), `CompanyName__c`, `Title` (padrão), contatos (`Email`, `Phone`, `MobilePhone`, `WhatsApp__c`). Nenhum marca "decisor" ou "cadastro qualificado" | **Sem campo** para "decisor"; "cadastro qualificado" é regra a definir, não campo | `describe` de Lead |

**Opportunity (peso máximo)**

| Critério (peso) | Campo na org | Situação | Prova |
|---|---|---|---|
| Estágio comercial com evidências de avanço (25) | `StageName` (13 valores: Qualificação, Análise Técnica, Precificação, Qualificado, Cotação, Execução técnica do projeto, Envio Cotação, Amostra, Análise Fiscal, Análise Financeira, Negociação Comercial, Fechado/Ganho, Fechado/Perdido). Evidências: `Discovery_Completed__c`, `Budget_Confirmed__c`, `ROI_Analysis_Completed__c` (booleans, sem descrição). O Flow `Opportunity_BeforeSave_QualificaOportunidade` (EPLAST-40) já usa `Discovery_Completed__c` e `Budget_Confirmed__c` para promover Qualificação a Qualificado | **Confirmado** para estágio; **evidências: confirmado para Discovery e Budget** pelo uso no Flow da EPLAST-40; `ROI_Analysis_Completed__c` é candidato (sem uso nem descrição). A tabela estágio x pontos não existe na org: é decisão do design | describe; retrieve do Flow (descrição e `<field>`) |
| Interação recente e próximo passo confirmado (20) | `LastActivityDate` ("Última atividade", date), `NextStep` ("Próxima etapa", string), `LastStageChangeDate`, `LastStageChangeInDays`, `HasOpenActivity`, `HasOverdueTask` (padrão). `NextStep` é texto livre: dá "preenchido", não "confirmado" | **Confirmado que os campos existem**; "interação" e "próximo passo preenchido" são mensuráveis, "confirmado" não. Task/Event: 0 registros na dev | `sf sobject describe -s Opportunity` |
| Prazo de compra confirmado pelo cliente (20) | `CloseDate` (padrão). Nenhum campo "prazo confirmado" | **Candidato** (`CloseDate` é previsão do vendedor, não confirmação do cliente); sem campo de confirmação | describe; busca por rótulo |
| Margem em relação à política comercial (20) | Nenhum em Opportunity. `SBQQ__QuoteLine__c.SBQQ__GrossProfit__c` ("Lucro bruto", CPQ) existe na linha da cotação; nenhum campo de política de margem foi achado. Não há campo de margem agregado na Opportunity | **Sem campo** em Opportunity; sem política de margem na org | `FieldDefinition` em `SBQQ__Quote__c`, `SBQQ__QuoteLine__c`, `OpportunityLineItem`, `Quote`, `Product2`, `Account` |
| Disponibilidade e viabilidade de atendimento (15) | Nenhum. As validation rules `FinancialAnalysis` e `TaxAnalysis` e os campos `FinancialAnalysis__c`/`TaxAnalysis__c` (booleans, sem descrição) são análise financeira e fiscal, não viabilidade de atendimento | **Sem campo** (não inferido) | describe; lista de validation rules (seção 3) |

Resumo: com campo confirmado ou candidato razoável existem hoje só estágio com evidências (Discovery e Budget), interação e próximo passo (parcial), prazo (`CloseDate`, candidato) e engajamento do Marketing Cloud (parcial). Os demais critérios não têm campo; pela regra do desenho, ficam com 0 ponto e entram na lista "depende de campo a criar ou preencher".

## 3. O que será tocado

| Objeto | Componente | Tipo | Descrição? | Prova |
|---|---|---|---|---|
| Lead | `PriorityScore__c`, `PriorityBand__c` (alterar fórmula e texto) | Number fórmula, Text fórmula | Sim (citam os pesos antigos; precisam ser reescritas) | retrieve (temp) |
| Opportunity | `PriorityScore__c`, `PriorityBand__c` | idem | Sim (idem) | retrieve (temp) |
| Lead | `Sector__c`, `Subsector__c`, `LeadSource`, `Status`, `MKT_MC_Engajamento__c` (leitura) | picklists | `Sector__c` e `Subsector__c` sem descrição | Tooling `CustomField.Description` |
| Opportunity | `StageName`, `Discovery_Completed__c`, `Budget_Confirmed__c`, `ROI_Analysis_Completed__c`, `LastActivityDate`, `NextStep`, `CloseDate` (leitura) | padrão e custom | 3 booleans sem descrição | idem |
| Lead | **`MKT_Nutricao_ProntoAbordagem__c`** (fórmula da EPLAST-45) | Checkbox fórmula, na org | Sim | retrieve: `AND(MKT_Nutricao_Elegivel__c, PriorityBand__c = "Alta")` |
| Opportunity | list view `Oportunidades_Prioridade_Alta` (filtro `Alta`) | list view | n/a | repositório |

**Quebra a tratar no desenho.** A fórmula `Lead.MKT_Nutricao_ProntoAbordagem__c` compara a faixa com o texto literal `"Alta"`. Com o rótulo novo (AA, A, ...), ela passa a ser sempre falsa. Ela alimenta a list view `Leads_Prontos_Abordagem` e os relatórios de nutrição da EPLAST-45. O mesmo vale para o filtro `Alta` da list view de Opportunity desta demanda. Os relatórios das EPLAST-42 e 43 filtram `PriorityBand__c notEqual "Sem dados suficientes"`; o novo "Não classificado" muda esse resultado.

### Preparação do Sales Cloud para o Marketing Cloud (o que a org mostra)

| Fato | Resultado | Prova |
|---|---|---|
| Conector `et4ae5` | Instalado, 264.1.0.1; `MCCA5PROD` também (recon de 15/11, não repeti) | `sf package installed list` |
| Campos `et4ae5` em Lead | `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c` | `describe -s Lead` (esta sessão) |
| Campos de retorno do Marketing Cloud em Lead | `MKT_MC_Engajamento__c`, `MKT_MC_EngajamentoData__c` (não editar à mão) | `describe -s Lead` |
| Lead pronto para nutrição | `MKT_Nutricao_Elegivel__c` (`NOT(IsConverted)` e Status Aberto - Não contatado ou Contatado) e `MKT_Nutricao_ProntoAbordagem__c` | retrieve (temp) |
| Opt-out de e-mail | `Lead.HasOptedOutOfEmail` (padrão) | repositório (`force-app`, `objects/Lead/fields`) |

Nada foi feito no Marketing Cloud.

## 4. Automação concorrente e ordem de execução

Fórmula não grava nem dispara automação, então o score continua fora da ordem de execução se o design mantiver fórmula. O mapa abaixo é para o caso de o design gravar algo ou criar objeto de parâmetro.

### Lead

| Componente | Tipo | Evento | Prova |
|---|---|---|---|
| `Lead_AfterInsert_AplicaRegraAtribuicao` | Flow, RecordAfterSave, Create (EPLAST-35); só entra com a custom permission `Lead_DistribuicaoAutomaticaViaApi` | after insert | `FlowDefinitionView` + retrieve |
| ApexTrigger | 0 | | Tooling `ApexTrigger` |
| Validation rules | `Celular`, `Telefone` (ativas) | before save | Tooling `ValidationRule` |

### Opportunity

| # | Componente | Tipo | Evento | Prova |
|---|---|---|---|---|
| 1 | `OpportunityBefore` (SBQQ) | ApexTrigger | before insert, before update | Tooling `ApexTrigger` (agora com eventos) |
| 2 | `Opportunity_BeforeSave_QualificaOportunidade` | Flow, RecordBeforeSave, CreateAndUpdate (EPLAST-40); grava `StageName` | before save | `FlowDefinitionView` + retrieve |
| 3 | 16 validation rules ativas (`CheckAccountHasBillingAddress`, `CheckAccountHasCNAE`, `CheckAccountHasCompanyName`, `CheckAccountHasEmail`, `CheckAccountHasPhone`, `CheckAccountHasStore`, `CheckAccountOwnerHasProtheusSellerId`, `CheckHasAccount`, `CheckOppHasBranch`, `CheckOppHasPaymentMethods`, `CheckOppHasPaymentTermId`, `FinancialAnalysis`, `LossReason`, `PriceBook`, `TaxAnalysis`, `Industria_Fase_Cotacao_Sem_Catalogo`) | ValidationRule | before save | Tooling `ValidationRule` (lista completa agora) |
| 4 | `OpportunityTrigger` (custom, sem namespace) | ApexTrigger | after insert, after update | Tooling `ApexTrigger` |
| 5 | `OpportunityAfter` (SBQQ) | ApexTrigger | after insert, after update | idem |
| 6 | `Oportunidade_Industria` ("Oportunidade Indústria") | Flow, RecordAfterSave, Update | after save | `FlowDefinitionView` |
| 6 | `OpportunityFlow` ("Fluxo Oportunidade") | Flow, RecordAfterSave, CreateAndUpdate | after save | idem |
| 6 | `Opportunity_AfterSave_ClassificaConta` (EPLAST-47; grava `Account.Ranking__c`, `IntegrationLog__c`) | Flow, RecordAfterSave, CreateAndUpdate | after save | idem + retrieve |
| 6 | `Opportunity_AfterSave_CriaCasoPosVendas` (cria Case) | Flow, RecordAfterSave, CreateAndUpdate | after save | idem + retrieve |
| agendado | `Opportunity_Scheduled_AlertaParada` (EPLAST-28; só `IntegrationLog__c`) | Flow, Scheduled | diário | idem + retrieve |

Ordem padrão da plataforma aplicada a essa lista (não executei nada): before triggers e before-save Flows, validação, triggers after, Flows after-save. O Salesforce não garante ordem entre os 4 Flows after-save, nem entre `OpportunityBefore` e o Flow before-save. Em Opportunity, o Flow `Opportunity_BeforeSave_QualificaOportunidade` grava `StageName`: se o score usa `StageName`, a fórmula já lê o valor promovido.

## 5. Volume e dados de teste

| Objeto | Contagem | Comando |
|---|---|---|
| Lead | 0 | `sf data query -q "SELECT COUNT() FROM Lead"` |
| Opportunity | 0 | idem, `Opportunity` |
| Account | 0 | idem, `Account` |
| Task / Event | 0 / 0 | idem |

A dev não tem dado nenhum nesses objetos: todo teste usa registro sintético, pelas fixtures (`fixtures/README.md`), com desvio `TriggerUtility.bypassTrigger` para Account. Sem histórico, nenhum peso pode ser calibrado agora. Não consultei o usuário de teste da regra 6 (o design define se usa).

## 6. Sobreposição com outras demandas (preflight) e consumidores dos campos

| Demanda | Estado | Componente em comum | O que isso pede ao design |
|---|---|---|---|
| EPLAST-30 | aguardando_homologacao | `flexipages/Opportunity_Record_Page` (campo `PriorityBand__c` no card, `Record.PriorityBand__c` na linha 378 da branch dela) | Não alterar a página no lugar; o rótulo do campo não muda, só os valores |
| EPLAST-35 | design | `layouts/Lead-Lead Layout` | Não editar no lugar; mudança só se o design exigir campo novo no layout |
| EPLAST-38 | aguardando_homologacao | `layouts/Lead-Lead Layout` | idem |
| EPLAST-40 | aguardando_gate_build | `layouts/Opportunity-Opportunity Layout`; também é dona do Flow `Opportunity_BeforeSave_QualificaOportunidade` | Se o score ler `Discovery_Completed__c` e `Budget_Confirmed__c`, depende do significado definido ali |
| EPLAST-41 | aguardando_homologacao | `layouts/Opportunity-Opportunity Layout` | Não editar no lugar |
| EPLAST-45 | aguardando_homologacao | `permissionsets/PS_Comercial_ScorePrioridade`; também dona de `MKT_Nutricao_ProntoAbordagem__c`, `Leads_Prontos_Abordagem` e relatórios `NUTRICAO_LEADS_*` | **Quebra direta** por `"Alta"` literal (seção 3). Mudar a fórmula dela exige coordenar com a EPLAST-45 |
| EPLAST-42, 43 | fora do preflight | Relatórios `LEADS_PROSPECCAO_PRIORIDADE` e `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` agrupam por `Lead.PriorityBand__c` e filtram `notEqual "Sem dados suficientes"`; `PS_Marketing_Publicos` dá leitura de `Lead.PriorityBand__c` | Impacto de "Não classificado". Achado por `git grep` nas branches remotas; não confirmei se estão na org |
| EPLAST-44 | fora do preflight | Relatório `LEADS_BOAS_VINDAS` usa a coluna `PriorityBand__c` | Só coluna; sem filtro por valor |
| EPLAST-28, 39 | não conferi | A análise prevê que consumam o score | `PriorityBand__c` não aparece em `force-app` das branches 28 e 39 que busquei. Nada a ajustar até ver o contrário |

Prova: `git grep -n "PriorityBand__c"` nas branches `origin/feature/EPLAST-<n>`, em `clients/eplast/force-app`. É leitura do repositório, não da org. Nenhum desses componentes foi alterado.

## 7. Permissões

| Fato | Resultado | Prova |
|---|---|---|
| OWD | Lead: interno `ReadWriteTransfer`, externo `Private`. Opportunity: interno `Read`, externo `Private` (recon de 15/11) | Tooling `EntityDefinition` |
| FLS dos campos de score | `PS_Comercial_ScorePrioridade` dá leitura dos 4 campos (repositório). Fórmula é somente leitura por natureza | `grep` no permissionset |
| Perfis com leitura em Lead e Opportunity | Lista no recon de 15/11 (`Comercial`, `Comercial Padrão`, `Comercial - Analista`, `Comercial - Analistas`, `Financeiro`, etc.); não repeti | `ObjectPermissions` |
| Leitura de `Lead.PriorityBand__c` por Marketing | `PS_Marketing_Publicos` (branches 42 e 43) | `git grep` |

## O que não consegui confirmar

1. **Se os campos que o cliente cita têm outro nome ou vivem noutro objeto.** A busca foi por rótulo (Lead, Opportunity) e por palavras-chave em outros 6 objetos, em `FieldDefinition`. Pode haver campo com rótulo diferente que escapou, ou dado em objeto que não consultei (ex.: produto ou cotação). Por isso "sem campo" na seção 2 vale como "não achei".
2. **Se `Lead.Rating` é a "classificação atual" do cliente**, quem o grava e se `Account.Rating` é mantido por alguma automação. Só vi que as picklists têm AA, A, B, C, D.
3. **O que `Previs_o_Eintein__c` guarda e quem o alimenta** (sem descrição, 0 registros, sem Flow ou Apex encontrado).
4. **Significado de `ROI_Analysis_Completed__c`, `Discovery_Completed__c`, `Budget_Confirmed__c`** além do uso do Flow da EPLAST-40; nenhum tem descrição. `Discovery` e `Budget` estão confirmados só pelo uso no Flow.
5. **Se a org tem os relatórios e list views das EPLAST-42, 43, 44 e 45.** Vi o `MKT_Nutricao_ProntoAbordagem__c` na org, mas os relatórios, as list views e o permission set `PS_Marketing_Publicos` só li nas branches remotas.
6. **Estado das list views da EPLAST-26 na org.** Li o repositório, não consultei `ListView` na org nesta sessão.
7. **Ordem real de execução** entre os triggers e os 4 Flows after-save de Opportunity: é a ordem padrão da plataforma, não medida. Corpo atual de `OpportunityTrigger` não baixado.
8. **`ScheduledFlowOpportunitySetting__mdt`**: só o Flow o referencia; não descrevi o tipo. E `Opportunity.IqScore` aparece no `force-app`, mas a consulta `FieldDefinition` não o retornou; não o uso.
9. **Cobertura Apex** das classes de Opportunity, **SFAgent2 na QA** e **dev distinta de QA** (resolvido pela regra 5 do cliente): não repeti nesta sessão.
10. **Precisão `18` x `3`** de `Opportunity.PriorityScore__c` entre org e repositório: não apurei a causa.
