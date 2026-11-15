# EPLAST-40: Design. Ciclo Marketing → SDR → Comercial → Pós-vendas

**Solução:** declarativa (configuração + 2 Flows novos), sem Apex. O ciclo usa os estágios e campos padrão que já existem (`Lead.Status`, conversão padrão do Lead, `Opportunity.StageName`, `Case`). Só duas regras pedem automação. A promoção `Qualificação` → `Qualificado` é um Flow before-save em Opportunity que muda o próprio registro sem DML. A criação do Case de Pós-vendas é um Flow after-save em Opportunity com caminho assíncrono, que grava apenas em Case. Configuração pura não resolve nenhuma das duas: validation rule e Path barram ou orientam, mas não avançam estágio nem criam registro. Apex não se justifica, porque não há callout, rollback complexo, recursão nem volume que um Flow não aguente (critérios da skill `salesforce-doutrina`).

**Impacto na org:** baixo a médio. Não altera nenhum Flow, trigger, classe, validation rule nem picklist existente. Cria 1 campo de relacionamento novo em Case (**mudança de modelo de dados: decisão do arquiteto humano neste gate**, ver seção 2), 1 fila, 2 Flows, 1 permission set e 1 list view, e acrescenta uma related list aos layouts de Opportunity. O risco está em Opportunity, o objeto com mais automação concorrente da org (seção 5).

**Bloqueio (caso 3 da regra 4):** nenhum.

**Org:** `sbx-eplast-dev` (Sandbox, Org ID `00DHa000006vfMLMAY`), conferida por `sf org list` em 2026-11-15. Só leitura nesta etapa. Confirmações novas desta etapa (além do `02-recon.md`): fórmulas das 16 validation rules de Opportunity (retrieve em `/tmp/arq40`, fora do repositório), `LeadStatus` convertido, ausência de valor padrão em `StageName`, record type padrão de Opportunity, campos de Case, `Opportunity.ContactId`, ausência de fila e de permission set de Pós-vendas, critérios de entrada de `OpportunityFlow`, `Oportunidade_Industria` e `Order`.

---

## 1. Componentes, item a item (regra 3)

### Reaproveita, sem alterar

| Peça | Uso no ciclo | Confirmação |
|---|---|---|
| `Lead.LeadSource` (13 valores) | Entrada pelo Marketing (RN1, P1) | recon, describe |
| `Lead.Status`: `Aberto - Não contatado` (padrão), `Contatado`, `Fechado - Convertido` (`IsConverted=true`), `Fechado - Não convertido` | Estágios do SDR (RN2) | `LeadStatus` nesta etapa |
| Conversão padrão do Lead, com `Lead.ConvertedDate` e `Lead.ConvertedOpportunityId` (campos padrão) | Passagem SDR→Comercial e o registro dela (RN3, PD1) | campos padrão da plataforma |
| Regra `Distribuicao_Regional_Leads` + Flow `Lead_AfterInsert_AplicaRegraAtribuicao` + classe `LeadAssignmentService` | Dono do Lead | recon |
| 8 filas de Lead (`Leads_CO` … `Leads_Triagem`) | Dono do Lead | recon |
| `PriorityScore__c`, `PriorityBand__c` (Lead e Opportunity) | Priorização do SDR e da Comercial, sem mudança | recon; EPLAST-26 |
| `Opportunity.StageName` (13 valores), `Discovery_Completed__c`, `Budget_Confirmed__c` | Estágios e critério de qualificação (RN4) | recon |
| Flow `Order` (em Order) que leva a Oportunidade a `Fechado/Ganho` | Gatilho da passagem para Pós-vendas | recon |
| `Case` padrão (`Status` `New`, record type `Mestre`), `Case.CreatedDate` | Registro de Pós-vendas e data da passagem (RN5, PD2) | describe nesta etapa |
| `Opportunity.ContactId`, `Opportunity.AccountId` | Copiados para o Case | describe nesta etapa |
| Campos `et4ae5__*` e `HasOptedOutOfEmail` | Lidos pelo Marketing Cloud, nunca escritos pela entrega | recon |
| `SFAgent2` | Não se aplica: a demanda não pede assistente, resumo, recomendação nem linguagem natural | recon |

### Cria

