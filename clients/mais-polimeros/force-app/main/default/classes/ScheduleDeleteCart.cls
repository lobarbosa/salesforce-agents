public class ScheduleDeleteCart implements Schedulable{
    
    //Expression to Start String cronExp = '0 59 23 * * ?';
    
    public void execute(SchedulableContext sc) {
        Date today = Date.today();
        if (today == today.toStartOfMonth().addMonths(1).addDays(-1)) {BathDeleteCart bdc = new BathDeleteCart(); Database.executeBatch(bdc,200);}
    }
          

}