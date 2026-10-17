@isTest()
global class QuoteTest
{
	@TestSetup
	static void makeData(){
		IntegrationParams__c param = new IntegrationParams__c(URI_API__c = '', URI_PriceProcessor__c = '');
		insert param;
	}

	@isTest
	static void test1()
	{
		
		Account conta              = InstanceToClassCoverage.conta('Conta para teste');
		Opportunity oportunidade   = InstanceToClassCoverage.oportunidade('Oportunidade para teste');
		UnidadeFilial__c filial    = InstanceToClassCoverage.filial();
		Quote cotacao              = InstanceToClassCoverage.cotacao('Cotacao para teste');
		Product2 produto           = InstanceToClassCoverage.produto('ABS-AE8000Z');
		Id lista		       	   = Test.getStandardPricebookId();		
		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();

		insert condicaoPagamento;
		insert filial;
		insert conta;
		insert produto;

		oportunidade.AccountId         = conta.id;
		oportunidade.Unidade_Filial__c = filial.id;
		oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;
		
		insert oportunidade;
		oportunidade.StageName = 'Negociação';
		update oportunidade;

		cotacao.Pricebook2Id   = lista;
		cotacao.OpportunityId  = oportunidade.id;
		insert cotacao;

		// PricebookEntry produtoList = new PricebookEntry( UnitPrice = 10, Pricebook2Id = lista, product2Id = produto.Id, isActive = true, UseStandardPrice = false ); 
		// insert produtoList;

        List<PricebookEntry> pbel = [   SELECT  Id
                                        FROM    PricebookEntry
                                        WHERE   Product2Id      = :produto.Id
                                        AND     Pricebook2Id    = :lista       
                                        AND     isActive        = true      ];

		QuoteLineItem itemDeLinha = new QuoteLineItem( Product2Id = produto.Id, PricebookEntryId = pbel[0].Id, UnitPrice = 20.00, TESEditavel__c = '521', PrecoUnitarioSImposto__c = 20.00, Quantity = 25, QuoteId = cotacao.Id ); 
		insert itemDeLinha;

		cotacao.Status = 'Negociação';
		update cotacao;
		
		Queue__c queue = QuoteBO.getInstance().criaFilaIntegracaoInsert( cotacao );		
		QuoteDAO.getInstance().getAllFields( cotacao.Id );
		QuoteDAO.getInstance().getAllQuoteLineItem( cotacao.Id );
		QuoteDAO.getInstance().getProduto( 'ABS-AE8000Z' );
		QuoteDAO.getInstance().getTES( cotacao );

		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(itemDeLinha.Id));

		Test.startTest();
			QuoteIntegrationBO.executeQueue(queue.id, cotacao.id ,queue.EventName__c, queue.payload__c);	
		Test.stopTest();
	}
	
	@isTest
	static void test2()
	{
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError());
		
		Account conta              = InstanceToClassCoverage.conta('Conta para teste');
		Opportunity oportunidade   = InstanceToClassCoverage.oportunidade('Oportunidade para teste');
		UnidadeFilial__c filial    = InstanceToClassCoverage.filial();
		Quote cotacao              = InstanceToClassCoverage.cotacao('Cotacao para teste');
		Product2 produto           = InstanceToClassCoverage.produto('ABS-AE8000Z');
		Id lista		       	   = Test.getStandardPricebookId();	
		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();	
		
		insert condicaoPagamento;
		insert filial;
		insert conta;
		insert produto;

		oportunidade.AccountId         = conta.id;
		oportunidade.Unidade_Filial__c = filial.id;
		oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;
		
		insert oportunidade;
		oportunidade.StageName = 'Negociação';
		update oportunidade;

		cotacao.Pricebook2Id   = lista;
		cotacao.OpportunityId  = oportunidade.id;
		insert cotacao;

		// PricebookEntry produtoList = new PricebookEntry( UnitPrice = 10, Pricebook2Id = lista, product2Id = produto.Id, isActive = true, UseStandardPrice = false ); 
		// insert produtoList;

        List<PricebookEntry> pbel = [   SELECT  Id
                                        FROM    PricebookEntry
                                        WHERE   Product2Id      = :produto.Id
                                        AND     Pricebook2Id    = :lista       
                                        AND     isActive        = true      ];

		QuoteLineItem itemDeLinha = new QuoteLineItem( Product2Id = produto.Id, PricebookEntryId = pbel[0].Id, UnitPrice = 15, TESEditavel__c = '521', PrecoUnitarioSImposto__c = 20.00, Quantity = 25, QuoteId = cotacao.Id ); 
		insert itemDeLinha;

		itemDeLinha.Quantity = 26;
		update itemDeLinha;

		update cotacao;
		
		Queue__c queue = QuoteProcessorController.getQuoteQueue( cotacao.Id );		
		QuoteDAO.getInstance().getAllFields( cotacao.Id );
		QuoteDAO.getInstance().getAllQuoteLineItem( cotacao.Id );
		QuoteDAO.getInstance().getProduto( 'ABS-AE8000Z' );
		QuoteDAO.getInstance().getTES( cotacao );

		try{
			AccountDAO.getInstance().accountByTOTVS('error');
		}catch(Exception ex){
			
		}
		Boolean tstMessage = QuoteProcessorController.btnIsVisible(cotacao.Id);
		String message = QuoteProcessorController.getMessage(cotacao.Id);

		Test.startTest();
			queue = QuoteProcessorController.sendToTotvs(queue);	
			delete itemDeLinha;
		Test.stopTest();

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
			res.setBody('{ "COTACOES": [{ "LIMITECREDITO":"58717", "MSGCREDITO":"Cliente com bloqueio de credito/cadastro", "BLOQUEIO":true, "OPERACAO":"INC", "ITENS": [{ "ITEM":"'+itemId+'", "PRODUTO":"ABS-AE8000Z", "FILIAL":"01", "TES":"521", "CONDICAOPAGAMENTO":"072", "QUANTIDADE":"25000", "VALORUNITARIOSEMIMP":"0", "VALORUNITARIOCOMIMP":"0", "VALORUNITARIOFRETE":"0.013", "COMISSAO":"0", "ICMS":"12", "IPI":"5", "QTDEATUAL":"40925", "QTDERESERVA":"7150", "QTDEDISPONIVEL":"33775", "QTDECOMPRAS":"0", "QTDESOLCOMPRAS":"0", "DATAULTIMASAI":"17/04/2019", "BLOQUEADOESTOQUE":"S" }] } ] }');

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
}