| API name | Tipo | O que faz | Descrição obrigatória |
|---|---|---|---|
| `Case.Oportunidade__c` | Lookup(Opportunity), opcional, `deleteConstraint` = SetNull, rótulo "Oportunidade", related list "Casos de Pós-vendas" | Liga o Case à Oportunidade ganha. Serve para rastrear o ciclo e para impedir Case duplicado. **Modelo de dados: aceite do arquiteto humano** | sim |
| Fila `PosVendas` (rótulo "Pós-vendas") | Queue, `QueueSobject` = Case, **sem membros no metadata** | Dona do Case de Pós-vendas (P6) | sim |
| `Opportunity_BeforeSave_QualificaOportunidade` | Flow record-triggered, before-save (Fast Field Update), Create e Update, nasce Active (Flow novo) | Entrada: `StageName = Qualificação` E `Discovery_Completed__c = true` E `Budget_Confirmed__c = true`. Ação: `StageName = Qualificado`. Sem consulta e sem DML | sim |
| `Opportunity_AfterSave_CriaCasoPosVendas` | Flow record-triggered, after-save, Create e Update, nasce Active (Flow novo) | Entrada: `StageName = Fechado/Ganho`, só quando o registro **passa** a atender a condição. Tudo roda no **caminho assíncrono** (*Run Asynchronously*). Consulta 1 Case com `Oportunidade__c = $Record.Id`; se não houver, consulta a fila pelo `DeveloperName` `PosVendas` (sem Id fixo) e cria o Case: `Oportunidade__c`, `AccountId`, `ContactId` (se houver), `OwnerId` = fila, `Status` = `New`, `Subject` = "Pós-vendas: " + nome da Oportunidade. Caminho de falha: encerra sem afetar a venda (a transação do Order já fechou) | sim |
| `PS_PosVendas_Atendimento` | Permission Set | Leitura de `Case.Oportunidade__c` e leitura de Opportunity. Não dá acesso a objeto além do que os perfis já dão | sim |
| List view `Case.PosVendas_Fila` | ListView | Casos com dono = fila `PosVendas`, abertos | n/a |

### Altera (metadata existente, sem versão de Flow, agente ou classe)

| Peça | Alteração | Observação |
|---|---|---|
| Page layouts de Opportunity em uso pelos 6 record types | Acrescentar a related list "Casos de Pós-vendas" (`Oportunidade__c`) | O builder descobre os layouts atribuídos por retrieve de `Layout`/atribuição e lista no plano quais alterou. Não é Flow, agente nem classe, então a regra de versão nova não se aplica. Rollback = reimplantar o layout anterior |

### Altera com versão nova

Nenhum. Nenhum Flow, agente ou classe ativo é alterado. `OpportunityFlow`, `Oportunidade_Industria`, `Order`, `OpportunityTrigger`, `OrderTrigger` (custom), `SBQQ.*` e `Lead_AfterInsert_AplicaRegraAtribuicao` continuam como estão.

### Não cria (e por quê)

- **Campo de data de passagem SDR→Comercial em Opportunity (desvio de RN3/P8).** `Lead.ConvertedDate` já grava a data da conversão, e `Lead.ConvertedOpportunityId` liga o Lead à Oportunidade. Gravar a data na Oportunidade obrigaria um Flow em Lead (after update de `IsConverted`) a fazer **um update extra em Opportunity**, o objeto mais concorrido da org. Esse update dispararia de novo `OpportunityFlow`, que roda sem critério de entrada, cria Quote/Order/Task e consulta Account a cada save, além de `Oportunidade_Industria`, `OpportunityTrigger` (Queueable) e os triggers `SBQQ`. Reaproveitar o campo padrão é mais seguro (regra 3). Ver PD1.
- **Campo de data de passagem para Pós-vendas em Case (desvio de P8).** O Case de Pós-vendas nasce na passagem, então `Case.CreatedDate` é a data da passagem. Ver PD2.
- Estágio, status ou picklist nova (P2), objeto customizado, Apex, relatório ou painel. Não há relatório novo, então não há sobreposição a checar em `Report`/`Dashboard` (item 10 do recon fica sem efeito).

## 2. Decisão de arquitetura para o aceite humano (modelo de dados)

O Case padrão não tem relacionamento com Opportunity (describe: `Opportunity` não tem relação filha com Case). O critério "existe exatamente 1 Case de Pós-vendas para essa Oportunidade" e o objetivo de "rastrear do Marketing ao Pós-vendas sem consulta fora da org" pedem esse vínculo.

