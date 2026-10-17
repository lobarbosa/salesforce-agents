trigger TrgSoliciatacaoCoffeeBreak on Solicita_o_de_Coffe__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new SolicitacaoCoffeeBreakTriggerHandler().run();
}