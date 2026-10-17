public with sharing class BrasilAPI {
    private static String URL = 'https://brasilapi.com.br/api';

    public static CNPJBrasilAPISearchResponse searchCNPJ(String cnpj){
        HttpRequest request = buildRequest('GET', URL + '/cnpj/v1/' + AccountUtility.cleanCNPJ(cnpj));
        request.setTimeout(30000);

        HttpResponse response = new Http().send(request);

        Logger.save('Consulta CNPJ', request, response);

        if(response.getStatusCode() != 200)
            return null;

        return (CNPJBrasilAPISearchResponse) JSON.deserialize(response.getBody(), CNPJBrasilAPISearchResponse.class);
    }

    private static HttpRequest buildRequest(String method, String endpoint){
        HttpRequest request = new HttpRequest();

        request.setMethod(method);
        request.setEndpoint(endpoint);

        return request;
    }
}