| Opção | Prós | Contras |
|---|---|---|
| **A (recomendada): lookup `Case.Oportunidade__c`** | Navegação nos dois sentidos (related list), base para relatório, checagem de duplicidade simples no Flow | É relacionamento novo (modelo de dados). O critério aprovado dizia "campos novos são somente os de data de passagem e a fila": troca dois campos de data por um lookup |
| B: campo texto `OportunidadeRef__c` único (External ID) com o Id da Oportunidade | O banco impede duplicata | Não navega, não aparece como related list e fica pior para relatório e para o Marketing Cloud |
| C: sem campo, Case ligado só à Conta | Nenhum campo novo | Não garante 1 Case por Oportunidade, não rastreia a venda e reprova o critério |

**Pedido ao arquiteto humano:** aceitar a opção A, junto com os desvios PD1 e PD2, que alteram a leitura literal dos critérios "data de passagem preenchida" e "campos novos são somente…". Se preferir manter os campos de data da análise, o design muda assim: +1 campo `Case.DataPassagemPosVendas__c`, preenchido no mesmo Create, sem custo adicional; +1 campo em Opportunity e +1 Flow em Lead para a data SDR→Comercial, com o risco de concorrência descrito na seção 1.

## 3. Fluxo do ciclo resultante

| Etapa | Estágio no CRM | Dono | Passagem e registro dela |
|---|---|---|---|
| Marketing | Lead `Aberto - Não contatado`, `LeadSource` de marketing | Fila regional (regra existente) | Lead criado pelo Marketing Cloud ou pela integração; o Marketing Cloud nutre |
| SDR | Lead `Contatado` | Dono do Lead | Manual: o SDR muda o status (sem automação) |
| SDR→Comercial | Lead `Fechado - Convertido` → Oportunidade | Dono definido na conversão | Conversão padrão; `Lead.ConvertedDate` e `ConvertedOpportunityId` |
| Comercial | `Qualificação` → `Qualificado` (automático com os 2 checkboxes) → … → `Fechado/Ganho` (Flow `Order`) | Dono da Oportunidade | `Opportunity_BeforeSave_QualificaOportunidade` |
| Comercial→Pós-vendas | Case `New` | Fila `PosVendas` | `Opportunity_AfterSave_CriaCasoPosVendas`; `Case.CreatedDate` e `Case.Oportunidade__c` |

## 4. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca lead, origem, nutrição, segmentação e relacionamento pós-venda (regra 2). **Nada é feito no Marketing Cloud e nada é enviado pelo CRM.** Nenhum Flow desta entrega tem e-mail alert, ação de envio ou Apex de e-mail.

- **Dados que o Marketing Cloud lê e onde ficam:**
  - `Lead`: `LeadSource`, `Status`, `IsConverted`, `ConvertedDate`, `Sector__c`, `PriorityBand__c`, `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c`.
  - `Contact`: os mesmos campos de opt-out (`HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c`), já existentes (recon).
  - `Opportunity`: `StageName`, `Type` (`Nova Compra`, `Compra Recorrente`, `Reativação`), `ContactId`.
  - `Case`: `Status`, `Oportunidade__c`, `ContactId`, `CreatedDate`. Servem ao público de relacionamento pós-venda, porque o Case leva o `ContactId` da Oportunidade quando houver.
- **Como o público fica identificável no CRM:** por filtro de campo, sem campanha nova. Nutrição de marketing: Leads com `Status = Aberto - Não contatado`, `LeadSource` de marketing e sem opt-out. Em atendimento pelo SDR: `Status = Contatado`. Pós-venda: Contatos dos Cases com `Oportunidade__c` preenchido. `Campaign`/`CampaignMember` continuam sem uso nesta entrega, como na EPLAST-33 (`[demandas/EPLAST-33/03-design.md]`).
- **O que o Marketing Cloud devolve e onde fica:** esta entrega não grava retorno. `CampaignMember.et4ae5__Activity__c` pertence ao conector, e a forma como é preenchido não foi verificada (incerteza herdada do recon). Retorno de engajamento no Lead é demanda própria com quem opera o Marketing Cloud.
- **Consentimento e opt-out:** os dois Flows não leem nem escrevem campo de opt-out. O teste confere que eles ficam iguais antes e depois do ciclo. Quem opera o Marketing Cloud aplica o opt-out ao montar o público.
- **Para quem opera o Marketing Cloud:** sincronizar Lead, Contact e, se quiser o público pós-venda, Case (decisão dele, pelo conector); montar os públicos pelos filtros acima; criar jornadas e envios; aplicar o opt-out.

