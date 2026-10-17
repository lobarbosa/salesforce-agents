trigger OrderTrigger on Order (before update, after update) {
  OrderTriggerHandler handler = new OrderTriggerHandler();

  switch on Trigger.operationType{
    when AFTER_UPDATE {
      if(!System.isQueueable() && !UserInfo.getUserName().startsWith('integracao'))
        this.handler.sendOrderToProtheus(Trigger.oldMap, Trigger.newMap);
    }
  }
}