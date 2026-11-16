**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev (Org ID 00DHa000006vfMLMAY; confirmada por `sf org list`, única org conectada)

# EPLAST-40: Verificação do build

Resumo: tudo o que a solução construiu e que dá para exercitar na dev passou (promoção a Qualificado, Case de Pós-vendas na fila sem duplicar, bulk de 200, ausência de envio, regressão Apex sem piora atribuível). Ficou sem prova a **conversão de Lead em Oportunidade** (critério 3 e PD6), porque o usuário de execução tem RT padrão `Sale` e a regra `PriceBook` barra a conversão antes de qualquer Flow novo. Isso não é defeito do build. Também não foram executados o teste de CPU com 150 itens e o opt-out de Contato.

## O que falta para provar (gate humano)
1. **Conversão de Lead (critério 3, PD6, opt-out durante a conversão):** converter na QAS/dev com usuário cujo RT padrão de Oportunidade seja `Industria`, ou um usuário do perfil que use esse RT. A esteira não pode trocar perfil nem RT padrão de ninguém. Esperado: Oportunidade em `Qualificação`, `Lead.ConvertedDate` preenchido, `ConvertedOpportunityId` igual à Oportunidade. Para o RT Venda a regra `PriceBook` (pré-existente) barra; segue PD5.
2. **CPU com 150 itens (design seção 9, item 5):** exige Order com 150 itens de pedido sintéticos; não montei. O bulk de 200 Oportunidades ficou em 1.317 ms de CPU de 10.000 (13%) no fechamento e 1.354 ms (13,5%) na qualificação, dentro do critério de 70%.
3. **Fila com membro (PD4):** 0 membros, premissa documentada (pendência do cliente, não reprovação).

## Alterações no usuário de execução (dev) e devolução
Usuário `005bJ00000piKAaQAM` (conta de serviço de teste, também o usuário autenticado no job). Perfil, papel e outros permission sets intocados.
| Item | Antes | Durante | Depois |
|---|---|---|---|
| `ProtheusSellerId__c` | null | `TESTE40` | null (conferido) |
| Permission set `PS_PosVendas_Atendimento` (criado pela demanda) | não atribuído | atribuído (`0PaHa00000EJcRNKA1`) | atribuição removida (contagem 0) |
| `UserPermissionsMarketingUser` | false | não alterado | false |

Observação: sem o permission set, a relação `Case.Oportunidade__r` não aparecia na consulta ("No such relation"), o que confirma que o campo só é visível com `PS_PosVendas_Atendimento`.

