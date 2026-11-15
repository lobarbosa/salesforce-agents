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

## Scripts provados (2026-11-15)

| Script | Cria | Exige antes | Provado por |
|---|---|---|---|
| `lead.apex` | Leads sintéticos simples | nada | EPLAST-26 |
| `lead-segmento.apex` | Leads com estado, setor e opt-out | nada (permite salvar duplicado de teste) | EPLAST-36 |
| `opportunity.apex` | Conta + Oportunidade (tipo Industria), aberta | `ProtheusSellerId__c` no proprietário | EPLAST-26 |
| `conta-oportunidade-ganha.apex` | Filial, condição de pagamento, 5 contas com contato e oportunidades Fechado/Ganho (alimenta `LastPurchase__c`) | `ProtheusSellerId__c` no proprietário | EPLAST-36 |
| `pedido-com-produto.apex` | Produto, entrada de catálogo, Pedido com item | a conta de `conta-oportunidade-ganha.apex` | EPLAST-36 |

Cada script diz no topo como apagar o que criou. Os nomes trazem o ID da demanda que o
provou; ao reutilizar, troque pelo ID da sua demanda.
