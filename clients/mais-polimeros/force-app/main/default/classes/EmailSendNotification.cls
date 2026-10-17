public class EmailSendNotification {
	Public static void sendNotification(String acctId) {
		Messaging.SingleEmailMessage message = new
		Messaging.SingleEmailMessage();
		message.setTargetObjectId(UserInfo.getUserId());
		message.setSenderDisplayName('Classificação de conta (Curva ABC)');
		message.setUseSignature(false);
		message.setBccSender(false);
		message.setSaveAsActivity(false);
		EmailTemplate emailTemplate = [Select Id, Subject, Description, HtmlValue, DeveloperName, Body from EmailTemplate where name = 'Test Account Alert Email'];
	
		message.setTemplateID(emailTemplate.Id);
	
		message.setWhatId(acctId);
		message.toAddresses = new String[] { 'Vitor@internix.com.br' };

		Messaging.SingleEmailMessage[] messages = new
		List<Messaging.SingleEmailMessage> { message };

		Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

		if (results[0].success)
		{
			System.debug('The email was sent successfully.');
		}
		else
		{
			System.debug('The email failed to send : ' + results[0].errors[0].message);
		}
	}

}