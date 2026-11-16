**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev`

# EPLAST-46 — Verificação do build (sugestão de campanhas, SFAgent2 v9)

`sf org list` confirmou uma única org conectada: `sbx-eplast-dev` (Sandbox, Org Id `00DHa000006vfMLMAY`, é a `eplast--qa` da Eplast pela regra 5). Nada na QA, nenhum deploy. Nada feito no Marketing Cloud; nenhum e-mail ou mensagem enviado. Só dado sintético `TESTE EPLAST-46`. Nenhum registro que eu não criei foi lido ou alterado (a dev não tinha Account/Contact/Opportunity).

## Dado de teste (fixture)
Fixture gravada e provada: `clients/eplast/fixtures/conta-oportunidade-contato-sinal.apex` (README de fixtures atualizado). Para passar nas validation rules foi preciso, além do que o design previa: `Branch__c` com `CodeERP__c`, `PaymentTerms__c` com `Codigo__c`, forma de pagamento, campos de Conta exigidos (razão social, CNAE, e-mail, telefone, loja) e formato `(xx)xxxxxxxx` de telefone, com `TriggerUtility.bypassTrigger = true`.

Contas (mesmo `Industry`): A compra há 100 dias, 3 contatos (c1 opt-out e-mail, c2 opt-out mensagem, c3 sem opt-out); B compra há 30 dias; C sem oportunidade; D compra há 30 dias + sinal `Cruzada` (grupo PREF); E compra há 200 dias + sinal `Cruzada`; F compra há 200 dias, 1 contato com opt-out de e-mail. Depois acrescentei dois contatos em D (c5 elegível, c6 opt-out) para o relatório.

## Mudanças temporárias no usuário de execução (`005bJ00000piKAaQAM`), todas desfeitas
| O que | Antes | Durante | Depois |
|---|---|---|---|
| `User.ProtheusSellerId__c` (exigido pela validation rule de Oportunidade) | vazio | `000001` | vazio (conferido) |
| Permission set `PS_Marketing_SugestaoCampanha` | não atribuído | atribuído (removido e reatribuído para os negativos) | não atribuído (0 atribuições, conferido) |
| SFAgent2 versão ativa | v8 | v9 ativada para testar a ação | v8 reativada (v9 Inactive, v8 Active) |

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | CA-01 | Flow `Account_Agente_SugestaoCampanha` por Apex (`Flow.Interview`) na conta A | `REATIVACAO`, motivo de falta de compra | `REATIVACAO`; "sem compra há 100 dias (última compra ganha). Público: SEM COMPRA - 91 A 180 DIAS" | passou (obs. 1) |
| C2 | CA-02 | Conta B (30 dias, sem sinal) | sem reativação | `NONE`; "Nenhuma campanha sugerida ... comprou recentemente" (cobre também CA-12) | passou |
| C3 | CA-03 | Conta F (200 dias, único contato com opt-out de e-mail) | e-mail "sem contato elegível" | "sem contato elegível para e-mail; 1 para mensagem" | passou |
| C4 | CA-04 | Conta A (c1 opt-out e-mail, c2 opt-out mensagem, c3 livre) | e-mail 2 (c2, c3), mensagem 2 (c1, c3) | "2 para e-mail; 2 para mensagem" | passou |
| C5 | CA-05 (reescrito) | Conta D (compra 30 dias, sinal PREF) | `AMPLIACAO_MIX` citando PREF | `AMPLIACAO_MIX`; "grupos ... PREF (1 produto(s) sugerido(s); sinais calculados em 2026-11-15). Público: AMPLIACAO MIX - CONTATOS" | passou |
| C6 | CA-06 | Conta C (sem oportunidade, sem sinal) | `SEM_HISTORICO`, sem erro | `SEM_HISTORICO`; sem exceção no log | passou |
| C7 | CA-12 | Conta B | `NONE` | `NONE` (ver C2) | passou |
| C8 | Prioridade | Conta E (200 dias + sinal) | reativação antes de ampliação | `REATIVACAO` e as duas campanhas na mensagem, reativação primeiro | passou |
| C9 | CA-07 | Contagens antes e depois de 20 execuções (4 transações de 5 contas) de `Campaign`, `CampaignMember`, `EmailMessage`, `et4ae5__IndividualEmailResult__c` | iguais | 0/0/0/0 antes e 0/0/0/0 depois; `Email Invocations` 0; Flow sem DML | passou (obs. 2) |
| C10 | CA-08 | `BotVersion` e `BotDefinition` de `SFAgent2` | nova versão, mesmo número de agentes | v9 criada (v8 e v7 existentes); `BotDefinition` `SFAgent2` = 1 | passou |
| C11 | CA-08/ação | v9 ativada; `sf agent preview start/send --use-live-actions`: "Qual campanha ... conta TESTE EPLAST-46 A?" | resposta do agente com a sugestão do Flow | Resposta com a reativação, público e contagens da conta A e "Nada foi enviado" | passou |
| C12 | CA-09 (Flow) | Sem o PS atribuído, Flow nas contas A e B | `NO_ACCESS`, sem dado da conta | `NO_ACCESS`: "Você não tem acesso ... Peça ao administrador o permission set PS Marketing Sugestão de Campanha." Sem nome nem dado | passou |
| C13 | CA-09 (agente) | Sem o PS, mesma pergunta ao SFAgent2 v9 | acesso negado | Mesma mensagem de acesso negado, sem dado da conta | passou |
| C14 | CA-11 | Mensagens de todas as respostas e log de 20 execuções (grep por `example.invalid` e `(11)9000`) | só contagens, códigos e público | 0 ocorrências de e-mail ou telefone; só nome da conta de teste, dias, grupo, público, contagens | passou |
| C15 | Relatório `AMPLIACAO MIX - CONTATOS` | `Reports.ReportManager.runReport` com c5 (elegível) e c6 (opt-out) em D | 1 linha (c5) | 1 linha | passou |
| C16 | CA-10 | Sem Apex | não se aplica | não se aplica | não executado (n/a) |

Observações:
1. CA-01 pede o motivo "sem compra há mais de 90 dias"; a mensagem traz o número exato de dias (100) e a faixa do público. Mesma informação, texto diferente. Peço ao revisor que confirme que serve.
2. Limite de SOQL: cada chamada usa cerca de 6 a 7 consultas. 20 chamadas na mesma transação estouraram o limite (105 de 100; 5 devolveram `ERRO`, tratadas pelo próprio Flow). Em 4 transações de 5, 33 de 100 e 0 erros. O agente chama uma conta por vez, então não afeta o uso previsto; só não use a ação em loop de mais de ~14 contas numa transação.
3. Contas sem compra ficam com `Inactive__c` falso (fórmula com `BlankAsZero`) e o Flow trata corretamente como `SEM_HISTORICO` (C6).

## O que pode ter saído da org
Nada. Contagens de `Campaign`, `CampaignMember`, `EmailMessage` e resultado de envio do conector ficaram em 0. Nenhuma chamada externa registrada pela cadeia (a inserção de Conta usa o desvio `bypassTrigger`). A org criou um `Case` por conta de teste ao inserir (automação existente da conta, 5 casos, todos ligados às contas de teste); foram apagados junto.

## Limpeza
Apagados: 6 contas, 5 oportunidades, 6 contatos, 2 sinais, 1 `Branch__c`, 1 `PaymentTerms__c`, 5 `Case` ligados às contas de teste (contagem final de cada um: 0). Nada ficou. Nenhum job agendado criado.

## Premissas PA-46-01 a PA-46-06
Testado conforme o design; nenhuma foi motivo de reprovação.

## Pendências para a QA (não são falhas)
- R1 do design: conferir `CommercialSignal__c`, `SFAgent2` v8 e `Branch__c`/dependências na QA antes do deploy.
- A v9 está Inactive na dev (v8 ativa); o `qa` ativa a v9 e registra.
