@isTest
public with sharing class GetClientFromProtheusTDF {
    
    public static Opportunity createOpportunity(Id accountId){
        Pricebook2 pb2 = new Pricebook2(
                Name = 'Catálogo Teste',
                IsActive = true
            );
            insert pb2;

            Id pricebookId = Test.getStandardPricebookId();
            Pricebook2 standardPricebook = new Pricebook2(
                Id = pricebookId,
                IsActive = true
            );
            update standardPricebook;

        return new Opportunity(
            Name = 'Dummy Opp',
            StageName = 'Amostra',
            CloseDate = Date.today(),
            Pricebook2Id = pricebookId,
            AccountId = accountId,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sale').getRecordTypeId()
        );
    }


    public static String getErrorResponseBody(){
        return '{"Mensagem":"Dados não encontrados"}';
    }

    public static String getSuccessResponseBody(){
        return '{"CodigoERP":"001444","Loja":"01","InscrEst":"","CredUso":"0","Cnae":"9492800","Inadimplente":"S"}';
    }
}