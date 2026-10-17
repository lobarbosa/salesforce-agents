public with sharing class ProtheusRequest {

    public static RequestInfo post(String endpoint, Object body){
        HttpRequest request = buildRequest('POST', endpoint);

        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(body));

        return new RequestInfo(request, sendRequest(request));
    }

    public static RequestInfo get(String endpoint, Map<String, String> queryParams){
        HttpRequest request = buildRequest('GET', endpoint + buildParams(queryParams));

        return new RequestInfo(request, sendRequest(request));
    }

    private static HttpRequest buildRequest(String method, String endpoint){
        Protheus__mdt credentials = getCredentials();
        HttpRequest request = new HttpRequest();

        request.setMethod(method);
        request.setEndpoint(credentials.BaseURL__c + endpoint);
        request.setHeader('Authorization', getAuthentication(credentials));
        request.setTimeout(120000);

        return request;
    }

    private static HttpResponse sendRequest(HttpRequest request){
        HttpResponse response = (new Http()).send(request);
        
        return response;
    }

    private static Protheus__mdt getCredentials(){
        return [ SELECT BaseURL__c, User__c, Password__c FROM Protheus__mdt WHERE DeveloperName = 'Credentials' LIMIT 1 ];
    }

    private static String getAuthentication(Protheus__mdt credentials){
        Blob userAndPassBlob = Blob.valueOf(credentials.User__c + ':' + credentials.Password__c);

        return 'Basic ' +  EncodingUtil.base64Encode(userAndPassBlob);
    }

    private static String buildParams(Map<String, String> params){
        if(params == null || params.isEmpty())
            return '';

        String formatString = '?';
        String[] paramKeys = new String[params.keySet()];

        for(Integer index = 0; index < paramKeys.size(); index++)
            formatString += paramKeys.get(index) + '={' + index + '}' + (index == paramKeys.size() - 1 ? '' : '&');

        return String.format(formatString, params.values());
    }
}