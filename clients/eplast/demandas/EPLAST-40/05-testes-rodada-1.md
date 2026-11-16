**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-40: Testes na QA

Org conferida com `sf org list`: só `sbx-eplast-qa` (Sandbox `eplast--qas`, Connected). Deploy da esteira `0AfHa00000EI5h8KAD` (Succeeded, commit `58a84fa8`). Os 7 componentes de `05-deploy-qa.md` existem na org (Flows ativos na versão 1, fila `PosVendas`, permission set, campo `Case.Oportunidade__c` via Tooling, list view `PosVendas_Fila`; layout conferido só no arquivo). Nada tocado em produção nem no Marketing Cloud. Avisos do preflight: EPLAST-26 e EPLAST-41 também mexem em layout/Opportunity Layout; os dois Flows seguem na versão 1, sem versão nova minha.

## Falhas

### FALHA 1 (crítica) — Conversão de Lead gerando Oportunidade em `Qualificação` não pôde ser provada
- Reproduzir: Apex anônimo na QA, `Database.convertLead` de Lead TESTE (LeadSource `E-mail MKT`, Status `Contatado`) para Conta TESTE completa, RT padrão do usuário.
- Obtido: `ConvertLead failed ... FIELD_CUSTOM_VALIDATION_EXCEPTION, Erro de validação em Oportunidade: Catálogo de preço selecionado inválido.` (validation rule pré-existente `PriceBook`: `ISNEW() && RT != 'Industria' && Pricebook2.Account__r.Id != Account.Id`).
- Esperado (critério "Conversão do Lead gera a Oportunidade da Comercial"): Oportunidade em `Qualificação`, LeadSource preservado, Lead `Fechado - Convertido`.
- Causa provável: a regra bloqueia a conversão no RT padrão (mesma restrição da dev, PD5/C1 da verificação). Sem esse caso o critério principal fica sem evidência, logo reprovado. Para o próximo build: provar a conversão com usuário cujo RT padrão seja `Industria`, ou ajustar a regra (fora do escopo, exige decisão).

### FALHA 2 (branda) — Fila `PosVendas` sem membros
- Obtido: `GroupMember` da fila `PosVendas` = 0. Critério "toda fila que recebe passagem tem membro" não atendido. É a pendência PD4 do design (membros definidos pela Eplast), não defeito de código; sem membro, o Case fica sem ninguém para atender.

## Casos

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| T1 Lead de marketing entra no funil | insert Lead TESTE, LeadSource `E-mail MKT`, opt-outs marcados | Status `Aberto - Não contatado`, origem preservada | `Aberto - Não contatado` / `E-mail MKT` | passou |
| T2 SDR marca contato | update Status para `Contatado` | Status `Contatado`, 0 Oportunidade criada | `Contatado`; 0 Oportunidades com origem SDR criadas | passou |
| T3 Conversão gera Oportunidade | convertLead | Oportunidade `Qualificação` | erro regra `PriceBook` (FALHA 1) | não executado / falhou |
| T4 Qualificado só com os dois critérios | insert O3 (nenhum), O2 (só Discovery), O1 (ambos); depois Budget em O2 | O3 e O2 `Qualificação`; O1 `Qualificado`; O2 vira `Qualificado` | O1 `Qualificado`; O2 `Qualificação`; O3 `Qualificação`; O2 após Budget `Qualificado` | passou |
| T5 Bulk de qualificação | insert de 20 Opps Industria com os 2 checkboxes | 20 `Qualificado` | 20 `Qualificado`, sem erro | passou (20; 200 foi provado na dev) |
| T6 Fechado/Ganho gera Case na fila | fechar 2 Opps (Industria e Sale) com campos exigidos | 1 Case por Opp, dono fila Pós-vendas, `New`, Subject "Pós-vendas: <nome>", Conta preenchida | 2 Cases, dono `Pós-vendas`, `New`, Subject conforme, AccountId preenchido | passou |
| T7 Sem duplicata ao reabrir | voltar a `Qualificado` e fechar de novo | continua 1 Case por Opp | 2 Cases no total | passou |
| T8 Order não muda | contar Orders das Opps TESTE | 0 | 0 (Order real não simulada) | passou (parcial) |
| T9 Sem comunicação pelo CRM | inspeção dos 2 Flows | 0 `actionCalls`/e-mail | 0 e 0 | passou |
| T10 Opt-out preservado | Lead com `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c` = true passa por criação e `Contatado` | mesmos valores | `true`/`true` antes e depois (conversão não exercitada) | passou (parcial) |
| T11 Fila com membro | GroupMember da fila `PosVendas` | >= 1 | 0 | falhou (FALHA 2, PD4) |
| T12 Componentes na org | Tooling/SOQL | existem | Flows v1 ativos, fila, PS, campo, list view presentes | passou |
| T13 Layout com related list | arquivo do deploy | `Oportunidade__c` presente | 1 ocorrência; renderização não conferida na tela | não executado (UI) |
| T14 Acesso sem permissão | só existe usuário admin (`005bJ00000hBJmYQAW` inativo) | | sem usuário não administrador | não executado |
| T15 Apex novo | demanda não criou classe Apex | n/a | n/a | n/a |

## Alterações no usuário de execução (QA) e devolução
- `005bJ00000piKAaQAM`: `ProtheusSellerId__c` antes `null`, durante `TESTE40`, ao final `null` (conferido). PS `PS_PosVendas_Atendimento`: atribuído (`0PaHa00000EJcbBKAT`), removido ao final (0 atribuições). Perfil, papel e outros usuários intocados.

## Dados de teste e limpeza
Sintéticos, `TESTE EPLAST-40`: 1 Conta (duplicate rule contornada com allowSave), catálogo, filial, condição de pagamento, 1 Lead, 25 Oportunidades, 2 Cases. Todos apagados; contagens finais de Case, Opportunity, Lead, Account e Pricebook2 `TESTE EPLAST-40` = 0. `TriggerUtility.bypassTrigger = true` (sem desvio para Protheus). Fixture reaproveitada: `fixtures/opportunity.apex` (na QA, o insert da Conta exige DuplicateRuleHeader allowSave e ProtheusId distinto).

## O que pode ter saído da org
Nada identificado: Flows sem envio, 0 Orders, trigger de Opportunity em bypass. Não consultei logs de integração.
