**Verificação:** reprovada
**Org de teste:** `sbx-eplast-dev`

# EPLAST-43 - Verificação do build

Org conferida com `sf org list`: `sbx-eplast-dev`, sandbox, Connected (único alias). Só dev. Nada em QA, produção ou Marketing Cloud. Só contagens e registros sintéticos `EPLAST43-TESTE`.

## Falha

### FALHA 1 — `04-plano-build.md` não traz a lista dos públicos (CA-03, Q10)
- Como reproduzir: ler `04-plano-build.md`. O design (seção 5, linha 150) e CA-03 mandam registrar nele o nome de cada relatório (60 + 3), com pasta e filtro.
- Obtido: o plano cita só os 3 relatórios novos e os 15 ajustados. Não há lista dos 63 públicos nem o filtro de cada um.
- Esperado: lista com nome e filtro de cada público da pasta. Na org a pasta tem 64 relatórios (`Report` com `OwnerId` da pasta), os 63 do design mais `LEADS_PROSPECCAO_PRIORIDADE` da EPLAST-42. A conta fecha.
- O que o builder precisa fazer: acrescentar a lista ao plano, só documentação. Nenhum defeito de configuração.

## Divergências sem reprovação (para o arquiteto e a homologação)
- **Q1 e Q2 do design esperavam o lead 3 e o contato 3 no segmento Alimentos.** Eles têm só opt-out de celular, e o segmento os exclui. `LEADS_SEGMENTO_ALIMENTOS` e `SEGMENTO_ALIMENTOS` já filtram `et4ae5__HasOptedOutOfMobile__c = Falso` na org. O recon registrou "não encontrado" nesse campo, mas só leu 2 relatórios. Não é do builder: ele só acrescentou `CONVERTED` (`LEADS_SEGMENTO_ALIMENTOS`, conferido por diff). Efeito: quem tem só opt-out de celular sai também do público de e-mail por segmento. Isso é mais restritivo que o necessário, e o CA-01 continua cumprido. Vale o arquiteto corrigir a premissa e o cliente confirmar.
- `SEGMENTO_ALIMENTOS` e `MSG_CONTATOS_CELULAR_APTOS` trazem um contato extra "Lead 5". É o contato criado pela conversão do lead 5 do fixture, não é defeito.
- Sobreposição de `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` com `LEADS_PROSPECCAO_PRIORIZADA` (EPLAST-42): já registrada no plano. Nenhum conflito de metadata encontrado com EPLAST-36, 37 ou 42: o PS tem as 12 FLS anteriores mais as novas, e o relatório da EPLAST-42 está intacto.

## Casos

