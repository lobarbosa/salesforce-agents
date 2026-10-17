public with sharing class OrderTriggerHandler {
    OrderTriggerHelper helper;
    public OrderTriggerHandler() {
        this.helper = new OrderTriggerHelper();
    }

    public void sendOrderToProtheus(Map<Id, Order> oldMap, Map<Id, Order> newMap){
        Set<Id> idsToSend = new Set<Id>();
        Boolean shouldSendToProtheus;

        for(Order order : newMap.values()){
            shouldSendToProtheus = order.Status != 'Revisao de Pedido' && (sensitiveFieldsChanged(oldMap.get(order.Id), order) || order.ExternalNumber__c == null);
            
            if(shouldSendToProtheus)
                idsToSend.add(order.Id);
        }

        this.helper.sendOrderToProtheus(idsToSend);

    }

    private Boolean sensitiveFieldsChanged(Order oldOrder, Order newOrder){
        if(newOrder.DispatchBranch__c != oldOrder.DispatchBranch__c)
            return true;
        if(newOrder.Status != oldOrder.Status)
            return true;
        if(newOrder.ExpectedSaleDate__c != oldOrder.ExpectedSaleDate__c)
            return true;
        if(newOrder.DeliveryDate__c != oldOrder.DeliveryDate__c)
            return true;
        if(newOrder.ShippingCompany__c != oldOrder.ShippingCompany__c)
            return true;
        if(newOrder.TypeShipping__c != oldOrder.TypeShipping__c)
            return true;
        if(newOrder.InternalObservation__c != oldOrder.InternalObservation__c)
            return true;
        if(newOrder.MessageNote__c != oldOrder.MessageNote__c)
            return true;
        if(newOrder.Volume1__c != oldOrder.Volume1__c)
            return true;
        if(newOrder.Species1__c != oldOrder.Species1__c)
            return true;
        if(newOrder.TypeOperation__c != oldOrder.TypeOperation__c)
            return true;
        if(newOrder.Parcel1__c != oldOrder.Parcel1__c)
            return true;
        if(newOrder.Parcel2__c != oldOrder.Parcel2__c)
            return true;
        if(newOrder.Parcel3__c != oldOrder.Parcel3__c)
            return true;
        if(newOrder.Parcel4__c != oldOrder.Parcel4__c)
            return true;
        if(newOrder.Parcel5__c != oldOrder.Parcel5__c)
            return true;
        if(newOrder.Parcel6__c != oldOrder.Parcel6__c)
            return true;
        if(newOrder.Parcel7__c != oldOrder.Parcel7__c)
            return true;
        if(newOrder.Parcel8__c != oldOrder.Parcel8__c)
            return true;
        if(newOrder.Parcel9__c != oldOrder.Parcel9__c)
            return true;
        if(newOrder.Parcel10__c != oldOrder.Parcel10__c)
            return true;
        if(newOrder.Parcel11__c != oldOrder.Parcel11__c)
            return true;
        if(newOrder.Parcel12__c != oldOrder.Parcel12__c)
            return true;
        if(newOrder.Expiration1__c != oldOrder.Expiration1__c)
            return true;
        if(newOrder.Expiration2__c != oldOrder.Expiration2__c)
            return true;
        if(newOrder.Expiration3__c != oldOrder.Expiration3__c)
            return true;
        if(newOrder.Expiration4__c != oldOrder.Expiration4__c)
            return true;
        if(newOrder.Expiration5__c != oldOrder.Expiration5__c)
            return true;
        if(newOrder.Expiration6__c != oldOrder.Expiration6__c)
            return true;
        if(newOrder.Expiration7__c != oldOrder.Expiration7__c)
            return true;
        if(newOrder.Expiration8__c != oldOrder.Expiration8__c)
            return true;
        if(newOrder.Expiration9__c != oldOrder.Expiration9__c)
            return true;
        if(newOrder.Expiration10__c != oldOrder.Expiration10__c)
            return true;
        if(newOrder.Expiration11__c != oldOrder.Expiration11__c)
            return true;
        if(newOrder.Expiration12__c != oldOrder.Expiration12__c)
            return true;

        return false;
    }
}