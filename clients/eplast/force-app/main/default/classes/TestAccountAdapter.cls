@IsTest
private class TestAccountAdapter {

    @TestSetup
    static void setupData() {
        TriggerUtility.bypassTrigger = true;
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());

        Account parentAccount = new Account(
            Name = 'TESTE EPLAST Apex Conta Pai',
            LimitAmount__c = 50000,
            LimitAmountDueDate__c = Date.today().addMonths(1),
            Store__c = '1',
            CompanyName__c = 'TESTE EPLAST MATRIZ',
            BillingCity = 'Cidade Teste',
            BillingState = 'SP',
            BillingNeighborhood__c = 'Bairro Teste',
            BillingStreet = 'Rua Teste 1',
            BillingPostalCode = '01310100',
            Phone = '(11)33334444',
            CompanyDocument__c = SearchAccountInfoByCNPJTDF.CNPJ_VALIDO,
            Email__c = 'teste.eplast.apex.matriz@example.com',
            Risk__c = 'A',
            CNAE__c = '6201501'
        );
        insert parentAccount;

        Account acc = new Account(
            Name = 'TESTE EPLAST Apex Conta Filha',
            ParentId = parentAccount.Id,
            Store__c = '2',
            CompanyName__c = 'TESTE EPLAST FILIAL',
            BillingCity = 'Cidade Teste',
            BillingState = 'SP',
            BillingNeighborhood__c = 'Bairro Teste',
            BillingStreet = 'Rua Teste 2',
            BillingPostalCode = '01310200',
            Phone = '(11)988888888',
            CompanyDocument__c = SearchAccountInfoByCNPJTDF.CNPJ_OUTRO,
            Email__c = 'teste.eplast.apex.filial@example.com',
            Risk__c = 'A',
            CNAE__c = '654321'
        );
        insert acc;
    }

    @IsTest
    static void testToProtheus() {
        
        Account acc = [SELECT Id, Store__c, CompanyName__c, BillingCity, BillingState, BillingNeighborhood__c, BillingStreet, BillingPostalCode, Phone, CompanyDocument__c, Email__c, Risk__c, CNAE__c, Owner.ProtheusSellerId__c, Parent.LimitAmount__c, Parent.LimitAmountDueDate__c, (SELECT User.ProtheusSellerId__c FROM AccountTeamMembers) FROM Account WHERE Name = 'TESTE EPLAST Apex Conta Filha' LIMIT 1];

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
        Assert.areEqual('11', result.DDD);
        Assert.areEqual('988888888', result.Telefone);
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