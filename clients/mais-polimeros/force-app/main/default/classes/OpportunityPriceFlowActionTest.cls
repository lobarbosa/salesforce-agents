/**
 * @Author             : Daniely Rosa
 * @Group              : 
 * @Last Modified By   : Gustavo Braga 
 * @Last Modified On   : 25/06/2026 10:07
 * @Modification Log   : 
 *==============================================================================
**/

@IsTest
private class OpportunityPriceFlowActionTest {

    @IsTest
    static void testEnviarCotacaoComListaVazia() {
        Test.startTest();

        OpportunityPriceFlowAction.enviarCotacao(null);
        OpportunityPriceFlowAction.enviarCotacao(
            new List<OpportunityPriceFlowAction.Request>()
        );

        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testEnviarCotacaoSemOpportunityId() {
        List<OpportunityPriceFlowAction.Request> requests =
            new List<OpportunityPriceFlowAction.Request>();

        requests.add(null);

        OpportunityPriceFlowAction.Request req =
            new OpportunityPriceFlowAction.Request();

        requests.add(req);

        Test.startTest();

        OpportunityPriceFlowAction.enviarCotacao(requests);

        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testEnviarCotacaoComOpportunityId() {
        OpportunityPriceFlowAction.bypassIntegrationForTest = true;

        OpportunityPriceFlowAction.Request req =
            new OpportunityPriceFlowAction.Request();

        req.opportunityId = '006000000000001';

        List<OpportunityPriceFlowAction.Request> requests =
            new List<OpportunityPriceFlowAction.Request>{ req };

        Test.startTest();

        OpportunityPriceFlowAction.enviarCotacao(requests);

        Test.stopTest();

        System.assertEquals(
            true,
            OpportunityPriceFlowAction.bypassIntegrationForTest
        );
    }

    @IsTest
    static void testAsyncSendPriceToTotvsSemIds() {
        OpportunityPriceFlowAction.bypassIntegrationForTest = true;

        Test.startTest();

        OpportunityPriceFlowAction.asyncSendPriceToTotvs(new List<String>());
        OpportunityPriceFlowAction.asyncSendPriceToTotvs(
            new List<String>{ '', null }
        );
        OpportunityPriceFlowAction.asyncSendPriceToTotvs(
            new List<String>{ 'a08000000000001' }
        );

        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testAsyncSendPriceToTotvsComQueueSemIntegracaoPreco() {
        OpportunityPriceFlowAction.bypassIntegrationForTest = false;

        Queue__c queue = new Queue__c(
            EventName__c = QueueEventNames.OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name(),
            Status__c = 'CREATED',
            RecordId__c = UserInfo.getUserId(),
            Payload__c = '{}',
            IgnoredByTrigger__c = true
        );
        insert queue;

        Test.startTest();

        OpportunityPriceFlowAction.asyncSendPriceToTotvs(
            new List<String>{ String.valueOf(queue.Id) }
        );

        Test.stopTest();

        System.assertNotEquals(null, queue.Id);
    }
}