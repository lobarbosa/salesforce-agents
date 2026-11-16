# Fixtures de dados de teste (Eplast)

Scripts de anonymous Apex que montam dado de teste fictício. Rodam só na sandbox de dev
(`sbx-eplast-dev`) ou, a pedido do QA, na QA. Não são implantados (não estão em `force-app`).
Todo registro criado leva o prefixo `EPLAST<n>-TESTE`; quem cria apaga, e só o que criou.

| Script | Demanda | O que cria |
|---|---|---|
| `eplast43_publicos.apex` | EPLAST-43 | 2 Accounts, 4 Contacts, 6 Leads (opt-out de e-mail, opt-out de celular, sem celular, fechado, convertido) para exercitar os públicos da pasta MARKETING CLOUD |

Uso: `sf apex run --file fixtures/eplast43_publicos.apex --target-org sbx-eplast-dev`.
Limpeza: bloco comentado no fim do script.
Status: executado na dev em 2026-11-16 pelo verificador da EPLAST-43 (passou com a linha de bypass de TriggerUtility no topo; limpeza por Apex anônimo conferida).
