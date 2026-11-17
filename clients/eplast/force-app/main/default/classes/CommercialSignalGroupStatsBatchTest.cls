@IsTest
private class CommercialSignalGroupStatsBatchTest {

    @TestSetup
    static void grantAccess() {
        CommercialSignalTestFactory.grantSignalAccess();
    }

    private static final String GROUP_A = 'Alimentos';
    private static final Date TODAY = Date.newInstance(2026, 11, 17);

    /** Segmento de `size` contas; as primeiras `buyers` compraram um produto da familia PREF ha 30 dias. */
    private static Product2 groupWithBuyers(String sector, Integer size, Integer buyers) {
        List<Account> accounts = CommercialSignalTestFactory.createAccounts(size, sector, 'GS ' + sector);
        Product2 p = CommercialSignalTestFactory.createProducts(1, 'PREF', 'UN')[0];
        List<CommercialSignalTestFactory.OrderSpec> specs = new List<CommercialSignalTestFactory.OrderSpec>();
        for (Integer i = 0; i < buyers; i++) {
            specs.add(new CommercialSignalTestFactory.OrderSpec(accounts[i].Id, 'Faturamento', TODAY.addDays(-30), 100, p.Id));
        }
        if (!specs.isEmpty()) {
            CommercialSignalTestFactory.createOrders(specs);
        }
        return p;
    }

    private static CommercialSignalGroupStatsBatch batch(CommercialSignalService.Settings s, Boolean chain) {
        return new CommercialSignalGroupStatsBatch(s, TODAY, chain);
    }

