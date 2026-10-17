@isTest
global with sharing class MockBrasilAPISearchCNPJSuccessResponse implements HttpCalloutMock{
    private Boolean companyWithoutQSA;

    global MockBrasilAPISearchCNPJSuccessResponse(){
        this.companyWithoutQSA = false;
    }

    global MockBrasilAPISearchCNPJSuccessResponse(Boolean companyWithoutQSA){
        this.companyWithoutQSA = companyWithoutQSA;
    }

    global HttpResponse respond(HttpRequest request){
        HttpResponse response = new HttpResponse();

        response.setStatusCode(200);
        response.setBody(this.companyWithoutQSA ? SearchAccountInfoByCNPJTDF.createBrasilAPICompanyWithEmptyQSASuccessBodyResponse() : SearchAccountInfoByCNPJTDF.createBrasilAPISuccessBodyResponse());

        return response;
    }
}