/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Hist_rico_de_Status_do_Pra0mTrigger on Hist_rico_de_Status_do_Projeto__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Hist_rico_de_Status_do_Projeto__c.SObjectType);
}