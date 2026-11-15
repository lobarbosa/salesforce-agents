@IsTest
private class CommercialSignalSchedulerTest {

    @IsTest
    static void scheduleDailyRegistersJob() {
        Test.startTest();
        Id jobId = CommercialSignalScheduler.scheduleDaily('EPLAST33 teste agendamento');
        Test.stopTest();
        CronTrigger ct = [SELECT CronExpression, CronJobDetail.Name, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(CommercialSignalScheduler.CRON_DAILY_0400_UTC, ct.CronExpression);
        System.assertEquals('EPLAST33 teste agendamento', ct.CronJobDetail.Name);
        System.assertEquals('EPLAST33 Sinais Comerciais', CommercialSignalScheduler.JOB_NAME, 'nome oficial do job');
        System.assertEquals(0, ct.TimesTriggered, 'ainda nao disparou');
    }

    @IsTest
    static void executeRunsBothPhasesAndWritesSignals() {
        List<Account> accounts = CommercialSignalTestFactory.createAccounts(3, null, 'SCH');
        Test.startTest();
        new CommercialSignalScheduler().execute(null);
        Test.stopTest();
        System.assertEquals(3, [SELECT COUNT() FROM CommercialSignal__c WHERE Type__c = 'NuncaComprou' AND Account__c IN :accounts],
            'o agendador dispara fase 1 e a fase 2 grava');
    }

    @IsTest
    static void emptyBaseRunsWithoutError() {
        Test.startTest();
        new CommercialSignalScheduler().execute(null);
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM CommercialSignal__c], 'sem contas, sem sinais');
    }
}
