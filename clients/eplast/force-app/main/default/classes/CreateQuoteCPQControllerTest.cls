@isTest
public class CreateQuoteCPQControllerTest {
    
    @testSetup
    static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse(true));
        // Criação de uma conta
        Account a = SendOrderToProtheusTDF.createAccount();
        
		User owner = SendAccountToProtheusTDF.createOwner();
        // Criação de uma conta para BlowerCustomer
        Account blowerAccount =  new Account(
            Name = 'Account Blower',
            ProtheusId__c = '123457',
            CompanyDocument__c = '21890886000166',
            CompanyName__c = 'Test Blower',
            BillingCountry = 'Test Country',
            BillingCity = 'Blower Shipping City',
            BillingState = 'Test State',
            BillingStreet = 'Test Street',
            BillingPostalCode = '00000000',
            BillingNeighborhood__c = 'Test Neighborhood',
            CNAE__c = '123456',
            Email__c = 'testblower@mail.com',
            Phone = '(99) 12341244',
            Owner = owner
        );

        insert blowerAccount;
        blowerAccount.Store__c = '01';
        update blowerAccount;

        // Atualização da conta original para adicionar BlowerCustomer__c
        a.BlowerCustomer__c = blowerAccount.Id;
        update a;

        Pricebook2 pb2 = new Pricebook2(
            Name = 'Catálogo Teste',
            IsActive = true,
            Account__c = a.Id
        );
        insert pb2;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            Account__c = a.Id,
            IsActive = true
        );
        update standardPricebook;

        // Criação de uma oportunidade
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualificado',
            Pricebook2Id = standardPricebook.Id,
            CloseDate = Date.today(),
            AccountId = a.Id,
            RecordTypeId = SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sale').getRecordTypeId()
        );
        insert opp;

        // Criação de uma cotação
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id
        );
        insert quote;
    }

    @isTest
    static void testCreateQuoteCPQAsBlowerCustomer() {
        // Buscar dados de teste
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account account = [SELECT Id, BlowerCustomer__c FROM Account WHERE Id = :opp.AccountId LIMIT 1];
        Quote quote = [SELECT Id, OpportunityId, AccountId FROM Quote LIMIT 1];
        
        // Configurar a solicitação
        CreateQuoteCPQController.QuoteRequest request = new CreateQuoteCPQController.QuoteRequest();
        request.quoteId = quote.Id;
        request.clientType = 'isBlowerCustomer';

        List<CreateQuoteCPQController.QuoteRequest> requests = new List<CreateQuoteCPQController.QuoteRequest>();
        requests.add(request);

        Test.startTest();
        CreateQuoteCPQController.createQuoteCPQ(requests);
        Test.stopTest();

        // Verificar se a cotação CPQ foi criada corretamente
        List<SBQQ__Quote__c> quotesCPQ = [SELECT SBQQ__ShippingCity__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        Assert.istrue(quotesCPQ.size() >= 1);
        Assert.areNotEqual('Blower Shipping City', quotesCPQ[0].SBQQ__ShippingCity__c);
    }

    @isTest
    static void testCreateQuoteCPQAsCustomer() {
        // Buscar dados de teste
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account account = [SELECT Id, BlowerCustomer__c FROM Account WHERE Id = :opp.AccountId LIMIT 1];
        Quote quote = [SELECT Id, OpportunityId, AccountId FROM Quote LIMIT 1];

        // Configurar a solicitação
        CreateQuoteCPQController.QuoteRequest request = new CreateQuoteCPQController.QuoteRequest();
        request.quoteId = quote.Id;
        request.clientType = 'isCustomer';

        List<CreateQuoteCPQController.QuoteRequest> requests = new List<CreateQuoteCPQController.QuoteRequest>();
        requests.add(request);

        Test.startTest();
        CreateQuoteCPQController.createQuoteCPQ(requests);
        Test.stopTest();

        // Verificar se a cotação CPQ foi criada corretamente
        List<SBQQ__Quote__c> quotesCPQ = [SELECT SBQQ__ShippingCity__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        Assert.isTrue(quotesCPQ.size() >= 1);
        Assert.areNotEqual('Test City', quotesCPQ[0].SBQQ__ShippingCity__c);
    }
}