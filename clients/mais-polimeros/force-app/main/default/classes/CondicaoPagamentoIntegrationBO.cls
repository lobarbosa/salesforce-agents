/**
 *    @author Lucas Oliveira
 *    @class WS for integration of CondicaoPagamento__c object
*/
public with sharing class CondicaoPagamentoIntegrationBO implements IProcessingQueue {
	public CondicaoPagamentoIntegrationBO() {}

	public static void executeQueue( String queueId , String recordId, String eventName, String payload ) {
       
		try{
		
			if( eventName.equals( QueueEventNames.CONDICAOPAGAMENTO_TOTVS_TO_SALESFORCE.name() ) )
				reciveToSalesforce( queueId, eventName, payload );
	   	
		}catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );            
        }
        
    }

	 public static void reciveToSalesforce(String queueId, String eventName, String payload){         
		Map<String, Object> resultMap           = (Map<String, Object>) JSON.deserializeUntyped( payload );
		List<Object> condicoesPagamento         = (List<Object>) resultMap.get( 'paymentConditions' );
		Schema.SObjectField totvsCode           = CondicaoPagamento__c.Fields.codigo__c;
		Boolean error                           = false;
		
		JSONGenerator gen   = JSON.createGenerator(true);
		gen.writeStartObject();
				gen.writeFieldName('paymentConditions');
				gen.writeStartArray();
				for (Object obj : condicoesPagamento ) {
					Map<String, Object> mapCondicoesPagamento = ( Map<String, Object> ) obj;
					
					CondicaoPagamento__c condicaoPagamento = new CondicaoPagamento__c(
						codigo__c           = Util.getString(mapCondicoesPagamento.get('code')),
						Name         = Util.getString(mapCondicoesPagamento.get('paymentCondition')),
						descricao__c        = Util.getString(mapCondicoesPagamento.get('description')),
						BloqueadoSim__c     = !Util.getBoolean(mapCondicoesPagamento.get('isActive'))
					);

					ProcessControl.ignoredByTrigger = true;  	
					Database.UpsertResult result = Database.Upsert(condicaoPagamento, totvsCode, false); 					
					String operation = result.isCreated() ? 'inserted' : 'updated';                    
					gen.writeStartObject();
					if (result.isSuccess()) {
						gen.writeStringField('paymentCondition', Util.getString(mapCondicoesPagamento.get('code')));
						gen.writeStringField('message','Successfully '+ operation +' payment condition');
					}else{
						error = true;
						for(Database.Error err : result.getErrors()) {
							gen.writeStringField('paymentCondition', Util.getString(mapCondicoesPagamento.get('code')));
							gen.writeStringField('message', err.getMessage());
						} 
					} 
					gen.writeEndObject();  
				}
				gen.writeEndArray();
		gen.writeEndObject();
		
		if (error){
			QueueBO.getInstance().updateQueue( queueId, '', gen.getAsString());
			return;
		}		
		QueueBO.getInstance().updateQueue( queueId, '');
  }
}
/* JSON RECIVED SAMPLE
{
  "paymentConditions": [
    {
      "code": "AXidgus78",
      "paymentCondition": "40 / 50 / 94",
      "description": "A prazo",
      "isActive": false
    },
    {
      "code": "AXidgus9",
      "paymentCondition": "40 / 50 / 94",
      "description": "A prazo escalonavel",
      "isActive": false
    }
  ]
}
*/