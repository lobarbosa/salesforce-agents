trigger OrderItemTrigger on OrderItem (before update, after update, after insert) {

    if (ProcessControl.ignoredByTrigger == true) return;   

    OrderItemTriggerHandler handler = new OrderItemTriggerHandler();

    handler.oldList = Trigger.old;
    handler.newList = Trigger.new;
    handler.oldMap = Trigger.oldMap; 
    handler.newMap = Trigger.newMap;

    if(Trigger.isAfter){
        if (Trigger.isInsert){
            handler.afterInsert();
        } else if (Trigger.isUpdate){
            handler.afterUpdate();
        }    
    } else {
        if (Trigger.isBefore && Trigger.isUpdate){
            handler.beforeUpdate();
        }
    }

}