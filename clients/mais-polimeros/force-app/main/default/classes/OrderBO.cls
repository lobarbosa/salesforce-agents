public class OrderBO {

    // private static final OrderBO instance = new OrderBO();
    // private OrderBO(){}

    // public static OrderBO getInstance() {
    //     return instance;
    // }

    // public void criaFilaIntegracaoUpdate(List<OrderItem> newItens, Map<Id,OrderItem> oldItens){

    //     system.debug('>> Entrou - Criação de Fila');

    //     List<Queue__c> queues = new List<Queue__c>();

    //     for(OrderItem ordItem : newItens){

    //         system.debug('>> CodigoPedidoTOTVS__c : ' + ordItem.CodigoPedidoTOTVS__c);
    //         system.debug('>> CodigoTOTVSAutoInc__c : ' + ordItem.CodigoTOTVSAutoInc__c);

    //         if(String.isEmpty(ordItem.CodigoPedidoTOTVS__c))
    //             continue;

    //         system.debug('>> Status__c : ' + ordItem.Status__c);
    //         if(ordItem.Status__c.Equals('Cancelado')){

    //             system.debug('>> Entrou - Item Cancelado');

    //             queues.add(new Queue__c(
    //                     EventName__c = QueueEventNames.EXC_OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name(),
    //                     Status__c    = 'CREATED',
    //                     RecordId__c  = ordItem.OrderId,
    //                     Payload__c   = OrderIntegrationBO.getJsonRequestExc(ordItem),   
    //                     IgnoredByTrigger__c = false 
    //                     )
    //                 );
    //         }

    //         // && !oldItens.keySet().contains(ordItem.Id)
    //         if(oldItens == null ){

    //             system.debug('>> Entrou - Data Alterada');

    //             queues.add(new Queue__c(
    //                     EventName__c = QueueEventNames.ALT_OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name(),
    //                     Status__c    = 'CREATED',
    //                     RecordId__c  = ordItem.OrderId,
    //                     Payload__c   = OrderIntegrationBO.getJsonRequest(ordItem, 'INC'),
    //                     IgnoredByTrigger__c = false
    //                     )
    //                 );
    //         }
    //     }

    //     if(queues != null && !queues.isEmpty())
    //         insert queues;
    // }
}