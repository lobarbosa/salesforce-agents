**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-43 - Testes na sandbox de QA (QAS da Eplast, Partial Copy)

Org conferida com `sf org list`: `sbx-eplast-qa` (Connected, único alias). Nada em produção nem no Marketing Cloud. Deploy da esteira: `0AfHa00000EI9snKAD` (Succeeded, commit `816a055a`). Primeira rodada de QA da demanda; não existe `05-testes-rodada-<n>.md`.

## Falhas
Nenhuma.

## Presença dos componentes na org
| Componente | Evidência | Status |
|---|---|---|
| Group `Marketing_Publicos` | `SELECT Id,Name FROM Group` devolveu `00GHa000006bQT7MAM` "Públicos de Marketing" | passou |
| PermissionSet `PS_Marketing_Publicos` | count = 1 | passou |
| Relatórios novos e alterados (5 conferidos por DeveloperName: `MSG_CONTATOS_CELULAR_APTOS`, `MSG_LEADS_CELULAR_APTOS`, `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE`, `LEADS_PROSPECCAO_PRIORIDADE`, `LEADS_ES_SQz`) | count = 5 | passou |
| Demais relatórios da lista do deploy (16 de Lead, `LEADS_SEGMENTO_ALIMENTOS` aberto) | A pasta tem 84 relatórios na QAS. Abertos por describe: `LEADS_SEGMENTO_ALIMENTOS`, `LEADS_ES_SQz`. Os outros 14 não foram abertos individualmente | parcial (ver "Sem prova") |

## Casos
Dado sintético criado pelo script `fixtures/eplast43_publicos.apex` (2 contas, 4 contatos, 6 leads, prefixo `EPLAST43-TESTE`, proprietário a conta de serviço de teste indicada no briefing da conta). Cada relatório foi executado pela Analytics API com um filtro extra "empresa começa por EPLAST43-TESTE", para só enxergar o dado de teste.

| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| Q1 | CA-01, CA-04 | Executar `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` (filtros: opt-out e-mail = falso, convertido = falso, status Aberto-Não contatado ou Contatado, prioridade diferente de "Sem dados suficientes") | Lead 1 e Lead 3 aparecem; Lead 2 (opt-out e-mail), Lead 4 (fechado), Lead 5 (convertido) fora | 2 linhas: Lead 1 e Lead 3. Lead 6 (sem origem nem prioridade) também fora | passou |
| Q2 | CA-01, CA-03 | Executar `LEADS_SEGMENTO_ALIMENTOS` | Lead 2 (opt-out) e Lead 5 (convertido) fora; Lead 4 (fechado) dentro (PA-09) | 3 linhas: Lead 1, Lead 3, Lead 4 | passou |
| Q3 | CA-02 | Executar `MSG_LEADS_CELULAR_APTOS` | Lead 3 (opt-out de celular), Lead 5 (convertido) e Lead 6 (sem celular) fora | 3 linhas: Lead 1, Lead 2, Lead 4. Lead 2 aparece porque o opt-out dele é só de e-mail | passou |
| Q4 | CA-02 | Executar `MSG_CONTATOS_CELULAR_APTOS` | Contato 3 (opt-out de celular) e Contato 4 (sem celular) fora | 3 linhas: Contato 1, Contato 2 e o contato nascido da conversão do Lead 5 (tem celular, sem opt-out) | passou |
| Q5 | CA-04 | Conferir descrição de `LEADS_ES_SQz`, `LEADS_SEGMENTO_ALIMENTOS`, `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE`, `MSG_LEADS_CELULAR_APTOS` | `CONVERTED = Falso` em todos | Presente nos 4 | passou |
| Q6 | CA-05 | `FieldPermissions` do `PS_Marketing_Publicos` com leitura | As 9 FLS novas mais as anteriores | 21 com leitura. Das 10 conferidas por nome (9 novas mais `Lead.PriorityBand__c`), as 10 existem | passou |
| Q7 | CA-06 | `git grep` de EmailAlert, sendEmail, Messaging., SingleEmailMessage nos reports, groups e permissionsets entregues | Zero | Zero | passou |
| Q8 | CA-07 | `git diff --name-only main...HEAD -- force-app` fora de reports, groups e permissionsets | Zero (sem trigger, Flow ou classe) | Nenhum arquivo | passou |
| Q9 | CA-10 | Roteiro do cliente com passos do Marketing Cloud e premissas | Existe | `05-roteiro-cliente.md` gravado | passou |

## Observações (não são falhas)
- `LEADS_ES_SQz` na QAS tem filtros UF = ES, opt-out e-mail = falso e convertido = falso, sem filtro de opt-out de celular. Na dev ele tinha esse filtro (colisão registrada em `04-verificacao.md`). A entrega desta demanda adicionou só o critério de convertido; a diferença entre dev e QAS vem de antes. Quem opera o Marketing Cloud deve saber que esse público não exclui opt-out de celular.
- Lead 3 (só opt-out de celular) aparece nos públicos de e-mail, como esperado: o opt-out de celular só vale para o público de mensagem.
- Interferência de outras demandas (EPLAST-36, 37, 42, 44, 45, 46 em `PS_Marketing_Publicos` e na pasta de relatórios): nenhuma observada. O permission set tem 21 FLS de leitura na QAS e o público de EPLAST-42 (`LEADS_PROSPECCAO_PRIORIDADE`) existe.

## Sem prova
- CA-08 (contagem antes e depois em cada relatório existente): não medida relatório a relatório, para não ler dado real da QAS. A mudança esperada é a saída de leads convertidos dos públicos de Lead; fica para `06-entrega.md` e para a homologação.
- CA-05 com usuário que recebe o permission set: não foi feito (atribuição a usuário administrador não prova FLS; a esteira não atribui a ninguém da Eplast). Conferido por `FieldPermissions`. Nenhum usuário recebeu o permission set (0 atribuições).
- Os outros 14 relatórios de Lead não foram abertos um a um.

## O que pode ter saído da org
Nenhuma chamada externa. O script criou 2 contas, 4 contatos e 6 leads sintéticos (mais 1 contato da conversão do Lead 5). Triggers de conta ficaram desligados pelo bypass do próprio script. Limpeza feita por Apex anônimo; conferido: 0 leads, 0 contatos, 0 contas com prefixo `EPLAST43-TESTE`.

## Mudanças no usuário de execução
Nenhuma (nenhum permission set atribuído, nenhum campo alterado).
