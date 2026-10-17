trigger AcessoProdutoTrigger on AcessoProduto__c (before insert, before update, after insert, after update, after delete) {

    AcessoProdutoTriggerHandler handler = new AcessoProdutoTriggerHandler();

    handler.oldList = Trigger.old;
    handler.newList = Trigger.new;
    handler.oldMap = Trigger.oldMap; 
    handler.newMap = Trigger.newMap;

    if(Trigger.isBefore){
        if(Trigger.isInsert || Trigger.isUpdate){
            // handler.consistirGrade();
        }
    } else if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUpdate){
            handler.atualizarPricebook();
        } else if(Trigger.isDelete){
            handler.inativarPricebook();
        }
    }
}