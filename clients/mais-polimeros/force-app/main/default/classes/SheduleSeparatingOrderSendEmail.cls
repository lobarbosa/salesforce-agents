public class SheduleSeparatingOrderSendEmail implements Schedulable {

	public void execute(SchedulableContext sc) {
		
		// Obtém o horário atual
		DateTime currentDateTime = DateTime.now();
		Time currentTime = currentDateTime.time();

		// Define o intervalo de tempo desejado, por exemplo, entre 07:30 e 21:00
		Time startTime = Time.newInstance(7, 30, 0, 0); // 07:30
		Time endTime = Time.newInstance(21, 0, 0, 0); // 21:00

		// Verifica se o horário atual está dentro do intervalo desejado
		if (currentTime >= startTime && currentTime <= endTime) {
			// Coloque aqui a lógica que deve ser executada apenas no horário determinado
			System.debug('Executando dentro do horário especificado.');

			sendOrderEmail();

		} else {
			System.debug('Fora do horário especificado.');
		}
		
	}

	public static void sendOrderEmail() {

        Set<String> Ids = new Set<String> ();
		List<PedidoEmail__c> peList = new List<PedidoEmail__c> ();
		List<PedidoEmail__c> emList = new List<PedidoEmail__c> ();

		try {
			//List<EmailTemplate> emailTemplate = [Select Id, Name from EmailTemplate where name in('Enviar Separando Pedido', 'Enviar Nota Fical Emitida') order by Name];
			EmailTemplate emailTemplate = [Select Id, Name from EmailTemplate where name = 'Enviar Separando Pedido'];

			emList = [SELECT Id, Order__c, Tipo__c, ContatoPrincipal__c 
					  FROM PedidoEmail__c 
					  WHERE CreatedDate = Today 
                      AND Tipo__c = '01'
			          AND Executado__c = false 
                      AND Delay__c >= 5
                      AND ContatoPrincipal__c != null
                      LIMIT 10];
            
            for (PedidoEmail__c pe : emList) { Ids.add(pe.Order__c); }
            
            Map<id, Order> orderMap = new Map<id, Order> ([SELECT id, Account.Name, Account.Owner.Email 
														   FROM Order 
                                                           WHERE Id in :ids]);

			// Obtém os e-mails da custom label
        	List<String> standardEmails = System.Label.StandartEmails.split(',');
            System.debug('List size: ' + emList.size());

			for (PedidoEmail__c em : emList) {
                
                Order occ = orderMap.get(em.Order__c);
                
                Account acc = [SELECT Id, Name, Owner.Email
                               FROM Account
                               WHERE Id =: occ.AccountId];

				User usr = [Select Id, name From User where Name = 'Administrador Mais Polímeros'];
				Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
				message.setOrgWideEmailAddressId('0D2N500000002Q1KAI');
				message.setTargetObjectId(usr.Id);
				message.setUseSignature(false);
				message.setBccSender(false);
				message.setSaveAsActivity(false);
				//Get templete id for set the templete.

				message.setTemplateID(emailTemplate.Id);

				message.setWhatId(em.Order__c); //This is important for the merge  fields in template to work
				System.debug('em.Order__c: ' + em.Order__c);

				// Cria a lista de destinatários (toAddresses)
            	List<String> recipients = new List<String>(standardEmails);
            	recipients.add(em.ContatoPrincipal__c); 
                recipients.add(acc.Owner.Email);

            	message.setToAddresses(recipients);
                System.debug('Email send to: ' + recipients);

                
				//message.toAddresses = new String[] { em.ContatoPrincipal__c };
				//message.toAddresses = new String[] { 'lucas.ancelmo@maispolimeros.com.br' };
				//message.toAddresses = new String[] { 'vitor@internix.com.br', 'lucas.ancelmo@maispolimeros.com.br' };

				Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> { message };

				Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

				if (results[0].success)
				{
					System.debug('The email was sent successfully.');
				}
				else
				{
					System.debug('The email failed to send: ' + results[0].errors[0].message);
				}

				PedidoEmail__c emails = new PedidoEmail__c();
				emails.Id = em.Id;
				emails.Executado__c = true;
				peList.add(emails);

			}


		} catch(Exception ex) {
			System.debug('Message: ' + ex.getMessage());
		}


		Database.SaveResult[] srList = Database.update(peList, false);

		// Iterate through each returned result
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess()) {
				// Operation was successful, so get the ID of the record that was processed
				System.debug('Successfully update PedidoEmail ID: ' + sr.getId());
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