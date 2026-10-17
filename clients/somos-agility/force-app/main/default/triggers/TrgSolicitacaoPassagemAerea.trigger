trigger TrgSolicitacaoPassagemAerea on Solicitacao_de_Passagem_Aerea__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new SolicitacaoPassagemAereaTriggerHandler().run();
}