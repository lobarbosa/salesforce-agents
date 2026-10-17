public with sharing class OrderInfo {
    public Order order;
    public SBQQ__QuoteLine__c[] cpqProductsInfo;
    public QuoteLineItem[] productsInfo;
    public String accountTeamMemberProtheusSellerId;

    public OrderInfo(Order order, SBQQ__QuoteLine__c[] cpqProductsInfo, QuoteLineItem[] productsInfo, String accountTeamMemberProtheusSellerId) {
        this.order = order;
        this.cpqProductsInfo = cpqProductsInfo;
        this.productsInfo = productsInfo;
        this.accountTeamMemberProtheusSellerId = accountTeamMemberProtheusSellerId;
    }
}