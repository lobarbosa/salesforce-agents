public class OpportunityBO {
    private static final OpportunityBO instance = new OpportunityBO();
    private OpportunityBO(){}

    public static OpportunityBO getInstance() {
        return instance;
    }

	public Queue__c criaFilaIntegracaoPreco(Opportunity op){ 	
        
        System.debug('>> criaFilaIntegracaoPreco: ');

		Queue__c queue = new Queue__c(
			EventName__c = QueueEventNames.QUOTE_SALESFORCE_TO_TOTVS.name(),
			Status__c    = 'CREATED',
			RecordId__c  = op.Id,
			Payload__c   = OpportunityIntegrationBO.getJsonRequestPreco( op, op.StageName == 'Checagem' ? 'ALT' : 'INC' ),   
			IgnoredByTrigger__c = true 
		);

		insert queue;
		return queue;
	}

}