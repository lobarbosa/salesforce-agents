@IsTest
private class CommercialSignalBatchTest {

    @TestSetup
    static void grantAccess() {
        CommercialSignalTestFactory.grantSignalAccess();
    }

    private static final Date TODAY = Date.today();

    private static void run(CommercialSignalService.Settings s,
                            Map<String, List<CommercialSignalService.Candidate>> q) {
        Test.startTest();
        Database.executeBatch(new CommercialSignalBatch(s, TODAY, q), 200);
        Test.stopTest();
    }

    /** Execucao sincrona do mesmo calculo do batch, para cenarios com duas execucoes no mesmo teste. */
    private static void runAgain(CommercialSignalService.Settings s) {
        new CommercialSignalBatch(s, TODAY, null).process([SELECT Id, Industry FROM Account]);
    }

    private static void run() {
        run(CommercialSignalTestFactory.settings(), null);
    }

    private static CommercialSignalTestFactory.OrderSpec spec(Id acc, String status, Integer daysAgo, Decimal amount, Id prod) {
        return new CommercialSignalTestFactory.OrderSpec(acc, status, TODAY.addDays(-daysAgo), amount, prod);
    }

    @IsTest
    static void recoveryAt61DaysAndNotAt59() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1)[0].Id;
        Account a61 = CommercialSignalTestFactory.createAccounts(1, null, 'R61')[0];
        Account a59 = CommercialSignalTestFactory.createAccounts(1, null, 'R59')[0];
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(a61.Id, 'Faturamento', 61, 100, prod), spec(a59.Id, 'Concluido', 59, 100, prod) });
        run();
        List<CommercialSignal__c> r = CommercialSignalTestFactory.signals(a61.Id, 'Recuperacao');
        System.assertEquals(1, r.size(), 'CA-01');
        System.assertEquals(61, r[0].DaysWithoutPurchase__c);
        System.assertEquals(0, CommercialSignalTestFactory.signals(a59.Id, 'Recuperacao').size(), 'CA-02');
        System.assertEquals(0, CommercialSignalTestFactory.signals(a59.Id, 'NuncaComprou').size(), 'comprou, nao e nunca comprou');
        }
    }

    @IsTest
    static void neverPurchasedAndInvalidOrdersDoNotCount() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1)[0].Id;
        Account none = CommercialSignalTestFactory.createAccounts(1, null, 'N0')[0];
        Account inv = CommercialSignalTestFactory.createAccounts(1, null, 'N1')[0];
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(inv.Id, 'Cancelado', 5, 100, prod), spec(inv.Id, 'Revisao de Pedido', 3, 100, prod) });
        run();
        System.assertEquals(1, CommercialSignalTestFactory.signals(none.Id, 'NuncaComprou').size(), 'CA-03');
        System.assertEquals(0, CommercialSignalTestFactory.signals(none.Id, 'Recuperacao').size());
        System.assertEquals(1, CommercialSignalTestFactory.signals(inv.Id, 'NuncaComprou').size(), 'CA-04');
        System.assertEquals(0, CommercialSignalTestFactory.signals(inv.Id, 'Recuperacao').size());
        }
    }

    @IsTest
    static void volumeDropAndRiseUseStrictLimits() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1)[0].Id;
        Account d30 = CommercialSignalTestFactory.createAccounts(1, null, 'D30')[0];
        Account d31 = CommercialSignalTestFactory.createAccounts(1, null, 'D31')[0];
        Account u30 = CommercialSignalTestFactory.createAccounts(1, null, 'U30')[0];
        Account u31 = CommercialSignalTestFactory.createAccounts(1, null, 'U31')[0];
        // atual = ultimos 3 meses (30 dias atras); base = 3 meses anteriores (120 dias atras)
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(d30.Id, 'Faturamento', 120, 10000, prod), spec(d30.Id, 'Faturamento', 30, 7000, prod),
            spec(d31.Id, 'Faturamento', 120, 10000, prod), spec(d31.Id, 'Faturamento', 30, 6900, prod),
            spec(u30.Id, 'Concluido', 120, 10000, prod), spec(u30.Id, 'Concluido', 30, 13000, prod),
            spec(u31.Id, 'Concluido', 120, 10000, prod), spec(u31.Id, 'Concluido', 30, 13100, prod) });
        run();
        System.assertEquals(0, CommercialSignalTestFactory.signals(d30.Id, 'QuedaVolume').size(), 'CA-05: 30% nao');
        List<CommercialSignal__c> drop = CommercialSignalTestFactory.signals(d31.Id, 'QuedaVolume');
        System.assertEquals(1, drop.size(), 'CA-05: 31% sim');
        System.assertEquals(31.0, drop[0].VariationPercent__c);
        System.assertEquals(10000, drop[0].BasePeriodAmount__c);
        System.assertEquals(6900, drop[0].CurrentPeriodAmount__c);
        System.assertEquals(0, CommercialSignalTestFactory.signals(u30.Id, 'AltaVolume').size(), 'CA-06: 30% nao');
        System.assertEquals(1, CommercialSignalTestFactory.signals(u31.Id, 'AltaVolume').size(), 'CA-06: 31% sim');
        }
    }

    @IsTest
    static void volumeWithoutBaseDoesNotClassify() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1)[0].Id;
        Account a = CommercialSignalTestFactory.createAccounts(1, null, 'V0')[0];
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(a.Id, 'Faturamento', 20, 5000, prod) });
        run();
        System.assertEquals(0, CommercialSignalTestFactory.signals(a.Id, 'QuedaVolume').size(), 'CA-07');
        System.assertEquals(0, CommercialSignalTestFactory.signals(a.Id, 'AltaVolume').size(), 'CA-07');
        }
    }

    @IsTest
    static void crossSellExcludesRecentBuyerAndAccountWithoutIndustry() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        List<Account> grp = CommercialSignalTestFactory.createAccounts(10, 'Embalagens', 'CS');
        Account noIndustry = CommercialSignalTestFactory.createAccounts(1, null, 'CSX')[0];
        Product2 p = CommercialSignalTestFactory.createProducts(1)[0];
        CommercialSignalService.Candidate c = new CommercialSignalService.Candidate();
        c.productId = p.Id;
        c.sharePercent = 40;
        c.buyers = 4;
        c.groupSize = 10;
        // conta 9 comprou P ha 90 dias (recente, CA-09); conta 8 comprou ha 200 dias (fora da janela de 180)
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(grp[9].Id, 'Faturamento', 90, 100, p.Id), spec(grp[8].Id, 'Faturamento', 200, 100, p.Id) });
        run(CommercialSignalTestFactory.settings(),
            new Map<String, List<CommercialSignalService.Candidate>>{ 'Embalagens' => new List<CommercialSignalService.Candidate>{ c } });
        System.assertEquals(0, CommercialSignalTestFactory.signals(grp[9].Id, 'Cruzada').size(), 'CA-09');
        System.assertEquals(1, CommercialSignalTestFactory.signals(grp[8].Id, 'Cruzada').size(), 'compra antiga nao bloqueia');
        System.assertEquals(1, CommercialSignalTestFactory.signals(grp[0].Id, 'Cruzada').size());
        System.assertEquals(0, CommercialSignalTestFactory.signals(noIndustry.Id, 'Cruzada').size(), 'CA-10');
        System.assertEquals(1, CommercialSignalTestFactory.signals(noIndustry.Id, 'NuncaComprou').size(), 'segue nos demais tipos');
        }
    }

    @IsTest
    static void doesNotWriteToCommercialObjects() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1)[0].Id;
        Account a = CommercialSignalTestFactory.createAccounts(1, 'Embalagens', 'W0')[0];
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(a.Id, 'Faturamento', 61, 100, prod) });
        Datetime accBefore = (Datetime) [SELECT MAX(LastModifiedDate) m FROM Account][0].get('m');
        Datetime ordBefore = (Datetime) [SELECT MAX(LastModifiedDate) m FROM Order][0].get('m');
        Integer accCount = [SELECT COUNT() FROM Account];
        Integer ordCount = [SELECT COUNT() FROM Order];
        Integer itemCount = [SELECT COUNT() FROM OrderItem];
        Integer oppCount = [SELECT COUNT() FROM Opportunity];
        run();
        System.assertEquals(accBefore, (Datetime) [SELECT MAX(LastModifiedDate) m FROM Account][0].get('m'), 'CA-12: Account');
        System.assertEquals(ordBefore, (Datetime) [SELECT MAX(LastModifiedDate) m FROM Order][0].get('m'), 'CA-12: Order');
        System.assertEquals(accCount, [SELECT COUNT() FROM Account]);
        System.assertEquals(ordCount, [SELECT COUNT() FROM Order]);
        System.assertEquals(itemCount, [SELECT COUNT() FROM OrderItem]);
        System.assertEquals(oppCount, [SELECT COUNT() FROM Opportunity]);
        System.assertEquals(0, [SELECT COUNT() FROM EmailMessage], 'nenhum e-mail');
        System.assert([SELECT COUNT() FROM CommercialSignal__c] > 0, 'o batch rodou e gravou so o objeto novo');
        }
    }

    @IsTest
    static void rerunIsIdempotent() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1)[0].Id;
        Account a = CommercialSignalTestFactory.createAccounts(1, null, 'I0')[0];
        CommercialSignalTestFactory.createAccounts(1, null, 'I1');
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(a.Id, 'Faturamento', 61, 100, prod) });
        runAgain(CommercialSignalTestFactory.settings());
        Map<Id, CommercialSignal__c> first = new Map<Id, CommercialSignal__c>([SELECT Id, SignalKey__c FROM CommercialSignal__c]);
        runAgain(CommercialSignalTestFactory.settings());
        Map<Id, CommercialSignal__c> second = new Map<Id, CommercialSignal__c>([SELECT Id, SignalKey__c FROM CommercialSignal__c]);
        System.assertEquals(2, second.size(), 'CA-15: sem duplicatas');
        System.assertEquals(first.keySet(), second.keySet(), 'mesmos registros (upsert, nao recria)');
        }
    }

    @IsTest
    static void newOrderRemovesRecoveryOnNextRun() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1)[0].Id;
        Account a = CommercialSignalTestFactory.createAccounts(1, null, 'N16')[0];
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(a.Id, 'Faturamento', 61, 100, prod) });
        runAgain(CommercialSignalTestFactory.settings());
        System.assertEquals(1, CommercialSignalTestFactory.signals(a.Id, 'Recuperacao').size());
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(a.Id, 'Faturamento', 0, 100, prod) });
        runAgain(CommercialSignalTestFactory.settings());
        System.assertEquals(0, CommercialSignalTestFactory.signals(a.Id, 'Recuperacao').size(), 'CA-16: sinal obsoleto removido');
        }
    }

    @IsTest
    static void parameterChangesClassificationWithoutCode() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1)[0].Id;
        Account a = CommercialSignalTestFactory.createAccounts(1, null, 'P17')[0];
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(a.Id, 'Faturamento', 61, 100, prod) });
        CommercialSignalService.Settings s = CommercialSignalTestFactory.settings();
        s.recoveryDays = 90;
        run(s, null);
        System.assertEquals(0, CommercialSignalTestFactory.signals(a.Id, 'Recuperacao').size(), 'CA-17');
        }
    }

    @IsTest
    static void bulkTwoHundredAccounts() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        List<Account> accounts = CommercialSignalTestFactory.createAccounts(200, 'Embalagens', 'B');
        run();
        System.assertEquals(200, [SELECT COUNT() FROM CommercialSignal__c WHERE Type__c = 'NuncaComprou' AND Account__c IN :accounts],
            'um sinal por conta em um unico lote de 200');
        }
    }

    @IsTest
    static void statefulCountersAndProcessDirectly() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        List<Account> accounts = CommercialSignalTestFactory.createAccounts(3, null, 'S');
        CommercialSignalBatch b = new CommercialSignalBatch(CommercialSignalTestFactory.settings(), TODAY, null);
        b.process([SELECT Id, Industry FROM Account WHERE Id IN :accounts]);
        System.assertEquals(3, b.accountsProcessed);
        System.assertEquals(3, b.signalsUpserted);
        System.assertEquals(0, b.signalsDeleted);
        System.assertEquals(0, b.failures);
        CommercialSignalService.Settings off = CommercialSignalTestFactory.settings();
        off.includeNeverPurchased = false;
        CommercialSignalBatch b2 = new CommercialSignalBatch(off, TODAY, null);
        b2.process([SELECT Id, Industry FROM Account WHERE Id IN :accounts]);
        System.assertEquals(3, b2.signalsDeleted, 'tipo desligado remove os sinais existentes');
        System.assertEquals(0, [SELECT COUNT() FROM CommercialSignal__c]);
        }
    }

    @IsTest
    static void signalsAreReadOnlyForPermissionSetUsers() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Account a = CommercialSignalTestFactory.createAccounts(1, null, 'PERM')[0];
        run();
        Profile prof = [SELECT Id FROM Profile WHERE UserType = 'Standard' AND (NOT Name LIKE '%Admin%') LIMIT 1];
        String uname = 'cs33' + Datetime.now().getTime() + '@example.com.invalid';
        User u = new User(
            Alias = 'cs33', Email = uname, Username = uname, LastName = 'Teste CS33', ProfileId = prof.Id,
            TimeZoneSidKey = 'America/Sao_Paulo', LocaleSidKey = 'pt_BR', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'pt_BR');
        insert u;
        System.runAs(u) {
            try {
                Database.query('SELECT Id FROM CommercialSignal__c WITH USER_MODE');
                System.assert(false, 'sem o permission set o usuario nao le o objeto');
            } catch (QueryException e) {
                System.assert(e.getMessage().length() > 0, 'acesso negado sem permission set');
            }
        }
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Comercial_SinaisComerciais'];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        }
        System.runAs(u) {
            List<SObject> visible = Database.query('SELECT Id FROM CommercialSignal__c WITH USER_MODE');
            System.assertEquals(1, visible.size(), 'com o permission set o usuario le o sinal');
            try {
                insert as user new CommercialSignal__c(Account__c = a.Id, Type__c = 'Cruzada', SignalKey__c = 'x');
                System.assert(false, 'permission set e somente leitura');
            } catch (Exception e) {
                System.assert(e instanceof TypeException || e instanceof DmlException,
                    'sem criar: ' + e.getTypeName());
            }
        }
        }
    }
}
