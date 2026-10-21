trigger TrgLancamentoDeDespesas on Lancamento_de_Despesas__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new LancamentoDespesasTriggerHandler().run();
}