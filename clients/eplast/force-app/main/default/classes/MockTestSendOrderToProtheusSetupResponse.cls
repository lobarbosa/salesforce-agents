@isTest
public with sharing class MockTestSendOrderToProtheusSetupResponse implements HttpCalloutMock {
    private Boolean randomizeAccountERPCode;

    public MockTestSendOrderToProtheusSetupResponse(){
        this.randomizeAccountERPCode = false;
    }

    public MockTestSendOrderToProtheusSetupResponse(Boolean randomizeAccountERPCode){
        this.randomizeAccountERPCode = randomizeAccountERPCode;
    }

    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        String endpoint = request.getEndpoint();

        if(endpoint.contains('brasilapi'))
            return mockBrasilAPIResponse(response);
            
        // URL contains 'WSEPLCLI' and not '?param1', it's a request to send Account to Protheus
        if(endpoint.contains('WSEPLCLI') && !endpoint.contains('?param1'))
            return mockSendClientToProtheusResponse(response);

        // URL is to send Order to Protheus
        return mockSendOrdertOProtheusResponse(response);
    }

    private HttpResponse mockBrasilAPIResponse(HttpResponse response){
        response.setStatusCode(200);
        response.setBody(SearchAccountInfoByCNPJTDF.createBrasilAPICompanyWithEmptyQSASuccessBodyResponse());

        return response;
    }

    private HttpResponse mockSendClientToProtheusResponse(HttpResponse response){
        response.setStatusCode(201);
        response.setBody(SendAccountToProtheusTDF.getSuccessResponseBody(this.randomizeAccountERPCode));

        return response;
    }

    private HttpResponse mockSendOrderToProtheusResponse(HttpResponse response){
        response.setStatusCode(201);
        response.setBody(SendOrderToProtheusTDF.getSuccessResponseBody());

        return response;
    }
}