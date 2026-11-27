@IsTest
private class CommercialSignalSchedulerTest {

    @TestSetup
    static void grantAccess() {
        CommercialSignalTestFactory.grantSignalAccess();
    }

    @IsTest
    static void scheduleDailyRegistersJob() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Test.startTest();
        Id jobId = CommercialSignalScheduler.scheduleDaily('EPLAST33 teste agendamento');
        Test.stopTest();
        CronTrigger ct = [SELECT CronExpression, CronJobDetail.Name, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(CommercialSignalScheduler.CRON_DAILY_0400_UTC, ct.CronExpression);
        System.assertEquals('EPLAST33 teste agendamento', ct.CronJobDetail.Name);
        System.assertEquals('EPLAST33 Sinais Comerciais', CommercialSignalScheduler.JOB_NAME, 'nome oficial do job');
        System.assertEquals(0, ct.TimesTriggered, 'ainda nao disparou');
        }
    }

    @IsTest
    static void executeRunsBothPhasesAndWritesSignals() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        List<Account> accounts = CommercialSignalTestFactory.createAccounts(3, null, 'SCH');
        Test.startTest();
        new CommercialSignalScheduler().execute(null);
        Test.stopTest();
        System.assertEquals(3, [SELECT COUNT() FROM CommercialSignal__c WHERE Type__c = 'NuncaComprou' AND Account__c IN :accounts],
            'o agendador dispara fase 1 e a fase 2 grava');
        }
    }

    @IsTest
    static void emptyBaseRunsWithoutError() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Test.startTest();
        new CommercialSignalScheduler().execute(null);
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM CommercialSignal__c], 'sem contas, sem sinais');
        }
    }

    /**
     * Usuario novo no perfil administrador (Modify All Data), sem o permission set.
     * E o caso da QA de 17/11: quem agendou era Administrador do sistema e os 13 lotes
     * quebraram em "No such column 'SignalKey__c'". O perfil nao tem FLS desses campos.
     */
    private static User adminWithoutSignalAccess() {
        Profile adminProfile = [
            SELECT Id FROM Profile
            WHERE UserType = 'Standard'
              AND PermissionsModifyAllData = true
              AND PermissionsViewAllData = true
              AND PermissionsCustomizeApplication = true
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        String stamp = String.valueOf(Datetime.now().getTime());
        User u = new User(
            Alias = ('e' + stamp).left(8),
            LastName = 'TESTE EPLAST-33 sem PS',
            ProfileId = adminProfile.Id,
            Email = 'teste.eplast33.' + stamp + '@example.com.invalid',
            Username = 'teste.eplast33.' + stamp + '@example.com.invalid',
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR'
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert u;
        }
        return u;
    }

    @IsTest
    static void executorWithPermissionSetHasAccess() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            System.assertEquals(15, CommercialSignalScheduler.REQUIRED_FIELDS.size(),
                'a checagem cobre os 15 campos de CommercialSignal__c');
            System.assertEquals(true, CommercialSignalScheduler.executorHasSignalAccess(),
                'o setup atribui o permission set e o usuario le os campos');
            CommercialSignalScheduler.assertSignalAccess();
            List<CommercialSignal__c> rows = [SELECT Id, SignalKey__c FROM CommercialSignal__c LIMIT 1];
            System.assertEquals(0, rows.size(), 'com o permission set a coluna SignalKey__c pode ser consultada');
        }
    }

    @IsTest
    static void adminWithoutPermissionSetCannotScheduleNorExecute() {
        User u = adminWithoutSignalAccess();
        System.assertEquals(0, [
            SELECT COUNT() FROM PermissionSetAssignment
            WHERE AssigneeId = :u.Id AND PermissionSet.Name = :CommercialSignalScheduler.PERMISSION_SET
        ], 'este usuario nao recebe o permission set');

        System.runAs(u) {
            QueryException queryError;
            try {
                List<CommercialSignal__c> ignored = [SELECT Id, SignalKey__c FROM CommercialSignal__c LIMIT 1];
                System.assert(false, 'sem o permission set a consulta tinha de falhar, linhas ' + ignored.size());
            } catch (QueryException e) {
                queryError = e;
            }
            System.assertNotEquals(null, queryError, 'sem o permission set a consulta de SignalKey__c tinha de falhar');
            System.assert(queryError.getMessage().contains('SignalKey__c'), queryError.getMessage());
            System.assertEquals(false, CommercialSignalScheduler.executorHasSignalAccess(),
                'administrador sem o permission set nao le os campos do sinal');

            String scheduleError;
            try {
                CommercialSignalScheduler.scheduleDaily('EPLAST33 teste sem PS');
            } catch (CommercialSignalScheduler.SignalAccessException e) {
                scheduleError = e.getMessage();
            }
            System.assertNotEquals(null, scheduleError, 'agendar sem o permission set falha na hora');
            System.assert(scheduleError.contains(CommercialSignalScheduler.PERMISSION_SET),
                'a mensagem diz qual permission set atribuir');
            System.assert(scheduleError.toLowerCase().contains(u.Username.toLowerCase()),
                'a mensagem diz qual usuario receber o permission set');
            System.assert(scheduleError.contains('signalkey__c'),
                'a mensagem aponta o campo que derrubou os lotes da QA');

            String executeError;
            try {
                new CommercialSignalScheduler().execute(null);
            } catch (CommercialSignalScheduler.SignalAccessException e) {
                executeError = e.getMessage();
            }
            System.assertNotEquals(null, executeError, 'executar sem o permission set falha antes de abrir os lotes');
        }
        System.assertEquals(
            0,
            [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'EPLAST33 teste sem PS'],
            'nada foi agendado'
        );
    }
}
