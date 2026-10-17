@isTest
private class WSTotvsTest {
    private static final String MOCK_RESPONSE_BODY = '{"success": true}';
    private static final Integer TIMEOUT = 120000;
    
    @TestSetup
    static void setupTestData() {
        IntegrationParams__c params = new IntegrationParams__c();
        params.URI_API__c = 'https://api.test.com';
        params.URI_PriceProcessor__c = '/price';
        params.URI_StorageProcessor__c = '/storage';
        params.URI_ClientProcessor__c = '/client';
        params.URI_OrderProcessor__c = '/order';
        params.URI_FreteProcessor__c = '/frete';
        insert params;
    }
    
    @isTest
    static void testPriceProcessorSuccess() {
        Test.setMock(HttpCalloutMock.class, new WSTotvsHttpMock(200, MOCK_RESPONSE_BODY));
        
        Test.startTest();
        WSTotvs ws = new WSTotvs('priceProcessor', '{"test": "data"}');
		String response = ws.Invoke();
        Test.stopTest();
        
        System.assertEquals(MOCK_RESPONSE_BODY, response, 'Response should match mock response');
    }
    
    @isTest
    static void testPriceProcessorFailure() {
        Test.setMock(HttpCalloutMock.class, new WSTotvsHttpMock(500, ''));
        
        Test.startTest();
        WSTotvs ws = new WSTotvs('priceProcessor', '{"test": "data"}');
		String response = ws.Invoke();
        Test.stopTest();
        
        System.assertEquals('500', response, 'Should return 500 status code as string');
    }
    
    @isTest
    static void testEstoqueProcessorSuccess() {
        Test.setMock(HttpCalloutMock.class, new WSTotvsHttpMock(200, MOCK_RESPONSE_BODY));
        
        Test.startTest();
        WSTotvs ws = new WSTotvs('priceProcessor', '{"test": "data"}');
		String response = ws.Invoke();
        Test.stopTest();
        
        System.assertEquals(MOCK_RESPONSE_BODY, response, 'Response should match mock response');
    }
    
    @isTest
    static void testAccountProcessorSuccess() {
        Test.setMock(HttpCalloutMock.class, new WSTotvsHttpMock(200, MOCK_RESPONSE_BODY));
        
        Test.startTest();
        WSTotvs ws = new WSTotvs('priceProcessor', '{"test": "data"}');
		String response = ws.Invoke();
        Test.stopTest();
        
        System.assertEquals(MOCK_RESPONSE_BODY, response, 'Response should match mock response');
    }
    
    @isTest
    static void testOpportunityProcessorSuccess() {
        Test.setMock(HttpCalloutMock.class, new WSTotvsHttpMock(200, MOCK_RESPONSE_BODY));
        
        Test.startTest();
        WSTotvs ws = new WSTotvs('priceProcessor', '{"test": "data"}');
		String response = ws.Invoke();
        Test.stopTest();
        
        System.assertEquals(MOCK_RESPONSE_BODY, response, 'Response should match mock response');
    }
    
    @isTest
    static void testFreteProcessorSuccess() {
        Test.setMock(HttpCalloutMock.class, new WSTotvsHttpMock(200, MOCK_RESPONSE_BODY));
        
        Test.startTest();
        WSTotvs ws = new WSTotvs('priceProcessor', '{"test": "data"}');
		String response = ws.Invoke();
        Test.stopTest();
        
        System.assertEquals(MOCK_RESPONSE_BODY, response, 'Response should match mock response');
    }
    
    private class WSTotvsHttpMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public WSTotvsHttpMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
}