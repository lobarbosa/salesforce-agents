public class SheduleCreateInvoiceDelivery implements Schedulable {

    public void execute(SchedulableContext sc) {
        sendOrderEmail();
    }

    public static void sendOrderEmail() {
        List<Order> ordersList = new List<Order>();
        List<OrderItem> emList = new List<OrderItem>();
        List<PedidoEmail__c> orderEmailList = new List<PedidoEmail__c>();

        try {
            // Create records of type 01 (Separating Order)
            List<Order> orders = [SELECT Id, CodigoTOTVS__c, Status, SeparatingEmail__c
                                  FROM Order
                                  WHERE Status = 'Aguardando Faturamento'
                                  AND SeparatingEmail__c = false
                                  AND CreatedDate = TODAY];         

            for (Order od : orders) {
                PedidoEmail__c pedidoEmail = new PedidoEmail__c(
                    Order__c = od.Id,
                    CodigoTOTVS__c = od.CodigoTOTVS__c,
                    Tipo__c = '01'
                );
                orderEmailList.add(pedidoEmail);

                od.SeparatingEmail__c = true;
                ordersList.add(od);
            }

            // Create records of types 02 and 03 (Invoiced Invoice and Delivered Order)
            Map<String, List<OrderItem>> groupedByInvoicedItems = new Map<String, List<OrderItem>>();
            List<OrderItem> invoicedItems = [SELECT OrderId, NotaFiscal__c, NFNumero__c, Link_NFe__c, CodigoTOTVS__c, DataEntrega__c, Email__c 
                                             FROM OrderItem
                                             WHERE Status__c = 'Faturado' 
                                             AND Email__c = false 
                                             AND DataEmissaoNota__c = TODAY];

            for (OrderItem item : invoicedItems) {
                String nfNumero = item.NFNumero__c;

                if (groupedByInvoicedItems.containsKey(nfNumero)) {
                    groupedByInvoicedItems.get(nfNumero).add(item);
                } else {
                    groupedByInvoicedItems.put(nfNumero, new List<OrderItem>{item});
                }

                OrderItem up = new OrderItem();
                up.Id = item.Id;
                up.Email__c = true;
                emList.add(up);
            }

            for (String nfNumero : groupedByInvoicedItems.keySet()) {
                List<OrderItem> items = groupedByInvoicedItems.get(nfNumero);

                PedidoEmail__c pedidoNotaFiscais = new PedidoEmail__c();
                pedidoNotaFiscais.Order__c = items.get(0).OrderId;
                pedidoNotaFiscais.Link_NFe__c = items.get(0).Link_NFe__c;
                pedidoNotaFiscais.CodigoTOTVS__c = items.get(0).CodigoTOTVS__c;
                pedidoNotaFiscais.NFNumero__c = items.get(0).NFNumero__c;
                pedidoNotaFiscais.Tipo__c = '02';
                orderEmailList.add(pedidoNotaFiscais);

                PedidoEmail__c pedidoEntregas = new PedidoEmail__c();
                pedidoEntregas.Order__c = items.get(0).OrderId;
                pedidoEntregas.Link_NFe__c = items.get(0).Link_NFe__c;
                pedidoEntregas.CodigoTOTVS__c = items.get(0).CodigoTOTVS__c;
                pedidoEntregas.NFNumero__c = items.get(0).NFNumero__c;
                pedidoEntregas.Tipo__c = '03';
                pedidoEntregas.DataEntrega__c = items.get(0).DataEntrega__c;
                orderEmailList.add(pedidoEntregas);
            }           

        } catch (Exception ex) {
            System.debug('Message: ' + ex.getMessage());
        }

        
        Database.SaveResult[] ordersToUpdate = Database.update(ordersList, false);
        Database.SaveResult[] srEmailList = Database.update(emList, false);
        Database.SaveResult[] srList = Database.insert(orderEmailList, false);
        
        List<PedidoEmail__c> createdRecords = [SELECT Id, Order__c, Tipo__c FROM PedidoEmail__c];
        System.debug('Created PedidoEmail__c records: ' + createdRecords);    
		// Iterate through each returned result
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess()) {
				// Operation was successful, so get the ID of the record that was processed
				System.debug('Successfully inserted: ' + sr.getId());                                            
			}
			else {
				// Operation failed, so get all errors                
				for (Database.Error err : sr.getErrors()) {
					System.debug('The following error has occurred.');
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
					System.debug('Account fields that affected this error: ' + err.getFields());
				}
			}
		}        
    }
}