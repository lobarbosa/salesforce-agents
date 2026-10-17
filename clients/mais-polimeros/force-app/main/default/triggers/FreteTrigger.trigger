trigger FreteTrigger on Frete__c (after insert) {
    if ( ProcessControl.ignoredByTrigger ) return;
    if(Trigger.isInsert){
        if(Trigger.isAfter){
            FreteBO.getInstance().criaFilaIntegracao(Trigger.new);
        }
    }
}