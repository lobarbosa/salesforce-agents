trigger OrderTrigger on Order (before update) {

    if (ProcessControl.ignoredByTrigger == true) return;

    OrderTriggerHandler handler = new OrderTriggerHandler();

    handler.oldList = Trigger.old;
    handler.newList = Trigger.new;
    handler.oldMap = Trigger.oldMap; 
    handler.newMap = Trigger.newMap;

    if(Trigger.isBefore && Trigger.isUpdate){
        handler.beforeUpdate();
    }
}