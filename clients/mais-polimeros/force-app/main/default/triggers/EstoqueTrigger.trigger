trigger EstoqueTrigger on Estoque__c ( After insert ) {
    if( !ProcessControl.ignoredByTrigger ) {
        if(Trigger.isAfter){
            if( Trigger.isInsert ){                
                EstoqueBO.getInstance().criaFilaIntegracaoInsert( Trigger.new );    
            } 
        }
    }
}