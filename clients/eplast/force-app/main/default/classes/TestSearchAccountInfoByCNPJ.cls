/*@isTest
public with sharing class TestSearchAccountInfoByCNPJ {
    public static String invalidCNPJErrorMessage = 'CNPJ incompleto ou inválido';
    public static String insertedAccountCNPJ = '00.000.000/0001-91';
    public static String updateIncompleteCNPJ = '00.000.000/0001';
    public static String updateCNPJWithInvalidFirstVerifyingDigit = '00.000.000/0001-81';
    public static String updateCNPJWithInvalidSecondVerifyingDigit = '00.000.000/0001-90';
    public static String updateValidCNPJ = '00.000.000/0002-72';
    public static String validButInexistentCNPJ = '00.000.000/0003-53';

    @testSetup
    public static void setup(){
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());
        insert SearchAccountInfoByCNPJTDF.createAccountWithCorrectCNPJ();
    }

    @isTest
    public static void insertAccountWithNullCNPJTest(){
        Account acc = new Account(Name = 'TESTE EPLAST Apex CNPJ invalido', CompanyDocument__c = null);

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
        Account acc = new Account(Name = 'TESTE EPLAST Apex CNPJ invalido', CompanyDocument__c = '');

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
        Account acc = new Account(Name = 'TESTE EPLAST Apex CNPJ invalido', CompanyDocument__c = updateIncompleteCNPJ);

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
        Account acc = new Account(Name = 'TESTE EPLAST Apex CNPJ invalido', CompanyDocument__c = updateCNPJWithInvalidFirstVerifyingDigit);

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
        Account acc = new Account(Name = 'TESTE EPLAST Apex CNPJ invalido', CompanyDocument__c = updateCNPJWithInvalidSecondVerifyingDigit);

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

        Account acc = new Account(Name = 'TESTE EPLAST Apex CNPJ invalido', CompanyDocument__c = validButInexistentCNPJ);
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
    public static String insertedAccountCNPJ = SearchAccountInfoByCNPJTDF.CNPJ_VALIDO;
    public static String updateIncompleteCNPJ = SearchAccountInfoByCNPJTDF.CNPJ_INCOMPLETO;
    public static String updateCNPJWithInvalidFirstVerifyingDigit = SearchAccountInfoByCNPJTDF.CNPJ_DIGITO_1_ERRADO;
    public static String updateCNPJWithInvalidSecondVerifyingDigit = SearchAccountInfoByCNPJTDF.CNPJ_DIGITO_2_ERRADO;
    public static String updateValidCNPJ = SearchAccountInfoByCNPJTDF.CNPJ_OUTRO;
    public static String validButInexistentCNPJ = SearchAccountInfoByCNPJTDF.CNPJ_TERCEIRO;

    @testSetup
    public static void setup(){
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());
        Account acc = SearchAccountInfoByCNPJTDF.createAccountWithCorrectCNPJ();
        acc.Name = 'TESTE EPLAST Apex CNPJ valido';
        insert acc;
    }

    private static void assertCnpjRecusado(Database.SaveResult result){
        Assert.isFalse(result.isSuccess(), 'CNPJ inválido deve ser recusado');
        Boolean found = false;
        for(Database.Error err : result.getErrors()){
            if(err.getMessage() == invalidCNPJErrorMessage)
                found = true;
        }
        Assert.isTrue(found, 'A recusa deve citar: ' + invalidCNPJErrorMessage);
    }

    @isTest
    public static void insertAccountWithNullCNPJTest(){
        Account acc = new Account(Name = 'TESTE EPLAST Apex CNPJ invalido', CompanyDocument__c = null);

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        assertCnpjRecusado(result);
    }

    @isTest
    public static void insertAccountWithEmptyCNPJTest(){
        Account acc = new Account(Name = 'TESTE EPLAST Apex CNPJ invalido', CompanyDocument__c = '');

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        assertCnpjRecusado(result);
    }

    @isTest
    public static void insertAccountWithIncompleteCNPJTest(){
        Account acc = new Account(Name = 'TESTE EPLAST Apex CNPJ invalido', CompanyDocument__c = updateIncompleteCNPJ);

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        assertCnpjRecusado(result);
    }

    @isTest
    public static void insertAccountWithWrongFirstVerifyingDigitTest(){
        Account acc = new Account(Name = 'TESTE EPLAST Apex CNPJ invalido', CompanyDocument__c = updateCNPJWithInvalidFirstVerifyingDigit);

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        assertCnpjRecusado(result);
    }

    @isTest
    public static void insertAccountWithWrongSecondVerifyingDigitTest(){
        Account acc = new Account(Name = 'TESTE EPLAST Apex CNPJ invalido', CompanyDocument__c = updateCNPJWithInvalidSecondVerifyingDigit);

        Test.startTest();
            Database.SaveResult result = Database.insert(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        assertCnpjRecusado(result);
    }

    /*
    @isTest
    public static void insertAccountWithValidButInexistentCNPJTest(){
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJErrorResponse());

        Account acc = new Account(Name = 'TESTE EPLAST Apex CNPJ invalido', CompanyDocument__c = validButInexistentCNPJ);
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

        assertCnpjRecusado(result);
    }

    @isTest
    public static void updateAccountWithEmptyCNPJTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = '';

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        assertCnpjRecusado(result);
    }

    @isTest
    public static void updateAccountWithIncompleteCNPJTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = updateIncompleteCNPJ;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        assertCnpjRecusado(result);
    }

    @isTest
    public static void updateAccountWithWrongFirstVerifyingDigitTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = updateCNPJWithInvalidFirstVerifyingDigit;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        assertCnpjRecusado(result);
    }

    @isTest
    public static void updateAccountWithWrongSecondVerifyingDigitTest(){
        Account acc = [SELECT Id, CompanyDocument__c FROM Account WHERE CompanyDocument__c = :insertedAccountCNPJ LIMIT 1];
        acc.CompanyDocument__c = updateCNPJWithInvalidSecondVerifyingDigit;

        Test.startTest();
            Database.SaveResult result = Database.update(acc, false);
        Test.stopTest();

        Database.Error[] errors = result.getErrors();

        assertCnpjRecusado(result);
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