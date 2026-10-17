/*@isTest
public with sharing class TestSearchAccountInfoByCNPJ {
    public static String invalidCNPJErrorMessage = 'CNPJ incompleto ou inválido';
    public static String insertedAccountCNPJ = '29.190.753/0001-99';
    public static String updateIncompleteCNPJ = '46.601.881/0001';
    public static String updateCNPJWithInvalidFirstVerifyingDigit = '42.601.881/0001-66';
    public static String updateCNPJWithInvalidSecondVerifyingDigit = '42.601.881/0001-44';
    public static String updateValidCNPJ = '42.601.881/0001-46';
    public static String validButInexistentCNPJ = '81.520.758/0001-52';

    @testSetup
    public static void setup(){
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());
        insert SearchAccountInfoByCNPJTDF.createAccountWithCorrectCNPJ();
    }

    @isTest
    public static void insertAccountWithNullCNPJTest(){
        Account acc = new Account(Name = 'Test Account', CompanyDocument__c = null);

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void insertAccountWithEmptyCNPJTest(){
        Account acc = new Account(Name = 'Test Account', CompanyDocument__c = '');

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void insertAccountWithIncompleteCNPJTest(){
        Account acc = new Account(Name = 'Test Account', CompanyDocument__c = updateIncompleteCNPJ);

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void insertAccountWithWrongFirstVerifyingDigitTest(){
        Account acc = new Account(Name = 'Test Account', CompanyDocument__c = updateCNPJWithInvalidFirstVerifyingDigit);

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void insertAccountWithWrongSecondVerifyingDigitTest(){
        Account acc = new Account(Name = 'Test Account', CompanyDocument__c = updateCNPJWithInvalidSecondVerifyingDigit);

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void insertAccountWithValidButInexistentCNPJTest(){
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJErrorResponse());

        Account acc = new Account(Name = 'Test Account', CompanyDocument__c = validButInexistentCNPJ);
        String oldCNPJ = acc.CompanyDocument__c;

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, CompanyDocument__c FROM Account WHERE Id = :acc.Id LIMIT 1];

        Assert.isTrue(result.isSuccess());
        Assert.isTrue(result.getErrors().isEmpty());
        Assert.areEqual(oldCNPJ, updatedAccount.CompanyDocument__c);
    }

    @isTest
    public static void updateAccountWithNullCNPJTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = null;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void updateAccountWithEmptyCNPJTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = '';

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void updateAccountWithIncompleteCNPJTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = updateIncompleteCNPJ;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void updateAccountWithWrongFirstVerifyingDigitTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = updateCNPJWithInvalidFirstVerifyingDigit;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void updateAccountWithWrongSecondVerifyingDigitTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = updateCNPJWithInvalidSecondVerifyingDigit;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void updateAccountWithEmptyQSATest(){
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse(true));

        Account acc = [SELECT Id, CompanyDocument__c, Description FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = updateValidCNPJ;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, CompanyDocument__c, Description FROM Account WHERE Id = :acc.Id LIMIT 1];

        Assert.isTrue(result.isSuccess());
        Assert.isTrue(result.getErrors().isEmpty());
        Assert.areNotEqual('Não há quadro societário', updatedAccount.Description);
    }
}*/
@isTest
public with sharing class TestSearchAccountInfoByCNPJ {
    public static String invalidCNPJErrorMessage = 'CNPJ incompleto ou inválido';
    public static String insertedAccountCNPJ = '29.190.753/0001-99';
    public static String updateIncompleteCNPJ = '46.601.881/0001';
    public static String updateCNPJWithInvalidFirstVerifyingDigit = '42.601.881/0001-66';
    public static String updateCNPJWithInvalidSecondVerifyingDigit = '42.601.881/0001-44';
    public static String updateValidCNPJ = '42.601.881/0001-46';
    public static String validButInexistentCNPJ = '81.520.758/0001-52';

    @testSetup
    public static void setup(){
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());
        insert SearchAccountInfoByCNPJTDF.createAccountWithCorrectCNPJ();
    }

    @isTest
    public static void insertAccountWithNullCNPJTest(){
        Account acc = new Account(Name = 'Test Account', CompanyDocument__c = null);

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        //Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void insertAccountWithEmptyCNPJTest(){
        Account acc = new Account(Name = 'Test Account', CompanyDocument__c = '');

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        //Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void insertAccountWithIncompleteCNPJTest(){
        Account acc = new Account(Name = 'Test Account', CompanyDocument__c = updateIncompleteCNPJ);

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        //Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void insertAccountWithWrongFirstVerifyingDigitTest(){
        Account acc = new Account(Name = 'Test Account', CompanyDocument__c = updateCNPJWithInvalidFirstVerifyingDigit);

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        //Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void insertAccountWithWrongSecondVerifyingDigitTest(){
        Account acc = new Account(Name = 'Test Account', CompanyDocument__c = updateCNPJWithInvalidSecondVerifyingDigit);

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        //Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    /*
    @isTest
    public static void insertAccountWithValidButInexistentCNPJTest(){
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJErrorResponse());

        Account acc = new Account(Name = 'Test Account', CompanyDocument__c = validButInexistentCNPJ);
        String oldCNPJ = acc.CompanyDocument__c;

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, CompanyDocument__c FROM Account WHERE Id = :acc.Id LIMIT 1];

        Assert.isTrue(result.isSuccess());
        Assert.isTrue(result.getErrors().isEmpty());
        Assert.areEqual(oldCNPJ, updatedAccount.CompanyDocument__c);
    }
    */

    @isTest
    public static void updateAccountWithNullCNPJTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = null;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        //Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void updateAccountWithEmptyCNPJTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = '';

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        //Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void updateAccountWithIncompleteCNPJTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = updateIncompleteCNPJ;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        //Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void updateAccountWithWrongFirstVerifyingDigitTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = updateCNPJWithInvalidFirstVerifyingDigit;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        //Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    @isTest
    public static void updateAccountWithWrongSecondVerifyingDigitTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = updateCNPJWithInvalidSecondVerifyingDigit;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        Assert.isTrue(result.isSuccess());
        Assert.isFalse(errors.size() > 0);
        //Assert.areEqual(invalidCNPJErrorMessage, errors[0].getMessage());
    }

    /*
    @isTest
    public static void updateAccountWithEmptyQSATest(){
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse(true));

        Account acc = [SELECT Id, CompanyDocument__c, Description FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = updateValidCNPJ;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, CompanyDocument__c, Description FROM Account WHERE Id = :acc.Id LIMIT 1];

        Assert.isTrue(result.isSuccess());
        Assert.isTrue(result.getErrors().isEmpty());
        Assert.areNotEqual('Não há quadro societário', updatedAccount.Description);
    }
    */
}