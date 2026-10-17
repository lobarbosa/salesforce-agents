trigger Account on Account (before insert, after update) {
    if ( ProcessControl.ignoredByTrigger ) return;

    if(Trigger.isInsert) {
        if(Trigger.isBefore) {
            for(Account a : Trigger.New) {
                a.Classificacao__c = 'Tipo SC';
            }

        }
    }

    if(Trigger.isUpdate) {        
        AccountBO.getInstance().criaFilaIntegracaoInsert(Trigger.oldMap, Trigger.new);        
    }
}