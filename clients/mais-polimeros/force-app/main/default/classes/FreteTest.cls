@isTest()
global class FreteTest {
	
	@TestSetup
	static void makeData(){
		IntegrationParams__c param = new IntegrationParams__c(URI_API__c = '', URI_PriceProcessor__c = '');
		insert param;
	}

	@isTest static void test_method_one() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		UnidadeFilial__c uniFilial = InstanceToClassCoverage.unidadeFilial('Teste');
		insert uniFilial;
		Account conta = InstanceToClassCoverage.conta('TesteFrete');
		insert conta;
		Frete__c frete = new Frete__c(Quantidade__c = 13750, UnidadeFilial__c = uniFilial.Id, Cliente__c = conta.Id );
		Test.startTest();
		insert frete;
		Test.stopTest();
	}

	global class MockHttpResponseGenerator implements HttpCalloutMock {
	    global HTTPResponse respond(HTTPRequest req) {	  
	        HttpResponse res   = new HttpResponse();
			IntegrationParams__c auth = [ SELECT URI_API__c, URI_FreteProcessor__c FROM IntegrationParams__c ];    
    		String endpoint    = (String)auth.get('URI_API__c');
			String uriStorage  = (String)auth.get('URI_FreteProcessor__c');

	        req.setEndpoint(endpoint += uriStorage);
	        req.setMethod('POST');
	        res.setHeader('Content-Type', 'application/json');
			res.setBody('{ "CALCFRETE": [{ "VALOR":"0.07073455" } ] }');

	        res.setStatusCode(201);
	        return res;
	    }
	}
	
}