public class BatchCurvaABC implements Database.Batchable<sObject>, Database.Stateful {


	public System.Iterable<sObject> start(Database.BatchableContext BC) {

		return[select AccountId, SUM(Valor_EX_total__c) Total from Order where CreatedDate = LAST_N_DAYS : 90 group by AccountId];
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope) {

		ProcessControl.ignoredByTrigger = true;

		List<Account> accts = new List<Account> ();
		List<Decimal> values = new List<Decimal> ();
		List<String> item = new List<String> ();


		for (sObject orders : scope) {

			//System.debug(orders.get('AccountId'));
			//System.debug(orders.get('Total'));

			item.add((String) orders.get('AccountId'));
			values.add((Decimal) orders.get('Total'));
		}


		//System.debug('Values: ' + values);

		Decimal totalValue = 0;
		for (Decimal value : values) {
			totalValue += value;
		}

		//System.debug('totalValue: ' + totalValue);

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
			if (cumulativeParticipation <= 80 && cumulativeParticipation<> 0) {
				type = 'A';
			} else if (cumulativeParticipation > 80 && cumulativeParticipation< 95) {
				type = 'B';
			} else {
				type = 'C';
			}

			System.debug('item: ' + item[i] + '  ' + 'type: ' + type);

			Account acct = new Account();
			acct.id = item[i];
			acct.Curva_ABC__c = type;
			accts.add(acct);

		}

		//System.debug(accts);

		Database.SaveResult[] srList = Database.update(accts, false);
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess()) {
				// This condition will be executed for successful records and will fetch
				// the ids of successful records
				System.debug('Successfully updated Invoice. Invoice ID is : ' + sr.getId());
			} else {
				// This condition will be executed for failed records
				for (Database.Error objErr : sr.getErrors()) {
					System.debug('The following error has occurred.');

					// Printing error message in Debug log
					System.debug(objErr.getStatusCode() + ': ' + objErr.getMessage());
					System.debug('Invoice oject field which are affected by the error:'
					             + objErr.getFields());
				}
			}
		}

	}

	public void finish(Database.BatchableContext BC) {
		
		ProcessControl.ignoredByTrigger = False;
	}

	public class ParetoResult {
		public String item { get; set; }
		public Decimal individualParticipation { get; set; }
		public Decimal cumulativeParticipation { get; set; }
		public String type { get; set; } // Adicionando o tipo

	}

}