public with sharing class OrderTriggerHelper {
    public void sendOrderToProtheus(Set<Id> ids){
        OrderInfo[] ordersInfo = OrderUtility.getOrderFromIds(ids);

        System.enqueueJob(new SendOrderToProtheus(ordersInfo));
    }
}