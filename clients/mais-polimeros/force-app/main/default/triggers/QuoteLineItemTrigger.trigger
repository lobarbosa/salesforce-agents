trigger QuoteLineItemTrigger on QuoteLineItem (before update,  before insert, before delete) {    
    if (ProcessControl.ignoredByTrigger) return;    
    if(Trigger.isUpdate) {        
        QuoteLineItemBO.getInstance().UpdateQuote(Trigger.new, Trigger.oldMap);      
    }
    if(Trigger.isInsert){
         QuoteLineItemBO.getInstance().UpdateQuote(Trigger.new);
    }
    if(Trigger.isDelete){
         QuoteLineItemBO.getInstance().UpdateQuoteDelete(Trigger.old);
    }
}