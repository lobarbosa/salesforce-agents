@IsTest
private class CommercialSignalBatchTest {

    @TestSetup
    static void grantAccess() {
        CommercialSignalTestFactory.grantSignalAccess();
    }

    /** Data fixa de calculo: ultimo mes fechado = out/2026; base = jul, ago e set/2026. */
    private static final Date TODAY = Date.newInstance(2026, 11, 17);

    private static void run(CommercialSignalService.Settings s,
                            Map<String, List<CommercialSignalService.Candidate>> q) {
        Test.startTest();
        Database.executeBatch(new CommercialSignalBatch(s, TODAY, q), 200);
        Test.stopTest();
    }

    /** Execucao sincrona do mesmo calculo do batch, para cenarios com duas execucoes no mesmo teste. */
    private static void runAgain(CommercialSignalService.Settings s) {
        new CommercialSignalBatch(s, TODAY, null).process([SELECT Id, Sector__c FROM Account]);
    }

    private static void run() {
        run(CommercialSignalTestFactory.settings(), null);
    }

    private static CommercialSignalTestFactory.OrderSpec spec(Id acc, String status, Integer daysAgo, Decimal amount, Id prod) {
        return new CommercialSignalTestFactory.OrderSpec(acc, status, TODAY.addDays(-daysAgo), amount, prod);
    }

    /** Pedido faturado no dia 15 do mes `monthsBack` meses antes de nov/2026 (1 = out, ultimo mes fechado; 2 a 4 = base). */
    private static CommercialSignalTestFactory.OrderSpec inMonth(Id acc, Integer monthsBack, Decimal amount, Id prod) {
        return new CommercialSignalTestFactory.OrderSpec(
            acc, 'Faturamento', Date.newInstance(2026, 11, 15).addMonths(-monthsBack), amount, prod);
    }

    /** Tres meses de base (jul, ago, set) com `base` cada e o ultimo mes fechado com `current`. */
    private static List<CommercialSignalTestFactory.OrderSpec> pattern(Id acc, Decimal base, Decimal current, Id prod) {
        return new List<CommercialSignalTestFactory.OrderSpec>{
            inMonth(acc, 4, base, prod), inMonth(acc, 3, base, prod), inMonth(acc, 2, base, prod), inMonth(acc, 1, current, prod) };
    }

