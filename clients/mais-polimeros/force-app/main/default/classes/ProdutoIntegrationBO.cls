/**
 *    @author Lucas Oliveira
 *    @class WS for integration of Product2 object
*/
public class ProdutoIntegrationBO implements IProcessingQueue{
	public ProdutoIntegrationBO() {}

	public static void executeQueue( String queueId , String recordId, String eventName, String payload ) {
		try{
			
			if( eventName.equals( QueueEventNames.PRODUTO_TOTVS_TO_SALESFORCE.name() ) )
				reciveToSalesforce( queueId, eventName, payload );
		
		}catch( DmlException ex ) {
			QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
		} catch( Exception ex ) {
			QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );            
		}
	}

	public static void reciveToSalesforce(String queueId, String eventName, String payload){         
		
		Boolean error                  = false;
		JSONGenerator gen   = JSON.createGenerator(true);

		// ('"isActive": false', '"isActive":false').replace('"isActive": true', '"isActive":true');
		Payload = payload.replaceAll(' ', '');

		try {
		
			Map<String, Object> resultMap  = (Map<String, Object>) JSON.deserializeUntyped( payload );
			List<Object> produtos          = (List<Object>) resultMap.get( 'Products' );
			Schema.SObjectField totvsCode  = Product2.Fields.CodigoTotvs__c;
			
		
			gen.writeStartObject();
				gen.writeFieldName('Products');
				gen.writeStartArray();
				for (Object obj : produtos ) {
					Map<String, Object> mapProdutos = ( Map<String, Object> ) obj;
					
					Product2 produto = new Product2(
						CodigoTotvs__c           = Util.getString(  mapProdutos.get('productCode') ),
						Name                     = Util.getString(  mapProdutos.get('productName') ),
						Description              = Util.getString(  mapProdutos.get('description') ),
						DescricaoTecnica__c      = Util.getString(  mapProdutos.get('techDescription') ),
						Family                   = Util.getString(  mapProdutos.get('family') ),
						DescritivoFamilia__c     = Util.getString(  mapProdutos.get('familyDescription') ),
						IsActive                 = Util.getBoolean( mapProdutos.get('isActive') )
					);
					ProcessControl.ignoredByTrigger = true;  
					Database.UpsertResult result = Database.Upsert(produto, totvsCode, false);  
					String operation = result.isCreated() ? 'inserted' : 'updated';                    
						gen.writeStartObject();
						if (result.isSuccess()) {
							gen.writeStringField('product', Util.getString(  mapProdutos.get('productCode')) );
							gen.writeStringField('message','Successfully '+ operation +' product');
						}else{
							error = true;
							for(Database.Error err : result.getErrors()) {
								gen.writeStringField('product', Util.getString(  mapProdutos.get('productCode')) );
								gen.writeStringField('message', err.getMessage());
							} 
						} 
						gen.writeEndObject();  
					}
				gen.writeEndArray();
			gen.writeEndObject();
		} catch (Exception ex){
			QueueBO.getInstance().updateQueue( queueId, '', ex.getStackTraceString());
			return;
		}

		if (error){
			QueueBO.getInstance().updateQueue( queueId, '', gen.getAsString());
			return;
		}		
		QueueBO.getInstance().updateQueue( queueId, '');
  }
}
/* JSON RECIVED SAMPLE
{
  "Products": [
    {
      "productCode": "ABS99999",
      "productName": "ABS99999",
      "description": "High Perform ABS",
      "techDescription": "High Perform ABS for tires",
      "family": "ESPEC",
      "familyDescription": "ACRILONITRILO BUTADIENO ESTIRE",
      "isActive": true
    },
    {
      "productCode": "ABS88888",
      "productName": "ABS88888",
      "description": "High Perform ABS",
      "techDescription": "High Perform ABS for slim tires",
      "family": "ESPEC",
      "familyDescription": "ACRILONITRILO BUTADIENO ESTIRED 2 PACKS",
      "isActive": true
    }
  ]
}
*/