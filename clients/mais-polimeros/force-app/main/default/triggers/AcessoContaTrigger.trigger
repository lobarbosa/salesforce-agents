trigger AcessoContaTrigger on AcessoConta__c (after insert, after update, after delete) {

    AcessoContaTriggerHandler handler = new AcessoContaTriggerHandler();

    handler.oldList = Trigger.old;
    handler.newList = Trigger.new;
    handler.oldMap = Trigger.oldMap; 
    handler.newMap = Trigger.newMap;

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            handler.handleInsert();
        } else if(Trigger.isUpdate){
            handler.handleUpdate();
        } else if(Trigger.isDelete){
            handler.handleDelete();
        }

        // AcessoContaIntegrationBO instance = new AcessoContaIntegrationBO();
        // instance.criaFilaIntegracaoInsert(Trigger.oldMap, Trigger.new);
    }
}