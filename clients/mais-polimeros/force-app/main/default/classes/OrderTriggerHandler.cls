public class OrderTriggerHandler {

	// public static void saveFieldHistories(List<Order> newOrders, Map<Id, Order> oldMap) {

	// 	//System.debug('newAccounts: ' + newOrders);
	// 	//System.debug('oldMap: ' + oldMap);

	// 	FieldTrackerService fts = FieldTrackerService.getInstance('Order');
	// 	fts.saveFieldHistories(newOrders, oldMap);
	// }


	public List<Order> oldList;
	public List<Order> newList;
	public Map<Id, Order> oldMap;
	public Map<Id, Order> newMap;

	public void beforeUpdate() {

		for (Order o : newList) {

            if(o.SalesStoreId == null || (o.status != 'Ativada (não usar)' && o.status != 'Activated')){

                if (o.QuantidadeItens__c > 0 &&
                (o.QuantidadeItens__c != oldMap.get(o.Id).QuantidadeItens__c ||
                o.QuantidadeItensFaturados__c != oldMap.get(o.Id).QuantidadeItensFaturados__c ||
                o.QuantidadeItensCancelados__c != oldMap.get(o.Id).QuantidadeItensCancelados__c)) {

                    if (o.QuantidadeItens__c == o.QuantidadeItensCancelados__c)
                    o.status = 'Cancelado';
                    else if (o.QuantidadeItens__c == o.QuantidadeItensFaturados__c)
                    o.status = 'Faturado Totalmente';
                    else if (o.QuantidadeItensFaturados__c > 0 && o.QuantidadeItensFaturados__c<o.QuantidadeItens__c)
                    o.status = 'Faturado Parcialmente';
                    else if (o.QuantidadeItensFaturados__c == 0)
                    o.status = 'Aguardando Faturamento';
                }

            }

		}
	}

	public void afterUpdate() {

		// for (Order a : newList) {
		// 	if (a.Status == 'Aguardando Faturamento') {

		// 		User usr = [Select Id, name From User where Name = 'Administrador Mais Polímeros'];
		// 		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

		// 		message.setOrgWideEmailAddressId('0D2N500000002Q1KAI');
		// 		message.setTargetObjectId(usr.Id);
		// 		message.setUseSignature(false);
		// 		message.setBccSender(false);
		// 		message.setSaveAsActivity(false);
		// 		EmailTemplate emailTemplate = [Select Id, Subject, Description, HtmlValue, DeveloperName, Body from EmailTemplate where name = 'Template Email Cliente'];
		// 		//Get templete id for set the templete.

		// 		message.setTemplateID(emailTemplate.Id);
		// 		message.setWhatId(a.Id); //This is important for the merge  fields in template to work

		// 		//message.toAddresses = new String[] { 'lucas.ancelmo@maispolimeros.com.br' };
		// 		message.toAddresses = new String[] { 'vitor@internix.com.br' };

		// 		Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> { message };

		// 		Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

		// 		if (results[0].success)
		// 		{
		// 			System.debug('The email was sent successfully.');
		// 		}
		// 		else
		// 		{
		// 			System.debug('The email failed to send: ' + results[0].errors[0].message);
		// 		}
		// 	}
		// }
	}


}