@isTest
public with sharing class GetClientFromProtheusTDF {
    
    public static Opportunity createOpportunity(Id accountId){
        Pricebook2 pb2 = new Pricebook2(
            Name = 'TESTE EPLAST Apex Catalogo',
            IsActive = true,
            Account__c = accountId
        );
        insert pb2;

        return new Opportunity(
            Name = 'TESTE EPLAST Apex Oportunidade',
            StageName = 'Amostra',
            CloseDate = Date.today(),
            Pricebook2Id = pb2.Id,
            AccountId = accountId,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sale').getRecordTypeId()
        );
    }

    @isTest
    static void catalogoDaOportunidadePertenceAConta(){
        TriggerUtility.bypassTrigger = true;
        Account acc = new Account(
            Name = 'TESTE EPLAST Apex Catalogo',
            CompanyDocument__c = SearchAccountInfoByCNPJTDF.CNPJ_QUARTO
        );
        insert acc;

        Opportunity opp = createOpportunity(acc.Id);
        Pricebook2 pb = [SELECT Account__c FROM Pricebook2 WHERE Id = :opp.Pricebook2Id];
        Assert.areEqual(acc.Id, pb.Account__c);
    }


    public static String getErrorResponseBody(){
        return '{"Mensagem":"Dados não encontrados"}';
    }

    public static String getSuccessResponseBody(){
        return '{"CodigoERP":"001444","Loja":"01","InscrEst":"","CredUso":"0","Cnae":"9492800","Inadimplente":"S"}';
    }
}