    @IsTest
    static void recoveryAt91DaysAndNotAt90() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1)[0].Id;
        Account a91 = CommercialSignalTestFactory.createAccounts(1, null, 'R91')[0];
        Account a90 = CommercialSignalTestFactory.createAccounts(1, null, 'R90')[0];
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(a91.Id, 'Faturamento', 91, 100, prod), spec(a90.Id, 'Concluido', 90, 100, prod) });
        run();
        List<CommercialSignal__c> r = CommercialSignalTestFactory.signals(a91.Id, 'Recuperacao');
        System.assertEquals(1, r.size(), 'CA-01');
        System.assertEquals(91, r[0].DaysWithoutPurchase__c);
        System.assertEquals(0, CommercialSignalTestFactory.signals(a90.Id, 'Recuperacao').size(), 'CA-02: 90 dias nao entra');
        System.assertEquals(0, CommercialSignalTestFactory.signals(a90.Id, 'NuncaComprou').size(), 'comprou, nao e nunca comprou');
        System.assertEquals(0, [SELECT COUNT() FROM CommercialSignal__c WHERE Account__c = :a91.Id AND Type__c != 'Recuperacao'],
            'PA-27: conta em recuperacao nao recebe sinal de volume');
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
        System.assertEquals(1, CommercialSignalTestFactory.signals(inv.Id, 'NuncaComprou').size(), 'CA-04: cancelado e rascunho nao contam');
        System.assertEquals(0, CommercialSignalTestFactory.signals(inv.Id, 'Recuperacao').size());
        }
    }

    @IsTest
    static void familyDropAtExactly20PercentAndNotAt19() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1, 'PREF', 'UN')[0].Id;
        Account d20 = CommercialSignalTestFactory.createAccounts(1, null, 'D20')[0];
        Account d19 = CommercialSignalTestFactory.createAccounts(1, null, 'D19')[0];
        // base: 10000 por mes (jul, ago, set); ultimo mes fechado (out): 8000 = queda de 20,0%; 8001 = 19,99%
        List<CommercialSignalTestFactory.OrderSpec> specs = pattern(d20.Id, 10000, 8000, prod);
        specs.addAll(pattern(d19.Id, 10000, 8001, prod));
        CommercialSignalTestFactory.createOrders(specs);
        run();
        List<CommercialSignal__c> drop = CommercialSignalTestFactory.signals(d20.Id, 'QuedaVolume');
        System.assertEquals(1, drop.size(), 'queda de 20% entra (20% ou mais)');
        System.assertEquals('PREF', drop[0].ProductFamily__c);
        System.assertEquals(20.0, drop[0].VariationPercent__c);
        System.assertEquals(10000, drop[0].BasePeriodAmount__c, 'media mensal da base');
        System.assertEquals(8000, drop[0].CurrentPeriodAmount__c, 'ultimo mes fechado');
        System.assertEquals('UN', drop[0].UnitOfMeasure__c);
        System.assertEquals(1, drop[0].BasePeriodQuantity__c, 'quantidade media mensal');
        System.assertEquals(1, drop[0].CurrentPeriodQuantity__c);
        System.assertEquals(d20.Id + '-QuedaVolume-PREF', drop[0].SignalKey__c);
        System.assertEquals(0, CommercialSignalTestFactory.signals(d19.Id, 'QuedaVolume').size(), '19,99% nao entra');
        System.assertEquals(0, CommercialSignalTestFactory.signals(d19.Id, 'HistoricoInsuficiente').size(), 'base completa, sem historico insuficiente');
        }
    }

    @IsTest
    static void averageCountsMonthWithoutPurchaseAsZeroAndRiseIsOff() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1, 'PREF', 'UN')[0].Id;
        Account avg = CommercialSignalTestFactory.createAccounts(1, null, 'AVG')[0];
        Account up = CommercialSignalTestFactory.createAccounts(1, null, 'UP')[0];
        // avg: base so em ago e set (15000 + 15000) = media 10000 sobre 3 meses; out = 8000 -> queda de 20%
        List<CommercialSignalTestFactory.OrderSpec> specs = new List<CommercialSignalTestFactory.OrderSpec>{
            inMonth(avg.Id, 3, 15000, prod), inMonth(avg.Id, 2, 15000, prod), inMonth(avg.Id, 1, 8000, prod) };
        specs.addAll(pattern(up.Id, 10000, 20000, prod));
        CommercialSignalTestFactory.createOrders(specs);
        run();
        List<CommercialSignal__c> drop = CommercialSignalTestFactory.signals(avg.Id, 'QuedaVolume');
        System.assertEquals(1, drop.size());
        System.assertEquals(10000, drop[0].BasePeriodAmount__c);
        System.assertEquals(0, CommercialSignalTestFactory.signals(up.Id, 'AltaVolume').size(), 'cliente pediu so queda');
        System.assertEquals(0, CommercialSignalTestFactory.signals(up.Id, 'QuedaVolume').size());
        }
    }

    @IsTest
    static void volumeIgnoresCurrentMonthAndOlderMonths() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1, 'PREF', 'UN')[0].Id;
        Account a = CommercialSignalTestFactory.createAccounts(1, null, 'WIN')[0];
        // estavel nos meses completos (10000 em jul/ago/set/out); compra grande em nov (mes corrente, fora da janela)
        // e compra antiga em jun (fora da base) nao mudam o resultado
        List<CommercialSignalTestFactory.OrderSpec> specs = pattern(a.Id, 10000, 10000, prod);
        specs.add(new CommercialSignalTestFactory.OrderSpec(a.Id, 'Faturamento', Date.newInstance(2026, 11, 10), 500000, prod));
        specs.add(new CommercialSignalTestFactory.OrderSpec(a.Id, 'Faturamento', Date.newInstance(2026, 6, 10), 500000, prod));
        CommercialSignalTestFactory.createOrders(specs);
        run();
        System.assertEquals(0, [SELECT COUNT() FROM CommercialSignal__c WHERE Account__c = :a.Id AND Type__c IN ('QuedaVolume', 'AltaVolume', 'HistoricoInsuficiente')],
            'so os 4 meses completos entram na comparacao');
        }
    }

    @IsTest
    static void insufficientHistoryWithOneBaseMonth() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1, 'TAMP', 'UN')[0].Id;
        Account one = CommercialSignalTestFactory.createAccounts(1, null, 'H1')[0];
        Account two = CommercialSignalTestFactory.createAccounts(1, null, 'H2')[0];
        List<CommercialSignalTestFactory.OrderSpec> specs = new List<CommercialSignalTestFactory.OrderSpec>{
            inMonth(one.Id, 2, 10000, prod), inMonth(one.Id, 1, 5000, prod),
            inMonth(two.Id, 3, 10000, prod), inMonth(two.Id, 2, 10000, prod), inMonth(two.Id, 1, 10000, prod) };
        CommercialSignalTestFactory.createOrders(specs);
        run();
        List<CommercialSignal__c> h = CommercialSignalTestFactory.signals(one.Id, 'HistoricoInsuficiente');
        System.assertEquals(1, h.size(), 'comprou a familia em 1 de 3 meses da base');
        System.assertEquals('TAMP', h[0].ProductFamily__c);
        System.assertEquals(null, h[0].VariationPercent__c, 'nao compara');
        System.assertEquals(0, CommercialSignalTestFactory.signals(one.Id, 'QuedaVolume').size());
        System.assertEquals(0, CommercialSignalTestFactory.signals(two.Id, 'HistoricoInsuficiente').size(), '2 de 3 meses basta');
        System.assertEquals(0, CommercialSignalTestFactory.signals(two.Id, 'QuedaVolume').size(), 'media de 6.666,67 contra 10000: alta, nao queda');
        }
    }

    @IsTest
    static void familiesAreIndependentAndNoGroupBecomesSemFamilia() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id pref = CommercialSignalTestFactory.createProducts(1, 'PREF', 'UN')[0].Id;
        Id tamp = CommercialSignalTestFactory.createProducts(1, 'TAMP', 'UN')[0].Id;
        Id none = CommercialSignalTestFactory.createProducts(1)[0].Id;
        Account a = CommercialSignalTestFactory.createAccounts(1, null, 'FAM')[0];
        List<CommercialSignalTestFactory.OrderSpec> specs = pattern(a.Id, 10000, 10000, pref);
        specs.addAll(pattern(a.Id, 10000, 1000, tamp));
        specs.addAll(pattern(a.Id, 10000, 1000, none));
        CommercialSignalTestFactory.createOrders(specs);
        run();
        Set<String> families = new Set<String>();
        for (CommercialSignal__c c : CommercialSignalTestFactory.signals(a.Id, 'QuedaVolume')) {
            families.add(c.ProductFamily__c);
        }
        System.assertEquals(new Set<String>{ 'TAMP', 'Sem familia' }, families, 'PREF estavel nao gera; produto sem grupo vira Sem familia');
        }
    }

    @IsTest
    static void mixedUnitsFamilyDoesNotSumQuantity() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id un = CommercialSignalTestFactory.createProducts(1, 'RESI', 'UN')[0].Id;
        Id kg = CommercialSignalTestFactory.createProducts(1, 'RESI', 'KG')[0].Id;
        Account a = CommercialSignalTestFactory.createAccounts(1, null, 'MIX')[0];
        List<CommercialSignalTestFactory.OrderSpec> specs = pattern(a.Id, 5000, 1000, un);
        specs.addAll(pattern(a.Id, 5000, 1000, kg));
        CommercialSignalTestFactory.createOrders(specs);
        run();
        List<CommercialSignal__c> r = CommercialSignalTestFactory.signals(a.Id, 'QuedaVolume');
        System.assertEquals(1, r.size(), 'uma linha por familia, nao por unidade');
        System.assertEquals('MISTA', r[0].UnitOfMeasure__c);
        System.assertEquals(null, r[0].CurrentPeriodQuantity__c, 'quantidade de unidades diferentes nao soma');
        System.assertEquals(null, r[0].BasePeriodQuantity__c);
        System.assertEquals(10000, r[0].BasePeriodAmount__c, 'valor soma as duas unidades');
        System.assertEquals(2000, r[0].CurrentPeriodAmount__c);
        }
    }

    @IsTest
    static void quantityMetricUsesQuantityNotValue() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1, 'PREF', 'UN')[0].Id;
        Account a = CommercialSignalTestFactory.createAccounts(1, null, 'QTY')[0];
        // valor estavel (10000), quantidade cai de 100 para 50 em out
        List<CommercialSignalTestFactory.OrderSpec> specs = new List<CommercialSignalTestFactory.OrderSpec>();
        for (Integer m = 2; m <= 4; m++) {
            specs.add(inMonth(a.Id, m, 10000, prod).withQuantity(100));
        }
        specs.add(inMonth(a.Id, 1, 10000, prod).withQuantity(50));
        CommercialSignalTestFactory.createOrders(specs);
        run();
        System.assertEquals(0, CommercialSignalTestFactory.signals(a.Id, 'QuedaVolume').size(), 'metrica Valor: estavel');
        CommercialSignalService.Settings s = CommercialSignalTestFactory.settings();
        s.volumeMetric = 'Quantidade';
        runAgain(s);
        List<CommercialSignal__c> r = CommercialSignalTestFactory.signals(a.Id, 'QuedaVolume');
        System.assertEquals(1, r.size(), 'metrica Quantidade: queda de 50%');
        System.assertEquals(50.0, r[0].VariationPercent__c);
        System.assertEquals(100, r[0].BasePeriodQuantity__c);
        System.assertEquals(50, r[0].CurrentPeriodQuantity__c);
        }
    }

    @IsTest
    static void crossSellByFamilyExcludesRecentBuyerAndAccountWithoutSector() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        List<Account> grp = CommercialSignalTestFactory.createAccounts(10, 'Alimentos', 'CS');
        Account noSector = CommercialSignalTestFactory.createAccounts(1, null, 'CSX')[0];
        Product2 p = CommercialSignalTestFactory.createProducts(1, 'PREF', 'UN')[0];
        CommercialSignalService.Candidate c = new CommercialSignalService.Candidate();
        c.itemKey = 'PREF';
        c.sharePercent = 40;
        c.buyers = 4;
        c.groupSize = 10;
        // conta 9 comprou PREF ha 90 dias (recente, CA-09); conta 8 comprou ha 200 dias (fora da janela de 180)
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(grp[9].Id, 'Faturamento', 90, 100, p.Id), spec(grp[8].Id, 'Faturamento', 200, 100, p.Id) });
        run(CommercialSignalTestFactory.settings(),
            new Map<String, List<CommercialSignalService.Candidate>>{ 'Alimentos' => new List<CommercialSignalService.Candidate>{ c } });
        System.assertEquals(0, CommercialSignalTestFactory.signals(grp[9].Id, 'Cruzada').size(), 'CA-09');
        List<CommercialSignal__c> old = CommercialSignalTestFactory.signals(grp[8].Id, 'Cruzada');
        System.assertEquals(1, old.size(), 'compra antiga nao bloqueia');
        System.assertEquals('PREF', old[0].ProductFamily__c, 'sugere familia');
        System.assertEquals(null, old[0].Product__c);
        System.assertEquals(1, CommercialSignalTestFactory.signals(grp[0].Id, 'Cruzada').size());
        System.assertEquals(0, CommercialSignalTestFactory.signals(noSector.Id, 'Cruzada').size(), 'CA-10');
        System.assertEquals(1, CommercialSignalTestFactory.signals(noSector.Id, 'NuncaComprou').size(), 'segue nos demais tipos');
        }
    }

    @IsTest
    static void crossSellByProductWhenLevelIsProduto() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        List<Account> grp = CommercialSignalTestFactory.createAccounts(3, 'Bebidas', 'CP');
        Product2 p = CommercialSignalTestFactory.createProducts(1, 'PREF', 'UN')[0];
        CommercialSignalService.Settings s = CommercialSignalTestFactory.settings();
        s.crossSellLevel = 'Produto';
        CommercialSignalService.Candidate c = new CommercialSignalService.Candidate();
        c.itemKey = String.valueOf(p.Id);
        c.productId = p.Id;
        c.sharePercent = 60;
        c.buyers = 3;
        c.groupSize = 5;
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(grp[0].Id, 'Faturamento', 20, 100, p.Id) });
        run(s, new Map<String, List<CommercialSignalService.Candidate>>{ 'Bebidas' => new List<CommercialSignalService.Candidate>{ c } });
        System.assertEquals(0, CommercialSignalTestFactory.signals(grp[0].Id, 'Cruzada').size(), 'comprou o produto ha 20 dias');
        List<CommercialSignal__c> r = CommercialSignalTestFactory.signals(grp[1].Id, 'Cruzada');
        System.assertEquals(1, r.size());
        System.assertEquals(p.Id, r[0].Product__c);
        System.assertEquals(null, r[0].ProductFamily__c);
        }
    }

    @IsTest
    static void changingPurchaseDateFieldChangesResultWithoutDeploy() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1)[0].Id;
        Account a = CommercialSignalTestFactory.createAccounts(1, null, 'DT')[0];
        Account empty = CommercialSignalTestFactory.createAccounts(1, null, 'DT0')[0];
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(a.Id, 'Faturamento', 30, 100, prod) });
        runAgain(CommercialSignalTestFactory.settings());
        System.assertEquals(0, CommercialSignalTestFactory.signals(a.Id, 'NuncaComprou').size(), 'EffectiveDate: tem compra');
        CommercialSignalService.Settings s = CommercialSignalTestFactory.settings();
        s.purchaseDateField = 'IssuanceDate__c';
        runAgain(s);
        System.assertEquals(1, CommercialSignalTestFactory.signals(a.Id, 'NuncaComprou').size(),
            'IssuanceDate__c vazio no pedido: so a data do parametro muda, sem deploy');
        // campo Data/Hora: a consulta usa limites Datetime; conta sem pedido segue como nunca comprou
        s.purchaseDateField = 'ActivatedDate';
        CommercialSignalBatch b = new CommercialSignalBatch(s, TODAY, null);
        b.process([SELECT Id, Sector__c FROM Account WHERE Id = :empty.Id]);
        System.assertEquals(1, CommercialSignalTestFactory.signals(empty.Id, 'NuncaComprou').size());
        System.assertEquals(0, b.failures);
        }
    }

    @IsTest
    static void doesNotWriteToCommercialObjects() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id prod = CommercialSignalTestFactory.createProducts(1)[0].Id;
        Account a = CommercialSignalTestFactory.createAccounts(1, 'Alimentos', 'W0')[0];
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            spec(a.Id, 'Faturamento', 91, 100, prod) });
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
            spec(a.Id, 'Faturamento', 91, 100, prod) });
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
            spec(a.Id, 'Faturamento', 91, 100, prod) });
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
            spec(a.Id, 'Faturamento', 91, 100, prod) });
        CommercialSignalService.Settings s = CommercialSignalTestFactory.settings();
        s.recoveryDays = 120;
        run(s, null);
        System.assertEquals(0, CommercialSignalTestFactory.signals(a.Id, 'Recuperacao').size(), 'CA-17: com 120 dias a conta de 91 nao entra');
        runAgain(CommercialSignalTestFactory.settings());
        System.assertEquals(1, CommercialSignalTestFactory.signals(a.Id, 'Recuperacao').size(), 'com o padrao de 90 dias a mesma conta entra, sem deploy');
        }
    }

    @IsTest
    static void bulkTwoHundredAccounts() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        List<Account> accounts = CommercialSignalTestFactory.createAccounts(200, 'Alimentos', 'B');
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
        b.process([SELECT Id, Sector__c FROM Account WHERE Id IN :accounts]);
        System.assertEquals(3, b.accountsProcessed);
        System.assertEquals(3, b.signalsUpserted);
        System.assertEquals(0, b.signalsDeleted);
        System.assertEquals(0, b.failures);
        CommercialSignalService.Settings off = CommercialSignalTestFactory.settings();
        off.includeNeverPurchased = false;
        CommercialSignalBatch b2 = new CommercialSignalBatch(off, TODAY, null);
        b2.process([SELECT Id, Sector__c FROM Account WHERE Id IN :accounts]);
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
