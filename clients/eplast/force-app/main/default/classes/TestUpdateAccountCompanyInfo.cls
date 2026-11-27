@isTest
public with sharing class TestUpdateAccountCompanyInfo {
    @TestSetup
    static void setupData() {
        TriggerUtility.bypassTrigger = true;
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());
        Account acc = SendAccountToProtheusTDF.createSecAccount();
        acc.Name = 'TESTE EPLAST Apex Setup Empresa';
        insert acc;
    }

    @isTest
    public static void updateAccountCompanyInfoTest() {
        TriggerUtility.bypassTrigger = true;
        User owner = usuarioSemVendedor();
        Account acc = SendAccountToProtheusTDF.createSecAccount();
        acc.Name = 'TESTE EPLAST Apex Atualiza Empresa';
        acc.CompanyDocument__c = SearchAccountInfoByCNPJTDF.CNPJ_QUARTO;
        acc.OwnerId = owner.Id;
        insert acc;

        acc = [
            SELECT Id, CompanyDocument__c, Store__c, Owner.ProtheusSellerId__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        Assert.isNull(acc.Owner.ProtheusSellerId__c);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());
            System.enqueueJob(new UpdateAccountCompanyInfo(acc));
        Test.stopTest();

        Account updatedAcc = [
            SELECT CompanyName__c, CNAE__c, OpeningDate__c, Phone, BillingPostalCode, BillingStreet,
                   BillingCity, BillingState, BillingCountry, BillingNeighborhood__c, Description
            FROM Account
            WHERE Id = :acc.Id
        ];

        Assert.areEqual('TESTE EPLAST COMERCIO LTDA', updatedAcc.CompanyName__c);
        Assert.areEqual('6201501', updatedAcc.CNAE__c);
        Assert.areEqual(Date.newInstance(2020, 1, 15), updatedAcc.OpeningDate__c);
        Assert.areEqual('(11)33334444', updatedAcc.Phone);
        Assert.areEqual('01310100', updatedAcc.BillingPostalCode);
        Assert.isTrue(updatedAcc.BillingStreet.contains('RUA TESTE'));
        Assert.areEqual('CIDADE TESTE', updatedAcc.BillingCity);
        Assert.areEqual('SP', updatedAcc.BillingState);
        Assert.isNull(updatedAcc.BillingCountry);
        Assert.areEqual('BAIRRO TESTE', updatedAcc.BillingNeighborhood__c);
        Assert.areNotEqual('Quadro Societário: \n\nNão há quadro societário', updatedAcc.Description);
        Assert.isTrue(updatedAcc.Description.contains('SOCIO TESTE UM'));
    }

    @isTest
    public static void updateAccountCompanyInfoWithMissingCNPJTest() {
        TriggerUtility.bypassTrigger = true;
        Account acc = new Account();
        acc.Name = 'TESTE EPLAST Apex Sem CNPJ';
        acc.CompanyDocument__c = 'invalid_cnpj';
        acc.Store__c = '01';
        insert acc;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJErrorResponse());
        System.enqueueJob(new UpdateAccountCompanyInfo(acc));
        Test.stopTest();

        Account updatedAcc = [SELECT CompanyName__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('CNPJ não encontrado', updatedAcc.CompanyName__c);
    }

    private static User usuarioSemVendedor(){
        String token = String.valueOf(Datetime.now().getTime());
        User owner = new User(
            Username = 'teste.eplast.apex.' + token + '@example.com',
            LastName = 'TESTE EPLAST',
            Email = 'teste.eplast.apex@example.com',
            Alias = 'tapex',
            TimeZoneSidKey = UserInfo.getTimezone().getId(),
            LocaleSidKey = UserInfo.getLocale(),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = UserInfo.getLanguage(),
            ProfileId = UserInfo.getProfileId()
        );
        insert owner;
        return owner;
    }
}
