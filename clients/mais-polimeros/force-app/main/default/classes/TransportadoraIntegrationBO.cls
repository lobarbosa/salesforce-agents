public class TransportadoraIntegrationBO implements IProcessingQueue{
	public TransportadoraIntegrationBO() {}

	public static void executeQueue( String queueId , String recordId, String eventName, String payload ) {
		try{
			
			if( eventName.equals( QueueEventNames.TRANSPORTADORA_TOTVS_TO_SALESFORCE.name() ) )
				reciveToSalesforce( queueId, eventName, payload );
		
		}catch( DmlException ex ) {
			QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
		} catch( Exception ex ) {
			QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );            
		}
	}

	public static void reciveToSalesforce(String queueId, String eventName, String payload){         
		Map<String, Object> resultMap  = (Map<String, Object>) JSON.deserializeUntyped( payload );
		List<Object> transportadoras          = (List<Object>) resultMap.get( 'Transportadoras' );
		Schema.SObjectField totvsCode  = Transportadora__c.Fields.CodigoTotvs__c;
		Boolean error                  = false;

		JSONGenerator gen   = JSON.createGenerator(true);
		gen.writeStartObject();
			gen.writeFieldName('Transportadoras');
			gen.writeStartArray();
			for (Object obj : transportadoras ) {
				Map<String, Object> mapTransportadoras = ( Map<String, Object> ) obj;
				
				Transportadora__c transportadora = new Transportadora__c(
					CNPJ__c       	= Util.getString(  mapTransportadoras.get('cnpj') ),
					CodigoTOTVS__c  = Util.getString(  mapTransportadoras.get('codigo') ),
					Name    	    = Util.getString(  mapTransportadoras.get('nomeFantasia') ),
					RazaoSocial__c  = Util.getString(  mapTransportadoras.get('razaoSocial') )
				);
				ProcessControl.ignoredByTrigger = true;  
				Database.UpsertResult result = Database.Upsert(transportadora, totvsCode, false);  
				String operation = result.isCreated() ? 'inserted' : 'updated';                    
					gen.writeStartObject();
					if (result.isSuccess()) {
						gen.writeStringField('message','Successfully '+ operation +' product');
					}else{
						error = true;
						for(Database.Error err : result.getErrors()) {
							gen.writeStringField('transportadora', Util.getString(  mapTransportadoras.get('codigo')) );
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