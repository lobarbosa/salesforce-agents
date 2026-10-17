public with sharing class SendOrderToProtheus implements Queueable, Database.AllowsCallouts {
    private OrderInfo[] ordersInfo;

    public SendOrderToProtheus(OrderInfo[] ordersInfo) {
        this.ordersInfo = ordersInfo;
    }

    public void execute(QueueableContext context){
        ProtheusOrderAPI.sendOrdersToProtheus(this.ordersInfo);
    }
}