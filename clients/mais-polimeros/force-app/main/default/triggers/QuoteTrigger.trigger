trigger QuoteTrigger on Quote ( before update ) { 
    if( !ProcessControl.ignoredByTrigger ) {
        if( Trigger.isBefore ){
            if( Trigger.isUpdate ){                
                QuoteBO.getInstance().checkCliente(Trigger.new);
            }
        }
    }  
}