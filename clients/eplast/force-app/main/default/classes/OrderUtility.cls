public with sharing class OrderUtility {
  public static OrderInfo[] getOrderFromIds(Id[] ids){
    OrderInfo[] ordersInfo = new OrderInfo[]{};

    Order[] orders = [
      SELECT 
        Id, Status, ProtheusId__c, ExternalNumber__c, TotalAmount, OrderNumber, EffectiveDate, ExpectedSaleDate__c, Discount__c ,DeliveryDate__c, Volume1__c, Species1__c, MessageNote__c, InternalObservation__c, Parcel1__c, Parcel2__c, Parcel3__c, Parcel4__c, Parcel5__c, Parcel6__c, Parcel7__c, Parcel8__c, Parcel9__c, Parcel10__c, Parcel11__c, Parcel12__c, Expiration1__c, Expiration2__c, Expiration3__c, Expiration4__c, Expiration5__c, Expiration6__c, Expiration7__c, Expiration8__c, Expiration9__c, Expiration10__c, Expiration11__c, Expiration12__c, TypeShipping__c,
          SBQQ__Quote__r.SBQQ__ListAmount__c,
          OpportunityId, Opportunity.Branch__r.CodeERP__c, Opportunity.Formas_de_Pagamento__c, Opportunity.SBQQ__PrimaryQuote__c, Opportunity.SyncedQuoteId, Opportunity.SyncedQuote.GrandTotal, Opportunity.PaymentTermId__r.Codigo__c,
          AccountId, Account.ProtheusId__c, Account.Store__c, Account.CompanyName__c, Account.BillingState, Account.BillingCity, Account.Owner.ProtheusSellerId__c,
          DispatchBranch__r.CodeERP__c,
          ShippingCompany__r.Code__c,
          TypeOperation__r.Name,
          DeliveryCustomer__r.ProtheusId__c,
          DeliveryCustomer__r.Store__c,
          DeliveryCustomer__r.CompanyName__c
      FROM Order
      WHERE Id IN :ids
    ];

    Map<Id, SBQQ__QuoteLine__c[]> cpqOrderProducts = getQuoteLinesCPQFromOrderOpp(orders);
    Map<Id, QuoteLineItem[]> orderProducts = getQuoteLinesItemsFromOrderOpp(orders);
    Map<Id, String> accountToTeamMemberProtheusSellerIdMap = extractAccountTeamMembersProtheusSellerIdFromOrderOpp(orders);

    for(Order order : orders)
      ordersInfo.add(
        new OrderInfo(
          order,
          cpqOrderProducts.get(order.OpportunityId), 
          orderProducts.get(order.OpportunityId),
          accountToTeamMemberProtheusSellerIdMap.get(order.AccountId) 
        )
      );

    return ordersInfo;
  }

  private static Map<Id, Id> extractPrimaryQuoteIdCPQFromOrderOpp(Order[] orders){
    Map<Id, Id> orderQuoteMap = new Map<Id, Id>();

    for(Order order : orders)
      if(order.Opportunity.SBQQ__PrimaryQuote__c != null)
        orderQuoteMap.put(order.OpportunityId, order.Opportunity.SBQQ__PrimaryQuote__c);

    return orderQuoteMap;
  }

  private static Map<Id, SBQQ__QuoteLine__c[]> getQuoteLinesCPQFromOrderOpp(Order[] orders){
    Map<Id, SBQQ__QuoteLine__c[]> orderOppToQuoteLineItemsMap = new Map<Id, SBQQ__QuoteLine__c[]>();
    
    SBQQ__QuoteLine__c[] orderProductsInfo = [
      SELECT 
        SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__ListTotal__c, SecondUnitQuantity__c,
          SBQQ__Product__r.QuantityUnitOfMeasure, SBQQ__Product__r.ProductCode, SBQQ__Product__r.Name,
          SBQQ__Quote__r.SBQQ__Opportunity2__c
        

      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Quote__c IN :extractPrimaryQuoteIdCPQFromOrderOpp(orders).values()
    ];

    for(SBQQ__QuoteLine__c orderProductInfo : orderProductsInfo)
      if(orderOppToQuoteLineItemsMap.get(orderProductInfo.SBQQ__Quote__r.SBQQ__Opportunity2__c) == null)
        orderOppToQuoteLineItemsMap.put(orderProductInfo.SBQQ__Quote__r.SBQQ__Opportunity2__c, new SBQQ__QuoteLine__c[]{orderProductInfo});
      else
        orderOppToQuoteLineItemsMap.get(orderProductInfo.SBQQ__Quote__r.SBQQ__Opportunity2__c).add(orderProductInfo);

    return orderOppToQuoteLineItemsMap;
  }

  private static Map<Id, Id> extractSyncedQuoteIdFromOrderOpp(Order[] orders){
    Map<Id, Id> orderQuoteMap = new Map<Id, Id>();

    for(Order order : orders)
      if(order.Opportunity.SyncedQuoteId != null)
        orderQuoteMap.put(order.OpportunityId, order.Opportunity.SyncedQuoteId);

    return orderQuoteMap;
  }

  private static Map<Id, QuoteLineItem[]> getQuoteLinesItemsFromOrderOpp(Order[] orders){
    Map<Id, QuoteLineItem[]> orderOppToQuoteLineItemsMap = new Map<Id, QuoteLineItem[]>();
    
    QuoteLineItem[] orderProductsInfo = [
      SELECT 
        Quantity, UnitPrice, TotalPrice, SecondUnitQuantity__c,
          Product2.QuantityUnitOfMeasure, Product2.ProductCode, Product2.Name,
          Quote.OpportunityId

      FROM QuoteLineItem
      WHERE QuoteId IN :extractSyncedQuoteIdFromOrderOpp(orders).values()
    ];

    for(QuoteLineItem orderProductInfo : orderProductsInfo)
      if(orderOppToQuoteLineItemsMap.get(orderProductInfo.Quote.OpportunityId) == null)
        orderOppToQuoteLineItemsMap.put(orderProductInfo.Quote.OpportunityId, new QuoteLineItem[]{orderProductInfo});
      else
        orderOppToQuoteLineItemsMap.get(orderProductInfo.Quote.OpportunityId).add(orderProductInfo);

    return orderOppToQuoteLineItemsMap;
  }
  
  private static Map<Id, String> extractAccountTeamMembersProtheusSellerIdFromOrderOpp(Order[] orders){
    Map<Id, String> orderAccountToTeamMemberProtheusSellerIdMap = new Map<Id, String>();
    Set<Id> orderAccountIdSet = new Set<Id>();
    
    for(Order order : orders)
      orderAccountIdSet.add(order.AccountId);

    Account[] accs = [
      SELECT
        Id,
          (SELECT User.ProtheusSellerId__c FROM AccountTeamMembers)
      FROM Account
      WHERE
        Id IN :orderAccountIdSet
    ]; 

    for(Account acc : accs)
      orderAccountToTeamMemberProtheusSellerIdMap.put(
        acc.Id, 
        (acc.AccountTeamMembers == null || acc.AccountTeamMembers.isEmpty() ? null : acc.AccountTeamMembers[0].User.ProtheusSellerId__c)
      );

    return orderAccountToTeamMemberProtheusSellerIdMap;
  }

  public static OrderInfo[] getOrderFromIds(Set<Id> ids){
    return getOrderFromIds(new Id[ids]);
  }

  public static String treatStoreLength(String store){
    String storeWithNoSpaces = store.replaceAll('[\\s]', ''); 

    return (storeWithNoSpaces.length() == 1 ? '0' + storeWithNoSpaces : storeWithNoSpaces);
  }
}