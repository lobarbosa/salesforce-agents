trigger PPMProjectTrigger on PPM_Project__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PPMProjectTriggerHandler().run();
}