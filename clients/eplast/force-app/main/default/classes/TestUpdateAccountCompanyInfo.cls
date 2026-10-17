@isTest
public with sharing class TestUpdateAccountCompanyInfo {
    private static String cnpj = '29.190.753/0001-99';

    @TestSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'Test Account',
            Store__c = '2',
            CompanyName__c = 'Test Company',
            BillingPostalCode = '02000-000',
            BillingStreet = 'Rua B',
            BillingCity = 'São Paulo',
            BillingState = 'SP',
            BillingCountry = 'BR',
            BillingNeighborhood__c = 'Centro',
            Phone = '(11) 98888-8888',
            //CompanyDocument__c = '12345678000195',
            Risk__c = 'A',
            LimitAmount__c = 50000,
            LimitAmountDueDate__c = Date.today().addMonths(1),
            Email__c = 'test@company.com',
            CNAE__c = '654321'
        );
        insert acc;
    }

    @isTest
    public static void updateAccountCompanyInfoTest() {
        //Account acc = [SELECT Id FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];
		Account acc = SendAccountToProtheusTDF.createSecAccount();
        insert acc;
        
        acc.CompanyDocument__c = null;
        update acc;
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());

        	System.enqueueJob(new UpdateAccountCompanyInfo(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT CompanyName__c, CNAE__c, OpeningDate__c, Phone, BillingPostalCode, BillingStreet, BillingCity, BillingState, BillingCountry, BillingNeighborhood__c, Description FROM Account WHERE Id = :acc.Id];

        System.assertNotEquals(null, updatedAcc.CompanyName__c);
        System.assertNotEquals(null, updatedAcc.CNAE__c);
        System.assertNotEquals(null, updatedAcc.OpeningDate__c);
        System.assertNotEquals(null, updatedAcc.Phone);
        System.assertNotEquals(null, updatedAcc.BillingPostalCode);
        System.assertNotEquals(null, updatedAcc.BillingStreet);
        System.assertNotEquals(null, updatedAcc.BillingCity);
        System.assertNotEquals(null, updatedAcc.BillingState);
        System.assertEquals(null, updatedAcc.BillingCountry);
        System.assertNotEquals(null, updatedAcc.BillingNeighborhood__c);
        System.assertNotEquals('Quadro Societário: \n\nNão há quadro societário', updatedAcc.Description);
    }

    @isTest
    public static void updateAccountCompanyInfoWithMissingCNPJTest() {
        Account acc = new Account();
        acc.Name = 'Test Account no CNPJ';
        acc.CompanyDocument__c = 'invalid_cnpj';
        acc.Store__c = '01';
        insert acc;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJErrorResponse());

        System.enqueueJob(new UpdateAccountCompanyInfo(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT CompanyName__c FROM Account WHERE Id = :acc.Id];

        System.assertEquals('CNPJ não encontrado', updatedAcc.CompanyName__c);
    }
}