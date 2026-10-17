trigger LancamentoCreditoProjetoTrigger on Lancamento_de_Creditos_em_Projeto__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	new LancamentoCreditoProjetoTriggerHandler().run();
}