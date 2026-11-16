**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-44 — Testes na sandbox de QA

Org conferida com `sf org list`: `sbx-eplast-qa` (Sandbox `eplast--qas`, Partial Copy, Org Id `00DHa000006vZtmMAE`, Connected). Deploy da esteira: `0AfHa00000EI8lSKAT` (Succeeded), `05-deploy-qa.md` presente, componente único: relatório `MARKETINGCLOUD/LEADS_BOAS_VINDAS`. Nada no Marketing Cloud, nada em produção.

## Falhas
Nenhuma falha que bloqueie o aceite. Observação (não é falha da entrega, mas o time deve saber):
- Os relatórios `MSG_LEADS_CELULAR_APTOS` e `MSG_CONTATOS_CELULAR_APTOS`, citados no design como reaproveitados para o canal mensagem, **não existem na QAS** (query em `Report` por DeveloperName: 0 linhas). Existem na dev. Não fazem parte do pacote desta demanda (que só leva C1); chegam à QA com a demanda que os criou. A pasta tem 62 relatórios na QAS (61 + C1), contra 65 na dev. Os outros 6 reaproveitados (R1–R6) existem na QAS.

## Estado da QAS e usuário
- Nenhum permission set, perfil, papel ou campo do usuário de execução foi alterado. Usuário de teste Konecta `005bJ00000piKAaQAM` (ativo, Administrador do sistema; `005bJ00000hBJmYQAW` inativo). Não há usuário sem acesso: teste de acesso negado fica para o roteiro do cliente (PD-09).
- Dado de teste criado com Apex anônimo (`fixtures/` não existe no repositório): 5 leads `TESTE EPLAST-44 T1..T5`, 1 conta `TESTE EPLAST-44 Conta` (CNPJ sintético) e 1 contato da conversão. Os relatórios foram executados pela Analytics API com os filtros salvos mais um filtro por `Empresa começa com "TESTE EPLAST-44"`, para não ler registro real.

## Casos

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| E1 | `SELECT ... FROM Report WHERE DeveloperName='LEADS_BOAS_VINDAS'` na QAS | Existe, Tabular, pasta MARKETING CLOUD | `LEADS_BOAS_VINDAS`, "LEADS - BOAS-VINDAS", Tabular, MARKETING CLOUD | passou |
| E2 | describe do relatório (Analytics API) | Filtros do design 3.1 | `CONVERTED=Falso`, `EMAIL_OPT_OUT=Falso`, `STATUS ≠ Fechado - Não convertido`, data `CREATED_DATE` `LAST_N_DAYS:7` (09/11 a 15/11), escopo org | passou |
| T1 / CA-06 entrada | Lead aberto, sem opt-out, criado agora; executar C1 | Aparece | Aparece (T1) | passou |
| T2 / CA-01, CA-06 saída | Lead com `HasOptedOutOfEmail=true` | Não aparece em C1 | Ausente. Execução com filtro de empresa: 5 linhas sem os filtros salvos, 3 com eles (T1, T4, T5) | passou |
| T3 / PD-05 | Lead "Fechado - Não convertido" | Fora de C1 | Ausente de C1; presente em R1 (R-05 do design, aceito) | passou |
| T4 / CA-03 | Lead convertido (conversão em conta de teste, sem oportunidade) | Fora de C1 e de R1 | Antes da conversão aparecia (3 linhas); depois: C1 devolve só T1 e T5; R1 não o devolve | passou |
| T5 / CA-02 (Lead) | Lead com `et4ae5__HasOptedOutOfMobile__c=true` | Fora de R1 | R1 sem o filtro de faixa (que o dado sintético não preenche): devolve T1 e T3, não T5. Retirando só o filtro de celular, T5 volta. Em C1 T5 aparece, por design (PD-06, público de e-mail) | passou |
| CA-01 / CA-02 (Contact) | Filtros dos 5 relatórios de Contact (describe na QAS) | Opt-out de e-mail e de celular excluídos | `EMAIL_OPT_OUT=Falso` e `et4ae5__HasOptedOutOfMobile__c=Falso` nos 5 (`POTENCIAIS_SEM_COMPRA`, `COMPRA_ULTIMOS_90_DIAS`, `SEM_COMPRA_*` x3). Execução com Contact sintético **não executada**: `RelationshipClass__c` e `LastPurchase__c` são fórmula (não editáveis) e dependem de pedido; sem Order sintético; filtro por conta também negado (ACCOUNT_NAME sem acesso) | passou por metadata; execução não executada |
| CA-04 | Pacote do deploy (`05-deploy-qa.md`) e arquivo do relatório | Só relatório, sem envio | 1 componente, `Report`; 0 ocorrências de EmailTemplate, EmailAlert, Messaging ou Flow no arquivo | passou |
| CA-05 | `COUNT()` em Report da pasta | C1 único criado, demais não alterados | 62 na QAS; C1 é o único componente do deploy | passou |
| MSG | Relatórios `MSG_*` na QAS | Existem | Não existem na QAS | não executável (ver observação) |
| Permissão por perfil | Usuário sem acesso | Negado | Não há usuário não-admin ativo; fica para o roteiro | não executado |
| Volume | `COUNT()` Lead criados nos últimos 7 dias | Só contagem | 4 antes do teste (dado real, não lido) | informativo |

## Premissas
PD-01 a PD-09 e PA-01 a PA-08 seguidas; nenhuma motivou reprovação.

## O que pode ter saído da org
Nenhum e-mail ou chamada externa disparados (nada de envio na solução). Criados e removidos ao final: 5 leads, 1 conta, 1 contato (apagado com a conta). Contagem final dos três prefixos `TESTE EPLAST-44`: 0. O Flow `Lead_AfterInsert_AplicaRegraAtribuicao` rodou na inserção dos leads (pode ter trocado proprietário), sem efeito persistente.

## Desfazer
Nada a desfazer: sem arme de agendamento, sem permission set atribuído, sem valor alterado.
