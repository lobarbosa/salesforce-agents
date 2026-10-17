public without sharing class OpportunityPriceFlowAction {

    @TestVisible
    private static Boolean bypassIntegrationForTest = false;

    public class Request {
        @InvocableVariable(required=true label='Opportunity Id')
        public Id opportunityId;
    }

    @InvocableMethod(
        label='Enviar Cotação para Protheus'
        description='Cria a fila de cotação da oportunidade e envia para o Protheus.'
    )
    public static void enviarCotacao(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        List<String> queueIds = new List<String>();

        for (Request req : requests) {
            if (req == null || req.opportunityId == null) {
                continue;
            }

            if (Test.isRunningTest() && bypassIntegrationForTest) {
                queueIds.add(String.valueOf(req.opportunityId));
                continue;
            }

            Queue__c queue = OpportunityProcessor.getPrecoOppQueue(req.opportunityId);

            if (queue != null && queue.Id != null) {
                queueIds.add(String.valueOf(queue.Id));
            }
        }

        if (!queueIds.isEmpty()) {
            if (Test.isRunningTest() && bypassIntegrationForTest) {
                return;
            }

            asyncSendPriceToTotvs(queueIds);
        }
    }

    @future(callout=true)
    public static void asyncSendPriceToTotvs(List<String> queueIds) {
        if (queueIds == null || queueIds.isEmpty()) {
            return;
        }

        Set<Id> queueIdSet = new Set<Id>();

        for (String queueId : queueIds) {
            if (String.isNotBlank(queueId)) {
                queueIdSet.add((Id) queueId);
            }
        }

        if (queueIdSet.isEmpty()) {
            return;
        }

        if (Test.isRunningTest() && bypassIntegrationForTest) {
            return;
        }

        List<Queue__c> queues = [
            SELECT Id, RecordId__c, EventName__c, Payload__c
            FROM Queue__c
            WHERE Id IN :queueIdSet
        ];

        for (Queue__c queue : queues) {
            OpportunityIntegrationBO.executeQueue(
                String.valueOf(queue.Id),
                String.valueOf(queue.RecordId__c),
                queue.EventName__c,
                queue.Payload__c
            );
        }
    }
}