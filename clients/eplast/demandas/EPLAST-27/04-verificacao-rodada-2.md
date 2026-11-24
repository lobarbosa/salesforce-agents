**Verificação:** reprovada
**Org de teste:** `sbx-eplast-dev`

# Verificação — EPLAST-27 (a ação aceita o código da conta no lugar do Id), nova rodada

`sf org list`: única org conectada, `sbx-eplast-dev` (Sandbox, Connected). QA e produção não tocadas. Esta é a rodada seguinte a `04-verificacao-rodada-1.md`, que reprovou com a FALHA 1. Cada caso rodou em Apex anônimo próprio (`Flow.Interview`, uma chamada por execução), com a massa criada em execuções separadas.

## Retestes da rodada anterior
- **FALHA 1 (código que casa uma conta devolve AMBIGUOUS com lista vazia): NÃO corrigida.** Reproduzida de novo (casos K2 e K3). O Flow do repositório (`clients/eplast/force-app/main/default/flows/Account_Agente_ProximaAcao.flow-meta.xml`) continua com o laço `LoopNames` em `collectionReference = GetAccountsByName` (linha 491). O caminho por código preenche `GetAccountsByCode`, que o laço não percorre, então `matchCount` fica 0 e cai em `AMBIGUOUS` sem nomes.

## FALHA 1 — Código da conta nunca devolve a ação; sempre AMBIGUOUS sem lista
- **Como reproduzir:** na dev, com o Flow v3 ativo, `Flow.Interview` com `recordId='927001'` (código de exatamente 1 conta de teste, gravado pela fixture `conta-codigo-protheus.apex`).
- **Obtido:** `AMBIGUOUS`, "Encontrei mais de uma conta com esse código: Diga qual delas você quer." Sem nome nem loja. Igual para o código duplicado `927002`.
- **Esperado:** uma conta, ação dela (A1, A2, A3, NONE, NODATA ou NOT_OWNER); duas contas, `AMBIGUOUS` com nome e loja.
- **Causa provável:** o laço `LoopNames` e a fórmula da lista (linha 462, que já tem a loja) leem `GetAccountsByName`. Falta o laço (ou a cópia do resultado de `GetAccountsByCode` para a coleção percorrida), e, no ramo de uma conta só, usar o Id dela e seguir por `GetAccount`.

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| K1 | Id válido (regressão) | `recordId` = Id da conta C1 (risco E) | A1 | A1, "Tratar risco da conta: ... risco E ..." | passou |
| K2 | Código que casa uma conta | `recordId='927001'` (C1) | A1 | AMBIGUOUS, lista vazia | falhou |
| K3 | Código que casa duas contas | `recordId='927002'` (C2 loja 001, C3 loja 002) | AMBIGUOUS com nome e loja | AMBIGUOUS, sem nome nem loja | falhou |
| K4 | Código inexistente | `recordId='999999'` | NOT_FOUND de código | NOT_FOUND "Não encontrei conta com esse código que você possa ver." | passou |
| K5 | Texto que não é Id nem código | `recordId='abcxyz'` | NOT_FOUND | NOT_FOUND (mensagem de código) | passou |
| K6 | Vazio com `accountName` (regressão) | `accountName='C2 A2'` | A2 | A2, "Retomar oportunidade parada: ... Qualificação sem atividade há 31 dias" | passou |
| K7 | Conta de outro dono por código | não executado: sem o K2 corrigido o código não chega ao `GetAccount` | NOT_OWNER | n/a | não executado |
| K8 | Conversa pelo agente | `SFAgent2` v15 não ativado nem chamado; só o Flow direto | n/a | n/a | não executado |

Passaram 4 (K1, K4, K5, K6), falharam 2 (K2, K3). O critério principal desta rodada (buscar a conta pelo código) não é atendido.

## Massa e mudanças feitas na dev, e o que foi desfeito
- Fixtures `conta-oportunidade-proxima-acao.apex` (blocos SELLER e MASSA) e `conta-codigo-protheus.apex`: 7 contas `TESTE EPLAST-27 C1..C7` e dados dependentes, `ProtheusId__c` em 5 delas. Todas sintéticas, com `TriggerUtility.bypassTrigger`. Proprietário e executor: usuário de teste Konecta `005bJ00000piKAaQAM` (a C6 tem outro dono Standard, escolhido pelo script, sem leitura nem alteração de registro dele).
- `User.ProtheusSellerId__c` do `005bJ00000piKAaQAM`: antes `null`, durante `TESTE27`, depois `null` (conferido por consulta). Perfil, papel e permission sets intocados.
- **Flow `Account_Agente_ProximaAcao`, ativação na dev:** antes v2 Ativa e v3 **Obsoleta** (não Draft, como diz o plano de build; a rodada anterior a ativou e desfez). Ativei a v3 por Tooling API (`FlowDefinition.Metadata.activeVersionNumber=3`) só para testar e **reativei a v2 ao final**. Estado final conferido: v1 Obsoleta, v2 Ativa, v3 Obsoleta. Nenhuma metadata foi alterada, só a versão ativa, restaurada.
- Dados de teste apagados (Case, Task, Opportunity, Account, Branch__c, PaymentTerms__c `TESTE EPLAST-27%`); contagem de contas `TESTE EPLAST-27%` depois: 0. Nada ficou.

## O que pode ter saído da org
Nada. Contas criadas com o desvio de trigger (sem Protheus nem BrasilAPI); sem e-mail, o Flow não faz DML nem envio. As oportunidades ganhas geraram Cases de pós-vendas por automação interna, apagados.

## Sem prova
Caso NOT_OWNER por código (K7) e conversa pelo agente (K8), dependem da correção da FALHA 1 e da ativação do agente v15. O formato de 6 dígitos de `ProtheusId__c` segue sem confirmação por contagem na dev (premissa do build).
