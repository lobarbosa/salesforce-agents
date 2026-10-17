/**
 *    @author Lucas Oliveira
 *    @class WS for integration of NotaFiscal__c object
*/

public class NotaFiscalIntegrationBO implements IProcessingQueue {
	public NotaFiscalIntegrationBO() {}

	public static void executeQueue( String queueId , String recordId, String eventName, String payload ) {
		try{
	
			if( eventName.equals( QueueEventNames.NF_TOTVS_TO_SALESFORCE.name() ) )
				reciveToSalesforce( queueId, eventName, payload );
			if( eventName.equals( QueueEventNames.NF_DEVOLUCAO.name() ) )
				devolucaoNF( queueId, eventName, payload );

		}catch( DmlException ex ) {
			QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
		} catch( Exception ex ) {
			QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );            
		}
	}

	public static void reciveToSalesforce(String queueId, String eventName, String payload){         
		Map<String, Object> resultMap           = (Map<String, Object>) JSON.deserializeUntyped( payload );
		List<Object> invoices                   = (List<Object>) resultMap.get( 'Invoices' );
		
		List<OrderItem> itemsToUpdate = new List<OrderItem>();
		Schema.SObjectField totvsCode           = NotaFiscal__c.Fields.Chave__c;
		Boolean error                           = false;

		JSONGenerator gen   = JSON.createGenerator(true);
		gen.writeStartObject();
			gen.writeFieldName('Invoices');
			gen.writeStartArray();

			for (Object obj : invoices ) {
				Map<String, Object> mapNotasFiscais   = ( Map<String, Object> ) obj;
				Map<String, Object> mapItens          = new Map<String, Object>();
				List<Object> items                    = (List<Object>) mapNotasFiscais.get( 'items' );
				String status                         = Util.getString(mapNotasFiscais.get( 'status' ));
				String numeroNota                     = Util.getString(mapNotasFiscais.get( 'number' ));
				List<String> idValid                  = new List<String>();
				integer count = 0;

				for (Object itemDaNota : items){
					Map<String, Object> mapItensNota = ( Map<String, Object> ) itemDaNota;							
					count ++;
					idValid.add(Util.getString(mapItensNota.get('itemId')) ); 						
				}

				List<OrderItem> itensDaNota = [SELECT Id, NotaFiscal__c, Status__c FROM OrderItem WHERE Id in :idValid]; 
				
				for ( OrderItem opotunittyLineIt : itensDaNota){
					mapItens.put(opotunittyLineIt.Id, opotunittyLineIt);		
				}

				if(itensDaNota.size() != count){											
					error = true;
					for (Object item : items) {
						Map<String, Object> mapItensNota = ( Map<String, Object> ) item;
						if (mapItens.containsKey(Util.getString(mapItensNota.get('itemId'))) == false){
							gen.writeStartObject();
								gen.writeStringField('invoice', numeroNota );
								gen.writeStringField('message', 'Invalid item id '+  Util.getString(mapItensNota.get('itemId')));
							gen.writeEndObject();
						}							
					}
					continue;
				}
				

					for (Object itemDaNota : items){
						Map<String, Object> mapItensNota = ( Map<String, Object> ) itemDaNota;
						NotaFiscal__c nf = new NotaFiscal__c(
							valorTotalNota__c        = Util.getDecimal( Util.getString(  mapNotasFiscais.get('total')) ),
							QuantidadeTotal__c       = Util.getDecimal( Util.getString(  mapNotasFiscais.get('quantidadetotal')) ),
							Status__c                = Util.getString(  mapNotasFiscais.get('status') ),
							DataEmissao__c           = Util.getDate(    mapNotasFiscais.get('issueDate') ),
							NumeroNota__c            = numeroNota,
							Chave__c				 = Util.getString( numeroNota + mapItensNota.get('itemId')),
							Conta__c                 = AccountDAO.getInstance().accountByTOTVS( Util.getString(  mapNotasFiscais.get('clientCode') )),
							ChaveNFe__c				 = Util.getString(mapNotasFiscais.get('chaveNFe'))
						);
						ProcessControl.ignoredByTrigger     = true; 
						
						Database.UpsertResult result = Database.Upsert(nf, totvsCode, false);
						String operation = result.isCreated() ? 'inserted' : 'updated';                    
						
						gen.writeStartObject();
						if (result.isSuccess()) {
							gen.writeStringField('invoice', numeroNota );
							gen.writeStringField('message','Successfully '+ operation +' invoice');
						}else{
							String except = '';
							error = true;
							gen.writeStringField('invoice', numeroNota );
							for(Database.Error err : result.getErrors()) {
								except = except + err.getMessage(); 
							} 
							gen.writeStringField('message', except);
							gen.writeEndObject();
							continue;
						} 
						gen.writeEndObject();

						ProcessControl.ignoredByTrigger     = false;

						itemsToUpdate.add(new OrderItem(
							Id            = Util.getString(mapItensNota.get('itemId')),
							NotaFiscal__c = nf.Id,
							Status__c     = status,
							ByPassVr__c  = true
						));				
					}
					Update itemsToUpdate;

					for (OrderItem iu : itemsToUpdate){
						iu.ByPassVr__c  = false;
					}
					Update itemsToUpdate;
								
				itemsToUpdate.clear();
				}
				gen.writeEndArray(); 
			gen.writeEndObject();				
		if (error){
			QueueBO.getInstance().updateQueue( queueId, '', gen.getAsString());
			return;
		}
		QueueBO.getInstance().updateQueue( queueId, '' );
	}		

	public static void devolucaoNF(String queueId, String eventName, String payload){         

		Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
		List<Object> lstInvoices = (List<Object>) resultMap.get('Invoices');

		List<String> lstItemIds = new List<String>();
		List<String> lstItemOppIds = new List<String>();

		Map<String,String> mapResultIds = new Map<String,String>();
		Map<String,Object> mapInvoices = new Map<String,Object>();

		for (Object obj : lstInvoices) {
			Map<String, Object> mapNotasFiscais = ( Map<String, Object> ) obj;
			String itemId = Util.getString(mapNotasFiscais.get('itemId'));

			if(itemId.left(3) == '00k'){
				OrderItem oi = OrderDAO.getOrderItemByOppItemId(itemId);
				lstItemIds.add(oi.Id);
				mapInvoices.put(oi.Id, obj);
			} else {
				lstItemIds.add(itemId);
				mapInvoices.put(itemId, obj);	
			}
		}

		List<OrderItem> newOrderItems = new List<OrderItem>();
		List<OrderItem> lstOrderItems = OrderDAO.getOrderItems(lstItemIds);

		Boolean error = false;
		JSONGenerator gen   = JSON.createGenerator(true);

		system.debug('lstOrderItems: ' + lstOrderItems);
		system.debug('lstOrderItems.size(): ' + lstOrderItems.size());
		system.debug('lstItemIds.size(): ' + lstItemIds.size());

		if(lstOrderItems.size() < lstItemIds.size()){

			error = true;
			for (OrderItem oi : lstOrderItems){
				mapResultIds.put(oi.Id, oi.Id);		
			}

			system.debug('mapResultIds: ' + mapResultIds);
			
			for (Object item : lstInvoices) {
				Map<String, Object> mapNotasFiscais = ( Map<String, Object> ) item;
				if (mapResultIds.containsKey(Util.getString(mapNotasFiscais.get('itemId'))) == false){
					gen.writeStartObject();
						gen.writeStringField('itemId', Util.getString(mapNotasFiscais.get('itemId')));
						gen.writeStringField('message', 'Item não encontrado');
					gen.writeEndObject();
				}
			}

			system.debug('gen: ' + gen.getAsString());

		} else {

			for (OrderItem oi : lstOrderItems) {
				Map<String, Object> mapItem = ( Map<String, Object> ) mapInvoices.get(String.valueOf(oi.Id));

				Decimal quantidade = Util.getDecimal(Util.getString(mapItem.get('quantidade')));
				Date data = Util.getDate(mapItem.get('data'));

				List<OrderItem> lstOrderItemOriginal = [	SELECT  Id
															FROM    OrderItem
															WHERE   ItemOriginal__c = :oi.Id
															AND		Data_entrada__c = :data
															AND		QuantidadeDevolvida__c = :quantidade	];
				system.debug('lstOrderItemOriginal: ' + lstOrderItemOriginal);

				if (lstOrderItemOriginal == null || lstOrderItemOriginal.size() == 0){
					OrderItem newOrderItem = new OrderItem (
						OrderId = oi.OrderId,
						PricebookEntryId = oi.PricebookEntryId,
						ItemOriginal__c = oi.Id,
						UnitPrice = oi.UnitPrice,
						TESEditavel__c = oi.TESEditavel__c,
						NumeroPediClin__c = oi.NumeroPediClin__c,
						NumeroItemCli__c = oi.NumeroItemCli__c,
						Quantity = 0,
						Status__c = 'Devolvido',
						QuantidadeDevolvida__c = quantidade,
						ValorDevolvido__c = Util.getDecimal(Util.getString(mapItem.get('valor'))),
						DataEntrega__c = data,
						Data_entrada__c = data
					);
					newOrderItems.add(newOrderItem);
				}
			}
			system.debug('newOrderItems: ' + newOrderItems);
			Database.SaveResult[] result = Database.insert(newOrderItems, true);

			gen.writeStartObject();
				gen.writeFieldName('items');
				gen.writeStartArray();
				for(Integer i=0; i < result.size(); i++){
					gen.writeStartObject();
						if (result.get(i).isSuccess()) {
							gen.writeStringField('itemId', result.get(i).getId() );
							gen.writeStringField('message', 'SUCCESS');
						} else {
							error = true;
							Database.Error dberro = result.get(i).getErrors().get(0);
							gen.writeStringField('itemId', newOrderItems.get(i).Id );
							gen.writeStringField('message', dberro.getMessage());
						}
					gen.writeEndObject();
				}
				gen.writeEndArray();
			gen.writeEndObject();
		}

		if(error){
			QueueBO.getInstance().updateQueue(queueId, '', gen.getAsString());
		} else {
			QueueBO.getInstance().updateQueue(queueId, '');
		}

	}
}