# Fixtures da Eplast

Dado sintético de teste, só nas sandboxes da esteira (`sbx-eplast-dev`, `sbx-eplast-qa`). Todo registro começa por `TESTE EPLAST-<n>`.

## eplast41_dados_teste.apex (EPLAST-41)

    sf apex run --file fixtures/eplast41_dados_teste.apex --target-org sbx-eplast-dev

Idempotente. Cria `TESTE EPLAST-41 Conta A` e `TESTE EPLAST-41 Conta B sem oportunidade` (preenchidas para passar as validation rules de Account/Opportunity: CNPJ sintético válido, endereço, CNAE, e-mail e telefone fictícios, loja) e tenta a oportunidade aberta e a ganha da Conta A.

Estado conferido na dev em 2026-11-15:
- Contas A e B: criadas (funcionou).
- Oportunidade aberta (Record Type Industria, sem catálogo): falha só por `CheckAccountOwnerHasProtheusSellerId`: o usuário de execução (proprietário da conta) não tem `User.ProtheusSellerId__c`. Preencher esse campo no usuário de execução na dev é o ajuste que o verificador pode fazer; depois, rodar o script de novo cria a oportunidade.
- Oportunidade ganha: além do Protheus, exige `Branch__c` (com `CodeERP__c`), `Formas_de_Pagamento__c` e `PaymentTermId__c` (objetos de apoio não criados). Opcional: sem ela o Flow mostra "nenhuma" para última ganha.
- Cotação CPQ não foi criada: o caminho comercial é testado "sem cotação".
- Na QA (Partial Copy), o `qa` roda o mesmo script e não abre nem altera registro que não criou.
