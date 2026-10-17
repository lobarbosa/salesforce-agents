public with sharing class TriggerUtility {
    public static Boolean bypassTrigger = [ SELECT BypassTrigger__c FROM TriggerUtility__mdt WHERE DeveloperName = 'TriggerExecution' LIMIT 1 ].BypassTrigger__c;
}