## 5. Ordem de execução e concorrência

### Opportunity (risco alto, achado 1 do assessment)

Em um save de Opportunity, a ordem é a da skill: before-save Flows → before triggers → validation rules → gravação → after triggers → after-save Flows → commit → assíncrono.

1. **`Opportunity_BeforeSave_QualificaOportunidade`** é o **único before-save Flow** em Opportunity (o recon não encontrou outro ativo) e roda antes de `SBQQ.OpportunityBefore`. Por mudar o próprio registro sem DML, não gera save extra nem recursão. Depois dele, o CPQ, as 16 validation rules, `OpportunityTrigger`, `SBQQ.OpportunityAfter`, `OpportunityFlow` e `Oportunidade_Industria` veem `Qualificado` **no mesmo save**, como se o usuário tivesse escolhido o estágio. **Efeito esperado e aceito:** `Oportunidade_Industria` reage à mudança de fase (cria Task) igual a uma mudança manual. **Incerteza:** se `SBQQ.OpportunityBefore` reescreve `StageName`, o resultado do Flow se perde. O CPQ não costuma fazer isso, mas não foi lido (pacote gerenciado). A verificação prova pelo estágio gravado.
2. **`Opportunity_AfterSave_CriaCasoPosVendas`** roda **no caminho assíncrono**, depois do commit da transação que fechou a venda (em geral a do Flow `Order`, que pode envolver `OrderTrigger` custom → `sendOrderToProtheus` e `SBQQ.OrderTrigger`). Assim: (a) erro na criação do Case **não desfaz** a Order nem o `Fechado/Ganho`; (b) a ordem entre os after-save Flows de Opportunity, que não têm `triggerOrder` definido, não importa para ele; (c) não escreve em Opportunity, então não redispara nada nela. O Case não tem trigger, Flow record-triggered nem validation rule (recon), então a gravação não tem concorrência.
3. **Reentrada:** o `OpportunityTriggerHelper` (Queueable, não lido) pode atualizar a Oportunidade de novo depois do fechamento. A entrada "só quando passa a atender" e a consulta de Case existente impedem um segundo Case.
4. **`OpportunityFlow` roda em todo create/update, sem critério de entrada** (confirmado no XML). Esta entrega não acrescenta update em Opportunity, o que pesou nos desvios PD1/PD2.

### Lead

Nenhuma automação nova. A conversão dispara a automação de Opportunity acima, como já acontece hoje.

### Order

Não é tocada. A verificação só confere que a contagem de Orders da Oportunidade não muda.

### Volume e CPU (dois cenários da skill)

- **Carga em massa:** uma atualização de Orders em lote (integração Protheus) leva N Oportunidades a `Fechado/Ganho`. O caminho assíncrono roda agrupado pelo motor de Flow: 2 consultas e 1 inserção por lote, não por registro, num contexto com 60 s de CPU. O before-save não consulta nem grava. Volume real desconhecido (dev com 0 registros; QAS não consultada). A verificação usa 200 Oportunidades sintéticas.
- **Um pai com muitos filhos:** nenhum Flow novo é disparado por filho (OrderItem, Task, Quote). Uma Order com muitos itens provoca **um** update de Opportunity pelo Flow `Order` e, portanto, uma única interview do Flow de Case. O custo dominante continua sendo o que já existe (`OpportunityFlow` sem critério). A verificação mede a CPU de um fechamento de Order com 150 itens antes e depois dos Flows novos. Se o acréscimo passar de 70% do limite, o design volta para revisão.

## 6. Riscos do assessment e da org: como o design lida

