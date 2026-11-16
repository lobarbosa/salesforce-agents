**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (Org ID 00DHa000006vfMLMAY, sandbox, a "QA" da Eplast pela regra 5 do cliente)

# EPLAST-40: Verificação do build (dev)

Org conferida com `sf org list`: só `sbx-eplast-dev` (Connected). Nada feito em QA, produção ou Marketing Cloud. Fixture `fixtures/opportunity.apex` (blocos 1 e 2) mais scripts de apoio em Apex anônimo. Flows ativos na dev (`FlowDefinitionView`): `Opportunity_AfterSave_CriaCasoPosVendas` e `Opportunity_BeforeSave_QualificaOportunidade`. Preflight: EPLAST-26 e EPLAST-41 tocam o mesmo layout; não mexi em nada deles.

## O que ficou sem prova (motivo da inconclusiva)
- **Conversão do Lead que CRIA a Oportunidade em `Qualificação` (PD6) e preserva LeadSource.** `Database.convertLead` para Conta completa falha com `FIELD_CUSTOM_VALIDATION_EXCEPTION, Catálogo de preço selecionado inválido.` A fórmula da validation rule pré-existente `PriceBook` (Tooling) é: `(ISNEW() && RecordType.DeveloperName != 'Industria' && Pricebook2.Account__r.Id != Account.Id) || (...)`. A Oportunidade da conversão nasce no RT padrão do usuário de execução (`Sale`) e sem catálogo, então a regra barra antes de qualquer Flow da EPLAST-40. Não posso mudar RT padrão nem a regra. O build registra isso como PD5 (fora do escopo), então não é reprovação.
- **O que uma pessoa precisa fazer:** converter um Lead TESTE pela interface com um usuário cujo RT padrão de Oportunidade seja `Industria` (ou a Eplast decidir sobre a regra `PriceBook`) e conferir `StageName = Qualificação` e `LeadSource` preservado.
- Related list de Casos no layout (tela) e acesso negado com usuário sem permissão: não executados (ver tabela).

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Lead de marketing entra | insert Lead TESTE, `E-mail MKT`, opt-outs true | `Aberto - Não contatado`, origem mantida | `L1 Aberto - Não contatado / E-mail MKT / true / true` | passou |
| V2 | SDR marca contato | update Status `Contatado` | `Contatado`, 0 Oportunidade | `L2 Contatado / true / true / opps=0` | passou |
| V3 | Conversão gera Oportunidade `Qualificação` | `convertLead` para Conta TESTE | Oportunidade `Qualificação`, LeadSource mantido | erro da regra `PriceBook` (acima) | não executado (bloqueado, sem prova) |
| V3b | Conversão para Oportunidade existente | `setOpportunityId` | converte, Lead `Fechado - Convertido` | `T3B true / Fechado - Convertido / Qualificação` | passou (parcial, não prova V3) |
| V4 | Qualificado só com os dois critérios | 3 Opps Industria (ambos / só Discovery / nenhum); depois Budget na 2ª | O1 `Qualificado`; O2 e O3 `Qualificação`; O2 vira `Qualificado` | `Qualificado`, `Qualificação`, `Qualificação`; `T4B Qualificado` (também prova que `SBQQ.OpportunityBefore` não reescreve o estágio) | passou |
| V5 | Bulk de 200 (Qualificado) | insert de 200 Opps com os 2 checkboxes | 200 `Qualificado`, CPU < 70% | `BULK200 200`, CPU 575 ms de 10000 | passou |
| V6 | Fechado/Ganho gera 1 Case na fila | fechar 2 Opps (Industria e Sale) | 1 Case por Opp, dono fila `Pós-vendas`, `New` | 2 Cases, `New`, dono `Pós-vendas` (agregado) | passou |
| V7 | Sem duplicata | reabrir (`Qualificado`) e fechar de novo | continua 1 por Opp | 2 Cases no total | passou |
| V8 | Bulk de fechamento | fechar 200 Opps | 200 Cases, sem estouro | `BULKCLOSE 200`, CPU 765 ms de 10000; 200 Cases; total com Subject "Pós-vendas: TESTE EPLAST-40..." e dono `Pós-vendas` = 202 | passou |
| V9 | Orders não mudam | contar Orders das Opps TESTE | 0 | 0 (Order real não simulada) | passou (parcial) |
| V10 | Sem comunicação pelo CRM | `grep` de `<actionCalls>`, `emailAlert`, `emailSimple` nos 2 Flows | 0 | 0 e 0 | passou |
| V11 | Opt-out preservado | opt-outs true na criação, em `Contatado` | iguais | `true/true` antes e depois | passou (parcial: conversão para Conta nova não exercitada) |
| V12 | Fila com membro | contar `GroupMember` de `PosVendas` | >= 1 | 0 (fila existe: 1) | restrição do cliente (PD4), não defeito do build |
| V13 | Componentes na org | Flows ativos, fila, `PS_PosVendas_Atendimento` | existem | Flows ativos, fila `PosVendas` = 1, PS atribuível | passou |
| V14 | Layout com related list (tela) | n/a | related list visível | não conferido (UI); 32 perfis do `CPQ Opportunity Layout` não a veem, conforme o plano | não executado |
| V15 | Acesso sem permissão | só existem admin ativo e o `005bJ00000hBJmYQAW` inativo | acesso negado | sem usuário não administrador | não executado |
| V16 | Apex novo | demanda sem classe Apex | n/a | n/a | n/a |
| V17 | Regressão Apex (`CreateQuoteCPQControllerTest`) | não repeti | n/a | falha de CNPJ pré-existente na fixture da conta do teste, inferência do plano, não confirmada por mim | não executado |

## Restrições e pendências do cliente (não reprovam o build)
- PD4: fila `PosVendas` sem membros; a Eplast define quem atende.
- PD5: validation rule `PriceBook` barra a conversão que cria Oportunidade no RT `Sale`; decisão da Eplast.

## Alterações no usuário de execução (dev) e devolução
`005bJ00000piKAaQAM`: `ProtheusSellerId__c` antes `null`, durante `TESTE40`, ao final `null` (conferido). `PS_PosVendas_Atendimento`: atribuído e removido (0 atribuições ao final). `UserPermissionsMarketingUser` não alterado. Perfil, papel e outros usuários intocados. Usuário de teste da conta de serviço (Id `005bJ00000piKAaQAM`, ativo na org de dev): único usuário usado nos testes.

## Dados de teste e limpeza
Sintéticos `TESTE EPLAST-40`: 1 Conta, catálogo, filial, condição de pagamento, 1 Lead, 205 Oportunidades, 202 Cases. Todos apagados; contagens finais de Case, Opportunity, Account, Lead, Pricebook2 e Branch__c = 0. Sem job agendado. `TriggerUtility.bypassTrigger = true`.

## O que pode ter saído da org
Nada identificado: Flows sem envio, 0 Orders, trigger de Opportunity em bypass. Não consultei logs de integração.
