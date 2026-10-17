/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Potencial_e_Objetivo_de_Va6BTrigger on Potencial_e_Objetivo_de_Vendas__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Potencial_e_Objetivo_de_Vendas__c.SObjectType);
}