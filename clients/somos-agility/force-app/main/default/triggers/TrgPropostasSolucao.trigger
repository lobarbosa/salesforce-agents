trigger TrgPropostasSolucao on Propostas_de_Solucao__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PropostasSolucaoTriggerHandler().run();
}