    @IsTest
    static void qualifiesFamilyBoughtBy40PercentOfSegment() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        groupWithBuyers(GROUP_A, 10, 4);
        CommercialSignalGroupStatsBatch b = batch(CommercialSignalTestFactory.settings(), false);
        b.collect([SELECT Id, Sector__c FROM Account WHERE Sector__c = :GROUP_A]);
        System.assertEquals(10, b.groupSizes.get(GROUP_A), 'tamanho do segmento');
        System.assertEquals(4, b.buyersByGroup.get(GROUP_A).get('PREF'), 'compradores da familia');
        Map<String, List<CommercialSignalService.Candidate>> q = b.qualify();
        System.assertEquals(1, q.get(GROUP_A).size(), 'CA-08: 40% passa');
        System.assertEquals('PREF', q.get(GROUP_A)[0].itemKey);
        System.assertEquals(40.0, q.get(GROUP_A)[0].sharePercent);
        }
    }

    @IsTest
    static void qualifiesProductWhenLevelIsProduto() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Product2 p = groupWithBuyers(GROUP_A, 10, 4);
        CommercialSignalService.Settings s = CommercialSignalTestFactory.settings();
        s.crossSellLevel = 'Produto';
        CommercialSignalGroupStatsBatch b = batch(s, false);
        b.collect([SELECT Id, Sector__c FROM Account WHERE Sector__c = :GROUP_A]);
        System.assertEquals(4, b.buyersByGroup.get(GROUP_A).get(String.valueOf(p.Id)), 'compradores do produto');
        System.assertEquals(p.Id, b.qualify().get(GROUP_A)[0].productId);
        }
    }

    @IsTest
    static void excludedFamilyDoesNotQualify() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        groupWithBuyers(GROUP_A, 10, 4);
        CommercialSignalService.Settings s = CommercialSignalTestFactory.settings();
        s.crossSellExcludedFamilies.add('pref');
        CommercialSignalGroupStatsBatch b = batch(s, false);
        b.collect([SELECT Id, Sector__c FROM Account WHERE Sector__c = :GROUP_A]);
        System.assertEquals(0, b.qualify().size(), 'familia excluida por parametro');
        }
    }

    @IsTest
    static void doesNotQualifyWhenOnly20PercentBought() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        groupWithBuyers(GROUP_A, 10, 2);
        CommercialSignalGroupStatsBatch b = batch(CommercialSignalTestFactory.settings(), false);
        b.collect([SELECT Id, Sector__c FROM Account WHERE Sector__c = :GROUP_A]);
        System.assertEquals(0, b.qualify().size(), 'CA-08: 2 de 10 nao gera');
        }
    }

    @IsTest
    static void smallSegmentDoesNotQualify() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        groupWithBuyers(GROUP_A, 4, 4);
        CommercialSignalGroupStatsBatch b = batch(CommercialSignalTestFactory.settings(), false);
        b.collect([SELECT Id, Sector__c FROM Account WHERE Sector__c = :GROUP_A]);
        System.assertEquals(0, b.qualify().size(), 'CA-11: segmento de 4');
        }
    }

    @IsTest
    static void ignoresCanceledOldAndDraftOrders() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        List<Account> accounts = CommercialSignalTestFactory.createAccounts(5, GROUP_A, 'GS old');
        Product2 p = CommercialSignalTestFactory.createProducts(1, 'PREF', 'UN')[0];
        List<CommercialSignalTestFactory.OrderSpec> specs = new List<CommercialSignalTestFactory.OrderSpec>();
        specs.add(new CommercialSignalTestFactory.OrderSpec(accounts[0].Id, 'Cancelado', TODAY.addDays(-5), 100, p.Id));
        specs.add(new CommercialSignalTestFactory.OrderSpec(accounts[1].Id, 'Faturamento', TODAY.addMonths(-13), 100, p.Id));
        specs.add(new CommercialSignalTestFactory.OrderSpec(accounts[2].Id, 'Revisao de Pedido', TODAY.addDays(-3), 100, p.Id));
        CommercialSignalTestFactory.createOrders(specs);
        CommercialSignalGroupStatsBatch b = batch(CommercialSignalTestFactory.settings(), false);
        b.collect([SELECT Id, Sector__c FROM Account WHERE Sector__c = :GROUP_A]);
        System.assertEquals(5, b.groupSizes.get(GROUP_A));
        System.assertEquals(false, b.buyersByGroup.containsKey(GROUP_A), 'nenhuma compra valida na janela');
        }
    }

    @IsTest
    static void productWithoutFamilyIsNeverCounted() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        List<Account> accounts = CommercialSignalTestFactory.createAccounts(5, GROUP_A, 'GS nf');
        Product2 p = CommercialSignalTestFactory.createProducts(1)[0];
        CommercialSignalTestFactory.createOrders(new List<CommercialSignalTestFactory.OrderSpec>{
            new CommercialSignalTestFactory.OrderSpec(accounts[0].Id, 'Faturamento', TODAY.addDays(-5), 100, p.Id) });
        CommercialSignalGroupStatsBatch b = batch(CommercialSignalTestFactory.settings(), false);
        b.collect([SELECT Id, Sector__c FROM Account WHERE Sector__c = :GROUP_A]);
        System.assertEquals(false, b.buyersByGroup.containsKey(GROUP_A), 'produto sem grupo nao vira sugestao');
        }
    }

    @IsTest
    static void accountsWithoutSectorAreIgnored() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        CommercialSignalTestFactory.createAccounts(3, null, 'GS none');
        CommercialSignalGroupStatsBatch b = batch(CommercialSignalTestFactory.settings(), false);
        b.collect([SELECT Id, Sector__c FROM Account]);
        System.assertEquals(0, b.groupSizes.size(), 'CA-10: sem Sector__c nao entra');
        System.assertEquals(0, b.qualify().size());
        }
    }

    @IsTest
    static void invalidGroupFieldFallsBackToSector() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        CommercialSignalService.Settings s = CommercialSignalTestFactory.settings();
        s.crossSellGroupField = 'Inexistente__c';
        CommercialSignalGroupStatsBatch b = batch(s, false);
        CommercialSignalTestFactory.createAccounts(2, GROUP_A, 'GS fb');
        b.collect([SELECT Id, Sector__c FROM Account]);
        System.assertEquals(2, b.groupSizes.get(GROUP_A));
        }
    }

    @IsTest
    static void endToEndChainsPhaseTwoAndWritesFamilyCrossSell() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        groupWithBuyers(GROUP_A, 10, 4);
        Id target = [SELECT Id FROM Account WHERE Sector__c = :GROUP_A AND Name = 'GS Alimentos 9'].Id;
        Test.startTest();
        Database.executeBatch(batch(CommercialSignalTestFactory.settings(), true), 200);
        Test.stopTest();
        List<CommercialSignal__c> cross = CommercialSignalTestFactory.signals(target, 'Cruzada');
        System.assertEquals(1, cross.size(), 'fase 2 encadeada gravou a cruzada');
        System.assertEquals('PREF', cross[0].ProductFamily__c);
        System.assertEquals(null, cross[0].Product__c);
        System.assertEquals(40.0, cross[0].VariationPercent__c);
        // quem comprou ha 30 dias nao recebe cruzada para a familia (CA-09)
        Id buyer = [SELECT Id FROM Account WHERE Sector__c = :GROUP_A AND Name = 'GS Alimentos 0'].Id;
        System.assertEquals(0, CommercialSignalTestFactory.signals(buyer, 'Cruzada').size());
        }
    }

    @IsTest
    static void bulkTwoHundredAccountsInOneScope() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        List<Account> accounts = CommercialSignalTestFactory.createAccounts(200, GROUP_A, 'GS bulk');
        CommercialSignalGroupStatsBatch b = batch(CommercialSignalTestFactory.settings(), false);
        b.collect(accounts);
        System.assertEquals(200, b.groupSizes.get(GROUP_A));
        }
    }
}
