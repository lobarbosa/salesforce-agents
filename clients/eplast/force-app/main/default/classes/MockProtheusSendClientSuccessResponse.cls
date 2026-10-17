@isTest
public with sharing class MockProtheusSendClientSuccessResponse implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest request){
        HttpResponse response = new HttpResponse();

        response.setStatusCode(201);

        response.setBody(SendAccountToProtheusTDF.getSuccessResponseBody());

        return response;
    }
}