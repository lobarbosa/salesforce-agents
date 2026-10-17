@isTest public class BatchCurvaABCTest {
    
    @TestSetup 
    public static void setupData (){
        Municipio__c municipio = new Municipio__c(
            Name = 'MUNICIPIO'
            
        );
        insert municipio;
        
        Account acc = new Account(
            Name                = 'ACC TESTE',
            NomeFantasia__c = 'nome fantasia',
            Municipio__c        = municipio.Id, 
            MunicipioEntrega__c = municipio.Id,
            Classificacao__c    = 'Tipo A'
        );
        insert acc;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Pricebook2 catalogo = new Pricebook2(
            IsActive    = true,
            Name        = 'CATALOGO'
            
        ); 
        insert catalogo;
        
        Product2 produto = new Product2(
            Name            = 'PRODUTO',
            CodigoTotvs__c  = '0000000000000000000000'
        );
        insert produto;
        
        PricebookEntry entradaCatalogo = new PricebookEntry(
            IsActive            = true,
            Pricebook2Id        = catalogo.Id,
            Product2Id          = produto.Id,
            UnitPrice           = 10,
            UseStandardPrice    = false
        );
        insert entradaCatalogo;
        
         Order ordem = new Order(

                AccountId       = acc.Id,
                EffectiveDate   = Date.valueOf(DateTime.now().addMonths(1)),
                Status          = 'Faturamento',
                Pricebook2Id    = catalogo.Id,
             createdDate = Date.Today().addDays(-5)

            );
         
        insert ordem;
        
    }
    
    @isTest 
    public static void test(){
        Test.startTest();
        
        BatchCurvaABC x = new BatchCurvaABC();
        
        database.executeBatch(x);
        
        Test.stopTest();
        
    }
}