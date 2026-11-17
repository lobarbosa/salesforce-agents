@IsTest
private class CommercialSignalServiceTest {

    private static final Date TODAY = Date.newInstance(2026, 11, 17);

    private static CommercialSignalService.AccountFacts facts(Date lastPurchase, String grp) {
        CommercialSignalService.AccountFacts f = new CommercialSignalService.AccountFacts();
        f.accountId = '001000000000001AAA';
        f.groupValue = grp;
        f.lastPurchase = lastPurchase;
        return f;
    }

    /** Familia com `baseTotal` somado nos meses da base (`baseMonths` meses com compra) e `cur` no ultimo mes. */
    private static CommercialSignalService.FamilyFacts fam(
        String name, Decimal cur, Decimal baseTotal, Integer baseMonths, String unit, Decimal curQty, Decimal baseQtyTotal
    ) {
        CommercialSignalService.FamilyFacts ff = new CommercialSignalService.FamilyFacts(name);
        ff.currentAmount = cur;
        ff.baseAmountTotal = baseTotal;
        ff.currentQuantity = curQty;
        ff.baseQuantityTotal = baseQtyTotal;
        for (Integer i = 0; i < baseMonths; i++) {
            ff.baseMonths.add('2026-' + (7 + i));
        }
        ff.units.add(unit);
        return ff;
    }

    private static CommercialSignalService.Candidate candidate(String key, Decimal share) {
        CommercialSignalService.Candidate c = new CommercialSignalService.Candidate();
        c.itemKey = key;
        c.sharePercent = share;
        c.buyers = 5;
        c.groupSize = 10;
        return c;
    }

    @IsTest
    static void recoveryLimitIsStrict() {
        System.assertEquals(true, CommercialSignalService.isRecovery(TODAY.addDays(-91), TODAY, 90), 'CA-01: 91 dias entra');
        System.assertEquals(false, CommercialSignalService.isRecovery(TODAY.addDays(-90), TODAY, 90), '90 dias nao entra (estrito)');
        System.assertEquals(false, CommercialSignalService.isRecovery(TODAY.addDays(-89), TODAY, 90), 'CA-02: 89 dias nao entra');
        System.assertEquals(false, CommercialSignalService.isRecovery(null, TODAY, 90), 'sem compra nao e recuperacao');
        System.assertEquals(false, CommercialSignalService.isRecovery(TODAY, null, 90));
        System.assertEquals(false, CommercialSignalService.isRecovery(TODAY.addDays(1), TODAY, 90), 'pedido futuro nao e recuperacao');
    }

