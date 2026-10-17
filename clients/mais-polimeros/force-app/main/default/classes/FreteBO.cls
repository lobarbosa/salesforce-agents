public  class FreteBO {
	private static final FreteBO instance = new FreteBO();    
	public FreteBO() {}
    
    public static FreteBO getInstance() {
        return instance;
    }

	public void criaFilaIntegracao(List<Frete__c> listFrete){
		List<Queue__c> listQueue = new List<Queue__c>();
		Set<Id> recordsId = new Set<Id>();
		for(Frete__c frete : listFrete){
			recordsId.add(frete.Id);
		}
		listFrete = FreteDAO.getInstance().getFretes(recordsId);
		for(Frete__c frete : listFrete){
			listQueue.add(new Queue__c(
				EventName__c = QueueEventNames.FRETE_SALESFORCE_TO_TOTVS.name(),
				Status__c    = 'CREATED',
				RecordId__c  = frete.Id,
				Payload__c   = FreteIntegrationBO.getJsonRequest( frete ),  
				IgnoredByTrigger__c = false 
			));
		}
		if(!listQueue.isEmpty()) insert listQueue;
	}
}