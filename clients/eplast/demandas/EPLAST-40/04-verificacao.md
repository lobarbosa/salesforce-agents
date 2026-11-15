**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-40: Verificação do build

Org conferida com `sf org list`: só `sbx-eplast-dev` (Sandbox, `00DHa000006vfMLMAY`), Connected. Usuário de execução `005bJ00000piKAaQAM`. Nada em QA nem produção; nada no Marketing Cloud.

**Por que inconclusiva:** a conversão de Lead que cria a Oportunidade em `Qualificação` (PD6) não pôde ser exercitada. Ela é barrada, sem relação com os Flows novos, pela validation rule `PriceBook` (ver caso C1). Tudo o mais passou, e a regressão do achado 2 é pré-existente. O que falta: converter um Lead com um usuário cujo record type padrão de Oportunidade seja `Industria`, ou com catálogo que a conversão aceite, na homologação.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Conversão gera Oportunidade em `Qualificação` (PD5/PD6) | `Database.convertLead` de Lead TESTE (LeadSource `E-mail MKT`) para Conta TESTE completa, RT padrão (Sale) | Oportunidade em `Qualificação` | `ConvertLead failed ... Catálogo de preço selecionado inválido` (regra `PriceBook`: `ISNEW() && RT != 'Industria' && Pricebook2.Account__r.Id != Account.Id`). O RT da conversão não é escolhível pela API e mudar o RT padrão do usuário é alteração de perfil, fora do que o verificador pode fazer. É a restrição prevista em PD5 | não executado |
| C2 | Lead nasce `Aberto - Não contatado`, LeadSource preservado | insert de Lead TESTE | Status `Aberto - Não contatado`, `E-mail MKT` | `Aberto - Não contatado` / `E-mail MKT` | passou |
| C3 | Mudar para `Contatado` não cria Oportunidade | update de Status do Lead | 0 Oportunidades | 0 | passou |
| C4 | Só `Discovery_Completed__c` mantém `Qualificação`; os dois promovem | insert O2 (só Discovery) e update posterior com Budget; insert O1 (ambos) e O3 (nenhum), RT Industria | O2 `Qualificação`, depois `Qualificado`; O1 `Qualificado`; O3 `Qualificação` | O2 `Qualificação` -> `Qualificado` após Budget; O1 `Qualificado`; O3 `Qualificação` | passou |
| C5 | PD3: vale para todos os RTs; R4 (`SBQQ.OpportunityBefore` não reescreve `StageName`) | insert de Opportunity com os dois checkboxes em cada RT ativo disponível (5: Sample, Bonus, Industria, Sale, SellWithShipping), `StageName` lido do banco | `Qualificado` em todos | `Qualificado` nos 5. O estágio gravado prova R4. Obs.: a org tem 5 RTs ativos, o design falava em 6 | passou |
| C6 | `Fechado/Ganho` gera 1 Case na fila `PosVendas` com `Oportunidade__c` | fechar 2 Oportunidades TESTE (Industria e Sale) com todos os campos de R2; consulta após o assíncrono | 1 Case por Oportunidade, dono = fila, `Status=New`, `Subject` "Pós-vendas: <nome>", AccountId preenchido | 2 Cases (1 por Oportunidade), dono `Pós-vendas`, `New`, Subject conforme PD7, AccountId preenchido; `CreatedDate` do Case = data da passagem (PD2) | passou |
| C7 | Sem duplicata ao reabrir e fechar de novo | as 2 Oportunidades voltam a `Qualificado` e vão de novo a `Fechado/Ganho` | continua 1 Case por Oportunidade | 2 Cases no total, 1 por Oportunidade | passou |
| C8 | Bulk de 200 | 200 Opps (Industria) criadas com os 2 checkboxes, depois todas a `Fechado/Ganho`, numa transação | 200 `Qualificado`; 200 Cases distintos na fila; CPU baixa | 200 `Qualificado`; 200 Cases, 200 `Oportunidade__c` distintos, 200 com dono `Pós-vendas`. CPU síncrona do insert: 594 ms; do update de fechamento: 804 ms (limite 10000 ms). Sem erro | passou |
| C9 | Order não muda | contagem de Orders das Oportunidades TESTE | 0 criadas pelo Flow | 0 Orders (nenhuma foi criada nem alterada; a Order real não foi simulada, ver "Sem prova") | passou (parcial) |
| C10 | Sem envio de comunicação | inspeção do XML dos 2 Flows | 0 `actionCalls`/e-mail | 0 ocorrências de `actionCalls`, `emailAlert`, `emailSimple` nos dois | passou |
| C11 | Permission set e campo | `FieldPermissions` e atribuição ao usuário de execução | PS concede o campo; com ele a consulta por `Oportunidade__r` funciona | `PS_PosVendas_Atendimento` tem `Case.Oportunidade__c`. Sem o PS, o administrador **não** enxergou o campo (`No such relation 'Oportunidade__r' on entity 'Case'`); com o PS atribuído passou a funcionar. Isso contradiz o design seção 7 ("admin vê pelo perfil"): o campo só aparece com o PS (ou FLS no perfil). Registrado, não é falha do build | passou (com ressalva) |
| C12 | List view `Case.PosVendas_Fila` | consulta de `ListView` e resultados via REST | view existe e executa | existe (`PosVendas_Fila`), executa e devolve registros; 202 Cases abertos na fila durante o teste | passou |
| C13 | Layout | `Opportunity-Opportunity Layout` com `Oportunidade__c` | related list presente | 1 ocorrência no arquivo implantado. Não conferi a renderização na tela. O `CPQ Opportunity Layout` (gerenciado) não foi alterado, como o build já registrou | passou (arquivo) |
| C14 | Fila `PosVendas` | `GroupMember` da fila | 0 (PD4) | 0 membros: pendência do cliente (PD4), não defeito | passou (conforme PD4) |

