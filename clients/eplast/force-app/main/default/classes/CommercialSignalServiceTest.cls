@IsTest
private class CommercialSignalServiceTest {

    private static final Date TODAY = Date.newInstance(2026, 11, 15);

    private static CommercialSignalService.AccountFacts facts(Date lastPurchase, String grp) {
        CommercialSignalService.AccountFacts f = new CommercialSignalService.AccountFacts();
        f.accountId = '001000000000001AAA';
        f.groupValue = grp;
        f.lastPurchase = lastPurchase;
        return f;
    }

    @IsTest
    static void recoveryLimitIsStrict() {
        System.assertEquals(true, CommercialSignalService.isRecovery(TODAY.addDays(-61), TODAY, 60), 'CA-01: 61 dias entra');
        System.assertEquals(false, CommercialSignalService.isRecovery(TODAY.addDays(-60), TODAY, 60), '60 dias nao entra (estrito)');
        System.assertEquals(false, CommercialSignalService.isRecovery(TODAY.addDays(-59), TODAY, 60), 'CA-02: 59 dias nao entra');
        System.assertEquals(false, CommercialSignalService.isRecovery(null, TODAY, 60), 'sem compra nao e recuperacao');
        System.assertEquals(false, CommercialSignalService.isRecovery(TODAY, null, 60));
        System.assertEquals(false, CommercialSignalService.isRecovery(TODAY.addDays(1), TODAY, 60), 'pedido futuro nao e recuperacao');
    }

