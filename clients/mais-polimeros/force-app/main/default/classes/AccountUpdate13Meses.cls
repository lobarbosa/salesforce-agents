global class AccountUpdate13Meses implements Database.Batchable<sObject> 
{
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        String query;
        query  = 'SELECT Id, FluxoVendasMeses__c, Dispara_flow__c FROM Account';
        return Database.getQueryLocator(query);        
    }
    global void execute(Database.BatchableContext BC, List<Account> scope)
    {    
      for ( Account a : scope)
        {
          a.DisparaFluxoMensal__c = true;          
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