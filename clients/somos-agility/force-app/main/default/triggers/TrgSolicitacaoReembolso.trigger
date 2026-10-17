trigger TrgSolicitacaoReembolso on Solicitacao_de_Reembolso__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new SolicitacaoReembolsoTriggerHandler().run();
}