    @IsTest
    static void recoveryParameterChangesClassification() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(facts(TODAY.addDays(-61), null), TODAY, s, null);
        System.assertEquals(0, out.size(), 'padrao 90: a conta de 61 dias nao e recuperacao');
        s.recoveryDays = 60;
        out = CommercialSignalService.buildSignals(facts(TODAY.addDays(-61), null), TODAY, s, null);
        System.assertEquals(1, out.size(), 'CA-17: com 60 dias a conta de 61 entra');
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
    static void volumeDropLimitIsInclusive() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        System.assertEquals('QuedaVolume', CommercialSignalService.classifyVolume(10000, 8000, s), 'queda de 20,0% entra (20% ou mais)');
        System.assertEquals(null, CommercialSignalService.classifyVolume(10000, 8001, s), 'queda de 19,99% nao entra');
        System.assertEquals('QuedaVolume', CommercialSignalService.classifyVolume(10000, 7000, s), 'queda de 30% entra');
        System.assertEquals('QuedaVolume', CommercialSignalService.classifyVolume(10000, 0, s), 'queda total entra');
        System.assertEquals(20.0, CommercialSignalService.variationPercent(10000, 8000), 'percentual exibido 20');
        System.assertEquals(19.9, CommercialSignalService.variationPercent(10000, 8010), 'percentual exibido 19,9');
    }

    @IsTest
    static void volumeRiseIsOffByDefaultAndInclusiveWhenOn() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        System.assertEquals(null, CommercialSignalService.classifyVolume(10000, 20000, s), 'alta desligada no padrao');
        s.directionRise = true;
        System.assertEquals('AltaVolume', CommercialSignalService.classifyVolume(10000, 12000, s), 'alta de 20% entra');
        System.assertEquals(null, CommercialSignalService.classifyVolume(10000, 11999, s));
    }

    @IsTest
    static void volumeWithoutBaseNeverClassifies() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        System.assertEquals(null, CommercialSignalService.classifyVolume(0, 5000, s), 'CA-07: base zero');
        System.assertEquals(null, CommercialSignalService.classifyVolume(null, 5000, s), 'CA-07: base nula');
        System.assertEquals(null, CommercialSignalService.variationPercent(0, 5000));
        System.assertEquals('QuedaVolume', CommercialSignalService.classifyVolume(10000, null, s), 'atual nulo conta como zero');
    }

    @IsTest
    static void volumeDirectionsAndThresholdAreConfigurable() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        s.directionDrop = false;
        System.assertEquals(null, CommercialSignalService.classifyVolume(10000, 1000, s), 'queda desligada');
        s.directionDrop = true;
        s.volumeThresholdPercent = 50;
        System.assertEquals(null, CommercialSignalService.classifyVolume(10000, 6000, s), 'limite 50% configuravel');
        System.assertEquals('QuedaVolume', CommercialSignalService.classifyVolume(10000, 5000, s));
    }

    @IsTest
    static void monthlyAverageCountsMissingMonthsAsZero() {
        System.assertEquals(10000, CommercialSignalService.monthlyAverage(30000, 3));
        System.assertEquals(0, CommercialSignalService.monthlyAverage(null, 3));
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        // base so em 2 dos 3 meses (15000 + 15000): media 10000; 8000 e queda de exatamente 20%
        System.assertEquals('QuedaVolume', CommercialSignalService.classifyFamily(fam('PREF', 8000, 30000, 2, 'UN', 0, 0), s));
    }

    @IsTest
    static void insufficientHistoryUsesMinimumBaseMonths() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        System.assertEquals('HistoricoInsuficiente', CommercialSignalService.classifyFamily(fam('PREF', 1, 30000, 1, 'UN', 0, 0), s), '1 mes da base: nao compara');
        System.assertEquals('QuedaVolume', CommercialSignalService.classifyFamily(fam('PREF', 1, 30000, 2, 'UN', 0, 0), s), '2 meses da base: compara');
        System.assertEquals(null, CommercialSignalService.classifyFamily(fam('PREF', 10000, 30000, 3, 'UN', 0, 0), s), 'estavel');
        s.volumeMinBaseMonths = 3;
        System.assertEquals('HistoricoInsuficiente', CommercialSignalService.classifyFamily(fam('PREF', 1, 30000, 2, 'UN', 0, 0), s), 'minimo e parametro');
    }

    @IsTest
    static void metricSelectsAmountQuantityOrEither() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        // valor estavel, quantidade caiu de 100 (media) para 50
        CommercialSignalService.FamilyFacts qtyDrop = fam('PREF', 10000, 30000, 3, 'UN', 50, 300);
        System.assertEquals(null, CommercialSignalService.classifyFamily(qtyDrop, s), 'metrica Valor ignora quantidade');
        s.volumeMetric = 'Quantidade';
        System.assertEquals('QuedaVolume', CommercialSignalService.classifyFamily(qtyDrop, s));
        s.volumeMetric = 'ValorOuQuantidade';
        System.assertEquals('QuedaVolume', CommercialSignalService.classifyFamily(qtyDrop, s));
        // unidades mistas: quantidade nao entra, so o valor
        CommercialSignalService.FamilyFacts mixed = fam('RESI', 10000, 30000, 3, 'UN', 50, 300);
        mixed.units.add('KG');
        System.assertEquals(true, CommercialSignalService.isMixedUnits(mixed));
        System.assertEquals(null, CommercialSignalService.classifyFamily(mixed, s), 'unidades mistas: quantidade nao soma');
        s.volumeMetric = 'Quantidade';
        System.assertEquals(null, CommercialSignalService.classifyFamily(mixed, s));
    }

    @IsTest
    static void familyDropSignalCarriesAmountsQuantityAndUnit() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        CommercialSignalService.AccountFacts f = facts(TODAY.addDays(-10), null);
        f.families.put('PREF', fam('PREF', 8000, 30000, 3, 'UN', 80, 300));
        f.families.put('TAMP', fam('TAMP', 10000, 30000, 3, 'UN', 100, 300));
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(f, TODAY, s, null);
        System.assertEquals(1, out.size(), 'so a familia que caiu gera sinal');
        System.assertEquals('QuedaVolume', out[0].Type__c);
        System.assertEquals('PREF', out[0].ProductFamily__c);
        System.assertEquals(10000, out[0].BasePeriodAmount__c, 'media mensal da base');
        System.assertEquals(8000, out[0].CurrentPeriodAmount__c, 'ultimo mes fechado');
        System.assertEquals(100, out[0].BasePeriodQuantity__c);
        System.assertEquals(80, out[0].CurrentPeriodQuantity__c);
        System.assertEquals('UN', out[0].UnitOfMeasure__c);
        System.assertEquals(20.0, out[0].VariationPercent__c);
        System.assert(out[0].SignalKey__c.endsWith('-QuedaVolume-PREF'), 'chave inclui a familia');
        System.assert(out[0].Reason__c.contains('PREF'));
    }

    @IsTest
    static void mixedUnitsFamilyShowsMistaAndNoQuantity() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        CommercialSignalService.AccountFacts f = facts(TODAY.addDays(-10), null);
        CommercialSignalService.FamilyFacts ff = fam('RESI', 5000, 30000, 3, 'UN', 5, 30);
        ff.units.add('KG');
        f.families.put('RESI', ff);
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(f, TODAY, s, null);
        System.assertEquals(1, out.size());
        System.assertEquals('MISTA', out[0].UnitOfMeasure__c);
        System.assertEquals(null, out[0].BasePeriodQuantity__c, 'quantidade nao e somada entre unidades');
        System.assertEquals(null, out[0].CurrentPeriodQuantity__c);
        System.assertEquals(10000, out[0].BasePeriodAmount__c);
    }

    @IsTest
    static void quantityMetricUsesQuantityVariationAndNoUnitLabel() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        s.volumeMetric = 'Quantidade';
        CommercialSignalService.AccountFacts f = facts(TODAY.addDays(-10), null);
        CommercialSignalService.FamilyFacts ff = fam('GPET', 10000, 30000, 3, 'SEM UNIDADE', 50, 300);
        f.families.put('GPET', ff);
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(f, TODAY, s, null);
        System.assertEquals(1, out.size());
        System.assertEquals(50.0, out[0].VariationPercent__c, 'percentual da quantidade (100 -> 50)');
        System.assertEquals('SEM UNIDADE', out[0].UnitOfMeasure__c);
        CommercialSignalService.AccountFacts g = facts(TODAY.addDays(-10), null);
        g.families.put('X', new CommercialSignalService.FamilyFacts('X'));
        g.families.get('X').baseMonths.addAll(new Set<String>{ 'a', 'b' });
        g.families.get('X').baseAmountTotal = 10;
        g.families.get('X').currentAmount = 10;
        System.assertEquals(0, CommercialSignalService.buildSignals(g, TODAY, new CommercialSignalService.Settings(), null).size(),
            'familia estavel: sem sinal');
    }

    @IsTest
    static void insufficientHistorySignalDoesNotCompare() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        CommercialSignalService.AccountFacts f = facts(TODAY.addDays(-10), null);
        f.families.put('TAMP', fam('TAMP', 500, 9000, 1, 'UN', 5, 90));
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(f, TODAY, s, null);
        System.assertEquals(1, out.size());
        System.assertEquals('HistoricoInsuficiente', out[0].Type__c);
        System.assertEquals('TAMP', out[0].ProductFamily__c);
        System.assertEquals(null, out[0].VariationPercent__c, 'nao compara');
        System.assert(out[0].Reason__c.contains('1 de 3'), 'motivo diz quantos meses da base: ' + out[0].Reason__c);
    }

    @IsTest
    static void accountInRecoveryOrNeverGetsNoVolumeSignal() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        CommercialSignalService.AccountFacts f = facts(TODAY.addDays(-91), null);
        f.families.put('PREF', fam('PREF', 0, 30000, 3, 'UN', 0, 300));
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(f, TODAY, s, null);
        System.assertEquals(1, out.size(), 'PA-27: so Recuperacao, sem queda por familia');
        System.assertEquals('Recuperacao', out[0].Type__c);
        CommercialSignalService.AccountFacts n = facts(null, null);
        n.families.put('PREF', fam('PREF', 0, 30000, 3, 'UN', 0, 300));
        s.includeNeverPurchased = false;
        System.assertEquals(0, CommercialSignalService.buildSignals(n, TODAY, s, null).size(), 'sem compra e tipo desligado: nada');
    }

    @IsTest
    static void qualifyGroupRulesByFamily() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        List<CommercialSignalService.Candidate> r =
            CommercialSignalService.qualifyGroup(10, new Map<String, Integer>{ 'PREF' => 4, 'TAMP' => 2 }, s);
        System.assertEquals(1, r.size(), 'CA-08: 4/10 passa, 2/10 nao');
        System.assertEquals('PREF', r[0].itemKey);
        System.assertEquals(null, r[0].productId, 'nivel familia nao tem produto');
        System.assertEquals(40.0, r[0].sharePercent);
        r = CommercialSignalService.qualifyGroup(10, new Map<String, Integer>{ 'PREF' => 3 }, s);
        System.assertEquals(1, r.size(), '30% exato passa (30% ou mais)');
        r = CommercialSignalService.qualifyGroup(4, new Map<String, Integer>{ 'PREF' => 4 }, s);
        System.assertEquals(0, r.size(), 'CA-11: segmento de 4 nao gera cruzada');
        r = CommercialSignalService.qualifyGroup(5, new Map<String, Integer>{ 'PREF' => 5 }, s);
        System.assertEquals(1, r.size(), 'segmento de 5 gera');
        System.assertEquals(0, CommercialSignalService.qualifyGroup(null, new Map<String, Integer>{ 'PREF' => 1 }, s).size());
        r = CommercialSignalService.qualifyGroup(10, new Map<String, Integer>{ 'Sem familia' => 9 }, s);
        System.assertEquals(0, r.size(), '"Sem familia" nunca e sugerida');
    }

    @IsTest
    static void excludedFamiliesAreNeverSuggested() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        s.crossSellExcludedFamilies.add('resi');
        List<CommercialSignalService.Candidate> r =
            CommercialSignalService.qualifyGroup(10, new Map<String, Integer>{ 'RESI' => 9, 'PREF' => 5 }, s);
        System.assertEquals(1, r.size());
        System.assertEquals('PREF', r[0].itemKey, 'RESI excluida');
    }

    @IsTest
    static void qualifyGroupByProductKeepsProductId() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        s.crossSellLevel = 'Produto';
        Id p1 = '01t000000000001AAA';
        List<CommercialSignalService.Candidate> r =
            CommercialSignalService.qualifyGroup(10, new Map<String, Integer>{ String.valueOf(p1) => 4 }, s);
        System.assertEquals(1, r.size());
        System.assertEquals(p1, r[0].productId);
        s.crossSellExcludedFamilies.add(String.valueOf(p1).toLowerCase());
        System.assertEquals(1, CommercialSignalService.qualifyGroup(10, new Map<String, Integer>{ String.valueOf(p1) => 4 }, s).size(),
            'exclusao de familia nao se aplica ao nivel produto');
    }

    @IsTest
    static void candidatesSortedByShareThenKey() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        List<CommercialSignalService.Candidate> r = CommercialSignalService.qualifyGroup(
            10, new Map<String, Integer>{ 'TAMP' => 5, 'PREF' => 9, 'ALCA' => 5 }, s);
        System.assertEquals(3, r.size());
        System.assertEquals('PREF', r[0].itemKey, 'maior percentual primeiro');
        System.assertEquals('ALCA', r[1].itemKey, 'empate pela chave');
        System.assertEquals('TAMP', r[2].itemKey);
    }

    @IsTest
    static void crossSellByFamilySkipsRecentAndHonorsCap() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        s.crossSellMaxPerAccount = 2;
        Map<String, List<CommercialSignalService.Candidate>> q = new Map<String, List<CommercialSignalService.Candidate>>();
        q.put('Alimentos', new List<CommercialSignalService.Candidate>{
            candidate('PREF', 49), candidate('TAMP', 48), candidate('ALCA', 47), candidate('GPET', 46) });
        CommercialSignalService.AccountFacts f = facts(TODAY.addDays(-5), 'Alimentos');
        f.recentItems.add('PREF');
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(f, TODAY, s, q);
        System.assertEquals(2, out.size(), 'teto de 2 por conta');
        System.assertEquals('TAMP', out[0].ProductFamily__c, 'CA-09: familia recente fica de fora');
        System.assertEquals('ALCA', out[1].ProductFamily__c);
        System.assertEquals(null, out[0].Product__c, 'sugere familia, nao item');
        System.assertEquals('Cruzada', out[0].Type__c);
        System.assertEquals(48.0, out[0].VariationPercent__c);
        System.assert(out[0].SignalKey__c.endsWith('-Cruzada-TAMP'));
        System.assert(out[0].Reason__c.contains('Alimentos'), 'motivo cita o segmento');
        // CA-10: sem segmento nao ha cruzada
        System.assertEquals(0, CommercialSignalService.buildSignals(facts(TODAY.addDays(-5), null), TODAY, s, q).size());
        System.assertEquals(0, CommercialSignalService.buildSignals(facts(TODAY.addDays(-5), 'Outro'), TODAY, s, q).size());
    }

    @IsTest
    static void crossSellByProductFillsProductField() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        s.crossSellLevel = 'Produto';
        Id p1 = '01t000000000001AAA';
        CommercialSignalService.Candidate c = candidate(String.valueOf(p1), 40);
        c.productId = p1;
        CommercialSignalService.AccountFacts f = facts(TODAY.addDays(-5), 'Bebidas');
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(
            f, TODAY, s, new Map<String, List<CommercialSignalService.Candidate>>{ 'Bebidas' => new List<CommercialSignalService.Candidate>{ c } });
        System.assertEquals(1, out.size());
        System.assertEquals(p1, out[0].Product__c);
        System.assertEquals(null, out[0].ProductFamily__c);
        System.assert(out[0].SignalKey__c.endsWith('-Cruzada-' + String.valueOf(p1)));
    }

    @IsTest
    static void groupWithoutSectorStillGetsRecovery() {
        List<CommercialSignal__c> out = CommercialSignalService.buildSignals(
            facts(TODAY.addDays(-91), null), TODAY, new CommercialSignalService.Settings(),
            new Map<String, List<CommercialSignalService.Candidate>>());
        System.assertEquals(1, out.size(), 'CA-10');
        System.assertEquals('Recuperacao', out[0].Type__c);
    }

    @IsTest
    static void helpers() {
        System.assertEquals(null, CommercialSignalService.groupKey(null));
        System.assertEquals(null, CommercialSignalService.groupKey('   '));
        System.assertEquals('Alimentos', CommercialSignalService.groupKey(' Alimentos '));
        System.assertEquals('Sem familia', CommercialSignalService.familyKey(null));
        System.assertEquals('PREF', CommercialSignalService.familyKey('PREF'));
        System.assertEquals(2, CommercialSignalService.splitList('Faturamento; Concluido;;').size());
        System.assertEquals(0, CommercialSignalService.splitList(null).size());
        System.assertEquals('Sector__c', CommercialSignalService.resolveGroupField('CampoQueNaoExiste__c'));
        System.assertEquals('Sector__c', CommercialSignalService.resolveGroupField(null));
        System.assertEquals('Type', CommercialSignalService.resolveGroupField('type'));
        System.assertEquals('001000000000001AAA-Cruzada-', CommercialSignalService.signalKey('001000000000001AAA', 'Cruzada', null));
        System.assertEquals('001000000000001AAA-Cruzada-PREF', CommercialSignalService.signalKey('001000000000001AAA', 'Cruzada', 'PREF'));
        System.assertEquals(60, CommercialSignalService.signalKey('001000000000001AAA', 'Cruzada', 'X'.repeat(100)).substringAfterLast('-Cruzada-').length(),
            'sufixo da chave limitado a 60');
    }

    @IsTest
    static void dateWindowsAreFullMonths() {
        System.assertEquals(Date.newInstance(2026, 10, 1), CommercialSignalService.currentMonthStart(TODAY), 'ultimo mes fechado comeca em 1/out');
        System.assertEquals(Date.newInstance(2026, 11, 1), CommercialSignalService.currentMonthEnd(TODAY), 'e termina antes de 1/nov');
        System.assertEquals(Date.newInstance(2026, 7, 1), CommercialSignalService.baseStart(TODAY, 3), 'base: jul, ago e set');
        System.assertEquals(Date.newInstance(2025, 12, 1), CommercialSignalService.currentMonthStart(Date.newInstance(2026, 1, 20)), 'virada de ano');
        System.assertEquals('2026-10', CommercialSignalService.monthKey(2026, 10));
    }

    @IsTest
    static void boundAndAsDateHandleDateAndDatetimeFields() {
        System.assertEquals(true, CommercialSignalService.bound(TODAY, 'EffectiveDate') instanceof Date);
        System.assertEquals(true, CommercialSignalService.bound(TODAY, 'ActivatedDate') instanceof Datetime);
        System.assertEquals(true, CommercialSignalService.isDateTimeField('ActivatedDate'));
        System.assertEquals(false, CommercialSignalService.isDateTimeField('IssuanceDate__c'));
        System.assertEquals(TODAY, CommercialSignalService.asDate(TODAY));
        System.assertEquals(TODAY, CommercialSignalService.asDate(Datetime.newInstance(2026, 11, 17, 10, 0, 0)));
        System.assertEquals(null, CommercialSignalService.asDate(null));
        System.assertEquals(TODAY, CommercialSignalService.asDate(CommercialSignalService.bound(TODAY, 'ActivatedDate')), 'ida e volta sem deslocar o dia');
    }

    @IsTest
    static void itemExpressionFollowsLevelAndFamilyField() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        System.assertEquals('Product2.Group__c', CommercialSignalService.itemExpression(s));
        s.familyField = 'Family';
        System.assertEquals('Product2.Family', CommercialSignalService.itemExpression(s));
        s.crossSellLevel = 'Produto';
        System.assertEquals('Product2Id', CommercialSignalService.itemExpression(s));
    }

    @IsTest
    static void pickAcceptsOnlyAllowedValues() {
        List<String> warnings = new List<String>();
        List<String> allowed = CommercialSignalService.ALLOWED_DATE_FIELDS;
        System.assertEquals('IssuanceDate__c', CommercialSignalService.pick(' issuancedate__c ', allowed, 'EffectiveDate', 'P', warnings), 'grafia canonica');
        System.assertEquals(0, warnings.size());
        System.assertEquals('EffectiveDate', CommercialSignalService.pick(null, allowed, 'EffectiveDate', 'P', warnings), 'vazio: padrao em silencio');
        System.assertEquals(0, warnings.size());
        System.assertEquals('EffectiveDate', CommercialSignalService.pick('Name FROM User--', allowed, 'EffectiveDate', 'PurchaseDateField__c', warnings),
            'texto fora da lista nunca vira SOQL');
        System.assertEquals(1, warnings.size());
        System.assert(warnings[0].contains('PurchaseDateField__c'));
        System.assertEquals('Group__c', CommercialSignalService.pick('X', CommercialSignalService.ALLOWED_FAMILY_FIELDS, 'Group__c', 'F', null));
    }

    @IsTest
    static void invalidCmdtValuesFallBackAndWarn() {
        CommercialSignalSetting__mdt m = new CommercialSignalSetting__mdt(
            PurchaseDateField__c = 'Name', FamilyField__c = 'Description', VolumeMetric__c = 'Lucro',
            CrossSellLevel__c = 'Marca', VolumeWindowMonths__c = 3, VolumeMinBaseMonths__c = 9,
            CrossSellExcludedFamilies__c = 'RESI; gpet', IncludeNeverPurchased__c = true);
        CommercialSignalService.Settings s = CommercialSignalService.fromRecord(m);
        System.assertEquals('EffectiveDate', s.purchaseDateField);
        System.assertEquals('Group__c', s.familyField);
        System.assertEquals('Valor', s.volumeMetric);
        System.assertEquals('Familia', s.crossSellLevel);
        System.assertEquals(4, s.warnings.size(), 'um aviso por valor recusado');
        System.assertEquals(3, s.volumeMinBaseMonths, 'minimo limitado ao total de meses da base');
        System.assertEquals(new Set<String>{ 'resi', 'gpet' }, s.crossSellExcludedFamilies);
        System.assertEquals(0, CommercialSignalService.fromRecord(null).warnings.size(), 'sem registro: padrao');
        m = new CommercialSignalSetting__mdt(VolumeMinBaseMonths__c = 0, VolumeWindowMonths__c = 3,
            PurchaseDateField__c = 'ActivatedDate', FamilyField__c = 'Family', VolumeMetric__c = 'valorouquantidade',
            CrossSellLevel__c = 'produto', VolumeDirections__c = 'Queda;Alta', IncludeNeverPurchased__c = false);
        s = CommercialSignalService.fromRecord(m);
        System.assertEquals(1, s.volumeMinBaseMonths, 'minimo de 1');
        System.assertEquals('ActivatedDate', s.purchaseDateField);
        System.assertEquals('Family', s.familyField);
        System.assertEquals('ValorOuQuantidade', s.volumeMetric);
        System.assertEquals('Produto', s.crossSellLevel);
        System.assertEquals(true, s.directionRise);
        System.assertEquals(false, s.includeNeverPurchased);
        System.assertEquals(0, s.warnings.size());
    }

    @IsTest
    static void loadSettingsMatchesDeployedDefault() {
        CommercialSignalService.Settings s = CommercialSignalService.loadSettings();
        System.assertEquals(90, s.recoveryDays);
        System.assertEquals(new List<String>{ 'Faturamento', 'Concluido' }, s.purchaseStatuses);
        System.assertEquals(3, s.volumeWindowMonths);
        System.assertEquals(2, s.volumeMinBaseMonths);
        System.assertEquals(20, s.volumeThresholdPercent);
        System.assertEquals(true, s.directionDrop);
        System.assertEquals(false, s.directionRise);
        System.assertEquals('Valor', s.volumeMetric);
        System.assertEquals('EffectiveDate', s.purchaseDateField);
        System.assertEquals('Group__c', s.familyField);
        System.assertEquals('Sector__c', s.crossSellGroupField);
        System.assertEquals('Familia', s.crossSellLevel);
        System.assertEquals(0, s.crossSellExcludedFamilies.size());
        System.assertEquals(12, s.crossSellLookbackMonths);
        System.assertEquals(180, s.crossSellRecentDays);
        System.assertEquals(30, s.crossSellMinSharePercent);
        System.assertEquals(5, s.crossSellMinGroupSize);
        System.assertEquals(10, s.crossSellMaxPerAccount);
        System.assertEquals(100, s.batchSize);
        System.assertEquals(true, s.includeNeverPurchased);
        System.assertEquals(0, s.warnings.size());
    }

    @IsTest
    static void bulkTwoHundredAccounts() {
        CommercialSignalService.Settings s = new CommercialSignalService.Settings();
        List<CommercialSignal__c> all = new List<CommercialSignal__c>();
        for (Integer i = 0; i < 200; i++) {
            CommercialSignalService.AccountFacts f = facts(i < 100 ? TODAY.addDays(-91) : null, null);
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
