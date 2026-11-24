**Verificação:** reprovada
**Org de teste:** `sbx-eplast-dev` (org de sandbox, Connected; única org de `sf org list`)

# Verificação — EPLAST-27 (a ação aceita o código da conta no lugar do Id)

Cada caso rodou em Apex anônimo próprio (`Flow.Interview`, uma chamada por execução), com a massa criada em execuções anteriores.

## FALHA 1 — Código que casa uma única conta devolve AMBIGUOUS, com lista vazia
- **Como reproduzir:** na dev, com o Flow v3 ativo, chamar `Account_Agente_ProximaAcao` com `recordId='927001'` (código que existe em exatamente 1 conta, confirmado por `SELECT ProtheusId__c, COUNT(Id) ... GROUP BY`) e `accountName` nulo.
- **Obtido:** `AMBIGUOUS`, "Encontrei mais de uma conta com esse código: Diga qual delas você quer." (nenhum nome na lista). O mesmo ocorre para os códigos únicos 927004 e 927006 e para o duplicado 927002.
- **Esperado:** uma conta: segue por `GetAccount` e devolve a ação (A1, A2, A3, NONE, NODATA ou NOT_OWNER). Duas contas: `AMBIGUOUS` com nome e loja.
- **Causa provável (lida no `force-app/.../Account_Agente_ProximaAcao.flow-meta.xml`):** o laço `LoopNames` percorre sempre `collectionReference = GetAccountsByName`. No caminho por código, quem foi preenchido foi `GetAccountsByCode`, então o laço não tem o que percorrer: `matchCount` fica 0, `AfterNames` cai no ramo "Várias" (`SetAmbiguous`) e `nameList` fica vazio. O `HasCodeMatches` aponta para `LoopNames`, mas o laço não lê a coleção do código. Também não há como a lista trazer nome e loja. O builder precisa de um laço para `GetAccountsByCode` (ou colocar o resultado na mesma coleção) e conferir `Store__c` na lista.

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| K1 | Ação por Id (regressão), A1 | `recordId` = Id da conta C1 (risco E + oportunidade parada) | A1 "Tratar risco da conta" | A1, "Tratar risco da conta: ... risco E ..." | passou |
| K2 | Código de 1 conta devolve a ação | `recordId='927001'` (C1) | A1 | AMBIGUOUS, lista vazia | falhou |
| K2b | idem, conta NONE | `recordId='927004'` (C4) | NONE | AMBIGUOUS, lista vazia | falhou |
| K2c | Conta de outro dono por código | `recordId='927006'` (C6, outro dono) | NOT_OWNER ou regra de dono | AMBIGUOUS, lista vazia | falhou |
| K3 | Código em 2 contas lista nome e loja | `recordId='927002'` (C2 loja 001, C3 loja 002) | AMBIGUOUS com os 2 nomes e a loja | AMBIGUOUS, mas sem nome nem loja na mensagem | falhou |
| K4 | Código inexistente | `recordId='999999'` | NOT_FOUND de código | NOT_FOUND "Não encontrei conta com esse código que você possa ver." | passou |
| K5 | Texto que não é Id nem código | `recordId='abcxyz'` | NOT_FOUND | NOT_FOUND (mensagem de código) | passou |
| K7 | Conta sem código | `recordId='927005'` (C5 sem `ProtheusId__c`) | NOT_FOUND | NOT_FOUND (mensagem de código) | passou |
| K6 | Nome, uma conta (regressão) | `accountName='C2 A2'` | A2 | A2, "oportunidade em Qualificação sem atividade há 31 dias" | passou |
| K6b | Nome, várias contas | `accountName='TESTE EPLAST-27 C'` | AMBIGUOUS com até 5 nomes | AMBIGUOUS, 5 nomes + "e outras" | passou |
| K6c | Nome, nenhuma | `accountName` inexistente | NOT_FOUND de nome | NOT_FOUND "...com esse nome..." | passou |
| K8 | Sem Id e sem nome | ambos nulos | NOT_FOUND | NOT_FOUND "...com esse nome..." | passou |
| K9 | Conversa pelo agente v15 | não executado | n/a | `SFAgent2` não foi ativado nem chamado; só o Flow foi testado direto | não executado |
| K10 | "A consulta não grava", sem e-mail, sem dado pessoal, limiar em Custom Metadata, mesma regra para consumidores | fora do que esta rodada mudou (nenhuma dessas partes foi alterada pelo build); não reexecutados | n/a | n/a | não executado |

Com a FALHA 1, o critério principal desta rodada (buscar a conta pelo código) não é atendido: nenhum código devolve ação.

## Massa usada (sintética)
- Execução de `fixtures/conta-oportunidade-proxima-acao.apex` (blocos SELLER e MASSA): 7 contas `TESTE EPLAST-27 C1..C7`, oportunidades e tasks sintéticas.
- Novo `fixtures/conta-codigo-protheus.apex`: `ProtheusId__c` 927001 (C1), 927002 (C2 e C3, lojas 001 e 002), 927004 (C4), 927006 (C6, de outro dono). Com `TriggerUtility.bypassTrigger`.
- O dono "outro" da C6 é escolhido pelo script entre os usuários ativos Standard; nenhum registro dele foi lido ou alterado. O usuário de teste da Konecta (Id `005bJ00000piKAaQAM`, ativo, Administrador) foi o proprietário e o executor.

## O que foi mudado no usuário de execução e desfeito
- `User.ProtheusSellerId__c` do `005bJ00000piKAaQAM`: antes `null`, durante `TESTE27`, depois `null` (conferido por consulta). Perfil, papel e permission sets não foram tocados.

## O que foi ativado para teste
- Flow `Account_Agente_ProximaAcao` v3 (era Draft, exigido pelo plano) foi ativado via Tooling API. Ao final reativei a v2, que era a ativa. **Estado final na dev: v1 Obsoleta, v2 Ativa, v3 Obsoleta** (a v3 deixou de ser Draft ao ser ativada; o build corrigido na dev vai gerar a v4 no deploy). Agente `SFAgent2`: não tocado (v13 ativa).

## Limpeza
- Apagados: Cases, Tasks, Opportunities, Accounts, Branch__c e PaymentTerms__c `TESTE EPLAST-27%`. `COUNT(Account)` voltou a 2 (as originais). Nada ficou. Sem job agendado.

## O que pode ter saído da org
- Nada: `TriggerUtility.bypassTrigger` ligado nos DMLs de `Account`, nenhuma chamada ao Protheus ou BrasilAPI; sem e-mail (o Flow não tem DML nem e-mail).

## Sem prova
- Conversa pelo agente (v15 ativo) e formato real do código no Protheus (a dev não tem conta com `ProtheusId__c`; os 6 dígitos usados são sintéticos).