Massa: fixture `fixtures/eplast43_publicos.apex`, rodado na dev com `TriggerUtility.bypassTrigger = true` na primeira linha. Sem o bypass não foi testado; o bypass passou a fazer parte do fixture. Proprietário: usuário ativo `005bJ00000piKAaQAM`, o próprio usuário de execução. Existe um segundo usuário da mesma conta de serviço, inativo (Id `005bJ00000hBJmYQAW`), não usado. Os relatórios foram lidos pela Analytics API (`GET /analytics/reports/<id>?includeDetails=true`), filtrando só linhas `EPLAST43-TESTE`.

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| Q1 | CA-01, CA-04 | Executei `LEADS_SEGMENTO_ALIMENTOS` | Leads 1, 3, 4; exclui 2 (opt-out e-mail) e 5 (convertido) | Leads 1 e 4. Excluiu 2 e 5. O lead 3 saiu por filtro preexistente de opt-out de celular (ver divergência) | passou (CA-01 e CA-04 cumpridos; esperado do design divergente) |
| Q2 | CA-01 | Executei `SEGMENTO_ALIMENTOS` | Contatos 1, 3, 4; exclui 2 | Contatos 1 e 4 (+ contato da conversão). Exclui 2 | passou (mesma ressalva) |
| Q3 | CA-02 | Executei `MSG_CONTATOS_CELULAR_APTOS` | Inclui 1 e 2; exclui 3 (opt-out celular) e 4 (sem celular) | Contatos 1 e 2 (+ contato da conversão). Exclui 3 e 4 | passou |
| Q4 | CA-02, CA-04 | Executei `MSG_LEADS_CELULAR_APTOS` | Inclui 1, 2, 4; exclui 3, 5, 6 | Leads 1, 2 e 4 | passou |
| Q5 | CA-04, PA-09 | Executei `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` | Inclui 1 e 3; exclui 2, 4, 5, 6 | Leads 1 e 3 | passou |
| Q6a | CA-05 | `FieldPermissions` do `PS_Marketing_Publicos`, `PermissionsRead=true` | 21 FLS, com as 9 novas | 21 linhas. Presentes: `Lead.LeadSource`, `Lead.MobilePhone`, `Lead.HasOptedOutOfEmail`, `Lead.et4ae5__Mobile_Country_Code__c`, `Contact.LeadSource`, `Contact.MobilePhone`, `Contact.HasOptedOutOfEmail`, `Contact.et4ae5__Mobile_Country_Code__c`, `Account.Type`, e as anteriores | passou |
| Q6b | CA-05 | `GET /folders/00lbJ000004l9K6QAI/shares` | `user/manage` preservado mais `group/view` | `[user/manage, group/view]`. Grupo `Marketing_Publicos` existe (`00GHa000006bP5eMAE`, "Públicos de Marketing") | passou |
| Q6c | CA-05 | Atribuir o PS ao usuário e ver o describe | Seria prova só por FLS | Não executado. O usuário é administrador, então o describe não prova FLS (risco R6 do design). Troquei por Q6a. Nenhuma alteração no usuário | não executado (substituído por Q6a) |
| Q7 | CA-06 | grep de `EmailAlert`, `sendEmail`, `Messaging.`, `SingleEmailMessage`, `emailAlerts`, `emailSimple` nos arquivos de `force-app` alterados na branch | Zero | Zero ocorrências | passou |
| Q8 | CA-07 | Diff `main...HEAD` em `force-app`: `classes`, `triggers`, `flows`, `workflows`, `objects` | Zero | Zero arquivos | passou |
| B5 | CA-04, CA-08 | grep de `<column>CONVERTED</column>` nos `LEADS_*` e `Cpia_de_LEADS_*` | Todos com o critério | Nenhum arquivo sem ele | passou |
| Q10 | CA-03 | Contagem de relatórios da pasta e lista no plano | 63 no plano, com nome e filtro | 64 na org (a conta fecha). Lista ausente no plano | falhou (FALHA 1) |
| Q9 | CA-08 | Contagem antes e depois nos 16 relatórios | Só na QA | Na dev há 0 leads reais, então não é mensurável. Cabe ao QA | não executado |
| Q11 | CA-10 | Roteiro do cliente | Existe depois do QA | Artefato de etapa posterior | não executado |

## Dados de teste e limpeza
- Criados: 2 Account, 4 Contact (mais 1 por conversão), 6 Lead, todos `EPLAST43-TESTE`, com `TriggerUtility.bypassTrigger = true`.
- Apagados por Apex anônimo na dev. Consulta final: 0 Lead, 0 Contact, 0 Account com o prefixo. Não ficou nada.
- Usuário de execução: nenhum campo, permission set ou opção alterados, então não há nada a devolver.

## O que pode ter saído da org
Nada. O bypass de trigger evitou a cadeia de `AccountTrigger`. Não criei Order, cotação nem log de integração. O Flow de atribuição de Lead pode ter rodado no insert, e os leads foram apagados em seguida. Nenhuma chamada externa registrada.

## Alterações no repositório (fixture, não implantadas)
- `clients/eplast/fixtures/eplast43_publicos.apex`: linha `TriggerUtility.bypassTrigger = true;` acrescentada no topo.
- `clients/eplast/fixtures/README.md`: status atualizado para executado.
- Sem commit pelo verificador.
