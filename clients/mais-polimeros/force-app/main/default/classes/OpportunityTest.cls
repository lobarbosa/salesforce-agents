@isTest()
global class OpportunityTest {

	@TestSetup
	static void makeData(){
		IntegrationParams__c param = new IntegrationParams__c(URI_API__c = '', URI_PriceProcessor__c = '');
		insert param;
	}

	global class MockHttpResponseGenerator implements HttpCalloutMock {
		Id itemId;
		global MockHttpResponseGenerator(Id itemId){
			this.itemId = itemId;
		}
	    global HTTPResponse respond(HTTPRequest req) {	  
	        HttpResponse res   = new HttpResponse();
			IntegrationParams__c auth = [ SELECT URI_API__c, URI_PriceProcessor__c FROM IntegrationParams__c ];    
    		String endpoint    = (String)auth.get('URI_API__c');
			String uriStorage  = (String)auth.get('URI_PriceProcessor__c');

	        req.setEndpoint(endpoint += uriStorage);
	        req.setMethod('POST');
	        res.setHeader('Content-Type', 'application/json');
			res.setBody('{ "COTACOES": [{ "LIMITECREDITO":"58717", "LIMITECREDBV": "58717", "LIMITECREDSI": "58717", "MSGCREDITO":"Cliente com bloqueio de credito/cadastro", "BLOQUEIO":true, "OPERACAO":"INC", "ITENS": [{ "ITEM":"'+itemId+'", "PRODUTO":"ABS-AE8000", "FILIAL":"01", "TES":"521", "CONDICAOPAGAMENTO":"072", "QUANTIDADE":"25000", "VALORUNITARIOSEMIMP":"0", "VALORUNITARIOCOMIMP":"0", "VALORUNITARIOFRETE":"0.013", "COMISSAO":"0", "ICMS":"12", "IPI":"5", "QTDEATUAL":"40925", "QTDERESERVA":"7150", "QTDEDISPONIVEL":"33775", "QTDECOMPRAS":"0", "QTDESOLCOMPRAS":"0", "DATAULTIMASAI":"17/04/2019", "BLOQUEADOESTOQUE":"S" }] } ] }');

	        res.setStatusCode(201);
	        return res;
	    }
	}

	global class MockHttpResponseGeneratorError implements HttpCalloutMock {
	    global HTTPResponse respond(HTTPRequest req) {	  
	        HttpResponse res   = new HttpResponse();
			IntegrationParams__c auth = [ SELECT URI_API__c, URI_PriceProcessor__c FROM IntegrationParams__c ];    
    		String endpoint    = (String)auth.get('URI_API__c');
			String uriStorage  = (String)auth.get('URI_PriceProcessor__c');

	        req.setEndpoint( endpoint += uriStorage );
	        req.setMethod('POST');
	        res.setHeader('Content-Type', 'application/json');
			res.setBody('{"ERROR":"Chama o pedro que ele resolve","cCodStatus":"500","cDesStatus":"Internal Server ERROR"}');

	        res.setStatusCode(500);
	        return res;
	    }
	}

	global class MockHttpResponseGeneratorConsulta implements HttpCalloutMock {
		Id itemId;
		global MockHttpResponseGeneratorConsulta(Id itemId) {
			this.itemId = itemId;
		}
		global HTTPResponse respond(HTTPRequest req) {      
			HttpResponse res = new HttpResponse();
			IntegrationParams__c auth = [SELECT URI_API__c FROM IntegrationParams__c];    
			String endpoint = (String)auth.get('URI_API__c');
	
			req.setEndpoint(endpoint + '/CONSPED');
			req.setMethod('POST');
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"CONSULTA_PEDIDO": [{"CABECALHO": {"PEDIDO": "123456", "ITEM": "' + itemId + '"}}]}');
			res.setStatusCode(201);
			return res;
		}
	}


	@isTest
	static void testPreco()
	{
		Id lista		       	   = Test.getStandardPricebookId();
		Account conta              = InstanceToClassCoverage.conta('Conta para teste');
		UnidadeFilial__c filial    = InstanceToClassCoverage.filial();
		Product2 produto           = InstanceToClassCoverage.produto('ABS-AE8000');
		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
		Opportunity oportunidade   = InstanceToClassCoverage.oportunidade('Oportunidade para teste');

		insert condicaoPagamento;
		insert filial;
		insert conta;
		insert produto;

		oportunidade.AccountId         = conta.id;
		oportunidade.Unidade_Filial__c = filial.id;
		oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;
		insert oportunidade;

		List<PricebookEntry> pbel = [   SELECT  Id
								FROM    PricebookEntry
								WHERE   Product2Id      = :produto.Id
								AND     Pricebook2Id    = :lista       
								AND     isActive        = true      ];

		OpportunityLineItem itemDeLinha = new OpportunityLineItem( 	Product2Id = produto.Id, 
																	PricebookEntryId = pbel[0].Id,
																	UnitPrice = 20.00,
																	TESEditavel__c = '521',
																	PrecoUnitarioSImposto__c = 20.00,
																	Quantity = 25, 
																	OpportunityId = oportunidade.Id,
																	DataEntrega__c = System.today(),
																	ValorFrete__c = 1.00 ); 
		insert itemDeLinha;

		Boolean btnVisible = OpportunityProcessor.btnIsVisible(oportunidade.Id);
		Opportunity stage = OpportunityProcessor.oppStatus(oportunidade.Id);

		Queue__c queue = OpportunityProcessor.getPrecoOppQueue(oportunidade.Id);

		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(itemDeLinha.Id));
		

		Test.startTest();
			Queue__c queue1 = OpportunityProcessor.sendPriceToTotvs(queue);
		Test.stopTest();
	}
	
	@isTest
	static void testConversao()
	{
		Id lista		       	   = Test.getStandardPricebookId();
		Account conta              = InstanceToClassCoverage.conta('Conta para teste');
		UnidadeFilial__c filial    = InstanceToClassCoverage.filial();
		Product2 produto           = InstanceToClassCoverage.produto('ABS-AE8000');
		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
		Opportunity oportunidade   = InstanceToClassCoverage.oportunidade('Oportunidade para teste');

		insert condicaoPagamento;
		insert filial;
		insert conta;
		insert produto;

		oportunidade.AccountId         = conta.id;
		oportunidade.Unidade_Filial__c = filial.id;
		oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;
		insert oportunidade;

		List<PricebookEntry> pbel = [   SELECT  Id
								FROM    PricebookEntry
								WHERE   Product2Id      = :produto.Id
								AND     Pricebook2Id    = :lista       
								AND     isActive        = true      ];

		OpportunityLineItem itemDeLinha = new OpportunityLineItem( 	Product2Id = produto.Id,
																	PricebookEntryId = pbel[0].Id,
																	UnitPrice = 20.00,
																	TESEditavel__c = '521',
																	PrecoUnitarioSImposto__c = 20.00,
																	Quantity = 25,
																	OpportunityId = oportunidade.Id,
																	DataEntrega__c = System.today(),
																	IPI__C = 0,
																	ValorFrete__c = 1.00 ); 
		insert itemDeLinha;

		Queue__c queue = OpportunityProcessor.converteOportunidade(oportunidade.Id);

		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(itemDeLinha.Id));

		Test.startTest();
			Queue__c queue1 = OpportunityProcessor.sendOrderToTotvs(queue);
		Test.stopTest();
	}

	@IsTest
	static void testOpportunityDAOMethods() {
		Id lista = Test.getStandardPricebookId();
		Account conta = InstanceToClassCoverage.conta('Conta para teste');
		UnidadeFilial__c filial = InstanceToClassCoverage.filial();
		Product2 produto = InstanceToClassCoverage.produto('ABS-AE8000');
		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
		Opportunity oportunidade = InstanceToClassCoverage.oportunidade('Oportunidade para teste');

		insert condicaoPagamento;
		insert filial;
		insert conta;
		insert produto;

		oportunidade.AccountId = conta.id;
		oportunidade.Unidade_Filial__c = filial.id;
		oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;
		insert oportunidade;

		List<PricebookEntry> pbel = [SELECT Id
									FROM PricebookEntry
									WHERE Product2Id = :produto.Id
									AND Pricebook2Id = :lista       
									AND isActive = true];

		OpportunityLineItem itemDeLinha = new OpportunityLineItem(
			Product2Id = produto.Id,
			PricebookEntryId = pbel[0].Id,
			UnitPrice = 20.00,
			TESEditavel__c = '521',
			PrecoUnitarioSImposto__c = 20.00,
			Quantity = 25,
			OpportunityId = oportunidade.Id,
			DataEntrega__c = System.today(),
			IPI__c = 0,
			ValorFrete__c = 1.00
		);
		insert itemDeLinha;

		Test.startTest();

		// Test getAllOpItems
		List<OpportunityLineItem> items = OpportunityDAO.getInstance().getAllOpItems(oportunidade.Id);
		System.assertEquals(1, items.size(), 'Should return one opportunity line item');
		System.assertEquals(itemDeLinha.Id, items[0].Id, 'Should return the correct opportunity line item');

		// Test getOpportunityIntegration
		Opportunity oppResult = OpportunityDAO.getInstance().getOpportunityIntegration(oportunidade.Id);
		System.assertEquals(oportunidade.Id, oppResult.Id, 'Should return the correct opportunity');
		System.assertEquals(conta.Id, oppResult.AccountId, 'Should return opportunity with correct account');
		System.assertEquals(filial.Id, oppResult.Unidade_Filial__c, 'Should return opportunity with correct branch');

		// Test getProduto
		String prodId = OpportunityDAO.getInstance().getProduto('ABS-AE8000');
		System.assertEquals(produto.Id, prodId, 'Should return the correct product Id');

		// Test getItensForPrice
		List<OpportunityLineItem> priceItems = OpportunityDAO.getInstance().getItensForPrice(oportunidade.Id);
		System.assertEquals(1, priceItems.size(), 'Should return one item for price');
		System.assertEquals(itemDeLinha.Id, priceItems[0].Id, 'Should return the correct item for price');

		// Test getAccountId
		String accountId = OpportunityDAO.getInstance().getAccountId(oportunidade.Id);
		System.assertEquals(conta.Id, accountId, 'Should return the correct account Id');

		Test.stopTest();
	}

	@IsTest
	static void testChecaPedidoDuplicado() {
		Id lista = Test.getStandardPricebookId();
		Account conta = InstanceToClassCoverage.conta('Conta para teste');
		UnidadeFilial__c filial = InstanceToClassCoverage.filial();
		Product2 produto = InstanceToClassCoverage.produto('ABS-AE8000');
		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
		Opportunity oportunidade = InstanceToClassCoverage.oportunidade('Oportunidade para teste');

		insert condicaoPagamento;
		insert filial;
		insert conta;
		insert produto;

		oportunidade.AccountId = conta.id;
		oportunidade.Unidade_Filial__c = filial.id;
		oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;
		insert oportunidade;

		Order ord = new Order(
			AccountId = conta.Id,
			EffectiveDate = System.today(),
			Status = 'Draft',
			OpportunityId = oportunidade.Id,
			Pricebook2Id = lista
		);
		insert ord;

		List<PricebookEntry> pbel = [SELECT Id
									FROM PricebookEntry
									WHERE Product2Id = :produto.Id
									AND Pricebook2Id = :lista       
									AND isActive = true];

		OrderItem item = new OrderItem(
			OrderId = ord.Id,
			PricebookEntryId = pbel[0].Id,
			Quantity = 1,
			UnitPrice = 100
		);
		insert item;

		Test.startTest();

		// Test successful scenario
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorConsulta(item.Id));
		String result = OpportunityProcessor.checaPedidoDuplicado(oportunidade.Id);
		System.assertEquals('123456', result, 'Should return the correct pedido number');

		// Test error scenario
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError());
		try {
			result = OpportunityProcessor.checaPedidoDuplicado(oportunidade.Id);
			System.assert(false, 'Should have thrown an exception');
		} catch(OpportunityProcessor.IntegrationException e) {
			System.assertEquals('Erro ao verificar duplicidade do Pedido!', e.getMessage(), 'Should return the correct exception message');
		}

		// Test scenario with no OrderItems
		Opportunity oppNoOrder = InstanceToClassCoverage.oportunidade('Test Opp No Order');
		oppNoOrder.AccountId = conta.Id;
		oppNoOrder.CondicaoPagamento__c = condicaoPagamento.Id;
		insert oppNoOrder;
		
		result = OpportunityProcessor.checaPedidoDuplicado(oppNoOrder.Id);
		System.assertEquals('', result, 'Should return empty string when no order items exist');
		
		Test.stopTest();
	}

}