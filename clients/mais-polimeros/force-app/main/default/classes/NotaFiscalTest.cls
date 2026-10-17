@isTest
public class NotaFiscalTest {
    @IsTest
    static void test_method_one(){

		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
        UnidadeFilial__c filial    = InstanceToClassCoverage.filial();
		insert condicaoPagamento;
		insert filial;

        Id lista = Test.getStandardPricebookId();
        Product2 produto = InstanceToClassCoverage.produto('ABS-AE8000');
        insert produto;

        Account conta = InstanceToClassCoverage.conta('Conta para teste');
        conta.beeCnpj__CNPJ__c = '27865757000102';
        insert conta;

		Opportunity oportunidade = InstanceToClassCoverage.oportunidade('Oportunidade para teste');
        oportunidade.AccountId = conta.Id;
        oportunidade.Pricebook2Id = lista;
        oportunidade.Unidade_Filial__c = filial.id;
	    oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;
        insert oportunidade;

        // PricebookEntry produtoList = new PricebookEntry( UnitPrice = 10, Pricebook2Id = lista, Product2Id = produto.Id, isActive = true, UseStandardPrice = false ); 
		// insert produtoList;
        List<PricebookEntry> pbel = [   SELECT  Id
                                FROM    PricebookEntry
                                WHERE   Product2Id      = :produto.Id
                                AND     Pricebook2Id    = :lista       
                                AND     isActive        = true      ];

        OpportunityLineItem oppLine = new OpportunityLineItem( IPI__c = 5, OpportunityId = oportunidade.Id, CodigoTOTVSAutoInc__c = '1', Product2Id = produto.Id, Quantity = 10, UnitPrice = 1, PricebookEntryId = pbel[0].Id, DataEntrega__c = System.today(), ValorFrete__c = 1.00);
        insert oppLine;

        Queue__c queue = OpportunityProcessor.converteOportunidade(oportunidade.Id);
        OrderItem orderLine = [SELECT Id FROM OrderItem LIMIT 1];

        oppLine.Quantity = 10;
        oppLine.DataEntrega__c = System.today() + 7;
        update oppLine;
        
        oppLine.status__c = 'Cancelado';
        update oppLine;

        Test.startTest();
            RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf('{ "Invoices": [{ "clientCode": "'+conta.Codigo__c+'", "issueDate": "22/05/2019", "number": "118943 /1 - 0100650601", "total": "96832.31", "quantidadetotal": "13750", "status": "faturado", "items": [ { "itemId": "'+ orderLine.Id +'" } ] }	] }');
            RestContext.request = req;
			RestResponse res = new RestResponse();
			RestContext.response = res;
			RESTNotaFiscal.doUpsert();
        Test.stopTest();
        
    }
    @IsTest
    static void test_method_two(){
        Test.startTest();
            RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf('{ "Invoices": [{ "clientCode": "00650601", "issueDate": "22/05/2019", "number": "118943 /1 - 0100650601", "total": "96832.31", "quantidadetotal": "13750", "status": "faturado", "items": [ { "itemId": "error" } ] }	] }');
            RestContext.request = req;
			RestResponse res = new RestResponse();
			RestContext.response = res;
			RESTNotaFiscal.doUpsert();
        Test.stopTest();
        
    }

    @IsTest
    static void test_method_three(){

		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
        UnidadeFilial__c filial    = InstanceToClassCoverage.filial();
		insert condicaoPagamento;
		insert filial;

        Id lista = Test.getStandardPricebookId();
        Product2 produto = InstanceToClassCoverage.produto('ABS-AE8000');
        insert produto;

        Account conta = InstanceToClassCoverage.conta('Conta para teste');
        conta.beeCnpj__CNPJ__c = '27865757000102';
        insert conta;

		Opportunity oportunidade = InstanceToClassCoverage.oportunidade('Oportunidade para teste');
        oportunidade.AccountId = conta.Id;
        oportunidade.Pricebook2Id = lista;
        oportunidade.Unidade_Filial__c = filial.id;
	    oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;
        insert oportunidade;

        // PricebookEntry produtoList = new PricebookEntry( UnitPrice = 10, Pricebook2Id = lista, Product2Id = produto.Id, isActive = true, UseStandardPrice = false ); 
		// insert produtoList;
        List<PricebookEntry> pbel = [   SELECT  Id
                                FROM    PricebookEntry
                                WHERE   Product2Id      = :produto.Id
                                AND     Pricebook2Id    = :lista       
                                AND     isActive        = true      ];

        OpportunityLineItem oppLine = new OpportunityLineItem( IPI__c = 5, OpportunityId = oportunidade.Id, CodigoTOTVSAutoInc__c = '1', Product2Id = produto.Id, Quantity = 10, UnitPrice = 1, PricebookEntryId = pbel[0].Id, DataEntrega__c = System.today(), ValorFrete__c = 1.00);
        insert oppLine;

        Queue__c queue = OpportunityProcessor.converteOportunidade(oportunidade.Id);
        OrderItem orderLine = [SELECT Id FROM OrderItem LIMIT 1];

        oppLine.Quantity = 10;
        oppLine.DataEntrega__c = System.today() + 7;
        update oppLine;
        
        oppLine.status__c = 'Cancelado';
        update oppLine;

        Test.startTest();
            RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf('{ "Invoices": [{ "clientCode": "'+conta.Codigo__c+'", "issueDate": "22/05/2019", "number": "118943 /1 - 0100650601", "total": "96832.31", "quantidadetotal": "13750", "status": "faturado", "items": [ { "itemId": "'+ orderLine.Id +'" } ] }	] }');
            RestContext.request = req;
			RestResponse res = new RestResponse();
			RestContext.response = res;
			RESTNotaFiscalDevolucao.RESTNotaFiscalDevolucao();
        Test.stopTest();
        
    }

