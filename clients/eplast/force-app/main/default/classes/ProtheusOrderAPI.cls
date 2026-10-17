public with sharing class ProtheusOrderAPI {
    public static void sendOrdersToProtheus(OrderInfo[] ordersInfo){
        for(OrderInfo orderInfo : ordersInfo){
            ProtheusInsertOrderModel requestBody = OrderAdapter.toProtheus(orderInfo);
            RequestInfo requestInfo = ProtheusRequest.post('/WSEPLPED', requestBody);
            treatSendOrderResponse(requestInfo, orderInfo);
        }
    }

    private static void treatSendOrderResponse(RequestInfo requestInfo, OrderInfo orderInfo){
        if(requestInfo.response.getStatusCode() == 201){
            ProtheusInserOrderSuccessResponseBody responseBody = (ProtheusInserOrderSuccessResponseBody) JSON.deserialize(requestInfo.response.getBody(), ProtheusInserOrderSuccessResponseBody.class);

            orderInfo.order.ExternalNumber__c = responseBody.Ret_Pedido.PedidoERP;

            update orderInfo.order;
        }

        Logger.save('Insert Order in Protheus', requestInfo.request, requestInfo.response);
    }
}