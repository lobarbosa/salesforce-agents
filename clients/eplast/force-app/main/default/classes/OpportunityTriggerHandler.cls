public with sharing class OpportunityTriggerHandler {
    private OpportunityTriggerHelper helper;

    public void afterInsert(Opportunity[] newOpportunities){
        System.enqueueJob(new OpportunityTriggerHelper(newOpportunities));
    }

    public void afterUpdate(Opportunity[] newRecords){
        System.enqueueJob(new OpportunityTriggerHelper(newRecords));
    }
}