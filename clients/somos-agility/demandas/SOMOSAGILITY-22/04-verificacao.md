**Verificação:** inconclusiva
**Org de teste:** `sbx-somos-agility-dev`
**Data:** 2026-11-15

# 04 — Verificação: SOMOSAGILITY-22

Org confirmada com `sf org list`: única conectada, `sbx-somos-agility-dev` (sandbox, orgId `00DHa0000070wxfMAA`). Todos os comandos passaram `--target-org` explícito. QA não foi tocada. Nenhum DML, nenhum Apex anônimo, nenhum dado de teste criado; nada a apagar. Nenhum registro de usuário foi lido ou alterado.

## O que foi verificado (metadata, por consulta à dev)

- Retrieve do `ApprovalProcess` `JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento` da dev, em diretório temporário dentro do projeto, depois apagado. O arquivo é idêntico ao versionado no repositório (`diff` sem diferença).
- O processo está `active=true`, `processOrder=2`, com 4 `approvalStep` e `initialSubmissionActions` = `Status_Qualificacao` (FieldUpdate), linhas 275-280. O `recallActions` referencia `Status_Qualificacao_Recall`.
- Não houve ativação nem edição de nada nesta sessão.
- Não conferi o conteúdo do FieldUpdate `Status_Qualificacao` (valor gravado) nem o Workflow nesta sessão. O plano de build afirma que grava `Pendente`; isso ficou como declaração do construtor, sem confirmação minha.

## Por que o envio não pôde ser exercitado

1. `CreatedById` no objeto de Job tem `createable=false` e `updateable=false` (`sf sobject describe`, filtrado). A opção A do plano (criar o Job com `CreatedById` de outro usuário) não vale: "Set Audit Fields upon Record Creation" não está ativo na dev.
2. Login-as não é feito por `sf data` nem por Apex anônimo. Exigiria sessão de outro usuário, o que não posso fazer sem usar credenciais ou alterar acesso de outro usuário (fora da minha autorização).
3. Os critérios de entrada dos processos ativos dependem do criador do Job, e o meu usuário de execução não está na lista. O envio daria `NO_APPLICABLE_PROCESS`, como na falha 1 da rodada 1 da QA. Não criei registro para repetir esse erro.
4. A dev tem 0 Jobs (`SELECT COUNT(Id)`, contagem agregada). Não há Job existente para reaproveitar, e eu não leria nem alteraria registro que não criei.
5. `clients/somos-agility/fixtures/` não existe, então não havia script de Job.

## Tabela de casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Config: `Status_Qualificacao` no envio inicial do processo de ordem 2 | Retrieve do ApprovalProcess da dev e leitura do XML | `initialSubmissionActions` com `Status_Qualificacao` | Presente (linhas 275-280), processo ativo | passou |
| C2 | Config igual ao repositório | `diff` entre dev e arquivo versionado | Sem diferença | Idêntico | passou |
| C3 | Sem etapas ou aprovadores alterados | Contagem de `approvalStep` | 4 | 4 | passou |
| C4 | Job enviado vira "Pendente" | Não exercitado (ver acima) | `Status_da_Qualificaco__c = Pendente` | Sem evidência | não executado |
| C5 | Aprovado, Rejeitado, reenvio do rejeitado volta a Pendente | Não exercitado | Aprovado / Rejeitado / Pendente | Sem evidência | não executado |
| C6 | `Status_Previs_o_de_Gastos__c` não muda | Não exercitado | Inalterado | Sem evidência | não executado |
| C7 | Nenhum job some do relatório, rosca = linhas | Não exercitado; relatório intocado e dev com 0 Jobs, então a contagem na dev não prova nada | Total igual a N | Sem evidência | não executado |
| C8 | Filtro do relatório cobre todos os status | Não exercitado; depende de Q1 e G2, sem resposta | Todos os valores cobertos | Sem evidência | não executado |
| C9 | Dashboard = relatório | Não exercitado; depende de Jobs e de Q1 | Contagens iguais | Sem evidência | não executado |
| C10 | Regressão do lookup `Relacionado_ao_Job__c` só com Job aprovado | Não exercitado | Só aceita Aprovado | Sem evidência | não executado |
| C11 | Nenhum dado de cliente no teste | Só metadata e contagem agregada, sem DML | Sem dado real | Cumprido | passou |

## Sem prova

- O comportamento principal: que o envio para aprovação grava `Pendente`, e as transições para Aprovado, Rejeitado e o reenvio. A configuração está certa, mas a execução não foi vista.
- O conteúdo do FieldUpdate `Status_Qualificacao` e o Workflow, por metadata.
- Relatório, filtro, dashboard e lookup: intocados nesta demanda, e sem Job na dev para comparar.

Para provar, uma pessoa precisa de uma destas:
- Um usuário de teste sintético na dev, que satisfaça os critérios de entrada do processo de ordem 2. Esse usuário deve ser registrado no `CLAUDE.md` do cliente, e o verificador precisa poder atuar como ele.
- Alguém com acesso fazer o envio manualmente na dev, ou na QA com o usuário certo, com um Job sintético (`TESTE SOMOSAGILITY-22`), e conferir o status.

## Pontos fora desta verificação (sem julgamento)

1. Pedido do cliente de 30/10 (obrigar "Classificação gerencial" e "Denominação" na aprovação): não está na análise nem no design e não foi construído. Não é escopo deste build.
2. G2 (janela do relatório), G3 (Jobs já em aprovação) e G4 (produção igual a dev) seguem sem resposta. O relatório continua intocado. Nada foi inventado.

## O que pode ter saído da org

Nada. Nenhum registro foi criado e nenhuma automação foi disparada.

## Recomendação ao gate humano

A configuração do processo de aprovação está correta e igual ao repositório, mas o envio não foi provado: decida se aceita com envio manual de um Job sintético na dev, ou forneça um usuário de teste que entre no processo de ordem 2.
