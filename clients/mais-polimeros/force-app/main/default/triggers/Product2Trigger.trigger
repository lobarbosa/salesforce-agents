trigger Product2Trigger on Product2 (after insert, after update) {

    Product2TriggerHandler handler = new Product2TriggerHandler();

    handler.oldList = Trigger.old;
    handler.newList = Trigger.new;
    handler.oldMap = Trigger.oldMap; 
    handler.newMap = Trigger.newMap;

    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUpdate){
            handler.atualizaPriceBooks();
        }
    }

}