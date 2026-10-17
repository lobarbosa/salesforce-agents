public without sharing class CreateQuoteCPQController {
    public class QuoteRequest {
        @InvocableVariable
        public Id quoteId;
        
        @InvocableVariable
        public String clientType;
    }
    
	@InvocableMethod
    public static void createQuoteCPQ(List<QuoteRequest> requests) {
        List<SBQQ__Quote__c> quotesCPQ = new List<SBQQ__Quote__c>();
        for(QuoteRequest request : requests) {
            Quote q = [SELECT Id, OpportunityId, AccountId FROM Quote WHERE Id = :request.quoteId];
            Opportunity opp = [
                SELECT 
                Id, 
                Account.BillingCity, 
                Account.BillingState, 
                Account.BillingCountry, 
                Account.BillingPostalCode,
                Account.BillingStreet,
                Account.ShippingCity, 
                Account.ShippingState, 
                Account.ShippingCountry, 
                Account.ShippingPostalCode,
                Account.ShippingStreet,
                Account.BlowerCustomer__c
                FROM Opportunity 
                WHERE Id =:q.OpportunityId LIMIT 1
            ];
            SBQQ__Quote__c quoteCPQ = new SBQQ__Quote__c();
            quoteCPQ.Quote__c = q.Id;
            quoteCPQ.SBQQ__Opportunity2__c = q.OpportunityId;
            quoteCPQ.SBQQ__Account__c = q.AccountId;
            quoteCPQ.SBQQ__BillingCity__c = opp.Account.BillingCity;
            quoteCPQ.SBQQ__BillingState__c = opp.Account.BillingState;
            quoteCPQ.SBQQ__BillingCountry__c = opp.Account.BillingCountry;
            quoteCPQ.SBQQ__BillingPostalCode__c = opp.Account.BillingPostalCode;
            quoteCPQ.SBQQ__BillingStreet__c = opp.Account.BillingStreet;
            
            switch on request.clientType {
                when 'isBlowerCustomer' {
                    Account blower = [
                        SELECT Id, BillingCity, BillingState, BillingCountry, BillingPostalCode, BillingStreet 
                        FROM ACCOUNT 
                        WHERE Id =:opp.Account.BlowerCustomer__c 
                        LIMIT 1
                    ];
                    
                    quoteCPQ.SBQQ__ShippingCity__c = blower.BillingCity;
                    quoteCPQ.SBQQ__ShippingState__c = blower.BillingState;
                    quoteCPQ.SBQQ__ShippingCountry__c = blower.BillingCountry;
                    quoteCPQ.SBQQ__ShippingPostalCode__c = blower.BillingPostalCode;
                    quoteCPQ.SBQQ__ShippingStreet__c = blower.BillingStreet;
                }
                when 'isCustomer' {
                    quoteCPQ.SBQQ__ShippingCity__c = opp.Account.BillingCity;
                    quoteCPQ.SBQQ__ShippingState__c = opp.Account.BillingState;
                    quoteCPQ.SBQQ__ShippingCountry__c = opp.Account.BillingCountry;
                    quoteCPQ.SBQQ__ShippingPostalCode__c = opp.Account.BillingPostalCode;
                    quoteCPQ.SBQQ__ShippingStreet__c = opp.Account.BillingStreet;
                }
            }
            
            quotesCPQ.add(quoteCPQ);
        }
        
        insert quotesCPQ;
    }
}