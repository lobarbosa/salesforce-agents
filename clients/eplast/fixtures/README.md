# Fixtures da Eplast

Scripts Apex que montam dado sintetico de teste (regra 6 do CLAUDE.md da conta). Registros com prefixo `REG-TESTE-` ou `TESTE EPLAST-<n>`. Nunca usar dado real.

| Script | Cria | Demanda |
|---|---|---|
| `account.apex` | 3 contas `TESTE EPLAST-29 ...` (uma unica, duas duplicadas), com `TriggerUtility.bypassTrigger` | EPLAST-29 |
| `lead.apex` | leads `REG-TESTE-LEAD-01`, 2x `REG-TESTE-DUP`, `REG-TESTE-LEAD-CONV` (convertido) e a conta `REG-TESTE-DUP` | EPLAST-29 |

Rodar: `sf apex run -o sbx-eplast-dev -f fixtures/<script>.apex`. Cada script traz no cabecalho como apagar o que criou. Conta criada pela tela ou por conversao de lead passa pela `AccountTrigger` (Protheus); o desvio `TriggerUtility.bypassTrigger` cobre as contas criadas dentro do script.

Estado: `lead.apex` ainda nao executado quando esta versao foi escrita; a verificacao grava aqui o que funcionar.
