global class scheduledAccount implements Schedulable {
    global void execute(SchedulableContext SC) {  
        AccountUpdateEveryDay ExecuteUpdate =  new AccountUpdateEveryDay();
        Id batchId = Database.executeBatch(ExecuteUpdate,12);
    }
}