@isTest()
global class EstoqueTest
{
	@TestSetup
	static void makeData(){
		IntegrationParams__c param = new IntegrationParams__c(URI_API__c = '', URI_PriceProcessor__c = '');
		insert param;
	}

	@isTest
	static void test1()
	{		
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

		List<Estoque__c> esList = new List<Estoque__c>(); 		
		UnidadeFilial__c filial = InstanceToClassCoverage.filial();
		Product2 Produto        = InstanceToClassCoverage.produto('ABS-AE8000X');

		insert filial;
		insert produto;

		Estoque__c estoque       = new Estoque__c();
		estoque.UnidadeFilial__c = filial.id;
		estoque.Produto__c       = produto.id;

		insert estoque;

		esList.add( estoque );

		EstoqueBO.getInstance().criaFilaIntegracaoInsert( esList );		

		Queue__c queue = InstanceToClassCoverage.QUEUE_ESTOQUE();
		insert queue;

		Test.startTest();
			EstoqueIntegrationBO.executeQueue(queue.id, estoque.id ,'ESTOQUE_SALESFORCE_TO_TOTVS', InstanceToClassCoverage.generateJSonEstoque());	
		Test.stopTest();
	}
	
	@isTest
	static void test2()
	{		
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError());

		List<Estoque__c> esList = new List<Estoque__c>(); 		
		UnidadeFilial__c filial = InstanceToClassCoverage.filial();
		Product2 Produto        = InstanceToClassCoverage.produto('ABS-AE8000X');

		insert filial;
		insert produto;

		Estoque__c estoque       = new Estoque__c();
		estoque.UnidadeFilial__c = filial.id;
		estoque.Produto__c       = produto.id;

		insert estoque;

		esList.add( estoque );

		EstoqueBO.getInstance().criaFilaIntegracaoInsert( esList );		

		Queue__c queue = InstanceToClassCoverage.QUEUE_ESTOQUE();
		insert queue;
		Test.startTest();
			EstoqueIntegrationBO.executeQueue(queue.id, estoque.id ,'ESTOQUE_SALESFORCE_TO_TOTVS', InstanceToClassCoverage.generateJSonEstoque());	
		Test.stopTest();
	}

	global class MockHttpResponseGenerator implements HttpCalloutMock {
	    global HTTPResponse respond(HTTPRequest req) {	  
	        HttpResponse res   = new HttpResponse();
			IntegrationParams__c auth = [ SELECT URI_API__c, URI_StorageProcessor__c FROM IntegrationParams__c ];    
    		String endpoint    = (String)auth.get('URI_API__c');
			String uriStorage  = (String)auth.get('URI_StorageProcessor__c');

	        req.setEndpoint(endpoint += uriStorage);
	        req.setMethod('POST');
	        res.setHeader('Content-Type', 'application/json');
			res.setBody('{"ESTOQUE":[{"ITENS":[{"PRODUTO":"ABS-AE8000X","FILIAL":"01","QTDEATUAL":"13750","QTDERESERVA":"0","QTDEDISPONIVEL":"13750","MENSAGEM":"OK"}]}]}');

	        res.setStatusCode(201);
	        return res;
	    }
	}

	global class MockHttpResponseGeneratorError implements HttpCalloutMock {
	    global HTTPResponse respond(HTTPRequest req) {	  
	        HttpResponse res   = new HttpResponse();
			IntegrationParams__c auth = [ SELECT URI_API__c, URI_StorageProcessor__c FROM IntegrationParams__c ];    
    		String endpoint    = (String)auth.get('URI_API__c');
			String uriStorage  = (String)auth.get('URI_StorageProcessor__c');

	        req.setEndpoint(endpoint += uriStorage);
	        req.setMethod('POST');
	        res.setHeader('Content-Type', 'application/json');
			res.setBody('{"ERROR":"Erro de teste","cCodStatus":"500","cDesStatus":"Internal Server ERROR"}');

	        res.setStatusCode(500);
	        return res;
	    }
	}
}