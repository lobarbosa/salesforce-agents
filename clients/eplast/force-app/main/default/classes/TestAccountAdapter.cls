@IsTest
private class TestAccountAdapter {

    @TestSetup
    static void setupData() {
        //User owner = TestDataFactory.createUser();

        Account parentAccount = new Account(
            Name = 'Parent Account',
            LimitAmount__c = 50000,
            LimitAmountDueDate__c = Date.today().addMonths(1),
            Store__c = '1',
            CompanyName__c = 'Parent Company',
            BillingCity = 'São Paulo',
            BillingState = 'SP',
            BillingNeighborhood__c = 'Centro',
            BillingStreet = 'Rua A',
            BillingPostalCode = '01000-000',
            Phone = '(11) 99999-9999',
            //CompanyDocument__c = '79653346000149',
            Email__c = 'email@company.com',
            Risk__c = 'A',
            CNAE__c = '123456'
        );
        insert parentAccount;

        Account acc = new Account(
            Name = 'Test Account',
            ParentId = parentAccount.Id,
            //OwnerId = owner.Id,
            Store__c = '2',
            CompanyName__c = 'Test Company',
            BillingCity = 'São Paulo',
            BillingState = 'SP',
            BillingNeighborhood__c = 'Centro',
            BillingStreet = 'Rua B',
            BillingPostalCode = '02000-000',
            Phone = '(11) 98888-8888',
            //CompanyDocument__c = '79653346000149',
            Email__c = 'test@company.com',
            Risk__c = 'A',
            CNAE__c = '654321'
        );
        insert acc;
    }

    @IsTest
    static void testToProtheus() {
        
        Account acc = [SELECT Id, Store__c, CompanyName__c, BillingCity, BillingState, BillingNeighborhood__c, BillingStreet, BillingPostalCode, Phone, CompanyDocument__c, Email__c, Risk__c, CNAE__c, Owner.ProtheusSellerId__c, Parent.LimitAmount__c, Parent.LimitAmountDueDate__c FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockProtheusSendClientSuccessResponse());

        ProtheusInsertClientModel result = AccountAdapter.toProtheus(acc);
		
        Test.stopTest();
        
        
        System.assertEquals(acc.Id, result.CodCRM);
        System.assertEquals('02', result.Loja);
        System.assertEquals(acc.CompanyName__c, result.Nome);
        System.assertEquals(acc.BillingCity, result.Cidade);
        System.assertEquals(acc.BillingState, result.UF);
        System.assertEquals(acc.BillingNeighborhood__c, result.Bairro);
        System.assertEquals(acc.BillingStreet, result.Endereco);
        System.assertEquals(AddressUtility.getFormattedPostalCode(acc.BillingPostalCode), result.CEP);
        System.assertEquals('11', result.DDD);
        System.assertNotEquals('988888888', result.Telefone);
        System.assertEquals(acc.CompanyDocument__c, result.CGC);
        //System.assertNotEquals(acc.Email__c, result.Email);
        System.assertEquals(acc.Owner.ProtheusSellerId__c, result.Vend1);
        System.assertEquals(50000, result.LimCred);
        System.assertEquals(DateTimeUtility.formatDate(acc.Parent.LimitAmountDueDate__c), result.VencLimCred);
        System.assertEquals(acc.CNAE__c, result.Cnae);
    }
    
    public class MockProtheusSendClient implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"success": true}');
        return res;
    }
}

}