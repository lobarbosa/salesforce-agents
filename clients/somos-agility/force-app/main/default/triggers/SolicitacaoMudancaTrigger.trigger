trigger SolicitacaoMudancaTrigger on Solicitacao_de_Mudanca__c (after update){
    
     
    SolicitacaoMudancaTriggerHandler handler = new SolicitacaoMudancaTriggerHandler();
    
    handler.oldRecordsList = Trigger.old;
    handler.newRecordsList = Trigger.new;
    
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate){
            handler.afterUpdate();
        }  
    }	
}