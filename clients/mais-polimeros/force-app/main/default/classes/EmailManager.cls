public class EmailManager {
	// Public method
    public void sendMail(List<String> addresses, String subject, String body) {
        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId('0D2N500000002Q1KAI');
        mail.setToAddresses(addresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body);

		// Pass this email message to the built-in sendEmail method
		// of the Messaging class
		Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		// Call a helper method to inspect the returned results
		inspectResults(results);
	}
	// Helper method
	private static Boolean inspectResults(Messaging.SendEmailResult[] results) {
		Boolean sendResult = true;
		// sendEmail returns a list of result objects.
		// Iterate through the list to inspect results.
		// In this class, the methods send only one email,
		// so we should have only one result.
		for (Messaging.SendEmailResult res : results) {
			if (res.isSuccess()) {
				System.debug('Email sent successfully');
			}
			else {
				sendResult = false;
				System.debug('The following errors occurred: ' + res.getErrors());
			}
		}
		return sendResult;
	}
}