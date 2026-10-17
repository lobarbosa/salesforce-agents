global class scheduledOrders13Meses implements Schedulable 
{
	global void execute(SchedulableContext SC)   
	{  
    	AccountUpdate13Meses ExecuteUpdate =  new AccountUpdate13Meses();
    	ProcessControl.ignoredByTrigger = true;
    	Id batchId = Database.executeBatch(ExecuteUpdate,12);
	}
}