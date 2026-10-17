@isTest
public with sharing class TestSendAccountToProtheus {
    private static String cnpj = '29.190.753/0001-99';

    @TestSetup
    static void setup(){
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());
        
        Account parentAccount = SendAccountToProtheusTDF.createAccountWithoutStoreField();
        insert parentAccount;
        
        /*Account acc = SendAccountToProtheusTDF.createAccount();
        insert acc;*/

        Account childAccount = SendAccountToProtheusTDF.createAccountWithoutStoreField();
        childAccount.ParentId = parentAccount.Id;

        insert childAccount;
    }

    @isTest
    public static void sendAccountWithoutStoreFieldTest(){
        Account acc = [SELECT Id, Phone, Store__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId = null LIMIT 1];
        acc.Store__c = null;

        Test.startTest();
        	System.enqueueJob(new SendAccountToProtheus(acc));
        Test.stopTest();
        Account updatedAcc = [SELECT Id, ProtheusId__c FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];

        Assert.isNull(updatedAcc.ProtheusId__c);
    }

    @isTest
    public static void sendAccountWithoutCompanyNameFieldTest(){
        Account acc = [SELECT Id, Phone, CompanyName__c, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId = null LIMIT 1];
        acc.Store__c = '01';
        acc.CompanyName__c = null;

        Test.startTest();
        System.enqueueJob(new SendAccountToProtheus(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT Id, ProtheusId__c, Phone FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];
        Assert.isNull(updatedAcc.ProtheusId__c);
    }

    @isTest
    public static void sendAccountWithoutBillingCityFieldTest(){
        //Account acc = [SELECT Id, Phone, BillingCity, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId = null LIMIT 1];
        Account acc = SendAccountToProtheusTDF.createAccount();
        insert acc;
        acc.Store__c = '01';
        acc.BillingCity = null;
        update acc;
        Test.startTest();
        	System.enqueueJob(new SendAccountToProtheus(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT Id, ProtheusId__c, Phone, CompanyName__c, BillingCity FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];
        Assert.isNull(updatedAcc.ProtheusId__c);
    } 

    @isTest
    public static void sendAccountWithoutBillingStateFieldTest(){
        //Account acc = [SELECT Id, Phone, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId = null LIMIT 1];
        Account acc = SendAccountToProtheusTDF.createAccount();
        insert acc;
        acc.Store__c = '01';
        acc.BillingState = null;
		update acc;
        Test.startTest();
        System.enqueueJob(new SendAccountToProtheus(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT Id, ProtheusId__c, Phone, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];

        Assert.isNull(updatedAcc.ProtheusId__c);
    } 

    @isTest
    public static void sendAccountWithoutBillingStreetFieldTest(){
        //Account acc = [SELECT Id, Phone, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId = null LIMIT 1];
        Account acc = SendAccountToProtheusTDF.createAccount();
        insert acc;
        acc.Store__c = '01';
        acc.BillingStreet = null;
        
        update acc;

        Test.startTest();
        System.enqueueJob(new SendAccountToProtheus(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT Id, ProtheusId__c, Phone, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];

        Assert.isNull(updatedAcc.ProtheusId__c);
    } 

   	@isTest
    public static void sendAccountWithoutBillingPostalCodeFieldTest(){
        //Account acc = [SELECT Id, Phone, BillingPostalCode, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId = null LIMIT 1];
        Account acc = SendAccountToProtheusTDF.createAccount();
        insert acc;
        acc.Store__c = '01';
        acc.BillingPostalCode = null;
    
        update acc;
    
        Account verifyAcc = [SELECT BillingPostalCode FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, verifyAcc.BillingPostalCode, 'BillingPostalCode deve ser nulo antes de iniciar o teste');
    
        Test.startTest();
        	System.enqueueJob(new SendAccountToProtheus(acc));
        Test.stopTest();
    
        Account updatedAcc = [SELECT Id, ProtheusId__c FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];
    
        System.assertEquals(null, updatedAcc.ProtheusId__c, 'ProtheusId__c deve ser nulo porque BillingPostalCode estava ausente');
    }

    @isTest
    public static void sendAccountWithoutBillingNeighborhoodFieldTest(){
        //Account acc = [SELECT Id, Phone, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId = null LIMIT 1];
        Account acc = SendAccountToProtheusTDF.createAccount();
        insert acc;
        acc.Store__c = '01';
        acc.BillingNeighborhood__c = null;
		update acc;
        Test.startTest();
        System.enqueueJob(new SendAccountToProtheus(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT Id, ProtheusId__c, Phone, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];

        Assert.isNull(updatedAcc.ProtheusId__c);
    } 

    @isTest
    public static void sendAccountWithoutPhoneFieldTest(){
        //Account acc = [SELECT Id, CompanyDocument__c, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId = null LIMIT 1];
        Account acc = SendAccountToProtheusTDF.createAccount();
        insert acc;
        acc.Store__c = '01';
        acc.Phone = null;
		update acc;
        Test.startTest();
        System.enqueueJob(new SendAccountToProtheus(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT Id, ProtheusId__c FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];

        Assert.isNull(updatedAcc.ProtheusId__c);
    } 

    @isTest
    public static void sendAccountWithoutEmailFieldTest(){
        //Account acc = [SELECT Id, Phone, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId = null LIMIT 1];
        Account acc = SendAccountToProtheusTDF.createAccount();
        insert acc;
        acc.Store__c = '01';
        acc.Email__c = null;
		update acc;
        Test.startTest();
        System.enqueueJob(new SendAccountToProtheus(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT Id, ProtheusId__c, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];

        Assert.isNull(updatedAcc.ProtheusId__c);
    } 

    @isTest
    public static void sendAccountWithoutCNAEFieldTest(){
        //Account acc = [SELECT Id, Phone, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId = null LIMIT 1];
        Account acc = SendAccountToProtheusTDF.createAccount();
        insert acc;
        acc.Store__c = '01';
        acc.CNAE__c = null;
		update acc;
        Test.startTest();
        System.enqueueJob(new SendAccountToProtheus(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT Id, ProtheusId__c, Phone, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];

        Assert.isNull(updatedAcc.ProtheusId__c);
    } 

    @isTest
    public static void sendAccountWithoutOwnerProtheusSellerIdFieldTest(){
        Account acc = [SELECT Id, Owner.ProtheusSellerId__c, Phone, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId = null LIMIT 1];
        /*Account acc = SendAccountToProtheusTDF.createAccount();
        insert acc;*/
        acc.Store__c = '01';
        acc.Owner.ProtheusSellerId__c = null;
		//update acc;
        Test.startTest();
        update acc.Owner;
        System.enqueueJob(new SendAccountToProtheus(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT Id, ProtheusId__c, Owner.ProtheusSellerId__c, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];

        Assert.isNull(updatedAcc.ProtheusId__c);
    } 

    @isTest
	public static void sendAccountWithRequiredFieldsTest() {
    Test.setMock(HttpCalloutMock.class, new MockProtheusSendClientSuccessResponse());

    Account acc = [
        /*SELECT Id, Phone, Store__c, CompanyName__c, BillingCity, BillingState, BillingStreet, 
               BillingPostalCode, BillingNeighborhood__c, ParentId, CNAE__c, Owner.ProtheusSellerId__c
        FROM Account 
        WHERE CompanyDocument__c = :cnpj 
        AND ParentId = null 
        LIMIT 1
    ];*/
        SELECT Id, Store__c, CompanyName__c, BillingCity, BillingState, BillingStreet, 
               BillingPostalCode, BillingNeighborhood__c, Phone, CompanyDocument__c, 
               Owner.ProtheusSellerId__c, Risk__c, 
               LimitAmount__c, Email__C,LimitAmountDueDate__c, CNAE__c,
               Parent.LimitAmount__c, Parent.LimitAmountDueDate__c
        FROM Account WHERE CompanyDocument__c =: cnpj
        AND ParentId = null
        LIMIT 1
     ];   
    
    acc.Store__c = '01';
    acc.CompanyName__c = 'My Company';
    acc.BillingCity = 'São Paulo';
    acc.BillingState = 'SP';
    acc.BillingStreet = 'Av. Paulista, 1000';
    acc.BillingPostalCode = '01310-100';
    acc.BillingNeighborhood__c = 'Bela Vista';
    acc.Phone = '11999999999';
    acc.CNAE__c = '12345';
    acc.Owner.ProtheusSellerId__c = '001';

    Test.startTest();
    	System.enqueueJob(new SendAccountToProtheus(acc));
    Test.stopTest();

    Account updatedAcc = [SELECT Id, ProtheusId__c FROM Account WHERE CompanyDocument__c = :cnpj LIMIT 1];
    Assert.isNotNull(updatedAcc.ProtheusId__c);
}


    @isTest
    public static void sendAccountWithRequiredFieldsAndParentAccountTest(){
        Test.setMock(HttpCalloutMock.class, new MockProtheusSendClientSuccessResponse());

        Account acc = [SELECT Id, Phone, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId != null LIMIT 1];
        acc.Store__c = '01';

        Test.startTest();
        System.enqueueJob(new SendAccountToProtheus(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT Id, ProtheusId__c, Phone, CompanyName__c FROM Account WHERE CompanyDocument__c = :cnpj AND ParentId != null LIMIT 1];

        Assert.isNull(updatedAcc.ProtheusId__c);
    }
}