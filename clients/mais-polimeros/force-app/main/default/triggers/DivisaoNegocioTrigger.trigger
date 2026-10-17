trigger DivisaoNegocioTrigger on DivisaoNegocio__c (before insert, before update) {

    DivisaoNegocioTriggerHandler handler = new DivisaoNegocioTriggerHandler();

    handler.oldList = Trigger.old;
    handler.newList = Trigger.new;
    handler.oldMap = Trigger.oldMap; 
    handler.newMap = Trigger.newMap;

    if(Trigger.isBefore){
        if(Trigger.isInsert || Trigger.isUpdate){
            handler.consisteFamilia();

            if(Trigger.isUpdate){
                handler.atualizaPriceBooks();
            }
        }
    }

}