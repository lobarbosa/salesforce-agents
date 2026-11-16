**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# Verificação — EPLAST-27 (ação aceita o nome da conta, Flow v3 e SFAgent2 v15)

Org conferida com `sf org list`: `sbx-eplast-dev` (Sandbox, Connected, a única conectada; é a "QA" da Eplast, regra 5 da conta). QA da esteira e produção não tocadas.

## Estado conferido na org (consulta)
- Flow `Account_Agente_ProximaAcao`: v1 Obsolete, v2 Active, **v3 Draft**.
- `SFAgent2`: v13 Active, v14 Inactive, **v15 Inactive**.
- `COUNT` de Account `TESTE EPLAST-27%` na dev: 0. Nenhum dado de teste criado, nenhum usuário alterado, nada a desfazer.

## Por que inconclusiva
A construção desta rodada (busca por nome, `AMBIGUOUS`, `NOT_FOUND`, v15 do agente) só roda quando o Flow v3 e o agente v15 estão ativos:
- A ação do agente chama a versão **ativa** do Flow (v2, que não conhece `accountName`). Flow em Draft não é executável por Apex (`Flow.Interview`), pela API de ações nem pelo agente; só pelo depurador da tela do Flow, que não é acessível nesta sessão.
- O agente v15 está inativo e `sf agent preview` conversa com a versão ativa; a v15 não pode ser exercitada sem ativá-la. Ativar é passo separado e fora do que o verificador pode fazer (regra da etapa: não alterar o build). Testar a v13 ativa pelo Id exercitaria o comportamento antigo, que não é o que esta rodada construiu.

Por isso nenhum caso foi executado e nenhum critério é dado como provado.

## Única checagem feita (estática, não conta como prova)
Metadata do Flow na branch: contém a entrada `accountName`, os resultados `NOT_FOUND` e `AMBIGUOUS`, descrição da v3 coerente com o plano e `<status>Draft</status>`. Não há ação de e-mail nem DML de Account/Opportunity/Task (busca por `emailSimple`, `recordCreates`, `recordUpdates` sem ocorrências). Isso é leitura de código, não execução.

## Tabela de casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | A1 (risco alto sobre A2) | Nada: v3/v15 inativos | "Tratar risco da conta", sem A2 | sem evidência | não executado |
| 2 | A2 parada | idem | "Retomar oportunidade parada" + estágio | sem evidência | não executado |
| 3 | A3 inativo 91 dias | idem | "Reativar cliente sem compra recente" | sem evidência | não executado |
| 4 | NONE | idem | "Nenhuma ação prioritária no momento" | sem evidência | não executado |
| 5 | NODATA | idem | "Dados insuficientes para sugerir ação", sem erro técnico | sem evidência | não executado |
| 6 | Conta de outro dono | idem | não revela dados | sem evidência | não executado |
| 7 | Consulta não grava | idem | LastModifiedDate intacto | sem evidência | não executado |
| 8 | Sem comunicação pelo CRM | leitura estática do XML | sem e-mail alert/ação de mensagem | nenhuma ocorrência no Flow v3 | não executado (só leitura) |
| 9 | Sem dado pessoal na resposta | idem | sem CPF/e-mail/telefone | sem evidência | não executado |
| 10 | Limiar por Custom Metadata | idem | A2 some com limiar 60 | sem evidência | não executado |
| 11 | Mesma regra para outros consumidores | idem | mesmo resultado | sem evidência | não executado |
| 12 | Nome único, ambíguo, inexistente, pergunta de continuação (novo desta rodada) | idem | segue / lista até 5 / NOT_FOUND / chama a ação de novo | sem evidência | não executado |

## O que uma pessoa precisa fazer para provar
1. Na dev, ativar o Flow `Account_Agente_ProximaAcao` v3 e depois o `SFAgent2` v15 (ordem do plano de build).
2. Rodar a verificação de novo: fixture `fixtures/conta-oportunidade-proxima-acao.apex` (seller + massa), conversa com `sf agent preview start/send/end`, por nome e por Id, 3 tentativas por cenário em sessões novas; depois apagar a massa (Case antes de Account, conforme o topo da fixture) e devolver `ProtheusSellerId__c`.
3. Alternativa sem ativar o agente: ativar só o Flow v3 e exercitá-lo por Apex anônimo (`Flow.Interview.createInterview`) com a massa da fixture, deixando o agente para o QA.

## O que pode ter saído da org
Nada: nenhum registro criado, nenhuma automação disparada.
