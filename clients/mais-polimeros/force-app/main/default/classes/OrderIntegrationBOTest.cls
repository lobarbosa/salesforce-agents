@isTest
global class OrderIntegrationBOTest {

    @TestSetup
	static void makeData() {
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

	global class MockHttpResponseGeneratorPedido2 implements HttpCalloutMock {
		Id itemId;
		global MockHttpResponseGeneratorPedido2(Id itemId) {
			this.itemId = itemId;
		}
	    global HTTPResponse respond(HTTPRequest req) {	  
	        HttpResponse res   = new HttpResponse();
			IntegrationParams__c auth = [ SELECT URI_API__c, URI_OrderProcessor__c FROM IntegrationParams__c ];    
    		String endpoint    = (String)auth.get('URI_API__c');
			String uriStorage  = (String)auth.get('URI_OrderProcessor__c');

	        req.setEndpoint(endpoint += uriStorage);
	        req.setMethod('POST');
	        res.setHeader('Content-Type', 'application/json');
			res.setBody('{"PEDIDOS": [{ "CABECALHO": { "PEDVEN":"173878", "PEDREM":"",	"MENSAGEM":"Pedido(s) incluido(s) com sucesso!", "BLOQCREDITO":"ATENCAO! Pedido com Bloqueio de credito!", "BLOQUEIO":true }, "ITENS": [ {	"ITEM":"1", "ID":"'+itemId+'", "STATUS":"Nao faturado" }, {	"ITEM":"2", "ID":"'+itemId+'", "STATUS":"Nao faturado" } ] } ] }');
	        res.setStatusCode(201);
	        return res;
	    }
	}

    global class MockHttpResponseGenerator implements HttpCalloutMock {
		Id itemId;
		global MockHttpResponseGenerator(Id itemId) {
			this.itemId = itemId;
		}
        global HTTPResponse respond(HTTPRequest req) {	  
	        HttpResponse res = new HttpResponse();
			IntegrationParams__c auth = [SELECT URI_API__c, URI_PriceProcessor__c FROM IntegrationParams__c];    
    		String endpoint = (String)auth.get('URI_API__c');
			String uriStorage = (String)auth.get('URI_PriceProcessor__c');

	        req.setEndpoint(endpoint += uriStorage);
	        req.setMethod('POST');
	        res.setHeader('Content-Type', 'application/json');
			res.setBody('{ "COTACOES": [{ "LIMITECREDITO":"58717", "MSGCREDITO":"Cliente com bloqueio de credito/cadastro", "BLOQUEIO":true, "OPERACAO":"INC", "ITENS": [{ "ITEM":"'+itemId+'", "PRODUTO":"ABS-AE8000", "FILIAL":"01", "TES":"521", "CONDICAOPAGAMENTO":"072", "QUANTIDADE":"25000", "VALORUNITARIOSEMIMP":"0", "VALORUNITARIOCOMIMP":"0", "VALORUNITARIOFRETE":"0.013", "COMISSAO":"0", "ICMS":"12", "IPI":"5", "QTDEATUAL":"40925", "QTDERESERVA":"7150", "QTDEDISPONIVEL":"33775", "QTDECOMPRAS":"0", "QTDESOLCOMPRAS":"0", "DATAULTIMASAI":"17/04/2019", "BLOQUEADOESTOQUE":"S" }] } ] }');

	        res.setStatusCode(201);
	        return res;
	    }
	}

    global class MockHttpResponseGeneratorError implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {	  
	        HttpResponse res = new HttpResponse();
			IntegrationParams__c auth = [SELECT URI_API__c, URI_PriceProcessor__c FROM IntegrationParams__c];    
    		String endpoint = (String)auth.get('URI_API__c');
			String uriStorage = (String)auth.get('URI_PriceProcessor__c');

	        req.setEndpoint( endpoint += uriStorage );
	        req.setMethod('POST');
	        res.setHeader('Content-Type', 'application/json');
			res.setBody('{"ERROR":"Chama o pedro que ele resolve","cCodStatus":"500","cDesStatus":"Internal Server ERROR"}');

	        res.setStatusCode(500);
	        return res;
	    }
	}

	
    @isTest
	static void test_method_one() {
		Id lista = Test.getStandardPricebookId();
		Account conta = InstanceToClassCoverage.conta('Conta para teste');
		UnidadeFilial__c filial = InstanceToClassCoverage.filial();
		Product2 produto = InstanceToClassCoverage.produto('ABS-AE8000');
		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
		Opportunity oportunidade = InstanceToClassCoverage.oportunidade('Oportunidade para teste');

		conta.beeCnpj__CNPJ__c = '27865757000102';
		insert condicaoPagamento;
		insert filial;
		insert conta;
		insert produto;

		oportunidade.AccountId = conta.id;
		oportunidade.Unidade_Filial__c = filial.id;
		oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;

		insert oportunidade;

		List<PricebookEntry> pbel = [SELECT  Id
									 FROM PricebookEntry
									 WHERE Product2Id = :produto.Id
									 AND Pricebook2Id = :lista       
									 AND isActive = true];

		OpportunityLineItem itemDeLinha = new OpportunityLineItem(Product2Id = produto.Id,
																  PricebookEntryId = pbel[0].Id,
																  UnitPrice = 20.00,
																  TESEditavel__c = '521',
																  PrecoUnitarioSImposto__c = 20.00,
																  Quantity = 25,
																  OpportunityId = oportunidade.Id,
																  DataEntrega__c = System.today(),
																  IPI__C = 0,
																  ValorFrete__c = 1.00); 
		insert itemDeLinha;

		Queue__c queue = OpportunityProcessor.converteOportunidade(oportunidade.Id);

		//OpportunityProcessor.desativaAvisoSincronizacao(oportunidade.Id);

		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(itemDeLinha.Id));

		Test.startTest();
			Queue__c queue1 = OpportunityProcessor.sendOrderToTotvs(queue);
		Test.stopTest();
	}

    @IsTest
    static void test_method_two() {

		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
        UnidadeFilial__c filial    = InstanceToClassCoverage.filial();
		insert condicaoPagamento;
		insert filial;

        Id lista = Test.getStandardPricebookId();
        Product2 produto = InstanceToClassCoverage.produto('ABS-AE8002');
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

        PricebookEntry produtoList = new PricebookEntry(UnitPrice = 10, Pricebook2Id = lista, Product2Id = produto.Id, isActive = true, UseStandardPrice = false); 
		//insert produtoList;
        List<PricebookEntry> pbel = [SELECT Id
                                	 FROM PricebookEntry
                                	 WHERE Product2Id = :produto.Id
                                	 AND Pricebook2Id = :lista       
                                	 AND isActive = true];

        OpportunityLineItem oppLine = new OpportunityLineItem(IPI__c = 5,
                                                              OpportunityId = oportunidade.Id,
                                                              CodigoTOTVSAutoInc__c = '1',
                                                              Product2Id = produto.Id,
                                                              Quantity = 10,
                                                              UnitPrice = 1,
                                                              PricebookEntryId = pbel[0].Id,
                                                              DataEntrega__c = System.today(),
                                                              ValorFrete__c = 1.00);
        insert oppLine;

        Queue__c queue = OpportunityProcessor.converteOportunidade(oportunidade.Id);
        OrderItem orderLine = [SELECT Id FROM OrderItem LIMIT 1];

        oppLine.Quantity = 10;
        oppLine.DataEntrega__c = System.today()+7;
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

    @isTest
    static void test_method_three() {

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

			OrderItem ordItem = [SELECT Id, OrderId, Status__c, CodigoPedidoTOTVS__c FROM OrderItem where OrderId = :ord.Id LIMIT 1];
			system.debug('>> ordItem: ' + ordItem);
			ordItem.Status__c = 'Cancelado';
			ordItem.MotivoCancelamento__c = 'Preço Errado';
			update ordItem;

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


	@IsTest
	static void executeQueue() {
		Final String payLoad = '{ "PEDIDO" : [ { "CABECALHO" : { "OPERACAO" : "INC", "PEDIDO1" : "", "PEDIDO2" : "", "OBS" : "", "COLETA" : "N", "TPFRETE" : "C", "TIPOCLI" : "S", "FILIAL" : "01", "CLIVEN" : "00184601", "CONDVENDA" : "262", "TRANSPORTA" : "", "TRIANGULAR" : "N", "CLIREM" : "", "CONDREMESSA" : "", "TESREMESSA" : "", "INFOADIC" : "", "DESPAC" : 0, "FORMAPAG" : "DP - Duplicata", "VENDEDOR" : "000145" }, "ITENS" : [ { "ITEM" : "1", "PRODUTO" : "ABS-FORM.AG100H", "ID" : "80288000001C1SnAAK", "TES" : "521", "QUANT" : 234.00, "PRECO" : 34.000, "DTENTREGA" : "2022-10-28 00:00:00", "COMISSAO" : 0, "NRPEDCLI" : "", "IPIPERCENT" : 0, "NRITEMCLI" : "", "FRETEUNIT" : 23.00 }, { "ITEM" : "2", "PRODUTO" : "ABS-FORM.AG1000", "ID" : "80288000001C1SoAAK", "TES" : "521", "QUANT" : 34.00, "PRECO" : 100.000, "DTENTREGA" : "2022-10-28 00:00:00", "COMISSAO" : 0, "NRPEDCLI" : "", "IPIPERCENT" : 0, "NRITEMCLI" : "", "FRETEUNIT" : 23.00 } ] } ] }';
		Account acc = InstanceToClassCoverage.conta('teste23');
		acc.beeCnpj__CNPJ__c = '27865757000102';
		insert acc;
		// Account acc2 = InstanceToClassCoverage.conta('teste23');
		// insert acc2;
		//Opportunity opp = new Opportunity();
		CondicaoPagamento__c cond = InstanceToClassCoverage.condicaoPagamento();
		insert cond;
		Opportunity oportunidade   = InstanceToClassCoverage.oportunidade('Oportunidade para teste');
		oportunidade.AccountId = acc.Id;
		oportunidade.CondicaoPagamento__c = cond.Id;
		insert oportunidade;

		Queue__c fila = new Queue__c();
		fila.RecordId__c = oportunidade.Id;
		fila.EventName__c = 'OPPORTUNIDADE_SALESFORCE_TO_TOTVS';
		fila.Payload__c = payLoad;
		insert fila;
		OrderIntegrationBO.executeQueue(fila.Id,fila.RecordId__c,fila.EventName__c,fila.Payload__c);
	}
    
    @isTest
	static void test_method_four() {
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

		System.debug('opp:'+oportunidade.Id);
		Order ord = [SELECT Id, CodigoTOTVS__c FROM Order  WHERE OpportunityId =:oportunidade.Id LIMIT 1];
		OrderItem ordItemPedido = [SELECT Id FROM OrderItem WHERE OrderId =:ord.Id LIMIT 1];
		System.debug('ordItemPedido:'+ordItemPedido);

		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorPedido2(ordItemPedido.Id));	
		Test.startTest();

			OpportunityProcessor.sendOrderToTotvs(queue2);

			ProcessControl.ignoredByTrigger = false;

			
			system.debug('>> ord: ' + ord);
			ord.CodigoTOTVS__c = '000222';
			update ord;
			// User usr = [SELECT Id FROM User WHERE Profile.Name='Gestor de Vendas' AND IsActive=true LIMIT 1];
			// System.runAs(usr) {
			OrderItem ordItem = [SELECT Id, OrderId, Status__c, CodigoPedidoTOTVS__c FROM OrderItem where OrderId = :ord.Id LIMIT 1];
			system.debug('>> ordItem: ' + ordItem);
			ordItem.Status__c = 'CREATED';
			ordItem.MotivoCancelamento__c = 'Preço Errado';
			update ordItem;
			// }

			OrderItem newOrderItem = new OrderItem( Status__c = 'CREATED', 
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
			OpportunityProcessor.sendOrderToTotvs(queue2);
		Test.stopTest();
	}
}