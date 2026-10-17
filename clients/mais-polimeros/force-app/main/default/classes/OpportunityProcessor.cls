public Without Sharing class OpportunityProcessor {

    public class IntegrationException extends Exception {}

    @AuraEnabled
    public static Boolean btnIsVisible(Id recordId){
        Opportunity opp = [ SELECT Id, StageName, ConferenciaOK__c FROM Opportunity WHERE id=:recordId ];
        if(!(opp.StageName.Equals('Conferência')) || !(opp.ConferenciaOK__c))
            return false;
        return true;
    }

    @AuraEnabled
    public static Opportunity oppStatus(Id recordId){
        Opportunity opp = [ SELECT Id, StageName, ConferenciaOK__c, HorarioLimitePedido__c, PedidoBloqueadoHorario__c, StatusPreco__c, StatusCredito__c FROM Opportunity WHERE id=:recordId ];
        return opp;
    }

    @AuraEnabled
    public static Queue__c sendPriceToTotvs(Queue__c queue){
        OpportunityIntegrationBO.executeQueue(queue.Id,queue.RecordId__c,queue.EventName__c,queue.Payload__c);

        return QueueDAO.getInstance().getOneQueueById(queue.Id);
    }
    
    @AuraEnabled
    public static Queue__c sendOrderToTotvs(Queue__c queue){
        OrderIntegrationBO.executeQueue(queue.Id,queue.RecordId__c,queue.EventName__c,queue.Payload__c);

        return QueueDAO.getInstance().getOneQueueById(queue.Id);
    }

    @AuraEnabled
    public static String getMessage(Id recordId){
        Opportunity opp = [ SELECT Id, AccountId FROM Opportunity WHERE id=:recordId ];
        Account account = [ SELECT Id, mensagemTOTVS__c FROM Account WHERE id=:opp.AccountId ];
        return account.mensagemTOTVS__c;
    }

    @AuraEnabled
    public static Queue__c getPrecoOppQueue(Id recordId){
 
        Opportunity opp = [ SELECT  Id
                                    , SincronizaTotvs__c
                                    , CodigoReceptorFormula__c
                                    , TipoDeFrete__c
                                    , Unidade_Filial__r.Codigo__c
                                    , Account.Codigo__c
                                    , CondicaoPagamento__r.codigo__c
                                    , Owner.CodVendedor__c
                                    , StageName
                            FROM    Opportunity
                            WHERE   Id = :recordId ];
        return OpportunityBO.getInstance().criaFilaIntegracaoPreco(opp);
    }

    @AuraEnabled
    public static Queue__c converteOportunidade(Id recordId){

        Queue__c queue;
        ProcessControl.ignoredByTrigger = true;

        Opportunity opp = [ SELECT Id, MensagemTOTVS__c, CodigoTOTVS__c, StageName,
                                    CodigoReceptor__c, ObservacoesLogistica__c,InformacoesParaLogistica__c, Coleta__c, 
                                    TipoDeFrete__c, TipoConta__c, Unidade_Filial__r.Codigo__c, DespesasAces__c, FormaDePagamento__c,
                                    Account.Id, Account.Codigo__c, Account.ObservacoesLogistica__c, CondicaoPagamento__r.Codigo__c, Description,
                                    ValorComissao__c, Transportadora__c, ContaReceptor__r.Codigo__c, ContaReceptor__r.ObservacoesLogistica__c, TESReceptor__c,
                                    CondicaoPagamentoReceptor__r.Name, CondicaoPagamentoReceptor__r.Codigo__c, TES__c, CodigoReceptorFormula__c, RecordTypeId,
                                    DataEntrega__c,DataPrevisaoEntrega__c, Frete__c, Pricebook2Id, PedidoBloqueadoHorario__c, Owner.CodVendedor__c,
                                    (SELECT Id, DataEntrega__c, Quantity, UnitPrice, ComissaoEditavel__c, Preco_Unitario_Com_Impostos__c,
                                            CodigoTOTVS__c, TESEditavel__c, Status__c, CodigoTOTVSAutoInc__c, NumeroPediClin__c, NumeroItemCli__c,IPI__c,Product2Id,
                                            BloqueioCalcFrete__c, Comissao__c, Percent_ICMS__c, PrecoUnitarioSImposto__c, ValorComissao__c, ValorFrete__c,
                                            Desconto__c, PricebookEntryId,Product2.Processo__c
                                    FROM OpportunityLineItems )
                            FROM Opportunity
                            WHERE Id =: recordId  ];

        if(opp.PedidoBloqueadoHorario__c == true ) {
            ParametrosGerais__c pg = ParametrosGerais__c.getInstance();
            throw new IntegrationException('Pedidos só podem ser enviados até ' + pg.HorarioLimitePedido__c);
        }

        if (opp != null){

            Id idOrder = null;
            List<Order> lstOrder = new List<Order>([    SELECT  Id 
                                                        FROM    Order
                                                        WHERE   CodigoTOTVS__c = null
                                                        AND     OpportunityId = :opp.Id
                                                        ORDER BY CreatedDate DESC NULLS LAST
                                                        LIMIT   1]);

            if (opp.CodigoTOTVS__c == null && lstOrder != null && lstOrder.size() > 0){

                idOrder = lstOrder[0].Id;

                List<OrderItem> lstOrderItemCheck = new List<OrderItem>([   SELECT  Id 
                                                                            FROM    OrderItem
                                                                            WHERE   OrderId = :idOrder]);

                if (lstOrderItemCheck != null && lstOrderItemCheck.size() > 0) delete lstOrderItemCheck;
            }  

            Order newOrder = new Order(
                AccountId = opp.Account.Id,
                OpportunityId = opp.Id,
                Status = 'Aguardando Faturamento',
                EffectiveDate = system.today(),
                Pricebook2Id = opp.Pricebook2Id,
                CodigoReceptor__c = opp.CodigoReceptor__c,
                InformacoesParaLogistica__c = opp.InformacoesParaLogistica__c,
                Coleta__c = opp.Coleta__c,
                TipoFrete__c =  String.valueOf(opp.TipoDeFrete__c).left(1),
                Frete__c = opp.Frete__c,
                UnidadeFilial__c = opp.Unidade_Filial__c,
                CondicaoPagamento__c = opp.CondicaoPagamento__c,
                Transportadora__c = opp.Transportadora__c,
                TESReceptor__c = opp.TESReceptor__c,
                Description = opp.Description,
                FormaPagamento__c = opp.FormaDePagamento__c,
                ObservacoesLogistica__c = opp.ObservacoesLogistica__c,
                ContaReceptor__c = opp.ContaReceptor__c,
                CondicaoPagamentoReceptor__c = opp.CondicaoPagamentoReceptor__c,
                TES__c = opp.TES__c,
                DataEntrega__c = opp.DataEntrega__c,
                DataPrevisaoEntrega__c = opp.DataPrevisaoEntrega__c
            );

            if (idOrder != null) newOrder.Id = idOrder;
            upsert newOrder;

            List<OrderItem> newOrderItems = new List<OrderItem>();
            for(OpportunityLineItem oppItem : opp.OpportunityLineItems){
                OrderItem newOrderItem = new OrderItem(
                    OrderId = newOrder.Id,
                    Product2Id = oppItem.Product2Id,
                    PricebookEntryId = oppItem.PricebookEntryId,
                    Quantity = oppItem.Quantity,
                    UnitPrice = oppItem.UnitPrice,
                    Status__c = 'Nao faturado',
                    TESEditavel__c = oppItem.TESEditavel__c,
                    DataEntrega__c = oppItem.DataEntrega__c,
                    ComissaoEditavel__c = oppItem.ComissaoEditavel__c,
                    NumeroPediClin__c = oppItem.NumeroPediClin__c,
                    NumeroItemCli__c = oppItem.NumeroItemCli__c,
                    PercentualIPI__c = oppItem.IPI__c,
                    BloqueioCalcFrete__c = oppItem.BloqueioCalcFrete__c,
                    Comissao__c = oppItem.Comissao__c,
                    PercentualDesconto__c = oppItem.Desconto__c,
                    PercentualComissao__c = oppItem.Comissao__c,
                    PercentualICMS__c  = oppItem.Percent_ICMS__c,
                    PrecoUnitarioSImposto__c = oppItem.PrecoUnitarioSImposto__c,
                    ValorComissao__c = oppItem.ValorComissao__c,
                    ValorFrete__c = oppItem.ValorFrete__c,
                    Processo__c = (oppItem.Product2.Processo__c != null ? oppItem.Product2.Processo__c : null)
                );
                newOrderItems.add(newOrderItem);
            }
            insert newOrderItems;

            queue = new Queue__c(
                EventName__c = QueueEventNames.OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name(),
                Status__c    = 'CREATED',
                RecordId__c  = newOrder.Id,
                Payload__c   = OrderIntegrationBO.getJsonRequest(newOrder.Id, 'INC'),   
                IgnoredByTrigger__c = true 
            );
            insert queue;
        }
        return queue;
    }

    @AuraEnabled
    public static String checaPedidoDuplicado(String oppId) {

        System.debug('>> Entrou checa pedido!');
        String orderItemId = '';

        List<OrderItem> lstOrderItem = new List<OrderItem>([    SELECT  Id
                                                                FROM    OrderItem
                                                                WHERE   OrderId IN (SELECT Id FROM Order WHERE OpportunityId = :oppId)]);
        if (lstOrderItem != null && lstOrderItem.size() > 0){
            orderItemId = lstOrderItem[0].Id;
        } else {
            return '';
        }

        IntegrationParams__c ip = IntegrationParams__c.getInstance();
        String pedido = null;

        SYSTEM.debug('orderItemId: ' + orderItemId);

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
            gen.writeStringField('Operacao', 'Item');
            gen.writeStringField('Chave', orderItemId);
        gen.writeEndObject();
        system.debug('payload: ' + gen.getAsString());

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HTTPResponse response = new HTTPResponse();

        request.setEndpoint(ip.URI_API__c + '/CONSPED');
        request.setMethod('POST');
        request.setTimeout(15000);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(gen.getAsString());

        system.debug('request: ' + request);

        response = http.send(request);
        system.debug('response: ' + response);

        if (response.getStatusCode() != 201 && response.getStatusCode() != 200) {
            throw new IntegrationException('Erro ao verificar duplicidade do Pedido!');
        } else {
            Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
            system.debug('responseMap: ' + responseMap);

            for (Object objPedido : (List<Object>) responseMap.get('CONSULTA_PEDIDO') ) {
                Map<String, Object> mapCabecalho = ( Map<String, Object> ) objPedido;
                system.debug('mapCabecalho: ' + mapCabecalho);

                Map<String, Object> mapCabecalho1 = ( Map<String, Object> ) mapCabecalho.get('CABECALHO');
                system.debug('mapCabecalho1: ' + mapCabecalho1);

                pedido = Util.getString(mapCabecalho1.get('PEDIDO'));
            }
        }

        System.debug('>> Retorno2: ' + pedido.trim());
        return pedido.trim();
    }

    @InvocableMethod(label='Send B2B Order to Protheus')
    public static void generateB2bOrderQueu(List<String> listOrderId){
        string orderId = listOrderId[0];
        Queue__c queue = new Queue__c(
            EventName__c = QueueEventNames.OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name(),
            Status__c    = 'CREATED',
            RecordId__c  = orderId,
            Payload__c   = OrderIntegrationBO.getJsonRequest(orderId, 'INC'),
            IgnoredByTrigger__c = true
        );
        insert queue;

        asyncSendOrderToTotvs(queue.Id);
    }

    @future(callout=true)
    public static void asyncSendOrderToTotvs(String queueId){
        Queue__c queue = [SELECT Id, RecordId__c, EventName__c, Payload__c FROM Queue__c WHERE Id = :queueId];
        OrderIntegrationBO.executeQueue(queue.Id,queue.RecordId__c,queue.EventName__c,queue.Payload__c);
    }

}