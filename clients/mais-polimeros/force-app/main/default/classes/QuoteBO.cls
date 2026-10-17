public class QuoteBO {
	private static final QuoteBO instance = new QuoteBO();
	private QuoteBO(){}

	public static QuoteBO getInstance() {
		return instance;
	}

	public Queue__c criaFilaIntegracaoInsert(Quote quote){ 		

		Queue__c queue = new Queue__c(
			EventName__c = QueueEventNames.QUOTE_SALESFORCE_TO_TOTVS.name(),
			Status__c    = 'CREATED',
			RecordId__c  = quote.Id,
			Payload__c   = QuoteIntegrationBO.getJsonRequest( quote, quote.Status == 'Checagem' ? 'ALT' : 'INC' ),   
			IgnoredByTrigger__c = true 
		);
		

		insert queue;
		return queue;
	}

	public void checkCliente(List<Quote> listOfQuote){
		for (Quote item : listOfQuote) {
			if ( item.Status == 'Checagem' ) item.SincronizaTotvs__c = true;
		}
	}
}