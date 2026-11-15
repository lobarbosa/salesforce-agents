**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-29 · Verificação do build

Org confirmada com `sf org list` (única: `sbx-eplast-dev`, sandbox, conectada). Só metadata, contagens e chamadas ao Flow que não gravam. Nenhum dado de teste foi criado, então não há o que apagar.

## Por que inconclusiva
O critério principal (criar a tarefa com confirmação, AC-1) e o AC-4 não puderam ser exercitados. Nenhum caso falhou.

1. **Caminho de sucesso sem prova.** Exige Account ou Opportunity sintética. Criar Account dispara `AccountTrigger`, e o código de `ProtheusAPI.sendClientToProtheus` faz callout para `Protheus__mdt.Credentials.BaseURL__c`. Na dev esse valor é um endereço `http://<IP>:8400`, e não há como saber por metadata se é ambiente não produtivo (R8 do design). `comentarios-do-card.md` não traz autorização escrita para testar com esse risco, então não disparei. Também não li registros existentes (não os criei).
2. **AC-4 sem prova.** Exige usuário de perfil `Comercial - Analista` sem acesso ao registro e licença de Agentforce (0 atribuições; R9). Isso é administração de usuário, não feita aqui.
3. **Parte conversacional (AC-1 a AC-3, AC-5 a AC-9 pelo agente) sem prova.** Sem licença de Agentforce e sem atribuição do PS (0 atribuições de `PS_Comercial_AssistenteAcoes`), não há conversa com o `SFAgent2` na dev.
4. **R5 (`DefaultMode` x contexto do agente)** não provado, depende do item 1.

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | AC-5 (guarda) | POST `/actions/custom/flow/Task_Agente_CriarTarefa` sem data | `Sucesso=false`, pede data, sem gravar | `Sucesso=false`, "Informe a data de vencimento da tarefa." | passou |
| C2 | AC-5 (guarda) | Mesmo Flow, assunto vazio | `Sucesso=false`, pede assunto | `Sucesso=false`, "Informe o assunto da tarefa." | passou |
| C3 | AC-7/AC-8 (check-in) | Assunto `Check In @ ...` | Recusa, sem Task | `Sucesso=false`, recusa de check-in | passou |
| C4 | AC-7 (outro objeto) | Id com prefixo `801` | Recusa de objeto | `Sucesso=false`, "só conta ou oportunidade" | passou |
| C5 | AC-5/AC-3 | Id `001` inexistente | "não encontrado ou sem acesso", sem Task | `Sucesso=false`, "Registro nao encontrado ou sem acesso." | passou |
| C6 | Nenhuma gravação nas guardas | `SELECT COUNT() FROM Task` depois de C1-C5 | 0 | 0 | passou |
| C7 | AC-9 / rollback | Query em `BotVersion` do `SFAgent2` | v5 Active, v4 Inactive | v5 `Active`, v4 `Inactive` | passou |
| C8 | PD-6 (PS) | Contagem de `SetupEntityAccess` do PS | 2 (Flow + agente) | 2 | passou |
| C9 | AC-1 (sucesso, criar Task) | Não executado: Account sintética dispararia callout Protheus sem autorização | Task criada com Subject, ActivityDate, WhatId, Owner = solicitante, Origem na descrição | n/a | não executado |
| C10 | AC-2 | Não executado: exige conversa com o agente | Recusa do resumo não grava | n/a | não executado |
| C11 | AC-3 | Não executado (conversa; precisa de dois registros sintéticos) | Lista candidatos, não grava | n/a | não executado |
| C12 | AC-4 | Não executado: sem usuário de teste e licença | Recusa sem vazar dado | n/a | não executado |
| C13 | AC-6 | Não executado: conversa | Rascunho como Task, sem envio | n/a | não executado |
| C14 | AC-7 (conversa) | Não executado: conversa | Recusa de outro objeto, sem gravar | n/a | não executado |
| C15 | AC-8 | Não executado: depende de C9 | Task rastreável pelo Origem na descrição | n/a | não executado |
| C16 | AC-9 (comportamento) | Só metadata conferida (C7); leitura de pedidos não exercitada | Leitura igual à v4 | n/a | não executado |

## O que uma pessoa precisa fazer para provar
- Confirmar que o endereço de `Protheus__mdt.Credentials` na dev é não produtivo, ou autorizar por escrito em `comentarios-do-card.md` a criação mínima de `TESTE EPLAST-29` Account (e Opportunity). Com isso, rodar C9, C15 e o debug log sem DML em Account.
- Atribuir licença de Agentforce e `PS_Comercial_AssistenteAcoes` a um usuário `Comercial - Analista` de teste (e a um segundo sem acesso ao registro para o AC-4), depois rodar C10-C14 e C16 na conversa com o `SFAgent2` v5.
- Se na conversa o Flow rodar em contexto de sistema (R5), o plano prevê trocar `runInMode` para `SystemModeWithSharing`.

## O que pode ter saído da org
Nada. Nenhum registro foi criado e nenhum callout externo disparado.
