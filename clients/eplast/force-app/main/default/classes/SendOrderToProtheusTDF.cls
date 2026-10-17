@isTest
public with sharing class SendOrderToProtheusTDF {
    public static Order setupOrder(Account acc, Opportunity opp, Pricebook2 pricebook, SBQQ__Quote__c cpqQuote){
        // Create the following objects: Account, Product2, Pricebook2 (Custom), PricebookEntry (Custom), Opportunity, Quote, CPQ Quote

        Product2 product = createProduct();
        PricebookEntry testPricebookEntry;
        Quote quote = createNormalQuote(opp);

        // Create pricebook entries and CPQ Quote Line Item: product needs to have a standard pricebook entry before creating custom pricebook entries
        createStandardPricebookEntry(product);
        testPricebookEntry = createTestPricebookEntry(pricebook, product);
        createCpqQuoteLineItem(cpqQuote, product, testPricebookEntry);

        
        // Creating Order
        return createTestOrder(acc, opp, cpqQuote);
    }

    public static Order setupOrder(Account acc, Opportunity opp, Pricebook2 pricebook, Quote quote){
        // Create the following objects: Account, Product2, Pricebook2 (Custom), PricebookEntry (Custom), Opportunity, Quote, CPQ Quote

        Product2 product = createProduct();
        PricebookEntry testPricebookEntry;

        // Create pricebook entries and CPQ Quote Line Item: product needs to have a standard pricebook entry before creating custom pricebook entries
        createStandardPricebookEntry(product);
        testPricebookEntry = createTestPricebookEntry(pricebook, product);
        createNormalQuoteLineItem(quote, product, testPricebookEntry);

        
        // Creating Order
        return createTestOrder(acc, opp);
    }

    public static Account createAccount(){
        User owner = SendAccountToProtheusTDF.createOwner();

        Account acc = new Account(
            Name = 'Account Order Test',
            ProtheusId__c = '123456',
            //CompanyDocument__c = '29190753000199',
            CompanyName__c = 'Test Account',
            BillingCountry = 'Test Country',
            BillingCity = 'Test City',
            BillingState = 'Test State',
            BillingStreet = 'Test Street',
            BillingPostalCode = '00000000',
            BillingNeighborhood__c = 'Test Neighborhood',
            CNAE__c = '123456',
            Email__c = 'test@test.com',
            Phone = '(99) 12341234',
            Owner = owner
        );

        insert acc;

        acc.Store__c = '01';

        update acc;

        return acc;
    }

    public static void createAccountTeamMember(Account acc){
        User teamMember = new User(
            Username = 'Test',
            LastName = ' Team Member',
            Email = 'test@mail.com',
            Alias = 'test',
            TimeZoneSidKey = UserInfo.getTimezone().getId(),
            LocaleSidKey = UserInfo.getLocale(),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = UserInfo.getLanguage(),
            ProfileId = UserInfo.getProfileId(),
            ProtheusSellerId__c = '000002'
        );

        insert teamMember;

        insert new AccountTeamMember(
            AccountId = acc.Id,
            UserId = teamMember.Id
        );
    }

    public static ShippingCompany__c createShippingCompany(){
        ShippingCompany__c shippingCompany = new ShippingCompany__c(
            Name = 'Test Shipping Company',
            Code__c = '123456'
        );

        insert shippingCompany;

        return shippingCompany;
    }

    public static Account createDeliveryCustomer(){
        Account deliveryCustomer = createAccount();

        deliveryCustomer.Name = 'Test Delivery Customer';

        insert deliveryCustomer;

        return deliveryCustomer;
    }

    public static PaymentTerms__c createPaymentTerm(){
        PaymentTerms__c paymentTerm = new PaymentTerms__c(
            Name = 'Test Payment Term',
            ProtheusId__c = '123',
            Codigo__c = '123'
        );

        insert paymentTerm;

        return paymentTerm;
    }

    public static Branch__c createBranch(){
        Branch__c branch = new Branch__c(
            Name = 'Test Branch',
            CodeERP__c = '1234'
        );

        insert branch;

        return branch;
    }

    public static TypeOperation__c createTypeOperation(){
        TypeOperation__c operationType = new TypeOperation__c(
            Name = 'Test Operation Type',
            Code__c = '123456'
        );

        insert operationType;

        return operationType;
    }

    public static Opportunity createOpportunity(Account acc, Pricebook2 pricebook, SBQQ__Quote__c cpqQuote){
        Opportunity opp = new Opportunity(
            RecordTypeId = SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sale').getRecordTypeId(),
            AccountId = acc.Id,
            Pricebook2Id = pricebook.Id,
            SBQQ__PrimaryQuote__c = cpqQuote.Id,
            PaymentTermId__c = createPaymentTerm().Id,
            Name = 'Test Opportunity',
            StageName = 'Qualificado',
            CloseDate = Date.today(),
            Formas_de_Pagamento__c = 'BOL',
            Branch__c = createBranch().Id
        );

        insert opp;

        return opp;
    }

    public static Opportunity createNormalQuoteOpportunity(Account acc, Pricebook2 pricebook){
        Opportunity opp = new Opportunity(
            RecordTypeId = SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sale').getRecordTypeId(),
            AccountId = acc.Id,
            Pricebook2Id = pricebook.Id,
            // SyncedQuoteId = quote.Id,
            PaymentTermId__c = createPaymentTerm().Id,
            Name = 'Test Opportunity',
            StageName = 'Qualificado',
            CloseDate = Date.today(),
            Formas_de_Pagamento__c = 'BOL',
            Branch__c = createBranch().Id
        );

        insert opp;

        return opp;
    }

    public static Product2 createProduct(){
        Product2 product = new Product2(
            Name = 'Test Product', 
            ProductCode = 'PREF00000', 
            QuantityConverter__c = 27.648, 
            IsActive = true, 
            SBQQ__PriceEditable__c = true, 
            QuantityUnitOfMeasure = 'UN',
            SecondUnitOfMeasure__c = 'CX'
        );

        insert product;

        return product;
    }

    public static void createStandardPricebookEntry(Product2 product){
        insert new PricebookEntry(
            IsActive = true,
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 15.0
        );
    }

    public static Pricebook2 createTestPricebook(Account acc){
        Pricebook2 pricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true,
            Account__c = acc.Id
        );

        insert pricebook;

        return pricebook;
    }

    public static PricebookEntry createTestPricebookEntry(Pricebook2 pricebook, Product2 product){
        PricebookEntry testPricebookEntry = new PricebookEntry(
            IsActive = true,
            Pricebook2Id = pricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 1234.56
        );

        insert testPricebookEntry;

        return testPricebookEntry;
    }

    public static Opportunity createTestOpportunity(Account acc, Pricebook2 pricebook){
        Opportunity opp = new Opportunity(
            RecordTypeId = SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sale').getRecordTypeId(),
            Name = 'Test Opportunity',
            StageName = 'Qualificado',
            CloseDate = Date.today(),
            Formas_de_Pagamento__c = 'BOL',
            AccountId = acc.Id,
            Pricebook2Id = pricebook.Id
        );

        insert opp;

        return opp;
    }
    
    public static Quote createNormalQuote(Opportunity opp){
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id
        );

        insert quote;

        return quote;
    }

    public static void createNormalQuoteLineItem(Quote quote, Product2 product, PricebookEntry pricebookEntry){
        insert new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 82944.09,
            SecondUnitQuantity__c = 3.00,
            UnitPrice = 1234.56
        );
    }

    // public static SBQQ__Quote__c createCPQQuote(Quote quote){
    public static SBQQ__Quote__c createCPQQuote(){
        SBQQ__Quote__c cpqQuote = new SBQQ__Quote__c(
            SBQQ__Status__c =  'Approved',
            SBQQ__Primary__c = true,
            SBQQ__SalesRep__c = UserInfo.getUserId()
        );

        insert cpqQuote;

        return cpqQuote;
    }

    public static void createCpqQuoteLineItem(SBQQ__Quote__c cpqQuote, Product2 product, PricebookEntry testPricebookEntry){
        insert new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = cpqQuote.Id,
            SBQQ__Product__c = product.Id,
            SBQQ__PricebookEntryId__c = testPricebookEntry.Id,
            SBQQ__Quantity__c = 82944.09,
            SecondUnitQuantity__c = 3.00,
            SBQQ__NetPrice__c = 1234.56
        );
    }

    public static Order createTestOrder(Account acc, Opportunity opp, SBQQ__Quote__c cpqQuote){
        Order order = new Order(
            AccountId = acc.Id,
            OpportunityId = opp.Id,
            SBQQ__Quote__c = cpqQuote.Id,
            Status = 'Revisao de Pedido',
            DeliveryDate__c = Date.today(),
            EffectiveDate = Date.today(),
            ExpectedSaleDate__c = Date.today(),
            Species1__c = 'CX',
            TypeShipping__c = 'C',
            Volume1__c = '02',
            DispatchBranch__c = createBranch().Id,
            TypeOperation__c = createTypeOperation().Id,
            ShippingCompany__c = createShippingCompany().Id
        );

        insert order;

        return order;
    }

    public static Order createTestOrder(Account acc, Opportunity opp){
        Order order = new Order(
            AccountId = acc.Id,
            OpportunityId = opp.Id,
            Status = 'Revisao de Pedido',
            DeliveryDate__c = Date.today(),
            EffectiveDate = Date.today(),
            ExpectedSaleDate__c = Date.today(),
            Species1__c = 'CX',
            TypeShipping__c = 'C',
            Volume1__c = '02',
            DispatchBranch__c = createBranch().Id,
            TypeOperation__c = createTypeOperation().Id,
            ShippingCompany__c = createShippingCompany().Id
        );

        insert order;

        return order;
    }

    public static String getSuccessResponseBody(){
        return '{"Ret_Pedido" :{"PedidoERP":"002622","PedidoCRM":"00000156","STATUS":"OK","Mensagem":"Pedido gravado com sucesso!" }}';
    }
}