    @IsTest
    static void recoveryParameterChangesClassification() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        s.recoveryDays = 90;
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(facts(TODAY.addDays(-61), null), TODAY, s, null);
        System.assertEquals(0, out.size(), 'CA-17: com 90 dias a conta de 61 nao e recuperacao');
        s.recoveryDays = 60;
        out = CommercialSignalService.buildSignals(facts(TODAY.addDays(-61), null), TODAY, s, null);
        System.assertEquals(1, out.size());
        System.assertEquals('Recuperacao', out[0].Type__c);
        System.assertEquals(61, out[0].DaysWithoutPurchase__c);
        System.assertEquals(TODAY.addDays(-61), out[0].LastPurchaseDate__c);
        System.assertEquals(TODAY, out[0].CalculationDate__c);
        System.assert(out[0].Reason__c.contains('61'), 'motivo traz a metrica');
    }

    @IsTest
    static void neverPurchasedAndSwitch() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(facts(null, null), TODAY, s, null);
        System.assertEquals(1, out.size());
        System.assertEquals('NuncaComprou', out[0].Type__c, 'CA-03');
        s.includeNeverPurchased = false;
        out = CommercialSignalService.buildSignals(facts(null, null), TODAY, s, null);
        System.assertEquals(0, out.size(), 'PA-21: tipo pode ser desligado');
    }

    @IsTest
    static void volumeDropLimitIsStrict() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        System.assertEquals(null, CommercialSignalService.classifyVolume(10000, 7000, s), 'CA-05: 30% exato nao entra');
        System.assertEquals('QuedaVolume', CommercialSignalService.classifyVolume(10000, 6900, s), 'CA-05: 31% entra');
        System.assertEquals(31.0, CommercialSignalService.variationPercent(10000, 6900), 'percentual exibido 31');
        System.assertEquals('QuedaVolume', CommercialSignalService.classifyVolume(10000, 0, s), 'queda total entra');
    }

    @IsTest
    static void volumeRiseLimitIsStrict() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        System.assertEquals(null, CommercialSignalService.classifyVolume(10000, 13000, s), 'CA-06: 30% exato nao entra');
        System.assertEquals('AltaVolume', CommercialSignalService.classifyVolume(10000, 13100, s), 'CA-06: 31% entra');
    }

    @IsTest
    static void volumeWithoutBaseNeverClassifies() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        System.assertEquals(null, CommercialSignalService.classifyVolume(0, 5000, s), 'CA-07: base zero');
        System.assertEquals(null, CommercialSignalService.classifyVolume(null, 5000, s), 'CA-07: base nula');
        System.assertEquals(null, CommercialSignalService.variationPercent(0, 5000));
        System.assertEquals('QuedaVolume', CommercialSignalService.classifyVolume(10000, null, new CommercialSignalService.Settings()),
            'atual nulo conta como zero');
    }

    @IsTest
    static void volumeDirectionsAreConfigurable() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        s.directionDrop = false;
        System.assertEquals(null, CommercialSignalService.classifyVolume(10000, 1000, s), 'queda desligada');
        System.assertEquals('AltaVolume', CommercialSignalService.classifyVolume(10000, 20000, s));
        s.directionRise = false;
        System.assertEquals(null, CommercialSignalService.classifyVolume(10000, 20000, s), 'alta desligada');
        s.directionDrop = true;
        s.volumeThresholdPercent = 50;
        System.assertEquals(null, CommercialSignalService.classifyVolume(10000, 6000, s), 'limite 50% configuravel');
    }

    @IsTest
    static void volumeSignalCarriesAmounts() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        CommercialSignalService.AccountFacts f = facts(TODAY.addDays(-10), null);
        f.baseAmount = 10000;
        f.currentAmount = 6900;
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(f, TODAY, s, null);
        System.assertEquals(1, out.size());
        System.assertEquals('QuedaVolume', out[0].Type__c);
        System.assertEquals(10000, out[0].BasePeriodAmount__c);
        System.assertEquals(6900, out[0].CurrentPeriodAmount__c);
        System.assertEquals(31.0, out[0].VariationPercent__c);
    }

    @IsTest
    static void qualifyGroupRules() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        Id p1 = '01t000000000001AAA';
        Id p2 = '01t000000000002AAA';
        List<CommercialSignalService.Candidate> r =
            CommercialSignalService.qualifyGroup(10, new Map<Id, Integer>{ p1 => 4, p2 => 2 }, s);
        System.assertEquals(1, r.size(), 'CA-08: 4/10 passa, 2/10 nao');
        System.assertEquals(p1, r[0].productId);
        System.assertEquals(40.0, r[0].sharePercent);
        r = CommercialSignalService.qualifyGroup(10, new Map<Id, Integer>{ p1 => 3 }, s);
        System.assertEquals(1, r.size(), '30% exato passa (30% ou mais)');
        r = CommercialSignalService.qualifyGroup(4, new Map<Id, Integer>{ p1 => 4 }, s);
        System.assertEquals(0, r.size(), 'CA-11: grupo de 4 nao gera cruzada');
        r = CommercialSignalService.qualifyGroup(5, new Map<Id, Integer>{ p1 => 5 }, s);
        System.assertEquals(1, r.size(), 'grupo de 5 gera');
        System.assertEquals(0, CommercialSignalService.qualifyGroup(null, new Map<Id, Integer>{ p1 => 1 }, s).size());
    }

    @IsTest
    static void candidatesSortedByShareThenId() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        Id p1 = '01t000000000001AAA';
        Id p2 = '01t000000000002AAA';
        Id p3 = '01t000000000003AAA';
        List<CommercialSignalService.Candidate> r =
            CommercialSignalService.qualifyGroup(10, new Map<Id, Integer>{ p3 => 5, p2 => 9, p1 => 5 }, s);
        System.assertEquals(3, r.size());
        System.assertEquals(p2, r[0].productId, 'maior percentual primeiro');
        System.assertEquals(p1, r[1].productId, 'empate por Id');
        System.assertEquals(p3, r[2].productId);
    }

    @IsTest
    static void crossSellSkipsRecentProductsAndHonorsCap() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        s.crossSellMaxPerAccount = 2;
        Map<String, List<CommercialSignalService.Candidate>> q = new Map<String, List<CommercialSignalService.Candidate>>();
        List<CommercialSignalService.Candidate> list1 = new List<CommercialSignalService.Candidate>();
        for (Integer i = 1; i <= 4; i++) {
            CommercialSignalService.Candidate c = new CommercialSignalService.Candidate();
            c.productId = '01t00000000000' + i + 'AAA';
            c.sharePercent = 50 - i;
            c.buyers = 5;
            c.groupSize = 10;
            list1.add(c);
        }
        q.put('Plastico', list1);
        CommercialSignalService.AccountFacts f = facts(TODAY.addDays(-5), 'Plastico');
        f.recentProducts.add(list1[0].productId);
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(f, TODAY, s, q);
        System.assertEquals(2, out.size(), 'teto de 2 por conta');
        System.assertEquals(list1[1].productId, out[0].Product__c, 'CA-09: produto recente fica de fora');
        System.assertEquals(list1[2].productId, out[1].Product__c);
        System.assertEquals('Cruzada', out[0].Type__c);
        System.assert(out[0].SignalKey__c.endsWith(String.valueOf(list1[1].productId)));
        // CA-10: sem grupo nao ha cruzada
        System.assertEquals(0, CommercialSignalService.buildSignals(facts(TODAY.addDays(-5), null), TODAY, s, q).size());
        System.assertEquals(0, CommercialSignalService.buildSignals(facts(TODAY.addDays(-5), 'Outro'), TODAY, s, q).size());
    }

    @IsTest
    static void groupWithoutIndustryStillGetsRecovery() {
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(
            facts(TODAY.addDays(-61), null), TODAY, new CommercialSignalService.Settings(),
            new Map<String, List<CommercialSignalService.Candidate>>());
        System.assertEquals(1, out.size(), 'CA-10');
        System.assertEquals('Recuperacao', out[0].Type__c);
    }

    @IsTest
    static void helpers() {
        System.assertEquals(null, CommercialSignalService.groupKey(null));
        System.assertEquals(null, CommercialSignalService.groupKey('   '));
        System.assertEquals('Plastico', CommercialSignalService.groupKey(' Plastico '));
        System.assertEquals(2, CommercialSignalService.splitList('Faturamento; Concluido;;').size());
        System.assertEquals(0, CommercialSignalService.splitList(null).size());
        System.assertEquals('Industry', CommercialSignalService.resolveGroupField('CampoQueNaoExiste__c'));
        System.assertEquals('Industry', CommercialSignalService.resolveGroupField(null));
        System.assertEquals('Type', CommercialSignalService.resolveGroupField('type'));
        System.assertEquals('001000000000001AAA-Cruzada-', CommercialSignalService.signalKey('001000000000001AAA', 'Cruzada', null));
    }

    @IsTest
    static void loadSettingsMatchesDeployedDefault() {
        CommercialSignalService.Settings s = CommercialSignalService.loadSettings();
        System.assertEquals(60, s.recoveryDays);
        System.assertEquals(new List<String>{ 'Faturamento', 'Concluido' }, s.purchaseStatuses);
        System.assertEquals(3, s.volumeWindowMonths);
        System.assertEquals(30, s.volumeThresholdPercent);
        System.assertEquals(true, s.directionDrop);
        System.assertEquals(true, s.directionRise);
        System.assertEquals('Industry', s.crossSellGroupField);
        System.assertEquals(12, s.crossSellLookbackMonths);
        System.assertEquals(180, s.crossSellRecentDays);
        System.assertEquals(5, s.crossSellMinGroupSize);
        System.assertEquals(10, s.crossSellMaxPerAccount);
        System.assertEquals(100, s.batchSize);
        System.assertEquals(true, s.includeNeverPurchased);
    }

    @IsTest
    static void bulkTwoHundredAccounts() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        List<CommercialSignal__c> all = new List<CommercialSignal__c>();
        for (Integer i = 0; i < 200; i++) {
            CommercialSignalService.AccountFacts f = facts(i < 100 ? TODAY.addDays(-61) : null, null);
            f.accountId = '001' + String.valueOf(1000000 + i).leftPad(12, '0') + 'AAA';
            all.addAll(CommercialSignalService.buildSignals(f, TODAY, s, null));
        }
        System.assertEquals(200, all.size());
        Set<String> keys = new Set<String>();
        for (CommercialSignal__c c : all) {
            keys.add(c.SignalKey__c);
        }
        System.assertEquals(200, keys.size(), 'chaves unicas');
    }
}
