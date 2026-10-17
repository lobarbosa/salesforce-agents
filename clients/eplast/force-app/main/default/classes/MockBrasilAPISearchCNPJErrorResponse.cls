@isTest
public with sharing class MockBrasilAPISearchCNPJErrorResponse implements HttpCalloutMock{
    public HttpResponse respond(HttpRequest request){
        HttpResponse response = new HttpResponse();

        response.setStatusCode(404);

        response.setBody(SearchAccountInfoByCNPJTDF.createBrasilAPIErrorBodyResponse());

        return response;
    }
}