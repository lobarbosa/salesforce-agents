@isTest
private class scheduledOrders13MesesTest {
     static testmethod void schedulerTest13() 
    {
        String CRON_EXP = '0 0 0 15 3 ? *';
        
               
        Test.startTest();

            String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new scheduledOrders13Meses());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
        
    }
}