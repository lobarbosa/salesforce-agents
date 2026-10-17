public class FreteIntegrationBO implements IProcessingQueue {
	public FreteIntegrationBO() {}
    public class IntegrationException extends Exception {}

	public static void executeQueue( String queueId , String recordId, String eventName, String payload ) {
       
        if( eventName.equals( QueueEventNames.FRETE_SALESFORCE_TO_TOTVS.name() ) )
            sendToTotvs( queueId, eventName, payload, recordId );
        
    }

	public static String getJsonRequest( Frete__c frete ) {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
            gen.writeStringField( 'FILIAL', Util.getString( frete.UnidadeFilial__r.codigo__c ) );
			gen.writeStringField( 'CLILOJA', Util.getString( frete.Cliente__r.codigo__c ) );
			gen.writeNumberField( 'QTDE', Util.getDecimal( Util.getString( frete.Quantidade__c ) ));
			gen.writeNumberField( 'PESO', Util.getDecimal( Util.getString( frete.Quantidade__c ) ));
		gen.writeEndObject();
        return (gen.getAsString());
	}

	@future(callout=true)
    public static void sendToTotvs(String queueId, String eventName, String payload, String recordId){
		try {
            // WSTotvs service                         = new WSTotvs();
			List<Frete__c> freteForUpdate 			= new List<Frete__c>();
            // String res                              = service.freteProcessor( payload );

            WSTotvs wst = new WSTotvs('freteProcessor', payload);
            String res = wst.Invoke();

            if (!res.equals('500') && !res.equals('503')){                 
                 Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped( res );

                for (Object objFrete : (List<Object>) responseMap.get('CALCFRETE') ) {
                    Map<String, Object> mapFrete = ( Map<String, Object> ) objFrete;

                    freteForUpdate.add( new Frete__c( Id = recordId,
                                                	  ValorUnitariokg__c = Util.getDecimal( Util.getString( mapFrete.get('VALOR'))).setScale(3)
                                                    	));
                    
                }

                ProcessControl.ignoredByTrigger = true;
                if(!freteForUpdate.isEmpty()) update freteForUpdate;
                QueueBO.getInstance().updateQueue( queueId, res, '');
                return;                
            }
                        
            update new Frete__c( Id = recordId,   
                                 Msg__c = 'ERRO NO TOTVS: ' + res );
            
            throw new IntegrationException('Erro na integração, serviço TOTVS indisponível');
        } catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        }  
	}

}