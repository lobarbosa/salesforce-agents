public without sharing class FlowOpportunityController {
    
    public class RequestItem {
        @InvocableVariable
        public Id recordId;
    }

    @InvocableMethod
    public static void createQuoteFromOpportunity(List<RequestItem> requests) {
        for (RequestItem request : requests)
            FlowOpportunityController.createQuoteFromOpportunityId(request.recordId);
    }

    public static void createQuoteFromOpportunityId(Id opportunityId) {
        Opportunity opportunity = [SELECT Id, Name, AccountId, Pricebook2Id, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet, (SELECT Id, PricebookEntryId, UnitPrice, Quantity, Description, ServiceDate FROM OpportunityLineItems) FROM Opportunity WHERE Id = :opportunityId];

        Quote quote = new Quote();
        quote.OpportunityId = opportunity.Id;
        quote.Name = opportunity.Name;
        quote.Pricebook2Id = opportunity.Pricebook2Id;
        quote.BillingCity = opportunity.Account.BillingCity;
        quote.BillingCountry = opportunity.Account.BillingCountry;
        quote.BillingPostalCode = opportunity.Account.BillingPostalCode;
        quote.BillingState = opportunity.Account.BillingState;
        quote.BillingStreet = opportunity.Account.BillingStreet;
        quote.ShippingCity = opportunity.Account.BillingCity;
        quote.ShippingCountry = opportunity.Account.BillingCountry;
        quote.ShippingPostalCode = opportunity.Account.BillingPostalCode;
        quote.ShippingState = opportunity.Account.BillingState;
        quote.ShippingStreet = opportunity.Account.BillingStreet;

        Database.insert(quote);

        SBQQ__Quote__c quoteCPQ = new SBQQ__Quote__c();
        quoteCPQ.Quote__c = quote.Id;
        quoteCPQ.SBQQ__PriceBook__c = opportunity.Pricebook2Id;
        quoteCPQ.SBQQ__Opportunity2__c = opportunity.Id;
        quoteCPQ.SBQQ__Account__c = opportunity.AccountId;
        quoteCPQ.SBQQ__BillingCity__c = opportunity.Account.BillingCity;
        quoteCPQ.SBQQ__BillingState__c = opportunity.Account.BillingState;
        quoteCPQ.SBQQ__BillingCountry__c = opportunity.Account.BillingCountry;
        quoteCPQ.SBQQ__BillingPostalCode__c = opportunity.Account.BillingPostalCode;
        quoteCPQ.SBQQ__BillingStreet__c = opportunity.Account.BillingStreet;
        quoteCPQ.SBQQ__ShippingCity__c = opportunity.Account.BillingCity;
        quoteCPQ.SBQQ__ShippingState__c = opportunity.Account.BillingState;
        quoteCPQ.SBQQ__ShippingCountry__c = opportunity.Account.BillingCountry;
        quoteCPQ.SBQQ__ShippingPostalCode__c = opportunity.Account.BillingPostalCode;
        quoteCPQ.SBQQ__ShippingStreet__c = opportunity.Account.BillingStreet;

        Database.insert(quoteCPQ);

    }

}