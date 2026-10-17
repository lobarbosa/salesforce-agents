trigger OpportunityTrigger on Opportunity (after insert, after update) {
  OpportunityTriggerHandler handler = new OpportunityTriggerHandler();

  switch on Trigger.operationType {
    when AFTER_INSERT {
      if(!TriggerUtility.bypassTrigger)
        handler.afterInsert(Trigger.new);
    }
    when AFTER_UPDATE{
      if(!System.isQueueable() && !TriggerUtility.bypassTrigger)
        handler.afterUpdate(Trigger.new);
    }
  }
}