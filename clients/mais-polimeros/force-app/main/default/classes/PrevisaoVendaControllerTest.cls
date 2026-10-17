@IsTest
public with sharing class PrevisaoVendaControllerTest {

    @TestSetup
    static void makeData(){

        Account acc = new Account(
            Name  = 'ACC TESTE',
            NomeFantasia__c = 'nome fantasia'           
        );
        insert acc;

        Product2 prd = new Product2 (
            Name = 'PRODUTO',
            CodigoTotvs__c  = '0000000000000000000000',
            IsActive = true
        );
        insert prd;

        Pricebook2 catalogo = new Pricebook2(
            IsActive = true,
            Name = 'CATALOGO'
        ); 
        insert catalogo;

        PricebookEntry entradaCatalogo = new PricebookEntry(
            IsActive = true,
            Pricebook2Id = catalogo.Id,
            Product2Id  = prd.Id,
            UnitPrice = 10,
            UseStandardPrice = false
        );
        insert entradaCatalogo;

        Order ordem = new Order (
            AccountId = acc.Id,
            EffectiveDate = Date.valueOf(DateTime.now().addMonths(-1)),
            Status = 'Draft',
            Pricebook2Id = catalogo.Id,
            Vendedor__c = UserInfo.getUserId()
        );
        insert ordem;

        OrderItem itemPedido = new OrderItem(
            OrderId = ordem.Id,
            Quantity = 10,
            UnitPrice = 10,
            Product2Id = prd.Id,
            Status__c = 'Faturado',
            PricebookEntryId = entradaCatalogo.Id,
            DataEntrega__c   = System.today().addDays(1)
        );
        insert itemPedido; 

        PrevisaoVenda__c pv = new PrevisaoVenda__c(
            Name = 'Previsão Teste',
            Ano__c = String.valueOf(Date.today().Year()),
            Mes__c = String.valueOf(Date.today().Month()),
            InicioPrenchimento__c = Date.today(),
            FimPreenchimento__c = Date.today().addMonths(1)
        );
        insert pv;

        ItemPrevisaoVenda__c ipv = new ItemPrevisaoVenda__c (
            PrevisaoVenda__c = pv.Id,
            Produto__c = prd.Id,
            Quantidade__c = 25,
            QuantidadeGO__c = 25,
            QuantidadePR__c = 25,
            QuantidadeSP__c = 25,
            QuantidadeSC__c = 25,
            QuantidadeRS__c = 25,
            QuantidadeRS08__c = 25
        );
        insert ipv;

    }

    @IsTest
    public static void mainTest(){

        String idPrevisao = [SELECT Id FROM PrevisaoVenda__c LIMIT 1]?.Id;
        String idProduto = [SELECT Id FROM Product2 LIMIT 1]?.Id;

        PrevisaoVendaController.getMesesPrevisao();
        PrevisaoVendaController.getLogins(idPrevisao);

        User u = [ SELECT Id, ByPassPB__c FROM User WHERE FirstName like '%dani%' ORDER BY CreatedDate LIMIT 1];
        System.runAs(u) {

            // Test.startTest();
                PrevisaoVendaController.getLogins(idPrevisao);
            // Test.stopTest();
        } 

        Map<Object,Object> mapFields = new Map<Object,Object>();
        mapFields.put('itemId', idProduto);
        mapFields.put('quantidadeGO', '50');
        mapFields.put('quantidadePR', '50');
        mapFields.put('quantidadeSC', '50');
        mapFields.put('quantidadeSP', '50');
        mapFields.put('quantidadeRS', '50');
        mapFields.put('quantidadeRS08', '50');

        Map<Object,Object> mapRecord = new Map<Object,Object>();
        mapRecord.put('fields', mapFields);

        List<Object> lstRecords = new List<Object>();
        lstRecords.add(mapRecord);

        PrevisaoVendaController.saveProdutos(idPrevisao, UserInfo.getUserId(), lstRecords);
        PrevisaoVendaController.getPrevisao(idPrevisao, UserInfo.getUserId(), true);
        PrevisaoVendaController.getPrevisao(idPrevisao, UserInfo.getUserId(), false);

    }

}