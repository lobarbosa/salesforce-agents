global class MetaUpdateDaily implements Database.Batchable<sObject> 
{
	global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        return Database.getQueryLocator('SELECT Id, AtualizaMetaReal__c FROM Meta__c WHERE Status__c = \'Aberta\' ');        
    }
    global void execute(Database.BatchableContext BC, List<Meta__c> scope)
    {    
    	for ( Meta__c m : scope)
        {
          m.AtualizaMetaReal__c = true;          
        }
        ProcessControl.ignoredByTrigger = true;
      	update scope;            
    }
    
    global void finish(Database.BatchableContext BC)
    {
      AsyncApexJob a = [Select a.TotalJobItems, a.Status, a.NumberOfErrors,a.JobType, a.JobItemsProcessed, a.ExtendedStatus, a.CreatedById,a.CompletedDate From AsyncApexJob a WHERE id = :BC.getJobId()];
      System.debug('$$$ Jobid is'+BC.getJobId()); 
    }

}