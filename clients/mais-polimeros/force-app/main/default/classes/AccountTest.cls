@isTest
global class AccountTest {

    @testSetup static void setup() {
        IntegrationParams__c param = new IntegrationParams__c(URI_API__c = '', URI_PriceProcessor__c = '');
		insert param;
    }

	global class MockHttpResponseConta implements HttpCalloutMock {
	    global HTTPResponse respond(HTTPRequest req) {	  

	        HttpResponse res   = new HttpResponse();
			IntegrationParams__c auth = [ SELECT URI_API__c, URI_OrderProcessor__c FROM IntegrationParams__c ];    
    		String endpoint    = (String)auth.get('URI_API__c');
			String uriStorage  = (String)auth.get('URI_OrderProcessor__c');

	        req.setEndpoint(endpoint += uriStorage);
	        req.setMethod('POST');
	        res.setHeader('Content-Type', 'application/json');
			res.setBody('{"CLIENTES": [{ "CLIENTE": [{ "CODIGO":"00000601", "EMAILNFE":"josef.plasticos@hotmail.com", "MENSAGEM":"Cliente Alterado com sucesso!" }] } ] }');
	        res.setStatusCode(201);
	        return res;
	    }
	}

	global class MockHttpResponseInfoFinanceira implements HttpCalloutMock {
	    global HTTPResponse respond(HTTPRequest req) {	  

	        HttpResponse res   = new HttpResponse();
			IntegrationParams__c auth = [ SELECT URI_API__c, URI_OrderProcessor__c FROM IntegrationParams__c ];    
    		String endpoint    = (String)auth.get('URI_API__c');
			String uriStorage  = 'USDBAPICLI';
			// res.setBody('{"PEDIDOS": [{ "CABECALHO": { "PEDVEN":"173878", "PEDREM":"",	"MENSAGEM":"Pedido(s) incluido(s) com sucesso!", "BLOQCREDITO":"ATENCAO! Pedido com Bloqueio de credito!", "BLOQUEIO":true }, "ITENS": [ {	"ITEM":"1", "ID":"8022T000001GCpSQAW", "STATUS":"Nao faturado" } ] } ] }');
	        req.setEndpoint(endpoint += uriStorage);
	        req.setMethod('POST');
	        res.setHeader('Content-Type', 'application/json');
			res.setBody('{"cliente":[{"credDisp":"472524.18", "limitTotal":"511500", "proxVencmento":"14/04/20", "statusCliente":"true", "totalAberto":"38975.82", "totalAtrasado":"0"}]}');
	        res.setStatusCode(201);
	        return res;
	    }
	}

	global class MockHttpResponseContaErro implements HttpCalloutMock {
	    global HTTPResponse respond(HTTPRequest req) {	  

	        HttpResponse res   = new HttpResponse();
			IntegrationParams__c auth = [ SELECT URI_API__c, URI_OrderProcessor__c FROM IntegrationParams__c ];    
    		String endpoint    = (String)auth.get('URI_API__c');
			String uriStorage  = (String)auth.get('URI_OrderProcessor__c');

	        req.setEndpoint(endpoint += uriStorage);
	        req.setMethod('POST');
	        res.setHeader('Content-Type', 'application/json');
			res.setBody('{"CLIENTES": [{ "CLIENTE": [{ "CODIGO":"00000601", "EMAILNFE":"josef.plasticos@hotmail.com", "MENSAGEM":"Cliente Alterado com sucesso!" }] } ] }');
	        res.setStatusCode(500);
	        return res;
	    }
	}

    @isTest
    static void successUpdateAccount() {

        Account conta = InstanceToClassCoverage.conta('Conta para teste');
        insert conta;
        conta.observacoes__c = 'Teste Update';

        Test.setMock( HttpCalloutMock.class, new MockHttpResponseConta());

        Test.startTest();
            update conta;
        Test.stopTest();
    }

    @isTest
    static void errorUpdateAccount() {

        Account conta = InstanceToClassCoverage.conta('Conta para teste');
        insert conta;
        conta.observacoes__c = 'Teste Update';

        Test.setMock( HttpCalloutMock.class, new MockHttpResponseContaErro());

        Test.startTest();
            update conta;
        Test.stopTest();
    }

	@isTest
    static void buscaInfoFinanceira() {

        Account conta = InstanceToClassCoverage.conta('Conta para teste');
		insert conta;
		
		List<String> lstConta = new List<String>();
		lstConta.add(String.valueOf(conta.Id));

        Test.setMock( HttpCalloutMock.class, new MockHttpResponseInfoFinanceira());

        Test.startTest();
			AccountIntegrationBO.buscaEstoque(lstConta);
        Test.stopTest();
	}

	/**
	@isTest
    static void testRESTClienteSimple() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        String testPayload = '{ "cliente": [{ "cdCliente": "00000601", "limitTotal": "16032.52", "limitTotal_BV": "10000", "limitTotal_SF": "1000" }] }';
        
        req.requestBody = Blob.valueOf(testPayload);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            RESTCliente.doUpsert();
        Test.stopTest();

        System.assertNotEquals(null, RestContext.response.responseBody);
    } 
	*/
	
}