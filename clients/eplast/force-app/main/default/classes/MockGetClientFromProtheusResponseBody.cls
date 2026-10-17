@isTest
public with sharing class MockGetClientFromProtheusResponseBody implements HttpCalloutMock {
    private Boolean generateErrorResponse;

    public MockGetClientFromProtheusResponseBody(Boolean generateErrorResponse) {
        this.generateErrorResponse = generateErrorResponse;
    }

    public HttpResponse respond(HttpRequest request){
        HttpResponse response = new HttpResponse();

        response.setStatusCode(this.generateErrorResponse ? 400 : 200);
        response.setBody(this.generateErrorResponse ? GetClientFromProtheusTDF.getErrorResponseBody() : GetClientFromProtheusTDF.getSuccessResponseBody());

        return response;
    }
}