| # | Risco | Severidade | Como o design lida |
|---|---|---|---|
| A1 | **Automação concorrente em Opportunity e Order** (assessment, achado 1) | alta | Nenhuma automação existente é alterada. Before-save sem DML; after-save assíncrono que só grava em Case. Detalhe na seção 5 |
| A2 | Cobertura Apex de 10% (achado 2) | média | Não há Apex novo. O deploy de Flow em sandbox não exige cobertura. Regressão: rodar no build `FlowOpportunityControllerTest` e as demais classes de teste que criam Opportunity, porque a promoção automática pode mudar o estágio esperado em teste existente |
| A3 | Validation rules de Order (achado 3; dev tem 17 ativas) | baixa | Order não é escrita. Se a fixture de fechamento esbarrar nelas, é ajuste de fixture, não de regra |
| A4 | Colisão de nome `OrderTrigger` (achado 5 do assessment) | baixa | Não tocado. Artefatos citam `OrderTrigger` (custom, sem namespace) e `SBQQ.OrderTrigger` pelo nome completo |
| A5 | Campos sem descrição (achado 4) | baixa | Todo componente novo leva descrição. `Discovery_Completed__c`/`Budget_Confirmed__c` são só lidos |
| A6 | Alias com "qa" na dev (achado 6) | n/a | Resolvido pela regra 5 da conta |
| R1 | **Validation rules de Opportunity bloqueiam a conversão com Oportunidade** (fórmulas lidas nesta etapa) | **alta para o teste, não para o desenho** | Em todo save, 8 regras exigem dados da Conta: telefone, CNAE, razão social, `Email__c`, loja, endereço de cobrança completo com `BillingNeighborhood__c` e `ProtheusSellerId__c` no dono da Conta. Também em todo save, `CheckHasAccount` exige a Conta. Na criação, `PriceBook` exige, fora do record type `Industria`, um catálogo com `Account__c` igual à Conta. O record type padrão é `Sale` (Venda). **Uma conversão que cria Conta nova ou usa RT Venda sem catálogo tende a falhar hoje, sem relação com esta entrega.** O design não altera essas regras, que são do processo do ERP. Ver PD5 |
| R2 | `Fechado/Ganho` exige `PaymentTermId__c`, `Formas_de_Pagamento__c`, `Branch__c` com `CodeERP__c`, `TaxAnalysis__c` (fora de Indústria) e `FinancialAnalysis__c` (Venda e Venda com remessa) | média (fixture) | A fixture de fechamento preenche tudo isso. O Flow de Case só roda depois que o fechamento passou |
| R3 | Filas sem membros (8 de Lead; `PosVendas` nasce vazia) | média | O Case vai para a fila mesmo sem membro. Membro é pré-requisito de homologação da Eplast, sem username no metadata (LGPD/guardrail 2). Ver PD4 |
| R4 | `SBQQ.OpportunityBefore` reescrever `StageName` | baixa (incerta) | Provado na verificação pelo estágio gravado |
| R5 | Falha na criação do Case passa despercebida | baixa | Caminho assíncrono com caminho de falha. A falha vai para o e-mail de erro de Flow do admin (padrão da plataforma) e não desfaz a venda. A list view da fila mostra o que entrou |

## 7. Permissões

- **Novo:** `PS_PosVendas_Atendimento` (leitura de `Case.Oportunidade__c`; leitura de Opportunity, que já é `Read` no OWD interno). A atribuição aos usuários de Pós-vendas é passo manual da Eplast, junto com os membros da fila.
- **Sem alteração de perfil.** Case tem OWD interno `ReadWriteTransfer`, então quem tem acesso a Case vê os Cases da fila. Os 8 perfis que já criam Case continuam iguais. O admin vê o campo novo pelo perfil.
- **Flows rodam em contexto de sistema** (padrão de record-triggered). Usuário sem o permission set não vê o lookup, mas o Case é criado do mesmo jeito.
- Usuário de teste: `005bJ00000piKAa` (ativo, administrador). Não serve para provar acesso negado por perfil (recon). O caso "usuário sem `PS_PosVendas_Atendimento` não vê o campo" fica para a homologação com usuário de perfil não administrador, se a Eplast indicar um. Perfil e permissão dele não são alterados (regra 6).

## 8. Premissas assumidas (validar na homologação)

Herdadas da análise e mantidas: P1 a P7 de `01-analise.md` (origens de marketing; estágios padrão; passagem = conversão; critério de qualificação com 2 checkboxes; Pós-vendas como Case em `Fechado/Ganho`; fila `Pós-vendas`; sem aviso nem SLA). P8 foi substituída por PD1 e PD2. Premissas novas do design:

