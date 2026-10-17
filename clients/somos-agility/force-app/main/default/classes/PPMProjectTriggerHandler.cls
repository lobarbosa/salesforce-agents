public class PPMProjectTriggerHandler extends TriggerHandler {
	
    public override void beforeUpdate() {
        PPMProjectBO.calculateDespesasRealizadas((List<PPM_Project__c>)Trigger.new);
    }
    
    public override void afterUpdate() {
        PPMProjectBO.updateInProject((Map<Id, PPM_Project__c>)Trigger.oldMap, (List<PPM_Project__c>)Trigger.new);
    }

    public override void afterInsert() {
        PPMProjectBO.createInProject((List<PPM_Project__c>)Trigger.new);
    }
}