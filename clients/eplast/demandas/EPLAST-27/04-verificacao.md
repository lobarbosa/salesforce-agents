**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev`

# Verificação — EPLAST-27 (rodada 3: correção do laço do código da conta)

`sf org list`: única org conectada, `sbx-eplast-dev` (Sandbox, Connected, usuário de execução da conta de serviço da Konecta, identificado pelo alias). QA e produção não tocadas. Cada caso rodou em Apex anônimo próprio (`Flow.Interview`, uma chamada por execução), com a massa criada em execuções separadas.

## Reteste da rodada anterior
- **FALHA 1 (código que casa uma conta devolvia AMBIGUOUS com lista vazia): CORRIGIDA.** K2 devolve a ação da conta; K3 devolve a lista com nome e loja. Flow v4 (laço `LoopCodes`) ativado na dev só para testar.

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| K1 | Id válido (regressão) | `recordId` = Id da C1 | A1 | A1, "Tratar risco da conta: ... risco E ..." | passou |
| K2 | Código que casa uma conta | `recordId='927001'` | A1 | A1 (mesma mensagem do K1) | passou |
| K3 | Código que casa duas contas | `recordId='927002'` | AMBIGUOUS com nome e loja | AMBIGUOUS: "C2 A2 parada (loja 001); C3 A3 inativo (loja 002)" | passou |
| K4 | Código de conta sem pendência | `recordId='927004'` | NONE | NONE, "Nenhuma ação prioritária no momento." | passou |
| K5 | Código inexistente | `recordId='999999'` | NOT_FOUND de código | NOT_FOUND, "Não encontrei conta com esse código que você possa ver." | passou |
| K6 | Texto que não é Id nem código | `recordId='abcxyz'` | NOT_FOUND | NOT_FOUND (mensagem de código) | passou |
| K7 | Conta de outro dono por código (carteira) | `recordId='927006'` (C6, outro dono) | NOT_OWNER sem dado da conta | NOT_OWNER, "Esta conta não está na sua carteira." | passou |
| K8 | Nome, uma conta (regressão) | `accountName='C2 A2'` | A2 | A2, "oportunidade em Qualificação sem atividade há 31 dias" | passou |
| K9 | Nome, várias (regressão) | `accountName='TESTE EPLAST-27'` | AMBIGUOUS, até 5 nomes | AMBIGUOUS com 5 nomes e "e outras" | passou |
| K10 | Nome, nenhuma (regressão) | `accountName='ZZZNAOEXISTE27'` | NOT_FOUND | NOT_FOUND "...com esse nome..." | passou |
| K11 | Carteira por Id (regressão) | Id da C6 | NOT_OWNER | NOT_OWNER | passou |
| K12 | A3 (91 dias), NODATA, precedência | Id da C3, C5, C7 | A3, NODATA, A2 (risco A fora da lista, oportunidade parada) | A3, NODATA, A2 | passou |
| K13 | Não grava nada | `MAX(LastModifiedDate)` e contagem das 7 contas antes e depois dos casos | iguais | `2026-11-24T12:44:26Z`, 7 contas, igual antes e depois | passou |
| K14 | Sem envio ao Protheus | `COUNT(IntegrationLog__c)` com CreatedDate=TODAY | 0 | 0 | passou |
| K15 | Conversa pelo `SFAgent2` v15 | não executado: o agente v15 não foi ativado (v13 segue ativa; não mexi no agente, compartilhado com EPLAST-29, 34 e 46). Só o Flow direto | n/a | n/a | não executado |

Passaram 14, nenhum falhou, 1 não executado (K15). A assinatura da ação não mudou, então a conversa depende só do Flow, já provado.

## Premissas assumidas
- **Campo do código = `Account.ProtheusId__c`:** funciona como campo de busca (K2 a K7). **Não confirmado:** o formato de 6 dígitos com dado real; a dev não tem conta com o campo preenchido, usei códigos sintéticos de 6 dígitos (927001 a 927006).
- **Igualdade exata:** não exercitei zeros à esquerda. Não confirmada.
- **Mesmo código em lojas diferentes devolve lista com a loja para escolha:** confirmada (K3).
- **`recordId` sem forma de Id vale como código mesmo se vier um nome:** confirmada (K6).
- **Recorte por dono (`RestrictToOwner__c`) por código:** confirmada (K7).

## Mudanças feitas na dev e o que foi desfeito
- Massa: fixtures `conta-oportunidade-proxima-acao.apex` (blocos SELLER e MASSA) e `conta-codigo-protheus.apex`, 7 contas `TESTE EPLAST-27 C1..C7` com `TriggerUtility.bypassTrigger`; `ProtheusId__c` em 5 delas. Proprietário: usuário de teste `005bJ00000piKAaQAM` (ativo, Administrador do sistema); a C6 tem outro dono Standard escolhido pelo script, sem leitura nem alteração de registro dele. O outro usuário de serviço da Konecta (`005bJ00000hBJmYQAW`) está inativo e não foi usado.
- `User.ProtheusSellerId__c` do usuário de execução: antes `null`, durante `TESTE27`, depois `null` (conferido).
- **Flow `Account_Agente_ProximaAcao`:** antes v1 Obsoleta, v2 Ativa, v3 Obsoleta, v4 Draft. Ativei a v4 por Tooling API (`FlowDefinition.Metadata.activeVersionNumber=4`) para testar e **reativei a v2 ao final**. Estado final conferido: v1, v3 e **v4 Obsoletas**, v2 Ativa. A v4 passou de Draft a Obsoleta, efeito da ativação seguida de troca; nenhuma metadata foi alterada. Para a ativação definitiva da v4 será preciso reativá-la (passo da esteira) ou reimplantá-la. Agente `SFAgent2` não tocado.
- Dados apagados (Case, Task, Opportunity, Account, Branch__c, PaymentTerms__c `TESTE EPLAST-27%`); contas `TESTE EPLAST-27%` depois: 0. Nada ficou.

## O que pode ter saído da org
Nada. Contas criadas com o desvio de trigger (sem Protheus nem BrasilAPI); `IntegrationLog__c` do dia: 0; o Flow não faz DML nem envia e-mail. As oportunidades ganhas geraram Cases de pós-vendas por automação interna, apagados.
