public with sharing class EstoqueBO {
	private static final EstoqueBO instance = new EstoqueBO();
	private EstoqueBO(){}

	public static EstoqueBO getInstance() {
		return instance; 
	}

	public PageReference criaFilaIntegracaoInsert(List<Estoque__c> estoqueLista){  
		List<Queue__c> queueList = new List<Queue__c>();
		String record;

		for(Estoque__c item : estoqueLista){
			record = item.Id; 
			queueList.add(new Queue__c(
				EventName__c = QueueEventNames.ESTOQUE_SALESFORCE_TO_TOTVS.name(),
				Status__c    = 'CREATED',
				RecordId__c  = record,
				Payload__c   = EstoqueIntegrationBO.getJsonRequest( item ),  
				IgnoredByTrigger__c = false 
			));
		}		

		insert queueList;
		
		PageReference pageRef = new PageReference('/lightning/r/Estoque__c/'+ record +'/view');
		pageRef.setRedirect(true);
		return pageRef;

	}	
}