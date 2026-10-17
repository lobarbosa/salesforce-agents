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
        //insert acc;
        return acc;
    }
    public static Account createSecAccount(){
        Account acc = new Account(
            Name = 'Test Sec Account',
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
        //insert acc;
        return acc;
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