- [x] **PD1: onde fica a data da passagem SDR→Comercial.** Pergunta: a data precisa ficar num campo da Oportunidade? Decisão: usar `Lead.ConvertedDate` e `Lead.ConvertedOpportunityId`, campos padrão gravados pela própria conversão, sem campo novo em Opportunity. Evidência: são campos padrão da plataforma; um campo na Oportunidade exigiria update extra em Opportunity, onde `OpportunityFlow` roda sem critério de entrada (XML conferido) e há 4 automações after-save. Como mudar: criar `Opportunity.DataPassagemComercial__c` e um Flow after-update em Lead que o preencha na conversão (seção 2).
- [x] **PD2: data da passagem para Pós-vendas.** Pergunta: precisa de campo próprio? Decisão: usar `Case.CreatedDate` do Case com `Oportunidade__c` preenchido, porque o Case nasce na passagem. Evidência: padrão da plataforma, opção mais simples. Como mudar: acrescentar `Case.DataPassagemPosVendas__c` no mesmo Create do Flow, sem outro impacto.
- [x] **PD3: promoção automática vale para todos os record types de Opportunity.** Pergunta: a regra `Qualificação` → `Qualificado` vale só para algum tipo de venda? Decisão: vale para todos os 6 record types em que o estágio `Qualificação` aparece. Evidência: a picklist é a mesma, e nenhuma validation rule nem Flow da org trata `Qualificado` de forma especial (fórmulas e XML conferidos). Como mudar: acrescentar o filtro de record type na entrada do Flow, em versão nova.
- [x] **PD4: fila `PosVendas` nasce sem membros.** Pergunta: quem atende o Pós-vendas? Decisão: a entrega cria a fila vazia, e a Eplast inclui membros e atribui `PS_PosVendas_Atendimento` antes da homologação. Evidência: não há perfil, papel nem fila de Pós-vendas na org (recon), e as filas de Lead também estão vazias. Username no metadata seria dado pessoal no repositório. Como mudar: membros entram pela tela de filas, sem deploy. O critério "fila tem membro" passa a ser pré-requisito de homologação, conferido na QA e registrado como pendência do cliente, não como defeito de build.
- [x] **PD5: conversão continua sujeita às validation rules atuais.** Pergunta: a conversão deveria contornar as regras de Conta e de catálogo de Opportunity? Decisão: não. As regras são do processo com o ERP, e o design não as muda. A verificação converte o Lead para uma **Conta existente com todos os campos exigidos** e testa com o record type padrão (Venda) e com `Industria`. Se a conversão com Oportunidade for barrada no RT Venda, o achado fica registrado como restrição atual da org e a regra de qualificação continua valendo para a Oportunidade criada pela Comercial. Evidência: fórmulas lidas nesta etapa (seção 6, R1). Como mudar: demanda própria para revisar `PriceBook` e as regras de Conta, com o dono da integração Protheus.
- [x] **PD6: estágio inicial da Oportunidade convertida.** Pergunta: a conversão cria a Oportunidade em `Qualificação`? Decisão: sim, porque `StageName` não tem valor padrão e `Qualificação` é o primeiro valor ativo (describe nesta etapa). Isso só se prova executando a conversão, e a verificação confere. Como mudar: definir o valor padrão da picklist ou o processo de venda do record type.
- [x] **PD7: conteúdo do Case de Pós-vendas.** Pergunta: quais campos o Case leva? Decisão: `Oportunidade__c`, `AccountId`, `ContactId` (quando a Oportunidade tiver), `Status = New`, `Subject` "Pós-vendas: <nome da Oportunidade>". `Origin`, `Type` e `Reason` ficam vazios, porque os valores atuais (`Email`/`Phone`/`Web`; `Problem`/`Feature Request`/`Question`) não descrevem pós-venda e todos aceitam vazio (describe). Como mudar: incluir um valor "Pós-vendas" em `Case.Type` e preenchê-lo no Flow, em versão nova.

## 9. Plano de testes (alto nível)

A massa é sintética, via `fixtures/`, gravada lá quando funcionar. Na dev não há registro. Na QA, só registros criados pelo agente. Dono dos registros: `005bJ00000piKAa`. A fixture preenche **todo campo exigido pelas 16 validation rules de Opportunity e pelas 2 de Lead (`Celular`, `Telefone`)**: Conta completa, dono com `ProtheusSellerId__c` (o verificador ajusta o próprio usuário de execução na dev, sem mexer no usuário de teste) e catálogo com `Account__c`.

