@isTest
public class CreateQuoteCPQControllerTest {
    
    @testSetup
    static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse(true));
        Account a = SendOrderToProtheusTDF.createAccount();

        User owner = SendAccountToProtheusTDF.createOwner();
        TriggerUtility.bypassTrigger = true;
        Account blowerAccount = SearchAccountInfoByCNPJTDF.aplicarEnderecoUnico(new Account(), 'P2LRBLOWER');
        blowerAccount.ProtheusId__c = '123457';
        blowerAccount.CompanyDocument__c = SearchAccountInfoByCNPJTDF.CNPJ_QUARTO;
        blowerAccount.BillingCity = 'Blower Shipping City';
        blowerAccount.CNAE__c = '6201501';
        blowerAccount.OwnerId = owner.Id;

        insert blowerAccount;
        blowerAccount.Store__c = '01';
        update blowerAccount;

        a.BlowerCustomer__c = blowerAccount.Id;
        update a;

        Pricebook2 pb2 = new Pricebook2(
            Name = 'TESTE EPLAST Apex Catalogo',
            IsActive = true,
            Account__c = a.Id
        );
        insert pb2;

        Opportunity opp = new Opportunity(
            Name = 'TESTE EPLAST Apex Oportunidade',
            StageName = 'Qualificado',
            Pricebook2Id = pb2.Id,
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
        Assert.isTrue(quotesCPQ.size() >= 1);
        Assert.areEqual('Blower Shipping City', quotesCPQ[0].SBQQ__ShippingCity__c);
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
        Account conta = [SELECT BillingCity FROM Account WHERE Id = :opp.AccountId];
        List<SBQQ__Quote__c> quotesCPQ = [SELECT SBQQ__ShippingCity__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        Assert.isTrue(quotesCPQ.size() >= 1);
        Assert.areEqual(conta.BillingCity, quotesCPQ[0].SBQQ__ShippingCity__c);
    }
}