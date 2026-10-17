global class ScheduleBatchCurvaABC implements Schedulable {
	/**
	 * @description Executes the scheduled Apex job. 
	 * @param sc contains the job ID
	 */
	global void execute(SchedulableContext sc) {
		paretoClass();

	}

	@future
	public static void paretoClass() {

		List<SObject> scope = new List<SObject> ();
		scope = [select AccountId, SUM(Valor_EX_total__c) Total from Order where CreatedDate = LAST_N_DAYS : 90 group by AccountId];

		//System.debug('scope: ' + scope);


		ProcessControl.ignoredByTrigger = true;
		String sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();

		List<Field_History__c> fhs = new List<Field_History__c> ();
		List<Account> accts = new List<Account> ();
		List<Account> emailList = new List<Account> ();
		List<Decimal> values = new List<Decimal> ();
		List<String> item = new List<String> ();

		Set<String> ids = new Set<String> ();

		for (sObject orders : scope) {
			//System.debug(orders.get('AccountId'));
			//System.debug(orders.get('Total'));

			item.add((String) orders.get('AccountId'));
			values.add((Decimal) orders.get('Total'));
			ids.add((String) orders.get('AccountId'));
		}

		//System.debug('Ids: ' + ids);
		Map<Id, Account> accMap = new Map<Id, Account> ([SELECT Id, Name, Curva_ABC__c, Curva_ABC_Old_Value__c FROM Account WHERE Id IN :Ids]);
		//System.debug('accMap: ' + accMap);

		Decimal totalValue = 0;
		for (Decimal value : values) {
			totalValue += value;
		}

		System.debug('totalValue: ' + totalValue);

		List<ParetoResult> results = new List<ParetoResult> ();
		Decimal cumulativeValue = 0;

		for (Integer i = 0; i<values.size(); i++) {
			Decimal individualValue = values[i];
			Decimal individualParticipation = totalValue> 0 ? (individualValue / totalValue) * 100 : 0;
			cumulativeValue += individualValue;
			Decimal cumulativeParticipation = totalValue > 0 ? (cumulativeValue / totalValue) * 100 : 0;

			// Determinando o tipo com base na participação acumulada

			System.debug('cumulativeParticipation: ' + cumulativeParticipation);

			String type;
			if (cumulativeParticipation >= 95) { 
				type = 'A';
			} else if (cumulativeParticipation > 80 && cumulativeParticipation< 95) {
				type = 'B';
			} else if (cumulativeParticipation < 80 && cumulativeParticipation <> 0) {
				type = 'C';
			}

			Field_History__c fh = new Field_History__c();
			fh.Tracked_Record_Id__c = item[i];
			fh.Tracked_Object__c = 'Account';
			fh.Tracked_Field_Label__c = 'Curva ABC';
			fh.Tracked_Field_API__c = 'Curva_ABC__c';
			fh.Old_Value__c = accMap.get(item[i]).Curva_ABC__c == accMap.get(item[i]).Curva_ABC_Old_Value__c ? '' : accMap.get(item[i]).Curva_ABC__c;
			fh.New_Value__c = type;
			fhs.add(fh);


			//System.debug('item: ' + item[i] + '  ' + 'type: ' + type);

			//System.debug('Result: ' + accMap.get(item[i]).Curva_ABC__c);

			Date dToday = Date.today();
			Account acct = new Account();
			acct.id = item[i];

			if (accMap.get(item[i]).Curva_ABC__c != accMap.get(item[i]).Curva_ABC_Old_Value__c) {

				acct.Curva_ABC_Old_Value__c = accMap.get(item[i]).Curva_ABC__c;

			}

			acct.Curva_ABC_Old_Value_Date__c = Date.valueOf(dToday.year() + '-' + dToday.month() + '-' + dToday.day());

			//acct.Curva_ABC_Old_Value__c = '';
			//acct.Curva_ABC__c = '';
			acct.Curva_ABC__c = type;

			acct.individualParticipation__c = String.valueOf(individualParticipation.setscale(2));
			acct.cumulativeParticipation__c = String.valueOf(cumulativeParticipation.setscale(2));
			acct.individualTotal__c = String.valueOf(values[i]);
			accts.add(acct);



		}



		System.debug('accts: ' + accts);

		Database.insert(fhs, false); //Não utilizado

		Database.SaveResult[] srList = Database.update(accts, false);
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess()) {
				// This condition will be executed for successful records and will fetch
				// the ids of successful records
				System.debug('Successfully updated Invoice. Invoice ID is : ' + sr.getId());
			} else {
				// This condition will be executed for failed records
				for (Database.Error objErr : sr.getErrors()) {
					//System.debug('The following error has occurred.');

					// Printing error message in Debug log
					//System.debug(objErr.getStatusCode() + ': ' + objErr.getMessage());
					//System.debug('Invoice oject field which are affected by the error:'
					//   + objErr.getFields());
				}
			}
		}


		ProcessControl.ignoredByTrigger = false;

		SendEmailNotification();

		ProcessControl.ignoredByTrigger = false;

	}

	private static void SendEmailNotification() {

		List<Account> accList = new List<Account> ([SELECT Id, Name, Curva_ABC__c, Curva_ABC_Old_Value__c FROM Account WHERE Curva_ABC_Old_Value_Date__c = Today]);

		Boolean curvaTipoA = false;
		String emailBody = '<p><b>Classificação de Contas por Periodo</b></p>';
		emailBody += '<html><table border = "1" style="border: 1px; border-collapse: collapse;">';
		emailBody += '<tr>';
		//emailBody += '<th>First Name</th>';
		emailBody += '<th align="center">Conta</th>';
		emailBody += '<th align="center">Curva (anterior)</th>';
		emailBody += '<th align="center">Curva (atual)</th>';
		emailBody += '</tr>';

		for (Account ac : accList) {
			if (ac.Curva_ABC__c != ac.Curva_ABC_Old_Value__c && ac.Curva_ABC_Old_Value__c != null) {
				System.debug('Entrou');
				curvaTipoA = true;
				emailBody += '<tr>';
				//emailBody += '<td>' + ac.Id + '</td>';
				emailBody += '<td align="center"><a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + ac.Id + '">' + ac.Name + '</a></ td>';
				emailBody += '<td align="center">' + ac.Curva_ABC_Old_Value__c + '</td>';
				emailBody += '<td align="center">' + ac.Curva_ABC__c + '</td>';
				emailBody += '</tr>';

			}
		}

		emailBody += '</table></html>';

		if (curvaTipoA == true && !Test.isRunningTest()) {
			EmailManager em = new EmailManager();
			em.sendMail(new List<String>{'lucas.ancelmo@maispolimeros.com.br'}, 'Classificação de contas (Curva A) ', emailBody);
		}
	}

	private class ParetoResult {
		public String item { get; set; }
		public Decimal individualParticipation { get; set; }
		public Decimal cumulativeParticipation { get; set; }
		public String type { get; set; } // Adicionando o tipo

	}
}