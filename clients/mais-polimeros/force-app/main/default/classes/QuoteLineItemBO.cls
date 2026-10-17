public with sharing class QuoteLineItemBO {
	
	private static final QuoteLineItemBO instance = new QuoteLineItemBO();
	private QuoteLineItemBO(){}

	public static QuoteLineItemBO getInstance() {
		return instance;
	}

	public PageReference UpdateQuote(List<QuoteLineItem> quoteLineItens, Map<Id, QuoteLineItem> oldMap){
		Map<Id, Quote> quoteForUpdateMap = new Map<Id, Quote>();
		Set<Id> recordsId = new Set<Id>();
		for(QuoteLineItem quoteLine : quoteLineItens){
			recordsId.add(quoteLine.QuoteId);
		}
		Map<Id, Quote> mapQuotes = QuoteDAO.getInstance().getMapQuote(recordsId);
		Boolean updateValue;
		for (QuoteLineItem quoteLineItem : quoteLineItens) {
			updateValue = false;
			if((!mapQuotes.get(quoteLineItem.QuoteId).Status.Equals('Fechado ganha'))&&(!mapQuotes.get(quoteLineItem.QuoteId).Status.Equals('Fechado perdido'))){
				System.debug('entrou');
				if(oldMap.get(quoteLineItem.Id).quantity != quoteLineItem.quantity){
					updateValue = true;
				}
				if(oldMap.get(quoteLineItem.Id).DataEntrega__c != quoteLineItem.DataEntrega__c){
					updateValue = true;
				}
				if(updateValue){
					Quote quote = new Quote();
					quote.id = quoteLineItem.QuoteId;
					quote.SincronizaTotvs__c = true;			  
					quote.Status = 'Negociação';
					quote.AprovaCredito__c = false;
					if(!quoteForUpdateMap.containsKey(quote.Id)) quoteForUpdateMap.put(quote.Id, quote);	 
				}
			}
		}	

		if(!quoteForUpdateMap.isEmpty()) update quoteForUpdateMap.values();
		return refresh( String.valueOf( quote.id ));
		
	}

	public PageReference UpdateQuote(List<QuoteLineItem> quoteLineItens){
		Map<Id, Quote> quoteForUpdateMap = new Map<Id, Quote>();
		Set<Id> recordsId = new Set<Id>();
		for(QuoteLineItem quoteLine : quoteLineItens){
			recordsId.add(quoteLine.QuoteId);
		}
		Map<Id, Quote> mapQuotes = QuoteDAO.getInstance().getMapQuote(recordsId);
		Boolean updateValue;
		for (QuoteLineItem quoteLineItem : quoteLineItens) {
			updateValue = false;
			if((!mapQuotes.get(quoteLineItem.QuoteId).Status.Equals('Fechado ganha'))&&(!mapQuotes.get(quoteLineItem.QuoteId).Status.Equals('Fechado perdido'))){			
				updateValue = true;
			} 
            Quote quote = new Quote();
            quote.SincronizaTotvs__c = true;
            quote.id = quoteLineItem.QuoteId;
			if(updateValue){
				quote.Status = 'Negociação';
			}	 
			if(!quoteForUpdateMap.containsKey(quote.Id)) quoteForUpdateMap.put(quote.Id, quote);
		}	

		if(!quoteForUpdateMap.isEmpty()) update quoteForUpdateMap.values();
		return refresh( String.valueOf( quote.id ));
		
	}

	public PageReference UpdateQuoteDelete(List<QuoteLineItem> quoteLineItemsOld){
		Map<Id, Quote> quoteForUpdateMap = new Map<Id, Quote>();
		for(QuoteLineItem quoteLineItemOld : quoteLineItemsOld){
			Quote quote = new Quote();
            quote.SincronizaTotvs__c = true;
            quote.id = quoteLineItemOld.QuoteId;
			quote.Status = 'Negociação';
			if(!quoteForUpdateMap.containsKey(quote.Id)) quoteForUpdateMap.put(quote.Id, quote);		
		}

		if(!quoteForUpdateMap.isEmpty()) update quoteForUpdateMap.values();
		return refresh( String.valueOf( quote.id ));
		
	}

	public PageReference refresh(String idToRefresh) {
        
        PageReference page = new PageReference('/lightning/r/Quote/'+ idToRefresh +'/view');
        page.setRedirect(true);

        return page;
    }

}