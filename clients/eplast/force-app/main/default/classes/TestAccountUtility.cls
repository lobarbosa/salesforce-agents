@IsTest
private class TestAccountUtility {
    @TestSetup
    static void setupData() {
        TriggerUtility.bypassTrigger = true;
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());

        Account acc = new Account(
            Name = 'TESTE EPLAST Apex Util',
            Store__c = '2',
            CompanyName__c = 'TESTE EPLAST COMERCIO LTDA',
            BillingPostalCode = '01310100',
            BillingStreet = 'Rua Teste 100',
            BillingCity = 'Cidade Teste',
            BillingState = 'SP',
            BillingCountry = 'BR',
            BillingNeighborhood__c = 'Bairro Teste',
            Phone = '(11)33334444',
            CompanyDocument__c = SearchAccountInfoByCNPJTDF.CNPJ_VALIDO,
            Risk__c = 'A',
            LimitAmount__c = 50000,
            LimitAmountDueDate__c = Date.today().addMonths(1),
            Email__c = 'teste.eplast.apex@example.com',
            CNAE__c = '6201501'
        );
        insert acc;

        String owner = UserInfo.getUserId();
        User user = [SELECT Id, ProtheusSellerId__c FROM User WHERE Id = :owner];
        user.ProtheusSellerId__c = '00043';
        update user;

        AccountTeamMember atm = new AccountTeamMember(
            AccountId = acc.Id,
            UserId = user.Id,
            TeamMemberRole = 'Sales Team'
        );
        insert atm;
    }

    @isTest
    static void testValidateCNPJ() {
        String validCNPJ = '12.345.678/0001-95';
        String invalidCNPJ = '11.111.111/1111-11';

        Boolean isValid = AccountUtility.validateCNPJ(validCNPJ);
        Assert.isTrue(isValid);

        Boolean isInvalid = AccountUtility.validateCNPJ(invalidCNPJ);
        Assert.isFalse(isInvalid);
        Assert.isTrue(AccountUtility.validateCNPJ(SearchAccountInfoByCNPJTDF.CNPJ_VALIDO));
    }

    @isTest
    static void testCleanCNPJ() {
        String cnpjWithFormatting = '12.345.678/0001-95';
        String cleanCNPJ = AccountUtility.cleanCNPJ(cnpjWithFormatting);
        Assert.areEqual('12345678000195', cleanCNPJ);
    }

    @isTest
    static void testGetAccountsById() {
        TriggerUtility.bypassTrigger = true;
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());
        Account testAccount = new Account(
            Name = 'TESTE EPLAST Apex Util Consulta',
            CompanyDocument__c = SearchAccountInfoByCNPJTDF.CNPJ_OUTRO
        );
        insert testAccount;

        Account[] accounts = AccountUtility.getAccountsById(new Set<Id>{ testAccount.Id });
        Assert.areEqual(1, accounts.size());
    }

    @isTest
    static void testCheckAccountTeamMembers() {
        AccountTeamMember teamMember = new AccountTeamMember(
            UserId = UserInfo.getUserId(),
            AccountId = [SELECT Id FROM Account WHERE Name = 'TESTE EPLAST Apex Util' LIMIT 1].Id
        );
        insert teamMember;

        Boolean hasTeamMembers = AccountUtility.checkAccountTeamMembers(new AccountTeamMember[]{ teamMember });
        Assert.isFalse(hasTeamMembers);
    }
}