1. **Entrada e SDR:** Lead com `LeadSource = E-mail MKT` nasce `Aberto - Não contatado`; a regra de atribuição roda uma vez; a mudança para `Contatado` não cria Oportunidade.
2. **Conversão (fragilidade R1):** converter para Conta existente completa, com RT `Industria` e com RT padrão (Venda). Esperado: Oportunidade em `Qualificação` (PD6), `Lead.ConvertedDate` preenchido, `ConvertedOpportunityId` igual à Oportunidade. Barramento no RT Venda é registrado conforme PD5.
3. **Qualificação:** só `Discovery_Completed__c` → continua `Qualificação`; os dois → `Qualificado` (prova R4). Também com os dois marcados já na criação. Regressão: a Oportunidade Indústria recebe a Task de `Oportunidade_Industria` como numa mudança manual.
4. **Pós-vendas:** fechar a Order sintética até o Flow `Order` levar a Oportunidade a `Fechado/Ganho` (fixture de R2). Esperado: depois do caminho assíncrono, 1 Case com `Oportunidade__c`, dono = fila `PosVendas`, `Status = New`, e a contagem de Orders sem mudança. Reabrir e salvar a Oportunidade de novo não cria segundo Case.
5. **Bulk e CPU (assessment, achado 1):** 200 Oportunidades em lote para `Qualificado` e para `Fechado/Ganho` (200 Cases, nenhum duplicado); fechamento de 1 Order com 150 itens, medindo a CPU antes e depois da ativação dos Flows novos, com o critério de 70%.
6. **Regressão de Apex (achado 2):** rodar as classes de teste locais que tocam Opportunity e Order (incluindo `FlowOpportunityControllerTest`) antes e depois. Nenhuma pode passar a falhar por causa dos Flows novos.
7. **Sem envio e opt-out:** inspecionar o XML dos 2 Flows (sem `actionCalls` de e-mail ou mensagem); `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c` do Lead e do Contato iguais antes e depois do ciclo.
8. **Permissão:** campo visível com `PS_PosVendas_Atendimento`; acesso negado com perfil não administrador só na homologação (seção 7).
9. **Fila com membro (PD4):** contagem agregada de `GroupMember` na QA. Se for zero, vira pendência do cliente.

## 10. O que NÃO será feito

- Nada no Marketing Cloud e nenhum envio pelo CRM (regra 2).
- Nenhuma alteração em validation rule, picklist, Flow, trigger ou classe existente, nem na regra de distribuição de Lead.
- Nenhum membro de fila, atribuição de permission set a usuário ou alteração de perfil.
- Aviso ao vendedor, SLA, retorno do Pós-vendas ao Marketing (recompra ou reativação), relatório ou painel de funil e revisão das validation rules que barram a conversão (PD5).
- Agentforce (`SFAgent2`) fica de fora.

## 11. Versões e ativação

Os 2 Flows são novos e nascem Active, porque não substituem nada (skill `salesforce-doutrina`). Para desfazer: desativar cada Flow. Nenhuma versão de componente existente é criada nem trocada. Os layouts alterados têm rollback pela versão anterior, guardada no plano de build.

## 12. Esforço

**Estimativa de esforço:** 20–30 h

O que mudou em relação à análise (32–48 h) e por quê: o recon e esta etapa confirmaram que dá para resolver sem Apex e sem automação em Lead, sem alterar nenhum Flow existente e sem campos de data. A ordem de execução em Opportunity ficou resolvida pelo desenho (before-save sem DML e after-save assíncrono), sem consolidar Flows existentes, que era o topo da faixa. O que segura o piso: a fixture, porque as 16 validation rules de Opportunity e as de fechamento exigem Conta, catálogo, filial e pagamento completos; o teste de CPU e bulk; e a regressão das classes de teste de Opportunity. O que leva ao teto: conversão barrada no RT Venda (PD5) exigindo investigação, ou o arquiteto humano escolher manter os campos de data da análise (+3 a 5 h, seção 2).

---

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o build, incluindo a decisão de modelo de dados da seção 2 (lookup `Case.Oportunidade__c`) e os desvios PD1/PD2 em relação aos critérios da análise.
