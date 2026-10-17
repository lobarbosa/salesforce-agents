@IsTest
private class TestAccountUtility {
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
            CompanyDocument__c = '12345678000195',
            Risk__c = 'A',
            LimitAmount__c = 50000,
            LimitAmountDueDate__c = Date.today().addMonths(1),
            Email__c = 'test@company.com',
            CNAE__c = '654321'
        );
        insert acc;

        String owner = UserInfo.getUserId();
        User user = [SELECT Id, ProtheusSellerId__c FROM User WHERE Id =: owner];
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
        System.assert(isValid == true);

        Boolean isInvalid = AccountUtility.validateCNPJ(invalidCNPJ);
        System.assert(isInvalid == false);
    }

    @isTest
    static void testCleanCNPJ() {
        String cnpjWithFormatting = '12.345.678/0001-95';
        String cleanCNPJ = AccountUtility.cleanCNPJ(cnpjWithFormatting);
        System.assertEquals('12345678000195', cleanCNPJ);
    }

    @isTest
    static void testGetAccountsById() {
        Account testAccount = new Account(Name = 'Test Account', CompanyDocument__c = '12345678000195');
        insert testAccount;

        Account[] accounts = AccountUtility.getAccountsById(new Set<Id>{testAccount.Id});
        System.assert(accounts.size() == 1);
    }

    @isTest
    static void testCheckAccountTeamMembers() {
        AccountTeamMember teamMember = new AccountTeamMember(UserId = UserInfo.getUserId(), AccountId = [SELECT Id FROM Account LIMIT 1].Id);
        insert teamMember;
        System.debug('teamMember ' + teamMember);

        Boolean hasTeamMembers = AccountUtility.checkAccountTeamMembers(new AccountTeamMember[]{ teamMember });
        Assert.isFalse(hasTeamMembers);
    }
}