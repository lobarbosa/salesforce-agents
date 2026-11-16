**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-40: Testes na QA (rodada 2)

Org conferida com `sf org list`: só `sbx-eplast-qa` (QAS, Connected). Deploy da esteira `0AfHa00000EI9j7KAD` (Succeeded, commit `82f54bde`). Componentes de `05-deploy-qa.md` conferidos na org: os 2 Flows ativos na versão 2 (`FlowDefinitionView`), fila `PosVendas` (Queue), permission set `PS_PosVendas_Atendimento`, campo `Case.Oportunidade__c` (Tooling), list view da fila; layout conferido só no arquivo (1 ocorrência de `Oportunidade__c`). Preflight: EPLAST-26 e EPLAST-41 também mexem no layout; não alterei layout. Nada tocado em produção nem no Marketing Cloud.

## Retestes da rodada 1
- FALHA 1 (conversão de Lead): **não corrigida**. O build não alterou metadata nesta rodada (ver `04-plano-build.md`) e a causa segue na org. Reteste abaixo (T3).
- FALHA 2 (fila `PosVendas` sem membros): **não corrigida**. `GroupMember` = 0 (PD4, decisão do cliente).

## Falhas

### FALHA 1 (crítica) — Conversão do Lead em Oportunidade `Qualificação` continua sem prova
- Reproduzir: Apex anônimo na QA, `Database.convertLead` de Lead TESTE (`E-mail MKT`, `Contatado`) para Conta TESTE completa.
- Obtido: `ConvertLead failed ... FIELD_CUSTOM_VALIDATION_EXCEPTION, Erro de validação em Oportunidade: Catálogo de preço selecionado inválido.` (regra pré-existente `PriceBook`, só libera RT `Industria` ou catálogo da Conta; a Oportunidade da conversão nasce no RT padrão do usuário, `Sale`).
- Esperado: Oportunidade em `Qualificação`, LeadSource preservado, Lead `Fechado - Convertido`.
- Limite de teste: o único usuário ativo de execução tem `Sale` como RT padrão (`getRecordTypeInfos`); não posso mudar RT padrão (fora do que está autorizado). A conversão para Oportunidade **existente** funcionou (Lead `Fechado - Convertido`, Oportunidade seguiu `Qualificação`), mas não prova a criação nem o estágio inicial (PD6).
- Para o próximo build/decisão: provar com usuário de RT padrão `Industria` ou decidir sobre a regra `PriceBook` (PD5 a deixa fora do escopo). Sem isso o critério principal não tem evidência.

### FALHA 2 (branda) — Fila `PosVendas` sem membros
- Obtido: 0 membros. Critério "fila que recebe passagem tem membro" não atendido. É PD4 (a Eplast define os membros); pendência de homologação, não defeito de código.

## Casos

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| T1 Lead de marketing entra | insert Lead TESTE `E-mail MKT`, opt-outs true | `Aberto - Não contatado`, origem preservada | `Aberto - Não contatado` / `E-mail MKT` | passou |
| T2 SDR marca contato | update Status `Contatado` | `Contatado`, 0 Oportunidade | `Contatado`, 0 Oportunidades | passou |
| T3 Conversão cria Oportunidade | `convertLead` | Oportunidade `Qualificação` | erro regra `PriceBook` (FALHA 1) | falhou |
| T3b Conversão p/ Oportunidade existente | `convertLead` com `setOpportunityId` | converte | `CONV2 true`, Lead `Fechado - Convertido`, Opp `Qualificação` | passou (parcial, não prova T3) |
| T4 Qualificado só com os 2 critérios | 3 Opps Industria (ambos / só Discovery / nenhum); depois Budget na 2ª | ambos `Qualificado`; 2ª e 3ª `Qualificação`; 2ª vira `Qualificado` | ambos `Qualificado`; `Qualificação`; `Qualificação`; 2ª `Qualificado` | passou |
| T5 Bulk | 20 Opps com os 2 checkboxes | 20 `Qualificado` | `BULK 20` | passou (20) |
| T6 Fechado/Ganho gera Case | fechar 2 Opps (Industria, Sale) | 1 Case por Opp, dono `Pós-vendas`, `New`, Subject "Pós-vendas: <nome>" | 2 Cases, dono `Pós-vendas`, `New`, Subject conforme (consulta após a transação: o Flow é assíncrono) | passou |
| T7 Sem duplicata | reabrir (`Qualificado`) e fechar de novo | 1 Case por Opp | 2 Cases no total | passou |
| T8 Order não muda | contar Orders das Opps TESTE | 0 | 0 (Order real não simulada) | passou (parcial) |
| T9 Sem comunicação pelo CRM | inspeção dos 2 Flows | 0 envio | 0 `actionCalls`/e-mail nos dois | passou |
| T10 Opt-out preservado | opt-outs true em criação e `Contatado` | iguais | `true`/`true` na criação; conversão p/ Conta nova não exercitada | passou (parcial) |
| T11 Fila com membro | contar `GroupMember` de `PosVendas` | >= 1 | 0 | falhou (FALHA 2) |
| T12 Componentes na org | queries | existem | Flows v2 ativos, fila, PS, campo, list view | passou |
| T13 Layout com related list | arquivo | `Oportunidade__c` presente | 1 ocorrência; tela não conferida | não executado (UI) |
| T14 Acesso sem permissão | só há usuário admin (o `005bJ00000hBJmYQAW` está inativo) | | sem usuário não administrador | não executado |
| T15 Apex novo | demanda sem classe Apex | n/a | n/a | n/a |

Aviso do preflight (Flows com versão ativa): confirmado, os 2 Flows estão na versão 2 como versão nova.

## Alterações no usuário de execução (QA) e devolução
- `005bJ00000piKAaQAM`: `ProtheusSellerId__c` antes `null`, durante `TESTE40`, ao final `null` (conferido). `PS_PosVendas_Atendimento` atribuído e removido (0 atribuições ao final). Perfil, papel e outros usuários intocados.

## Dados de teste e limpeza
Sintéticos `TESTE EPLAST-40`: 1 Conta (duplicate rule contornada com allowSave), catálogo, filial, condição de pagamento, 2 Leads, 25 Oportunidades, 2 Cases. Todos apagados; contagens finais de Case, Opportunity, Account, Lead e Pricebook2 = 0. `TriggerUtility.bypassTrigger = true`.

## O que pode ter saído da org
Nada identificado: Flows sem envio, 0 Orders, trigger de Opportunity em bypass. Não consultei logs de integração.
