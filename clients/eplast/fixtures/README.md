# Fixtures de teste — Eplast

Scripts de Apex anônimo que montam dado **sintético** de teste e que uma verificação já
provou na org (`sbx-eplast-dev`, e na QA quando o QA os usar). Quem cria e mantém: o
`verificador` e o `qa` (ver `.claude/agents/verificador.md`, passo 4a).

Regras:
- Só nas sandboxes da esteira, com a org explícita. Nunca produção.
- Todo registro com `TESTE` no nome. Nenhum CNPJ, CPF, e-mail ou telefone real.
- Cada script diz no topo o que cria, o que exige da org e como apagar.
- Conta: a `AccountTrigger` valida CNPJ e consulta a BrasilAPI; use o desvio oficial
  `TriggerUtility.bypassTrigger` (o mesmo da fábrica de teste da EPLAST-33).
- Oportunidade: exige "ID Usuário Protheus" no proprietário. Use o usuário de teste do
  `CLAUDE.md` da conta, se houver; senão, o verificador pode preencher esse campo no
  próprio usuário de execução, só na dev, e devolve o valor ao final.

Scripts provados na dev:
- `conta-oportunidade-contato-sinal.apex` (EPLAST-46, 2026-11-16): 6 contas, oportunidades Fechado/Ganho, contatos com opt-out, sinais `CommercialSignal__c`; exige `ProtheusSellerId__c` no usuario de execucao.
