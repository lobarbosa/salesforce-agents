global class AccountUpdateEveryDay implements Database.Batchable<sObject>
{ 
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query;
        query  = 'SELECT Id, Dispara_flow__c FROM Account';
        return Database.getQueryLocator(query);        
    }
    global void execute(Database.BatchableContext BC, List<Account> scope)
    {    
      for ( Account a : scope)
        {
          a.Dispara_flow__c = true;
        }
         ProcessControl.ignoredByTrigger = true;
         update scope;            
    } 
    global void finish(Database.BatchableContext BC)
    {
      String email = 'victor_oliver9@hotmail.com';
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      AsyncApexJob a = [Select a.TotalJobItems, a.Status, a.NumberOfErrors,a.JobType, a.JobItemsProcessed, a.ExtendedStatus, a.CreatedById,a.CompletedDate From AsyncApexJob a WHERE id = :BC.getJobId()];
      System.debug('$$$ Jobid is'+BC.getJobId()); 
      mail.setToAddresses(new String[]{'victor_oliver9@hotmail.com'});
      mail.setReplyTo('victor@altostratrustecnologia.com.br');
      mail.setSenderDisplayName('MP - Execução Diária Finalizada.');
      mail.setPlainTextBody('Total de lotes: ' + a.TotalJobItems+'. '+a.NumberOfErrors+ ' com falha.'+ ' Total de trabalhos processados ' + a.JobItemsProcessed);
      if (!Test.isRunningTest()) {
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
      }
    }
}