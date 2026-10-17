public class OrderItemTriggerHandler {

	public List<OrderItem> oldList;
    public List<OrderItem> newList;
    public Map<Id,OrderItem> oldMap;
    public Map<Id,OrderItem> newMap;

    public void beforeInsert(){

        Set<String> setOrderId = new Set<String>();
        for(OrderItem ord : newList){
            setOrderId.add(ord.OrderId);
        }
        System.debug('setOrderId: ' + setOrderId);

        Map<String,Order> mapOrder = new Map<String,Order>();
        for(Order ord : [SELECT Id FROM Order WHERE Id IN :setOrderId AND SalesStoreId != NULL]){
            mapOrder.put(ord.Id, ord);
        }
        System.debug('mapOrder: ' + mapOrder);

        // OrderId = newOrder.Id,
        // Product2Id = oppItem.Product2Id,
        // PricebookEntryId = oppItem.PricebookEntryId,
        // Quantity = oppItem.Quantity,
        // UnitPrice = oppItem.UnitPrice,
        // Status__c = 'Nao faturado',
        // TESEditavel__c = oppItem.TESEditavel__c,
        // DataEntrega__c = oppItem.DataEntrega__c,
        // ComissaoEditavel__c = oppItem.ComissaoEditavel__c,
        // NumeroPediClin__c = oppItem.NumeroPediClin__c,
        // NumeroItemCli__c = oppItem.NumeroItemCli__c,
        // PercentualIPI__c = oppItem.IPI__c,
        // BloqueioCalcFrete__c = oppItem.BloqueioCalcFrete__c,
        // Comissao__c = oppItem.Comissao__c,
        // PercentualDesconto__c = oppItem.Desconto__c,
        // PercentualComissao__c = oppItem.Comissao__c,
        // PercentualICMS__c  = oppItem.Percent_ICMS__c,
        // PrecoUnitarioSImposto__c = oppItem.PrecoUnitarioSImposto__c,
        // ValorComissao__c = oppItem.ValorComissao__c,
        // ValorFrete__c = oppItem.ValorFrete__c,
        // Processo__c = (oppItem.Product2.Processo__c != null ? oppItem.Product2.Processo__c : null)

        for(OrderItem ordItem : newList){
            if(mapOrder.containsKey(ordItem.OrderId)){
                if(String.isBlank(ordItem.Status__c)){
                    ordItem.Status__c = 'Nao faturado';
                }
            }
        }
    }

    public void beforeUpdate(){

        for(OrderItem ordItem : newList){
            if(ordItem.Status__c != null && ordItem.Status__c.Equals('Cancelado') && ordItem.Status__c != oldmap.get(ordItem.Id).Status__c){
                system.debug('Trigger Status__c: ' + ordItem.Status__c);
                system.debug('Trigger old Status__c: ' + oldmap.get(ordItem.Id).Status__c);

                ordItem.StatusPreIntegracao__c = oldmap.get(ordItem.Id).Status__c;
            }
        }

    }

    public void afterInsert(){

        List<Queue__c> queues = new List<Queue__c>();
        Set<Id> orderIds = new Set<Id>();

        for(OrderItem ordItem : newList){
            if (ordItem.CodigoPedidoTOTVS__c != null && ordItem.Status__c != 'Devolvido'){
                orderIds.add(ordItem.OrderId);
            }
        }

        if(orderIds.size() > 0){
            for(Id ordId : orderIds){
                queues.add(new Queue__c(
                        EventName__c = QueueEventNames.ALT_OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name(),
                        Status__c    = 'CREATED',
                        RecordId__c  = ordId,
                        Payload__c   = OrderIntegrationBO.getJsonRequest(ordId, 'ALT'),
                        IgnoredByTrigger__c = false
                        )
                    );
            }
            insert queues;
        }
    }

    public void afterUpdate(){

        List<Queue__c> queues = new List<Queue__c>();

        Set<Id> orderIdsData = new Set<Id>();
        Set<Id> orderIdsStatus = new Set<Id>();

        for(OrderItem ordItem : newList){
 
            if (ordItem.CodigoPedidoTOTVS__c != null && ordItem.Status__c != 'Devolvido'){
                if (ordItem.Status__c.Equals('Cancelado') &&
                    ordItem.Status__c != oldmap.get(ordItem.Id).Status__c) {
                        orderIdsStatus.add(ordItem.OrderId);
                }

                if (!ordItem.Status__c.Equals('Cancelado') &&
                    ( ordItem.DataEntrega__c != oldmap.get(ordItem.Id).DataEntrega__c || 
                      ordItem.NumeroPediClin__c != oldmap.get(ordItem.Id).NumeroPediClin__c ||
                      ordItem.NumeroItemCli__c != oldmap.get(ordItem.Id).NumeroItemCli__c ||
                      ordItem.Atualizar__c != oldmap.get(ordItem.Id).Atualizar__c )) {

                    orderIdsData.add(ordItem.OrderId);
                }
            }
        }

        for(Id ordId : orderIdsStatus){
            queues.add(new Queue__c(
                    EventName__c = QueueEventNames.EXC_OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name(),
                    Status__c    = 'CREATED',
                    RecordId__c  = ordId,
                    Payload__c   = OrderIntegrationBO.getJsonRequest(ordId, 'EXC'),   
                    IgnoredByTrigger__c = false
                    )
            );
        }

        for(Id ordId : orderIdsData){
            queues.add(new Queue__c(
                    EventName__c = QueueEventNames.ALT_OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name(),
                    Status__c    = 'CREATED',
                    RecordId__c  = ordId,
                    Payload__c   = OrderIntegrationBO.getJsonRequest(ordId, 'ALT'),
                    IgnoredByTrigger__c = false
                    )
            );
        }

        if(queues.size() > 0){
            insert queues;
        }
    }
}