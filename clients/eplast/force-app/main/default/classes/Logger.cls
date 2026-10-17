public with sharing class Logger {

    public static void save(String integrationAction, HttpRequest request, HttpResponse response){
        saveLog(integrationAction, request, response);
    }

    private static void saveLog(String integrationAction, HttpRequest request, HttpResponse response){
        IntegrationLog__c log = new IntegrationLog__c();

        log.ExecutionDate__c = Datetime.now();
        log.IntegrationAction__c = integrationAction;
        log.Endpoint__c = request.getEndpoint();
        log.HttpMethod__c = request.getMethod();
        log.RequestBody__c = request.getBody();
        log.ResponseStatusCode__c = response.getStatusCode();
        log.ResponseBody__c = response.getBody();
        log.ResponseStatus__c = (response.getStatusCode() >= 300 ? 'Erro' : 'Sucesso') + '(' + response.getStatus() + ')';

        insert log;
    }
}