    @IsTest
    static void OrderDAOgetOrderItemByOppItemIdTeste(){

		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
        UnidadeFilial__c filial    = InstanceToClassCoverage.filial();
		insert condicaoPagamento;
		insert filial;

        Id lista = Test.getStandardPricebookId();
        Product2 produto = InstanceToClassCoverage.produto('ABS-AE8000');
        insert produto;

        Account conta = InstanceToClassCoverage.conta('Conta para teste');
        conta.beeCnpj__CNPJ__c = '27865757000102';
        insert conta;

		Opportunity oportunidade = InstanceToClassCoverage.oportunidade('Oportunidade para teste');
        oportunidade.AccountId = conta.Id;
        oportunidade.Pricebook2Id = lista;
        oportunidade.Unidade_Filial__c = filial.id;
	    oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;
        insert oportunidade;

        // PricebookEntry produtoList = new PricebookEntry( UnitPrice = 10, Pricebook2Id = lista, Product2Id = produto.Id, isActive = true, UseStandardPrice = false ); 
		// insert produtoList;
        List<PricebookEntry> pbel = [   SELECT  Id
                                FROM    PricebookEntry
                                WHERE   Product2Id      = :produto.Id
                                AND     Pricebook2Id    = :lista       
                                AND     isActive        = true      ];

        OpportunityLineItem oppLine = new OpportunityLineItem( IPI__c = 5, OpportunityId = oportunidade.Id, CodigoTOTVSAutoInc__c = '1', Product2Id = produto.Id, Quantity = 10, UnitPrice = 1, PricebookEntryId = pbel[0].Id, DataEntrega__c = System.today(), ValorFrete__c = 1.00);
        insert oppLine;

        Queue__c queue = OpportunityProcessor.converteOportunidade(oportunidade.Id);
        OrderItem orderLine = [SELECT Id FROM OrderItem LIMIT 1];

        oppLine.Quantity = 10;
        oppLine.DataEntrega__c = System.today() + 7;
        update oppLine;
        
        oppLine.status__c = 'Cancelado';
        update oppLine;

        Test.startTest();
            RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf('{ "Invoices": [{ "clientCode": "'+conta.Codigo__c+'", "issueDate": "22/05/2019", "number": "118943 /1 - 0100650601", "total": "96832.31", "quantidadetotal": "13750", "status": "faturado", "items": [ { "itemId": "'+ oppLine.Id +'" } ] }	] }');
            RestContext.request = req;
			RestResponse res = new RestResponse();
			RestContext.response = res;
			RESTNotaFiscalDevolucao.RESTNotaFiscalDevolucao();
        Test.stopTest();
        
    }

    @IsTest
    static void test_method_devolucaoNF_else_branch() {
        CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
        UnidadeFilial__c filial = InstanceToClassCoverage.filial();
        insert condicaoPagamento;
        insert filial;

        Id lista = Test.getStandardPricebookId();
        Product2 produto = InstanceToClassCoverage.produto('ABS-AE8000');
        insert produto;

        Account conta = InstanceToClassCoverage.conta('Conta para teste');
        conta.beeCnpj__CNPJ__c = '27865757000102';
        insert conta;

        Opportunity oportunidade = InstanceToClassCoverage.oportunidade('Oportunidade para teste');
        oportunidade.AccountId = conta.Id;
        oportunidade.Pricebook2Id = lista;
        oportunidade.Unidade_Filial__c = filial.id;
        oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;
        insert oportunidade;

        List<PricebookEntry> pbel = [SELECT Id
                                    FROM PricebookEntry
                                    WHERE Product2Id = :produto.Id
                                    AND Pricebook2Id = :lista       
                                    AND isActive = true];

        OpportunityLineItem oppLine = new OpportunityLineItem(
            IPI__c = 5, 
            OpportunityId = oportunidade.Id,
            CodigoTOTVSAutoInc__c = '1',
            Product2Id = produto.Id,
            Quantity = 10,
            UnitPrice = 1,
            PricebookEntryId = pbel[0].Id,
            DataEntrega__c = System.today(),
            ValorFrete__c = 1.00
        );
        insert oppLine;

        Queue__c queue = OpportunityProcessor.converteOportunidade(oportunidade.Id);
        
        OrderItem orderItem = [SELECT Id FROM OrderItem LIMIT 1];

        Test.startTest();
        RestRequest req = new RestRequest();
        String jsonBody = '{ "Invoices": [' +
            '{ "itemId": "' + orderItem.Id + '",' +
            '"quantidade": "5",' +
            '"valor": "500",' +
            '"data": "22/05/2023" }' +
            '] }';
        
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        RESTNotaFiscalDevolucao.RESTNotaFiscalDevolucao();
        Test.stopTest();
        
        List<OrderItem> newItems = [SELECT Id, Status__c, QuantidadeDevolvida__c, ValorDevolvido__c 
                                FROM OrderItem 
                                WHERE ItemOriginal__c = :orderItem.Id];
        
        System.assertEquals(1, newItems.size(), 'Um novo OrderItem devia ter sido criado');
        System.assertEquals('Devolvido', newItems[0].Status__c, 'Status devia ser "Devolvido"');
        System.assertEquals(5, newItems[0].QuantidadeDevolvida__c, 'Quantidade devia ser 5');
        System.assertEquals(500, newItems[0].ValorDevolvido__c, 'Valor devia ser 500');
    }

}