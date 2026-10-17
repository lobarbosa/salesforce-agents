@isTest
public class FlowOpportunityControllerTest {
    
    @testSetup
    static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new MockTestSendOrderToProtheusSetupResponse(true));

        User user = new User(Id = UserInfo.getUserId(), ProtheusSellerId__c = '000001');
        update user;
        // Criação de uma conta para BlowerCustomer
        Account blowerAccount =  new Account(
            Name = 'Account Blower',
            ProtheusId__c = '123457',
            CompanyDocument__c = '34921036000120',
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
            OwnerId = user.Id
        );

        insert blowerAccount;
        blowerAccount.Store__c = '01';
        update blowerAccount;

        Pricebook2 pb2 = new Pricebook2(
            Name = 'Catálogo Teste',
            IsActive = true,
            Account__c = blowerAccount.Id
        );
        insert pb2;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            Account__c = blowerAccount.Id,
            IsActive = true
        );
        update standardPricebook;

        // Criação de uma oportunidade
        TriggerUtility.bypassTrigger = true;
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualificado',
            Pricebook2Id = standardPricebook.Id,
            CloseDate = Date.today(),
            AccountId = blowerAccount.Id,
            RecordTypeId = SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Industria').getRecordTypeId(),
            OwnerId = user.Id
        );
        insert opp;

    }
    

    @IsTest
    static void test_create(){
        
        Test.startTest();
        FlowOpportunityController.RequestItem item = new FlowOpportunityController.RequestItem();
        item.recordId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        FlowOpportunityController.createQuoteFromOpportunity(new List<FlowOpportunityController.RequestItem>{item});
        Test.stopTest();
        
    }

}