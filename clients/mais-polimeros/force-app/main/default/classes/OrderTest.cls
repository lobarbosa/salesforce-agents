@isTest()
global class OrderTest {

	@TestSetup
	static void makeData(){
		IntegrationParams__c param = new IntegrationParams__c(URI_API__c = '', URI_PriceProcessor__c = '');
		insert param;
	}

	global class MockHttpResponseGeneratorPedido implements HttpCalloutMock {
	    global HTTPResponse respond(HTTPRequest req) {	  
	        HttpResponse res   = new HttpResponse();
			IntegrationParams__c auth = [ SELECT URI_API__c, URI_OrderProcessor__c FROM IntegrationParams__c ];    
    		String endpoint    = (String)auth.get('URI_API__c');
			String uriStorage  = (String)auth.get('URI_OrderProcessor__c');

	        req.setEndpoint(endpoint += uriStorage);
	        req.setMethod('POST');
	        res.setHeader('Content-Type', 'application/json');
			res.setBody('{"PEDIDOS": [{ "CABECALHO": { "PEDVEN":"173878", "PEDREM":"",	"MENSAGEM":"Pedido(s) incluido(s) com sucesso!", "BLOQCREDITO":"ATENCAO! Pedido com Bloqueio de credito!", "BLOQUEIO":true }, "ITENS": [ {	"ITEM":"1", "ID":"8022T000001GCpSQAW", "STATUS":"Nao faturado" } ] } ] }');
	        res.setStatusCode(201);
	        return res;
	    }
	}
	@isTest static void test_method_one(){

		Id lista		       	   = Test.getStandardPricebookId();
		Account conta              = InstanceToClassCoverage.conta('Conta para teste');
		UnidadeFilial__c filial    = InstanceToClassCoverage.filial();
		Product2 produto           = InstanceToClassCoverage.produto('ABS-AE8000');
		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
		Opportunity oportunidade   = InstanceToClassCoverage.oportunidade('Oportunidade para teste');

		conta.beeCnpj__CNPJ__c = '27865757000102';

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

		oportunidade.ConferenciaOK__c = true;
		update oportunidade;

		Queue__c queue2 = OpportunityProcessor.converteOportunidade(oportunidade.Id);

		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorPedido());	
		Test.startTest();
		
			OpportunityProcessor.sendOrderToTotvs(queue2);

			ProcessControl.ignoredByTrigger = false;

			Order ord = [SELECT Id, CodigoTOTVS__c FROM Order LIMIT 1];
			system.debug('>> ord: ' + ord);
			ord.CodigoTOTVS__c = '000222';
			update ord;
			User usr = [SELECT Id FROM User WHERE Profile.Name='Supervisor vendas' AND IsActive=true LIMIT 1];
			System.runAs(usr) {
			OrderItem ordItem = [SELECT Id, OrderId, Status__c, CodigoPedidoTOTVS__c FROM OrderItem where OrderId = :ord.Id LIMIT 1];
			system.debug('>> ordItem: ' + ordItem);

			ordItem.Atualizar__c = true;
			update ordItem;

			ordItem.Status__c = 'Cancelado';
			ordItem.MotivoCancelamento__c = 'Preço Errado';
			update ordItem;
			}

			OrderItem newOrderItem = new OrderItem( Status__c = 'Nao Faturado', 
													Product2Id = produto.Id,
													PricebookEntryId = pbel[0].Id,
													UnitPrice = 20.00,
													TESEditavel__c = '521',
													PrecoUnitarioSImposto__c = 20.00,
													Quantity = 25,
													OrderId = ord.Id,
													DataEntrega__c = System.today(),
													PercentualIPI__C = 0,
													ValorFrete__c = 1.00); 
			insert newOrderItem;
		Test.stopTest();

	}
}