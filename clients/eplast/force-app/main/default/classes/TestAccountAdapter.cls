@IsTest
private class TestAccountAdapter {

    @TestSetup
    static void setupData() {
        TriggerUtility.bypassTrigger = true;
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());

        Account parentAccount = SearchAccountInfoByCNPJTDF.aplicarEnderecoUnico(new Account(), 'N2CKPAI');
        parentAccount.LimitAmount__c = 50000;
        parentAccount.LimitAmountDueDate__c = Date.today().addMonths(1);
        parentAccount.Store__c = '1';
        parentAccount.CompanyDocument__c = SearchAccountInfoByCNPJTDF.CNPJ_VALIDO;
        parentAccount.Risk__c = 'A';
        parentAccount.CNAE__c = '6201501';
        insert parentAccount;

        Account acc = SearchAccountInfoByCNPJTDF.aplicarEnderecoUnico(new Account(), 'B7QSFILHA');
        acc.ParentId = parentAccount.Id;
        acc.Store__c = '2';
        acc.CompanyDocument__c = SearchAccountInfoByCNPJTDF.CNPJ_OUTRO;
        acc.Risk__c = 'A';
        acc.CNAE__c = '654321';
        insert acc;
    }

    @IsTest
    static void testToProtheus() {
        
        Account acc = [SELECT Id, Store__c, CompanyName__c, BillingCity, BillingState, BillingNeighborhood__c, BillingStreet, BillingPostalCode, Phone, CompanyDocument__c, Email__c, Risk__c, CNAE__c, Owner.ProtheusSellerId__c, Parent.LimitAmount__c, Parent.LimitAmountDueDate__c, (SELECT User.ProtheusSellerId__c FROM AccountTeamMembers) FROM Account WHERE Name = 'B7QSFILHA TESTE' LIMIT 1];

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
        Map<String, String> phoneParts = PhoneUtility.getPhoneInParts(acc.Phone);
        Assert.areEqual(phoneParts.get('ddd'), result.DDD);
        Assert.areEqual(phoneParts.get('phone'), result.Telefone);
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