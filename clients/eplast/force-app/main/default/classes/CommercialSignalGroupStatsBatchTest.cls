@IsTest
private class CommercialSignalGroupStatsBatchTest {

    private static final String GROUP_A = 'Embalagens';

    /** Grupo de 10 contas; as primeiras `buyers` compraram o produto P ha 30 dias. */
    private static Product2 groupWithBuyers(String industry, Integer size, Integer buyers) {
        List<Account> accounts = CommercialSignalTestFactory.createAccounts(size, industry, 'GS ' + industry);
        Product2 p = CommercialSignalTestFactory.createProducts(1)[0];
        List<CommercialSignalTestFactory.OrderSpec> specs = new List<CommercialSignalTestFactory.OrderSpec>();
        for (Integer i = 0; i < buyers; i++) {
            specs.add(new CommercialSignalTestFactory.OrderSpec(accounts[i].Id, 'Faturamento', Date.today().addDays(-30), 100, p.Id));
        }
        if (!specs.isEmpty()) {
            CommercialSignalTestFactory.createOrders(specs);
        }
        return p;
    }

    @IsTest
    static void qualifiesProductBoughtBy40PercentOfGroup() {
        Product2 p = groupWithBuyers(GROUP_A, 10, 4);
        CommercialSignalGroupStatsBatch b = new CommercialSignalGroupStatsBatch(
            CommercialSignalTestFactory.settings(), Date.today(), false);
        b.collect([SELECT Id, Industry FROM Account WHERE Industry = :GROUP_A]);
        System.assertEquals(10, b.groupSizes.get(GROUP_A), 'tamanho do grupo');
        System.assertEquals(4, b.buyersByGroup.get(GROUP_A).get(p.Id), 'compradores do produto');
        Map<String, List<CommercialSignalService.Candidate>> q = b.qualify();
        System.assertEquals(1, q.get(GROUP_A).size(), 'CA-08: 40% passa');
        System.assertEquals(p.Id, q.get(GROUP_A)[0].productId);
        System.assertEquals(40.0, q.get(GROUP_A)[0].sharePercent);
    }

    @IsTest
    static void doesNotQualifyWhenOnly20PercentBought() {
        groupWithBuyers(GROUP_A, 10, 2);
        CommercialSignalGroupStatsBatch b = new CommercialSignalGroupStatsBatch(
            CommercialSignalTestFactory.settings(), Date.today(), false);
        b.collect([SELECT Id, Industry FROM Account WHERE Industry = :GROUP_A]);
        System.assertEquals(0, b.qualify().size(), 'CA-08: 2 de 10 nao gera');
    }

    @IsTest
    static void smallGroupDoesNotQualify() {
        groupWithBuyers(GROUP_A, 4, 4);
        CommercialSignalGroupStatsBatch b = new CommercialSignalGroupStatsBatch(
            CommercialSignalTestFactory.settings(), Date.today(), false);
        b.collect([SELECT Id, Industry FROM Account WHERE Industry = :GROUP_A]);
        System.assertEquals(0, b.qualify().size(), 'CA-11: grupo de 4');
    }

    @IsTest
    static void ignoresCanceledAndOldOrders() {
        List<Account> accounts = CommercialSignalTestFactory.createAccounts(5, GROUP_A, 'GS old');
        Product2 p = CommercialSignalTestFactory.createProducts(1)[0];
        List<CommercialSignalTestFactory.OrderSpec> specs = new List<CommercialSignalTestFactory.OrderSpec>();
        specs.add(new CommercialSignalTestFactory.OrderSpec(accounts[0].Id, 'Cancelado', Date.today().addDays(-5), 100, p.Id));
        specs.add(new CommercialSignalTestFactory.OrderSpec(accounts[1].Id, 'Faturamento', Date.today().addMonths(-13), 100, p.Id));
        specs.add(new CommercialSignalTestFactory.OrderSpec(accounts[2].Id, 'Revisao de Pedido', Date.today().addDays(-3), 100, p.Id));
        CommercialSignalTestFactory.createOrders(specs);
        CommercialSignalGroupStatsBatch b = new CommercialSignalGroupStatsBatch(
            CommercialSignalTestFactory.settings(), Date.today(), false);
        b.collect([SELECT Id, Industry FROM Account WHERE Industry = :GROUP_A]);
        System.assertEquals(5, b.groupSizes.get(GROUP_A));
        System.assertEquals(false, b.buyersByGroup.containsKey(GROUP_A), 'nenhuma compra valida na janela');
    }

    @IsTest
    static void accountsWithoutGroupAreIgnored() {
        CommercialSignalTestFactory.createAccounts(3, null, 'GS none');
        CommercialSignalGroupStatsBatch b = new CommercialSignalGroupStatsBatch(
            CommercialSignalTestFactory.settings(), Date.today(), false);
        b.collect([SELECT Id, Industry FROM Account]);
        System.assertEquals(0, b.groupSizes.size(), 'CA-10: sem Industry nao entra');
        System.assertEquals(0, b.qualify().size());
    }

    @IsTest
    static void invalidGroupFieldFallsBackToIndustry() {
        CommercialSignalService.Settings s = CommercialSignalTestFactory.settings();
        s.crossSellGroupField = 'Inexistente__c';
        CommercialSignalGroupStatsBatch b = new CommercialSignalGroupStatsBatch(s, Date.today(), false);
        CommercialSignalTestFactory.createAccounts(2, GROUP_A, 'GS fb');
        b.collect([SELECT Id, Industry FROM Account]);
        System.assertEquals(2, b.groupSizes.get(GROUP_A));
    }

    @IsTest
    static void endToEndChainsPhaseTwoAndWritesCrossSell() {
        Product2 p = groupWithBuyers(GROUP_A, 10, 4);
        Id target = [SELECT Id FROM Account WHERE Industry = :GROUP_A AND Name = 'GS Embalagens 9'].Id;
        Test.startTest();
        Database.executeBatch(new CommercialSignalGroupStatsBatch(), 200);
        Test.stopTest();
        List<CommercialSignal__c> cross = CommercialSignalTestFactory.signals(target, 'Cruzada');
        System.assertEquals(1, cross.size(), 'fase 2 encadeada gravou a cruzada');
        System.assertEquals(p.Id, cross[0].Product__c);
        System.assertEquals(40.0, cross[0].VariationPercent__c);
        // quem comprou ha 30 dias nao recebe cruzada para o produto (CA-09)
        Id buyer = [SELECT Id FROM Account WHERE Industry = :GROUP_A AND Name = 'GS Embalagens 0'].Id;
        System.assertEquals(0, CommercialSignalTestFactory.signals(buyer, 'Cruzada').size());
    }

    @IsTest
    static void bulkTwoHundredAccountsInOneScope() {
        List<Account> accounts = CommercialSignalTestFactory.createAccounts(200, GROUP_A, 'GS bulk');
        CommercialSignalGroupStatsBatch b = new CommercialSignalGroupStatsBatch(
            CommercialSignalTestFactory.settings(), Date.today(), false);
        b.collect(accounts);
        System.assertEquals(200, b.groupSizes.get(GROUP_A));
    }
}
