**Verificação:** inconclusiva
**Org de teste:** `sbx-somos-agility-dev`

# 04 — Verificação: SOMOSAGILITY-22 (reverificação, regras de 15/11)

Org confirmada com `sf org list`: única conectada, `sbx-somos-agility-dev` (Sandbox, Connected). Usuário de execução: "Konecta Consultoria", perfil Administrador do sistema. Nada tocado em QA ou produção.

## Divergência do preflight
`00-preflight.md` diz "Etapa: build / sem componentes no repositório". No disco há um componente construído: `force-app/main/default/approvalProcesses/JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento.approvalProcess-meta.xml` (ação de envio inicial `Status_Qualificacao`). Há também `04-plano-build.md`. O preflight está defasado e o build existe.

## Conclusão
Não foi possível exercitar o critério principal (Job vai a "Pendente" ao ser enviado para aprovação) por motivo que o builder não resolve. Não é defeito comprovado.

**Motivo:** todos os critérios de entrada do processo alterado dependem do nome do usuário criador do Job (`CreatedBy` igual a nomes de pessoas e grupos específicos do cliente) mais `Status_da_Qualificaco__c` diferente de "Aprovado". O usuário de execução ("Konecta Consultoria") não está em nenhuma dessas listas. Pela regra desta etapa só posso alterar nesse usuário os campos autorizados (campo exigido por validation rule, permission set da demanda, Marketing User). O nome não está entre eles. Também não posso criar Jobs como usuário real nem alterar outro usuário.

## Estado confirmado na dev (metadata)
- Processos de aprovação do objeto (consulta `ProcessDefinition`): `Aprova_o_JOB` (Active), `JOB_de_solicitacoes_de_investimento` (Active, o alterado), 3 `JOBSolicitacaoInvestimento*` (Obsolete) e `JOB_de_solicitacoes_de_investimentos` (Inactive).
- Picklist `Status_da_Qualificaco__c`: Não Enviado, Pendente, Aprovado, Rejeitado, Recall.
- Validation rules ativas no objeto: 7 (Classificacao_Gerencial 1 a 5, Formato_CNPJ, Checa_o_Preenchimento_dos_Campos_CEO). Nenhuma impediu criar o Job de teste.
- O objeto tinha 0 registros na dev antes do teste (contagem agregada).
- O XML versionado contém o bloco `initialSubmissionActions` com `Status_Qualificacao`. Isso é só leitura do arquivo, não prova o comportamento.

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Envio inicial muda status para "Pendente" (critério do design, causa raiz) | Apex anônimo: inseri 1 Job `TESTE SOMOSAGILITY-22` (campo `Observa_o__c`; `Name` é autonumber) e chamei `Approval.process` | Status "Não Enviado" antes, "Pendente" depois do envio | Antes: `Não Enviado` / `Status_Previs_o_de_Gastos__c` = `Fechado`. Envio: `NO_APPLICABLE_PROCESS, Não foi encontrado nenhum processo de aprovação aplicável`. Depois: continuou `Não Enviado` / `Fechado` | não executado (usuário fora dos critérios de entrada; não é falha da construção) |
| C2 | Aprovar leva a "Aprovado" | Depende de C1 | "Aprovado" | Sem processo em andamento para aprovar | não executado |
| C3 | Rejeitar leva a "Rejeitado" e reenvio volta a "Pendente" | Depende de C1 | "Rejeitado", depois "Pendente" | Idem | não executado |
| C4 | `Status_Previs_o_de_Gastos__c` não muda com o envio (R4 do design) | Depende de C1 | Sem alteração | Valor `Fechado` estável, mas sem envio efetivo | não executado |
| C5 | Relatório não perde Jobs e rosca = linhas (analise, cenário 1) | Não aplicável na dev | Total do relatório = N | Dev tem 0 Jobs; relatório e dashboard não são alterados pela construção (G2 sem resposta) | não executado |
| C6 | Dashboard bate com relatório (analise, cenário 4) | Idem C5 | Contagens iguais | Sem dados na dev | não executado |
| C7 | Nenhum dado de cliente nos testes | Só dado sintético, nenhum SOQL de dado de cliente | Nenhum dado real | Atendido: só contagem agregada e 1 registro sintético, apagado | passou |

## Riscos do assessment
- Automação concentrada em Oportunidade (31 automações): não se aplica. A construção só toca um processo de aprovação em objeto custom de Job, sem tocar em Oportunidade.
- Cobertura Apex baixa: a construção não tem Apex. O plano de build já registra que a validação completa falha por testes pré-existentes quebrados da org (não reexecutado aqui).
- Efeito colateral em outro processo ativo: o objeto tem 2 processos ativos (`Aprova_o_JOB` e o alterado). Qual deles pega um envio depende da ordem e dos critérios. Isso não foi exercitado.

## Dados de teste e limpeza
- Criado: 1 Job com `Observa_o__c` = "TESTE SOMOSAGILITY-22 job 1". Apagado. Consulta de conferência devolveu 0 registros com esse texto.
- Usuário de execução: nenhuma alteração (sem campo, permission set ou Marketing User).
- Nenhum job agendado criado.

## O que pode ter saído da org
Nada. O envio falhou antes de iniciar o processo, então não houve e-mail de aprovação nem outra chamada externa.

## O que uma pessoa precisa fazer para provar
1. Na dev ou na QA, com um usuário cujo nome esteja nos critérios de entrada do processo (por exemplo, um usuário de teste de um dos grupos nomeados, autorizado pelo cliente), criar 1 Job de teste e enviá-lo para aprovação. Esse usuário não pode ser de uma pessoa real sem autorização.
2. Conferir que o status vira "Pendente" e que `Status_Previs_o_de_Gastos__c` não muda. Depois aprovar, rejeitar e reenviar, conferindo o status.
3. Alternativa: o cliente ou o arquiteto indicar um usuário de teste no `CLAUDE.md` do cliente (hoje não há) para o verificador e o QA usarem como criador do Job.

## Pontos abertos que não são desta verificação
- G2 (janela do relatório), G3 (correção de dados em aprovação) e G4 (produção igual à dev) continuam abertos, segundo o `04-plano-build.md`.
- O comentário do cliente de 2026-10-30 pede tornar obrigatórios "Classificação gerencial" e "Denominação" na aprovação do Walmor. O plano de build não registra essa mudança. A dev tem a regra `Classificacao_Gerencial` (condicional), mas não confirmei se o pedido foi atendido. Fica como ponto a decidir no gate.
