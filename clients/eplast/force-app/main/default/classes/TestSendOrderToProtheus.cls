@isTest
public with sharing class TestSendOrderToProtheus {
    @TestSetup
    static void makeData(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = SendOrderToProtheusTDF.createAccount();
        SendOrderToProtheusTDF.createTestPricebook(acc);
    }

    @isTest
    public static void testChangeOrderStatus(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);

        Test.startTest();
            order.Status = 'Liberacao Financeiro';
            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c FROM Order WHERE Id = :order.Id ];

        Assert.areEqual('002622', updatedOrder.ExternalNumber__c);
    }

    @isTest
    public static void testNormalQuote(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        Opportunity opp = SendOrderToProtheusTDF.createNormalQuoteOpportunity(acc, pricebook);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        opp.SyncedQuoteId = quote.Id;

        update opp;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, quote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Id oldDispatchBranch = order.DispatchBranch__c;

        Test.startTest();
            order.DispatchBranch__c = SendOrderToProtheusTDF.createBranch().Id;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, DispatchBranch__c FROM Order WHERE Id = :order.Id ];

        Assert.areNotEqual(oldDispatchBranch, updatedOrder.DispatchBranch__c);
    }

    @isTest
    public static void testChangeOrderDispatchBranch(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Id oldDispatchBranch = order.DispatchBranch__c;

        Test.startTest();
            order.DispatchBranch__c = SendOrderToProtheusTDF.createBranch().Id;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, DispatchBranch__c FROM Order WHERE Id = :order.Id ];

        Assert.areNotEqual(oldDispatchBranch, updatedOrder.DispatchBranch__c);
    }

    @isTest
    public static void testChangeOrderExpectedSaleDate(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpectedSaleDate = order.ExpectedSaleDate__c;

        Test.startTest();
            order.ExpectedSaleDate__c = Date.today().addDays(1);

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, ExpectedSaleDate__c FROM Order WHERE Id = :order.Id ];

        Assert.areNotEqual(oldExpectedSaleDate, updatedOrder.ExpectedSaleDate__c);
    }

    @isTest
    public static void testChangeOrderDeliveryDate(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldDeliveryDate = order.DeliveryDate__c;

        Test.startTest();
            order.DeliveryDate__c = Date.today().addDays(1);

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, DeliveryDate__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldDeliveryDate, updatedOrder.DeliveryDate__c);
    }

    @isTest
    public static void testChangeOrderShippingCompany(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Id oldShippingCompany = order.ShippingCompany__c;

        Test.startTest();
            order.ShippingCompany__c = SendOrderToProtheusTDF.createShippingCompany().Id;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, ShippingCompany__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldShippingCompany, updatedOrder.ShippingCompany__c);
    }

    @isTest
    public static void testChangeOrderTypeShipping(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        String oldTypeShipping = order.TypeShipping__c;

        Test.startTest();
            order.TypeShipping__c = 'F';

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, TypeShipping__c FROM Order WHERE Id = :order.Id ];

        Assert.areNotEqual(oldTypeShipping, updatedOrder.TypeShipping__c);
    }

    @isTest
    public static void testChangeOrderInternalObservation(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        String oldInternalObservation = order.InternalObservation__c;

        Test.startTest();
            order.InternalObservation__c = 'Another value';

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, InternalObservation__c FROM Order WHERE Id = :order.Id ];

        Assert.areNotEqual(oldInternalObservation, updatedOrder.InternalObservation__c);
    }

    @isTest
    public static void testChangeOrderMessageNote(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        String oldMessageNote = order.MessageNote__c;

        Test.startTest();
            order.MessageNote__c = 'Another value';

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, MessageNote__c FROM Order WHERE Id = :order.Id ];

        Assert.areNotEqual(oldMessageNote, updatedOrder.MessageNote__c);
    }

    @isTest
    public static void testChangeOrderVolume1(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        String oldVolume1 = order.Volume1__c;

        Test.startTest();
            order.Volume1__c = 'Another value';

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Volume1__c FROM Order WHERE Id = :order.Id ];

        Assert.areNotEqual(oldVolume1, updatedOrder.Volume1__c);
    }

    @isTest
    public static void testChangeOrderSpecies1(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        String oldSpecies1 = order.Species1__c;

        Test.startTest();
            order.Species1__c = 'Another value';

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Species1__c FROM Order WHERE Id = :order.Id ];

        Assert.areNotEqual(oldSpecies1, updatedOrder.Species1__c);
    }

    @isTest
    public static void testChangeOrderTypeOperation(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Id oldTypeOperation = order.TypeOperation__c;

        Test.startTest();
            order.TypeOperation__c = SendOrderToProtheusTDF.createTypeOperation().Id;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, TypeOperation__c FROM Order WHERE Id = :order.Id ];


        Assert.areNotEqual(oldTypeOperation, updatedOrder.TypeOperation__c);
    }

    @isTest
    public static void testChangeOrderParcel1(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;
        
        Double oldParcel1 = order.Parcel1__c;

        Test.startTest();

            order.Parcel1__c = 99.0;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Parcel1__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldParcel1, updatedOrder.Parcel1__c);
    }

    @isTest
    public static void testChangeOrderParcel2(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Double oldParcel2 = order.Parcel2__c;

        Test.startTest();
            order.Parcel2__c = 99.0;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Parcel2__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldParcel2, updatedOrder.Parcel2__c);
    }

    @isTest
    public static void testChangeOrderParcel3(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Double oldParcel3 = order.Parcel3__c;

        Test.startTest();
            order.Parcel3__c = 99.0;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Parcel3__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldParcel3, updatedOrder.Parcel3__c);
    }

    @isTest
    public static void testChangeOrderParcel4(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Double oldParcel4 = order.Parcel4__c;

        Test.startTest();
            order.Parcel4__c = 99.0;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Parcel4__c FROM Order WHERE Id = :order.Id ];

        Assert.areNotEqual(oldParcel4, updatedOrder.Parcel4__c);
    }

    @isTest
    public static void testChangeOrderParcel5(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Double oldParcel5 = order.Parcel5__c;

        Test.startTest();
            order.Parcel5__c = 99.0;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Parcel5__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldParcel5, updatedOrder.Parcel5__c);
    }

    @isTest
    public static void testChangeOrderParcel6(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Double oldParcel6 = order.Parcel6__c;

        Test.startTest();
            order.Parcel6__c = 99.0;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Parcel6__c FROM Order WHERE Id = :order.Id ];

        Assert.areNotEqual(oldParcel6, updatedOrder.Parcel6__c);
    }

    @isTest
    public static void testChangeOrderParcel7(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Double oldParcel7 = order.Parcel7__c;

        Test.startTest();
            order.Parcel7__c = 99.0;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Parcel7__c FROM Order WHERE Id = :order.Id ];

        Assert.areNotEqual(oldParcel7, updatedOrder.Parcel7__c);
    }

    @isTest
    public static void testChangeOrderParcel8(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Double oldParcel8 = order.Parcel8__c;

        Test.startTest();
            order.Parcel8__c = 99.0;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Parcel8__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldParcel8, updatedOrder.Parcel8__c);
    }

    @isTest
    public static void testChangeOrderParcel9(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Double oldParcel9 = order.Parcel9__c;

        Test.startTest();
            order.Parcel9__c = 99.0;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Parcel9__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldParcel9, updatedOrder.Parcel9__c);
    }

    @isTest
    public static void testChangeOrderParcel10(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Double oldParcel10 = order.Parcel10__c;

        Test.startTest();
            order.Parcel10__c = 99.0;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Parcel10__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldParcel10, updatedOrder.Parcel10__c);
    }

    @isTest
    public static void testChangeOrderParcel11(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Double oldParcel11 = order.Parcel11__c;

        Test.startTest();
            order.Parcel11__c = 99.0;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Parcel11__c FROM Order WHERE Id = :order.Id ];

        Assert.areNotEqual(oldParcel11, updatedOrder.Parcel11__c);
    }

    @isTest
    public static void testChangeOrderParcel12(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Double oldParcel12 = order.Parcel12__c;

        Test.startTest();
            order.Parcel12__c = 99.0;

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Parcel12__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldParcel12, updatedOrder.Parcel12__c);
    }

    @isTest
    public static void testChangeOrderExpiration1(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpiration1 = order.Expiration1__c;

        Test.startTest();
            order.Expiration1__c = Date.today();

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Expiration1__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldExpiration1, updatedOrder.Expiration1__c);
    }

    @isTest
    public static void testChangeOrderExpiration2(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpiration2 = order.Expiration2__c;

        Test.startTest();
            order.Expiration2__c = Date.today();

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Expiration2__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldExpiration2, updatedOrder.Expiration2__c);
    }

    @isTest
    public static void testChangeOrderExpiration3(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpiration3 = order.Expiration3__c;

        Test.startTest();
            order.Expiration3__c = Date.today();

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Expiration3__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldExpiration3, updatedOrder.Expiration3__c);
    }

    @isTest
    public static void testChangeOrderExpiration4(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpiration4 = order.Expiration4__c;

        Test.startTest();
            order.Expiration4__c = Date.today();

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Expiration4__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldExpiration4, updatedOrder.Expiration4__c);
    }

    @isTest
    public static void testChangeOrderExpiration5(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpiration5 = order.Expiration5__c;

        Test.startTest();
            order.Expiration5__c = Date.today();

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Expiration5__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldExpiration5, updatedOrder.Expiration5__c);
    }

    @isTest
    public static void testChangeOrderExpiration6(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpiration6 = order.Expiration6__c;

        Test.startTest();
            order.Expiration6__c = Date.today();

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Expiration6__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldExpiration6, updatedOrder.Expiration6__c);
    }

    @isTest
    public static void testChangeOrderExpiration7(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpiration7 = order.Expiration7__c;

        Test.startTest();
            order.Expiration7__c = Date.today();

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Expiration7__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldExpiration7, updatedOrder.Expiration7__c);
    }

    @isTest
    public static void testChangeOrderExpiration8(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpiration8 = order.Expiration8__c;

        Test.startTest();
            order.Expiration8__c = Date.today();

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Expiration8__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldExpiration8, updatedOrder.Expiration8__c);
    }

    @isTest
    public static void testChangeOrderExpiration9(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpiration9 = order.Expiration9__c;

        Test.startTest();
            order.Expiration9__c = Date.today();

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Expiration9__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldExpiration9, updatedOrder.Expiration9__c);
    }

    @isTest
    public static void testChangeOrderExpiration10(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpiration10 = order.Expiration10__c;

        Test.startTest();
            order.Expiration10__c = Date.today();

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Expiration10__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldExpiration10, updatedOrder.Expiration10__c);
    }

    @isTest
    public static void testChangeOrderExpiration11(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpiration11 = order.Expiration11__c;

        Test.startTest();
            order.Expiration11__c = Date.today();

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Expiration11__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldExpiration11, updatedOrder.Expiration11__c);
    }

    @isTest
    public static void testChangeOrderExpiration12(){
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse());
        Account acc = [ SELECT Id from Account ];
        Pricebook2 pricebook = [ SELECT id FROM Pricebook2 WHERE Account__c = :acc.Id ];
        SBQQ__Quote__c cpqQuote = SendOrderToProtheusTDF.createCPQQuote();
        Opportunity opp = SendOrderToProtheusTDF.createOpportunity(acc, pricebook, cpqQuote);
        Quote quote = SendOrderToProtheusTDF.createNormalQuote(opp);

        cpqQuote.SBQQ__Opportunity2__c = quote.OpportunityId;
        cpqQuote.Quote__c = quote.Id;

        update cpqQuote;
        
        Order order = SendOrderToProtheusTDF.setupOrder(acc, opp, pricebook, cpqQuote);
        order.Status = 'Liberacao Financeiro';
        update order;

        Date oldExpiration12 = order.Expiration12__c;

        Test.startTest();
            order.Expiration12__c = Date.today();

            update order;
        Test.stopTest();

        Order updatedOrder = [ SELECT Id, ExternalNumber__c, Expiration12__c FROM Order WHERE Id = :order.Id ];
    
        Assert.areNotEqual(oldExpiration12, updatedOrder.Expiration12__c);
    }
}