## Casos
Fixture: `fixtures/opportunity.apex` (blocos 1 e 2, rodados com `sf apex run -o sbx-eplast-dev`, `TriggerUtility.bypassTrigger=true`). Dev tinha 0 Opportunity, 0 Case, 0 Account antes.

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | 1. Lead entra no funil | Insert de Lead `TESTE EPLAST-40 Lead` com `LeadSource='E-mail MKT'` | Status `Aberto - Não contatado`, LeadSource mantido | Status `Aberto - Não contatado`, LeadSource `E-mail MKT` | passou (regra de atribuição "uma vez" não medida: automação existente, não alterada) |
| C2 | 2. SDR marca contato | Update Status para `Contatado` | Status `Contatado`, 0 Oportunidade criada | `Contatado`; 0 Oportunidades | passou |
| C3 | 3. Conversão gera Oportunidade em `Qualificação` (PD6) | `Database.convertLead` para Conta de teste existente e completa, RT padrão `Sale` | Oportunidade em `Qualificação`, `ConvertedDate` | Falhou: "Erro de validação em Oportunidade: Catálogo de preço selecionado inválido." (regra `PriceBook`, ativa: `ISNEW() && RT != 'Industria' && Pricebook2.Account__r.Id != Account.Id`). Conversão não aceita definir RT, e o RT padrão do usuário é `Sale` | não executado (barrado por regra pré-existente, PD5; ver "O que falta") |
| C4 | 4. Qualificação, criação com os dois marcados | Insert Opp RT `Industria`, Discovery e Budget true | `Qualificado` | O1 `Qualificado` | passou |
| C5 | 4. Só um critério | Insert com só Discovery; insert sem nenhum | continua `Qualificação` | O2 e O3 `Qualificação` | passou |
| C6 | 4. Segundo critério depois | Update O2 com Budget true | `Qualificado` (e R4: `SBQQ` não reescreve `StageName`) | O2 `Qualificado` após o update | passou |
| C7 | 4. Só Budget sem Discovery | Update O3 com Budget true | continua `Qualificação` | O3 `Qualificação` (D=false, B=true) | passou |
| C8 | 5. Fechamento gera 1 Case na fila | Fixture bloco 2: 2 Opps (`Industria` e `Sale`) levadas a `Fechado/Ganho` | 1 Case por Opp, `Oportunidade__c` preenchido, dono = fila, `Status=New` | 2 Cases (`500Ha00000OySQDIA3`, `500Ha00000OySQEIA3`), dono `Pós-vendas`, Status `New`, Subject "Pós-vendas: <nome>", 1 por Opp | passou |
| C9 | 5. Sem duplicar | Reabrir (`Qualificado`) e fechar de novo as 2 Opps | continua 1 Case por Opp | contagem de Case 2, `COUNT_DISTINCT(Oportunidade__c)` 2 | passou |
| C10 | 5. Orders não mudam | Contagem de Order da Conta de teste | 0 antes e depois | 0 (a fixture fecha a Opp direto, sem Order; Flow `Order` não exercitado) | passou, com ressalva: o gatilho via Order não foi exercitado |
| C11 | Bulk (design 9.5) | 200 Opps: insert, depois Discovery+Budget; depois update de campos exigidos e `Fechado/Ganho` | 200 `Qualificado`; 200 Cases sem duplicata | 200 `Qualificado` (CPU 1.354/10.000 ms); 200 `Fechado/Ganho` (CPU 1.317/10.000 ms); Cases após o assíncrono: 202 total, 202 distintos, 202 na fila `Pós-vendas` com `Status=New` | passou |
| C12 | 7. Sem envio | `grep -c` de `actionCalls|emailAlert|emailSimple|apex` nos 2 XML; Flows ativos por `FlowDefinitionView` | 0 | 0 nos dois arquivos; ativos: `Opportunity_BeforeSave_QualificaOportunidade` (301Ha000016UPv4IAG), `Opportunity_AfterSave_CriaCasoPosVendas` (301Ha000016UPv3IAG) | passou |
| C13 | 8. Opt-out inalterado | Lead com `HasOptedOutOfEmail=true` e `et4ae5__HasOptedOutOfMobile__c=true`, passou por criação e `Contatado` | iguais antes e depois | true/true antes e depois | passou parcial (etapa de conversão não executada; Contato não testado) |
| C14 | 9. Reuso/metadata | Plano de build: sem objeto novo, sem Flow existente editado; só `Case.Oportunidade__c` (lookup, PD1/PD2 no lugar de campos de data), fila, 2 Flows, PS, list view, layout | alinhado ao design | confere com `04-plano-build.md` e com `FlowDefinitionView` (só os 2 Flows novos nesse padrão). Sem Apex novo, sem exigência de cobertura | passou |
| C15 | 10. Fila com membro (PD4) | `SELECT COUNT(Id) FROM GroupMember WHERE Group.DeveloperName='PosVendas'` | ≥1 | 0 | não atende; é a premissa PD4 documentada (pendência de homologação do cliente), não reprova o build |
| C16 | Permissão (design 9.8) | Consulta de `Case.Oportunidade__r` sem e com o PS | invisível sem, visível com | sem PS: erro "No such relation"; com PS: consulta devolveu o vínculo | passou |
| C17 | Regressão Apex (design 9.6) | `FlowOpportunityControllerTest`, `CreateQuoteCPQControllerTest`, `TestSendOrderToProtheus`, `TestGetAccountFromProtheus` | nenhuma passa a falhar por causa dos Flows novos | `FlowOpportunityControllerTest.test_create` passou. `CreateQuoteCPQControllerTest` (2 falhas) e `TestSendOrderToProtheus` (falhas) com `CNPJ incompleto ou inválido: [CompanyDocument__c]`; stack: `SendOrderToProtheusTDF.createAccount` linha 56, chamado de `setupTestData` linha 8, ou seja, no insert da Conta, antes de existir Opportunity | passou, com ressalva: falha pré-existente da massa de teste do cliente; não fiz a rodada "antes" porque desativar Flows seria alterar o que o builder construiu. A causa está num insert de Conta, fora do alcance de Flows de Opportunity |
| C18 | Layout | Não exercitado na UI | related list visível em `Opportunity Layout` | não executado (sem UI na sessão). Vínculo provado por `Oportunidade__c` (C8). Desvio já registrado no plano: nos 32 perfis do `CPQ Opportunity Layout` do RT `012bJ000000m049QAA` a related list não aparece | não executado |

## Falha 1 da rodada anterior (QA)
- **Conversão barrada pela `PriceBook`:** confirmada e reproduzida (C3). Não corrigível no build (regra pré-existente, PD5). Não foi possível provar a conversão com `Industria` porque a esteira não troca o RT padrão do usuário.
- **Fila sem membros:** confirmada (C15), PD4.

## O que pode ter saído da org
Nada. Os Flows novos não chamam sistema externo; a fixture usou `TriggerUtility.bypassTrigger=true` (sem consulta ao Protheus); nenhuma Order, cotação ou log de integração foi criado (contagem de Order da Conta de teste: 0). Nada de Marketing Cloud foi tocado.

## Dados de teste: limpeza
Apagados: 202 Cases, 202 Opportunities, 1 Lead, Pricebook2, `Branch__c`, `PaymentTerms__c` e a Account `TESTE EPLAST-40 Conta`. Contagens finais na dev: Case 0, Opportunity 0, Lead 0, Account 0, Pricebook2 `TESTE EPLAST-40%` 0, `Branch__c` 0, `PaymentTerms__c` 0, atribuição do PS 0, `ProtheusSellerId__c` null. Nada ficou. A primeira tentativa de limpeza falhou por MIXED_DML e foi revertida por inteiro; refeita em execuções separadas. Sem job Apex agendado nesta demanda.
