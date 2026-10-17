public class CloneQuote {

    @AuraEnabled
    public static Id toCloneQuote(Id recordId) {

        Quote clonedQuote;
        Quote initialQuote = QuoteDAO.getinstance().getAllFields(recordId);
        clonedQuote = initialQuote.clone(false, true);
        clonedQuote.Status = 'Negociação';
        clonedQuote.BloqueioFinanceiro__c = true;
        clonedQuote.AprovaCredito__c = false;
        if(clonedQuote.DataPrevisaoEntrega__c < System.today()){
            clonedQuote.DataPrevisaoEntrega__c = System.today();
        }
        insert clonedQuote;

        //criação das cotações novas
        List<QuoteLineItem> quoteItems = QuoteDAO.getinstance().getAllQuoteLineItem(recordId);
        List<QuoteLineItem> clonedQuoteItems = new List<QuoteLineItem>();
        Set<Id> recordsId = new Set<Id>();
        for(QuoteLineItem quoteItem : quoteItems){
            QuoteLineItem clonedQuoteItem = quoteItem.clone(false,true);
            clonedQuoteItem.QuoteId = clonedQuote.Id;
            if(clonedQuoteItem.DataEntrega__c < System.today()){
                clonedQuoteItem.DataEntrega__c = System.today();
            }
            clonedQuoteItems.add(clonedQuoteItem);
            recordsId.add(quoteItem.Id);
        }
        insert clonedQuoteItems;


        return clonedQuote.id;
    }

}