**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-38 · Testes na QA: roteamento regional do lead

Org confirmada com `sf org list`: `sbx-eplast-qa` (org 00DHa000006vZtmMAE, Partial Copy "eplast--qas"). Pacote do deploy `0AfHa00000EI5PNKA1` conferido na org: as 8 filas, a regra `Distribuicao_Regional_Leads` (ativa), o Flow `Lead_AfterInsert_AplicaRegraAtribuicao` (v1, ativo, única versão), `LeadAssignmentService` e `LeadAssignmentServiceTest`, e o permission set `PS_Integracao_DistribuicaoLead` existem.

Dados: só Leads com `LastName` iniciado por `EPLAST38-TESTE-`, criados pelos scripts de `fixtures/` (copiados para /tmp com o modo trocado). Consultas só por contagem agregada ou por esse prefixo. Ao fim, `LIMPAR` apagou 233 Leads e a contagem final do prefixo é 0.

Usuário de teste da regra 6: dois usuários da conta de serviço da Konecta existem na QA (busca por padrão de username, sem citar o login). `005bJ00000piKAaQAM` (ativo, Administrador do sistema, é o usuário de execução desta sessão) e `005bJ00000hBJmYQAW` (inativo). Usei só o ativo como dono informado. Nenhum perfil, permissão ou papel foi alterado.

## Falhas
Nenhuma.

## Resultado por critério

| Caso | Critério | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|---|
| 1 | CA-01 | REGRA, Lead State=SP, com cabeçalho de regra | Leads SP | SP e "sp" em Leads SP (2) | passou |
| 2 | CA-02 | State vazio, "São Paulo", "sp" | Triagem; "sp" em SP | Consulta por Lead: "São Paulo" e nulo em Leads Triagem; "sp" em Leads SP | passou |
| 3 | CA-03 | 30 Leads (27 UF + 3 especiais) | Tabela 3.1 do design | 30 de 30 inseridos. SP 2, RJ 1, MG 1, ES 1, Sul 3, Centro-Oeste 5, Norte e Nordeste 15, Triagem 2 | passou |
| 4 | CA-04 ramo sem regra | MANTER_DONO: dono = usuário `005bJ00000piKAaQAM`, sem cabeçalho | Dono continua o usuário | Owner.Type = User (1 Lead) | passou |
| 5 | CA-04 ramo com regra | Dono usuário informado + cabeçalho de regra, SP | Regra define a fila | Leads SP | passou |
| 6 | CA-05 | Status "Aberto - Não contatado", setor e origem preenchidos | Score 60 / Média | MIN e MAX de `PriorityScore__c` nos 30 Leads = 60 | passou |
| 7 | CA-05 | Status "Contatado", SP | Score 100 / Alta | 100 / Alta, dono Leads SP | passou |
| 8 | CA-06 (caminho A/D) | MASSA_REGRA, 200 Leads numa operação | 200 de 200, nenhum com dono usuário, distribuição da tabela | 200 de 200. Sul 24, RJ 8, CO 39, SP 8, ES 8, MG 8, NO/NE 105 (soma 200). 0 Leads com dono usuário. Sem erro de governador | passou |
| 9 | CA-07 | Metadata do pacote e filas na org | Sem e-mail, template ou envio | Regra com 0 `<template>`; 8 filas com `DoesSendEmailToMembers=false` e sem e-mail; Flow sem ação de e-mail (única ocorrência de "http" é o namespace XML); classe com 0 ocorrências de envio | passou |
| 10 | Cobertura | `sf apex run test -n LeadAssignmentServiceTest -c` na QA | Mínimo 85% | 7 de 7 passaram, `LeadAssignmentService` 100% | passou |

## Não executado na QA
- **Caminho C (integração com o permission set, assíncrono; parte de CA-03 e CA-06).** Exigiria atribuir `PS_Integracao_DistribuicaoLead` ao usuário de execução, que é a conta de serviço da regra 6, e a regra proíbe alterar permissão dela. Não executado. A evidência vem da dev (`04-verificacao.md`, casos 4a e 10: 30 e 200 Leads, distribuição idêntica, 0 com dono usuário) e do teste Apex na QA (caso 10). Não é critério principal isolado: CA-01 a CA-07 foram provados pelos caminhos A/D. Fica como conferência do time técnico se a integração real for usada.
- **Membros das filas:** 0 membros nas 8 filas da QA (`GroupMember` = 0). É passo do operador (design, seção 7), não é falha. O roteamento prova-se pelo dono (fila).
- **Teste pela tela (`qa_browser_*`):** não usado. Os caminhos de criação foram exercidos por Apex anônimo com o mesmo cabeçalho de regra de atribuição que a tela e a API usam. Fica no roteiro do cliente.

## Efeito combinado com EPLAST-26 e EPLAST-35
Ambas aguardam homologação e tocam os mesmos componentes (layout de Lead, regra, filas, Flow e classe). O deploy desta demanda é idêntico em conteúdo ao que já é versionado; o Flow continua com uma única versão (v1) e a regra continua uma só, sem sobreposição. Nenhum conflito observado na QA com os 233 Leads de teste.

## O que pode ter saído da org
- 233 Leads sintéticos criados e depois apagados (contagem final 0). Eles ficam na lixeira da org até esvaziar.
- Nenhum e-mail: regra sem template e filas sem envio. Nenhuma chamada externa. Marketing Cloud não foi tocado.
- Nenhuma alteração em usuário, permission set, fila ou membro.
