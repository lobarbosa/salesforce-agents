public with sharing class EstoqueIntegrationBO implements IProcessingQueue {
	public EstoqueIntegrationBO() {}
    public class IntegrationException extends Exception {}

	public static void executeQueue( String queueId , String recordId, String eventName, String payload ) {
       
        if( eventName.equals( QueueEventNames.ESTOQUE_SALESFORCE_TO_TOTVS.name() ) )
            sendToTotvs( queueId, eventName, payload, recordId );
        
    }

	public static String getJsonRequest( Estoque__c item ) {

        JSONGenerator gen = JSON.createGenerator(true);

        String filial  = [ SELECT Codigo__c FROM UnidadeFilial__c WHERE Id =: item.UnidadeFilial__c  ].Codigo__c;
        String produto = [ SELECT Name FROM Product2 WHERE Id =: item.Produto__c  ].Name; 

        gen.writeStartObject();
            gen.writeFieldName('ESTOQUE');
            gen.writeStartArray();
                    gen.writeStartObject();
                        gen.writeFieldName('ITENS');
                        gen.writeStartArray();
                            gen.writeStartObject();                                
                                gen.writeStringField( 'FILIAL',            Util.getString( filial ) );
                                gen.writeStringField( 'PRODUTO',           Util.getString( produto ) );
                            gen.writeEndObject();
                        gen.writeEndArray();
                    gen.writeEndObject();
            gen.writeEndArray();
        gen.writeEndObject(); 
         
        return (gen.getAsString()); 
    }

	@future(callout=true)
    public static void sendToTotvs(String queueId, String eventName, String payload, String recordId){
        try {
            // WSTotvs service                         =  new WSTotvs();
            List<QuoteLineItem> itemLinhaForUpdate  =  new List<QuoteLineItem>();
            List<Estoque__c>    estoqueForUpdate    =  new List<Estoque__c>();
            // String res                              =  service.estoqueProcessor( payload );

            WSTotvs wst = new WSTotvs('estoqueProcessor', payload);
            String res = wst.Invoke();
            
            System.debug( res );

            if (!res.equals('500') && !res.equals('503')){                 
                 Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped( res );

                for (Object objEstoque : (List<Object>) responseMap.get('ESTOQUE') ) {
                    Map<String, Object> mapEstoque = ( Map<String, Object> ) objEstoque;
                    for (Object objItens : (List<Object>) mapEstoque.get('ITENS')) {
                        Map<String, Object> mapItens = ( Map<String, Object> ) objItens;

                        estoqueForUpdate.add( new Estoque__c(       Id                       = recordId,
                                                                    Produto__c               = QuoteDAO.getInstance().getProduto( Util.getString( mapItens.get('PRODUTO')) ),
                                                                    horarioConsulta__c       = System.now(), 
                                                                    QAtual__c                = Util.getDecimal( Util.getString( mapItens.get('QTDEATUAL')) ), 
                                                                    QReserva__c              = Util.getDecimal( Util.getString( mapItens.get('QTDERESERVA')) ), 
                                                                    QDisponivel__c           = Util.getDecimal( Util.getString( mapItens.get('QTDEDISPONIVEL')) ),
                                                             		QCompras__c              = Util.getDecimal( Util.getString( mapItens.get('QTDECOMPRAS')) ),
                                                                    QSolCompras__c           = Util.getDecimal( Util.getString( mapItens.get('QTDESOLCOMPRAS')) ),
                                                                    USaida__c                = Util.getDate( mapItens.get('DATAULTIMASAI')),
                                                                    Mensagem__c              = Util.getString(  mapItens.get('MENSAGEM') )
                                                                ));
                    }
                }

                ProcessControl.ignoredByTrigger = true;
                update estoqueForUpdate;
                QueueBO.getInstance().updateQueue( queueId, res, '');
                return;                
            }
                        
            Update new Estoque__c(  Id                  = recordId,                                    
                                    horarioConsulta__c  = System.now(), 
                                    Mensagem__c         = 'ERRO NO TOTVS ->' + res );
            
            throw new IntegrationException('Erro na integração, serviço TOTVS indisponível');

        } catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        }  
    }
}