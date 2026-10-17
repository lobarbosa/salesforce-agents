trigger AccountTrigger on Account (before insert, after insert, before update, after update) {
  if(TriggerUtility.bypassTrigger)
     return;
      
  AccountTriggerHandler handler = new AccountTriggerHandler(Trigger.isExecuting, Trigger.size);

  switch on Trigger.operationType {
    when BEFORE_INSERT{
      handler.validateCNPJ(Trigger.new, Trigger.old);
    }
    when BEFORE_UPDATE{
      handler.validateCNPJ(Trigger.new, Trigger.old);
    }
    when AFTER_INSERT {
      handler.fillAccountWithCNPJInfo(Trigger.newMap);
    }
    when AFTER_UPDATE {
      if(!System.isQueueable())
        handler.updateAccountCNPJInfo(Trigger.oldMap, Trigger.newMap);
    }
  }
}