@isTest
public with sharing class SendAccountToProtheusTDF {
    public static User createOwner(){
        User owner;

        try{
            owner = [SELECT Id FROM User WHERE Alias = 'dummy' LIMIT 1];
        }
        catch(Exception e){
            owner = new User(
                Username = 'dummyu@mail.com',
                LastName = 'Dummy Last Name',
                Email = 'dummy@mail.com',
                Alias = 'dummy',
                TimeZoneSidKey = UserInfo.getTimezone().getId(),
                LocaleSidKey = UserInfo.getLocale(),
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = UserInfo.getLanguage(),
                ProfileId = UserInfo.getProfileId(),
                ProtheusSellerId__c = '000001'
            );
        
            insert owner;
        }

        return owner;
    }

    public static Account createAccountWithoutStoreField(){
        Account acc = SearchAccountInfoByCNPJTDF.createAccountWithCorrectCNPJ();
        acc.Owner = createOwner();
        acc.OwnerId = acc.Owner.Id;
        return fillRequiredFields(acc, 'Store');
    }
    
    public static Account createAccount(){
        Account acc = baseAccount('TESTE EPLAST Apex Conta Envio');
        acc.CompanyDocument__c = SearchAccountInfoByCNPJTDF.CNPJ_OUTRO;
        return acc;
    }

    public static Account createSecAccount(){
        Account acc = baseAccount('TESTE EPLAST Apex Conta Secundaria');
        acc.CompanyDocument__c = SearchAccountInfoByCNPJTDF.CNPJ_TERCEIRO;
        return acc;
    }

    private static Account baseAccount(String name){
        return new Account(
            Name = name,
            Store__c = '2',
            CompanyName__c = 'TESTE EPLAST COMERCIO LTDA',
            BillingPostalCode = '01310100',
            BillingStreet = 'Rua Teste 100',
            BillingCity = 'Cidade Teste',
            BillingState = 'SP',
            BillingCountry = 'BR',
            BillingNeighborhood__c = 'Bairro Teste',
            Phone = '(11)33334444',
            Risk__c = 'A',
            LimitAmount__c = 50000,
            LimitAmountDueDate__c = Date.today().addMonths(1),
            Email__c = 'teste.eplast.apex@example.com',
            CNAE__c = '6201501'
        );
    }

    @isTest
    static void fabricaEntregaContaSinteticaComCnpjValido(){
        Account acc = createAccount();
        Account sec = createSecAccount();
        Assert.isTrue(acc.Name.startsWith('TESTE'));
        Assert.isTrue(AccountUtility.validateCNPJ(acc.CompanyDocument__c));
        Assert.isTrue(AccountUtility.validateCNPJ(sec.CompanyDocument__c));
        Assert.areNotEqual(acc.CompanyDocument__c, sec.CompanyDocument__c);
    }

    public static String getSuccessResponseBody(){
        return '{"Ret_cliente" :{"codigo_erp":"001442","codigo_crm":"0018900000HpaNqAWWW","STATUS":"OK-ALTERADO SA1","error_log":"" }}';
    }

    public static String getSuccessResponseBody(Boolean randomizeERPCode){
        if(!randomizeERPCode)
            return getSuccessResponseBody();

        Integer fakeERPCode = Integer.valueOf(Math.random()*1000000);

        return '{"Ret_cliente" :{"codigo_erp":"' + fakeERPCode + '","codigo_crm":"0018900000HpaNqAWWW","STATUS":"OK-ALTERADO SA1","error_log":"" }}';
    }

    private static Account fillRequiredFields(Account acc, String excecptField){
        if(excecptField == null)
            return acc;

        if(excecptField != 'Store')
            acc.Store__c = '01';

        return acc;
    }
}