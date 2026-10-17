trigger OpportunityLineItemTrigger on OpportunityLineItem (after update) {
    if ( ProcessControl.ignoredByTrigger ) return;    
    // if( Trigger.isAfter ){
    //     if( Trigger.isUpdate ){
    //         OpportunityBO.getInstance().criaFilaIntegracaoUpdate(Trigger.new, Trigger.oldMap);
    //     }
    // }

}