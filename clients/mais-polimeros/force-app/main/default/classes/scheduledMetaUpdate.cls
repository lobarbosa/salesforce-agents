global class scheduledMetaUpdate implements Schedulable {
    global void execute(SchedulableContext SC) {  
        MetaUpdateDaily ExecuteUpdate =  new MetaUpdateDaily();
        Id batchId = Database.executeBatch(ExecuteUpdate,12);
    }
}