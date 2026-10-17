public with sharing class OrderAdapter {
    public static ProtheusInsertOrderModel toProtheus(OrderInfo orderInfo){
        ProtheusInsertOrderModel payload = new ProtheusInsertOrderModel();
        payload.Pedido = new ProtheusInsertOrderModel.Pedido[]{};
        ProtheusInsertOrderModel.Pedido payloadOrder = new ProtheusInsertOrderModel.Pedido();
        payloadOrder.itens = new ProtheusInsertOrderModel.Item[]{};
        Order order = orderInfo.order;
        System.debug('OrderAdapter: order ' + order);
        String[] orderPaymentWays = order.Opportunity.Formas_de_Pagamento__c.split(';');
        //Filling Fields
        payloadOrder.Filial = order.Opportunity.Branch__r.CodeERP__c; //
        payloadOrder.FilDespacho = order.DispatchBranch__r.CodeERP__c; //
        payloadOrder.NumPedCRM = order.OrderNumber; //
        payloadOrder.NumERP = (order.ExternalNumber__c == null ? '' : order.ExternalNumber__c); //
        payloadOrder.cliVen = order.Account.ProtheusId__c; //
        payloadOrder.LojaVen = OrderUtility.treatStoreLength(order.Account.Store__c); //
        payloadOrder.NomeCliVen = order.Account.CompanyName__c; //
        determineDeliveryCustomer(payloadOrder, order);
        payloadOrder.UFVenda = StringUtility.replaceAllCaseVowelsAccent(order.Account.BillingState).toUpperCase(); //
        payloadOrder.CidadeVenda = StringUtility.replaceAllCaseVowelsAccent(order.Account.BillingCity).toUpperCase(); //
        payloadOrder.CondPagto = order.Opportunity.PaymentTermId__r.Codigo__c; //
        payloadOrder.FormaPagto = orderPaymentWays[0]; //
        payloadOrder.FormaPagto2 = (orderPaymentWays.size() > 1 ? orderPaymentWays[1] : '');
        payloadOrder.Vend1 = order.Account.Owner.ProtheusSellerId__c; //
        payloadOrder.Vend2 = (orderInfo.accountTeamMemberProtheusSellerId != null ? orderInfo.accountTeamMemberProtheusSellerId : ''); 
        payloadOrder.DtEmissao = order.EffectiveDate.format(); //
        payloadOrder.DtPrevVenda = order.ExpectedSaleDate__c.format(); //
        payloadOrder.DtEntrega = order.DeliveryDate__c.format(); //
        payloadOrder.Volume = order.Volume1__c; //
        payloadOrder.Especie = order.Species1__c; //
        payloadOrder.MensNota = (order.MessageNote__c != null ? order.MessageNote__c : '');
        payloadOrder.Observacao = (order.InternalObservation__c != null ? order.InternalObservation__c : '');
        payloadOrder.Parcela1 = (order.Parcel1__c != null ? order.Parcel1__c : 0);
        payloadOrder.Parcela2 = (order.Parcel2__c != null ? order.Parcel2__c : 0);
        payloadOrder.Parcela3 = (order.Parcel3__c != null ? order.Parcel3__c : 0);
        payloadOrder.Parcela4 = (order.Parcel4__c != null ? order.Parcel4__c : 0);
        payloadOrder.Parcela5 = (order.Parcel5__c != null ? order.Parcel5__c : 0);
        payloadOrder.Parcela6 = (order.Parcel6__c != null ? order.Parcel6__c : 0);
        payloadOrder.Parcela7 = (order.Parcel7__c != null ? order.Parcel7__c : 0);
        payloadOrder.Parcela8 = (order.Parcel8__c != null ? order.Parcel8__c : 0);
        payloadOrder.Parcela9 = (order.Parcel9__c != null ? order.Parcel9__c : 0);
        payloadOrder.Parcela10 = (order.Parcel10__c != null ? order.Parcel10__c : 0);
        payloadOrder.Parcela11 = (order.Parcel11__c != null ? order.Parcel11__c : 0);
        payloadOrder.Parcela12 = (order.Parcel12__c != null ? order.Parcel12__c : 0);
        payloadOrder.Vencimento1 = (order.Expiration1__c != null ? order.Expiration1__c.format() : '');
        payloadOrder.Vencimento2 = (order.Expiration2__c != null ? order.Expiration2__c.format() : '');
        payloadOrder.Vencimento3 = (order.Expiration3__c != null ? order.Expiration3__c.format() : '');
        payloadOrder.Vencimento4 = (order.Expiration4__c != null ? order.Expiration4__c.format() : '');
        payloadOrder.Vencimento5 = (order.Expiration5__c != null ? order.Expiration5__c.format() : '');
        payloadOrder.Vencimento6 = (order.Expiration6__c != null ? order.Expiration6__c.format() : '');
        payloadOrder.Vencimento7 = (order.Expiration7__c != null ? order.Expiration7__c.format() : '');
        payloadOrder.Vencimento8 = (order.Expiration8__c != null ? order.Expiration8__c.format() : '');
        payloadOrder.Vencimento9 = (order.Expiration9__c != null ? order.Expiration9__c.format() : '');
        payloadOrder.Vencimento10 = (order.Expiration10__c != null ? order.Expiration10__c.format() : '');
        payloadOrder.Vencimento11 = (order.Expiration11__c != null ? order.Expiration11__c.format() : '');
        payloadOrder.Vencimento12 = (order.Expiration12__c != null ? order.Expiration12__c.format() : '');
        payloadOrder.Transport = order.ShippingCompany__r.Code__c; //
        payloadOrder.OperPed = order.Status; //
        payloadOrder.TipoOper = order.TypeOperation__r.Name; //
        payloadOrder.TipoFrete = order.TypeShipping__c; //
        payloadOrder.MotCancel = (order.Status == 'Cancelado' ? 'TRUE' : 'FALSE'); //
        payloadOrder.DESCONTO = order.Discount__c;
        payloadOrder.IDEXTERNO = order.Id;
        if(orderInfo.cpqProductsInfo != null && !orderInfo.cpqProductsInfo.isEmpty())
            configureCPQQuoteInfoPayload(payloadOrder, orderInfo);
        else
            configureQuoteInfoPayload(payloadOrder, orderInfo);
        payload.Pedido.add(payloadOrder);
        return payload;
    }
    private static void configureCPQQuoteInfoPayload(ProtheusInsertOrderModel.Pedido payloadOrder, OrderInfo orderInfo){
        payloadOrder.ValorPedido = orderInfo.order.SBQQ__Quote__r.SBQQ__ListAmount__c.setScale(6); //
        for(Integer index = 0; index < orderInfo.cpqProductsInfo.size(); index++){
            ProtheusInsertOrderModel.Item payloadOrderItem = new ProtheusInsertOrderModel.Item();
            String indexValue = String.valueOf(index + 1);
            SBQQ__QuoteLine__c orderProduct = orderInfo.cpqProductsInfo[index];
            payloadOrderItem.Filial = payloadOrder.Filial;
            payloadOrderItem.NumERP = (orderInfo.order.ExternalNumber__c == null ? '' : orderInfo.order.ExternalNumber__c);
            payloadOrderItem.NumPedCRM = payloadOrder.NumPedCRM;
            payloadOrderItem.Item = (indexValue.length() == 1 ? '0' + indexValue : indexValue);
            payloadOrderItem.Produto = orderProduct.SBQQ__Product__r.ProductCode;
            payloadOrderItem.Unidade = orderProduct.SBQQ__Product__r.QuantityUnitOfMeasure;
            payloadOrderItem.Quant1UM = orderProduct.SBQQ__Quantity__c.setScale(6);
            payloadOrderItem.VlUnit = orderProduct.SBQQ__ListPrice__c.setScale(6);
            payloadOrderItem.VlTotal = orderProduct.SBQQ__ListTotal__c.setScale(6);
            payloadOrderItem.Quant2UM = orderProduct.SecondUnitQuantity__c.setScale(6);
            payloadOrder.itens.add(payloadOrderItem);
        }
    }
    private static void configureQuoteInfoPayload(ProtheusInsertOrderModel.Pedido payloadOrder, OrderInfo orderInfo){
        payloadOrder.ValorPedido = orderInfo.order.Opportunity.SyncedQuote.GrandTotal.setScale(6); //
        for(Integer index = 0; index < orderInfo.productsInfo.size(); index++){
            ProtheusInsertOrderModel.Item payloadOrderItem = new ProtheusInsertOrderModel.Item();
            String indexValue = String.valueOf(index + 1);
            QuoteLineItem orderProduct = orderInfo.productsInfo[index];
            payloadOrderItem.Filial = payloadOrder.Filial;
            payloadOrderItem.NumERP = (orderInfo.order.ExternalNumber__c == null ? '' : orderInfo.order.ExternalNumber__c);
            payloadOrderItem.NumPedCRM = payloadOrder.NumPedCRM;
            payloadOrderItem.Item = (indexValue.length() == 1 ? '0' + indexValue : indexValue);
            payloadOrderItem.Produto = orderProduct.Product2.ProductCode;
            payloadOrderItem.Unidade = orderProduct.Product2.QuantityUnitOfMeasure;
            payloadOrderItem.Quant1UM = orderProduct.Quantity.setScale(6);
            payloadOrderItem.VlUnit = orderProduct.UnitPrice.setScale(6);
            payloadOrderItem.VlTotal = orderProduct.TotalPrice.setScale(6);
            payloadOrderItem.Quant2UM = orderProduct.SecondUnitQuantity__c.setScale(6);
            payloadOrder.itens.add(payloadOrderItem);
        }
    }
    private static void determineDeliveryCustomer(ProtheusInsertOrderModel.Pedido payloadOrder, Order order){
        Boolean accountHasDeliveryCustomer = order.DeliveryCustomer__r != null;
        payloadOrder.cliEnt = (accountHasDeliveryCustomer ? order.DeliveryCustomer__r.ProtheusId__c : order.Account.ProtheusId__c);
        payloadOrder.LojaEnt = OrderUtility.treatStoreLength(accountHasDeliveryCustomer ? order.DeliveryCustomer__r.Store__c : order.Account.Store__c);
        payloadOrder.NomeCliEnt = (accountHasDeliveryCustomer ? order.DeliveryCustomer__r.CompanyName__c : order.Account.CompanyName__c);
    }
}