## Regressão Apex (achado 2): com e sem os Flows

Todas as execuções com `sf apex run test -n CreateQuoteCPQControllerTest -n FlowOpportunityControllerTest`.

| Rodada | Flows | `CreateQuoteCPQControllerTest` | `FlowOpportunityControllerTest` |
|---|---|---|---|
| A (run `707Ha00001E2pIR`) | os 2 ativos (estado do build) | 2 de 3 falham: `CNPJ incompleto ou inválido: [CompanyDocument__c]` em `SendOrderToProtheusTDF.createAccount` (linha 56), chamado de `setupTestData` (linha 8) | passa |
| B | os 2 **desativados** | as mesmas 2 falhas, mesma mensagem e mesma linha | passa |

Conclusão: a falha de `CreateQuoteCPQControllerTest` é **pré-existente** (insert da Conta na fixture do teste, antes de qualquer Opportunity; ocorre sem os Flows). Não é regressão desta demanda. Sugestão para outra demanda: corrigir o CNPJ da fixture em `SendOrderToProtheusTDF`.

**O que fiz nos Flows:** desativação via Tooling API (`PATCH FlowDefinition/<id>` com `Metadata.activeVersionNumber = 0`) dos dois `FlowDefinition` (`300Ha00000Oy7QcIAJ` e `300Ha00000Oy7QdIAJ`), nenhuma versão nova criada. **Restauração:** `activeVersionNumber = 1` nos dois. Conferido no fim: `Opportunity_AfterSave_CriaCasoPosVendas` ativo na versão `301Ha000016UPv3IAG`, `Opportunity_BeforeSave_QualificaOportunidade` ativo na versão `301Ha000016UPv4IAG` (iguais às do início; LatestVersionId igual).

## Mudanças no usuário de execução (dev) e devolução

- `User.ProtheusSellerId__c` de `005bJ00000piKAaQAM`: antes `null`, durante o teste `TESTE40`, ao final `null` (conferido por consulta).
- Permission set `PS_PosVendas_Atendimento`: atribuído (`0PaHa00000EJQoNKAX`) para ver o campo; removido ao final (0 atribuições).
- Perfil, papel, outros permission sets e outros usuários: intocados. Usuário `005bJ00000hBJmYQAW` não usado.

## Dados de teste

Todos com `TESTE EPLAST-40` no nome (Conta, Catálogo, Filial, Condição de Pagamento, Lead, 8 + 5 + 2 + 200 Oportunidades, 202 Cases), sintéticos, `TriggerUtility.bypassTrigger = true`. Apagados ao final: contagens de Case, Opportunity, Account, Lead e Pricebook2 `TESTE EPLAST-40` = 0. Nada ficou. Nenhum job agendado criado. Fixture gravada em `clients/eplast/fixtures/opportunity.apex`.

## O que pode ter saído da org

Nada identificado: Flows sem `actionCalls`; `bypassTrigger` evitou o desvio para Protheus no trigger de Opportunity; nenhuma Order foi criada, então `sendOrderToProtheus` não rodou. Nenhum registro de integração foi criado por mim (não consultei logs de integração).

## Sem prova (o que falta)

1. **Conversão de Lead com Oportunidade em `Qualificação` (C1, PD6):** barrada pela regra `PriceBook` no RT padrão. Provar com usuário de RT padrão `Industria` ou após revisão da regra (demanda própria, PD5).
2. Fechamento via Order real e Flow `Order` (design caso 4): fechei a Oportunidade diretamente. O Flow de Case roda no `Fechado/Ganho` independentemente da origem, mas a sequência Order -> Opportunity não foi exercitada. CPU com Order de 150 itens (comparação antes/depois) não medida.
3. Task de `Oportunidade_Industria`, opt-out de Lead/Contato antes e depois do ciclo, e acesso negado por perfil não administrador: não executados.
4. Renderização da related list na tela (só confirmado o arquivo de layout).
