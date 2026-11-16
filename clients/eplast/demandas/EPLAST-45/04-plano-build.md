**Resultado do build:** concluído

# EPLAST-45 · Plano de build: nutrição de leads até a abordagem comercial

**Org:** `sbx-eplast-dev` (`projetos@konectabr.com.eplast2.qa`, Org Id `00DHa000006vfMLMAY`, a "QA" da Eplast; regra 5 da conta). Única conectada em `sf org list`.
**Branch:** `feature/EPLAST-45`. Deploy de validação (`--dry-run`) e deploy real: Succeeded (Deploy ID `0AfHa00000EI6zlKAD`). Sem Apex, então sem testes. Nada tocado no Marketing Cloud, em produção, em `et4ae5` nem na `Marketing_Cloud_Connected_App`.
Build conforme `03-design.md` (PD-01 a PD-07). Nenhum ponto do design ficou sem resposta.

## Componentes criados

| # (design) | Componente | Tipo | Observação |
|---|---|---|---|
| 5 | `Lead.MKT_Nutricao_Elegivel__c` | Fórmula Checkbox | `AND(NOT(IsConverted), OR(ISPICKVAL(Status,"Aberto - Não contatado"), ISPICKVAL(Status,"Contatado")))` |
| 6 | `Lead.MKT_Nutricao_ProntoAbordagem__c` | Fórmula Checkbox | `AND(MKT_Nutricao_Elegivel__c, PriorityBand__c = "Alta")` |
| 7 | `Lead.MKT_MC_Engajamento__c` | Picklist restrita | Sem engajamento, Baixo, Médio, Alto |
| 8 | `Lead.MKT_MC_EngajamentoData__c` | DateTime | Data e hora do retorno |
| 9 | `MARKETINGCLOUD/NUTRICAO_LEADS_EMAIL` | Relatório LeadList, Tabular, escopo org | Elegível = verdadeiro, `EMAIL_OPT_OUT` = falso, `EMAIL` não vazio |
| 10 | `MARKETINGCLOUD/NUTRICAO_LEADS_MENSAGEM` | Relatório LeadList, Tabular, escopo org | Elegível = verdadeiro, `et4ae5__HasOptedOutOfMobile__c` = falso, `MOBILE_PHONE` não vazio; coluna `et4ae5__Mobile_Country_Code__c` |
| 13 | `Lead.Leads_Prontos_Abordagem` | List view | Filtro `MKT_Nutricao_ProntoAbordagem__c = true`; colunas de `Leads_Abertos_Prioridade` + engajamento e data; escopo Everything, sem `sharedTo`, igual à de origem |
| 16 | `PS_Marketing_RetornoMC` | Permission set | Leitura em 5 e 6; leitura e edição em 7 e 8; sem permissão de objeto; sem atribuição |

## Componentes alterados (só FLS de leitura nos 4 campos novos)
- `PS_Comercial_ScorePrioridade` (14) e `PS_Marketing_Publicos` (15): leitura nos campos 5 a 8. A descrição foi reescrita mais curta (limite de 255 caracteres), preservando as referências às demandas anteriores.

## Reaproveitado sem alteração
`PriorityBand__c`, `PriorityScore__c`, `Status`, `IsConverted`, `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c`, list view `Leads_Abertos_Prioridade` (PD-06), relatórios existentes da pasta, Flow `Lead_AfterInsert_AplicaRegraAtribuicao`, validation rules de Lead, `SFAgent2`. Não se criou Flow, Apex, objeto nem perfil.

## Desvios e observações
- As `description` de todos os componentes novos começam por "EPLAST-45." (campos, relatórios, permission set). List view não tem campo de descrição.
- O XML de `PS_Comercial_ScorePrioridade` e `PS_Marketing_Publicos` não estava no repositório; foi baixado da dev antes de editar (baseline = estado da org).
- Relatórios modelados no XML de `MSG_LEADS_CELULAR_APTOS` (que foi baixado só como modelo e descartado, não entra no PR).
- Usado `MOBILE_PHONE`/`MobilePhone` no público de mensagem, como no relatório existente.

## Versões e ativação
Não se aplica: nenhum Flow, agente ou classe novo ou alterado. Nada a ativar.

## O que deve ser verificado
1. Os 4 campos existem em Lead com `description`; fórmulas compiladas; picklist restrita com os 4 valores.
2. Fixture de Lead `TESTE` (L1 a L7 do design, seção 8; script `fixtures/lead-nutricao.apex`, a criar pelo verificador; telefones vazios ou em `(DD)NNNNNNNNN`): elegibilidade e prontidão como na tabela (L1 elegível não pronto; L2 pronto; L7 e L5 convertido não elegíveis; L6 sem dados não pronto).
3. Relatório de e-mail: sai L3 (opt-out e-mail), entra L4; relatório de mensagem: sai L4 (opt-out mobile), entra L3; contagem do relatório 9 igual ao SOQL agregado do CA-01, só leads TESTE.
4. List view `Leads_Prontos_Abordagem` mostra L2 e não mostra L1, L5, L6.
5. CA-06/07: gravar `MKT_MC_Engajamento__c = Alto` e a data em L2; `Status`, `PriorityBand__c`, `OwnerId` não mudam e L2 continua pronto.
6. Permission sets: leitura nos 4 campos em 14, 15 e 16; edição só em 7 e 8 e só no 16 (inspeção de metadata).
7. CA-08/CA-10: nenhum Flow ou Apex novo; todas as descrições preenchidas. CA-11 não se aplica.
8. Limpeza dos leads `TESTE` ao fim.
