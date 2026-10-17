public Without Sharing class AccountBO {
	private static final AccountBO instance = new AccountBO();
	private AccountBO(){}

	public static AccountBO getInstance() {
		return instance;
	}

	public void criaFilaIntegracaoInsert(Map<Id,Account> oldAccounts, List<Account> accounts){ 
		List<Queue__c> queueList = new List<Queue__c>();

		for(Account account : accounts){

			if (account.beeCnpj__CNPJ__c != oldAccounts.get(account.Id).beeCnpj__CNPJ__c ||
				account.BillingStreet != oldAccounts.get(account.Id).BillingStreet ||
				account.BairroCobranca__c != oldAccounts.get(account.Id).BairroCobranca__c ||
				account.NomeCidadeFormula__c != oldAccounts.get(account.Id).NomeCidadeFormula__c ||
				account.MunicipioFormula__c != oldAccounts.get(account.Id).MunicipioFormula__c ||
				account.CodigoPaisFormula__c != oldAccounts.get(account.Id).CodigoPaisFormula__c ||
				account.CodigoCidadeFormula__c != oldAccounts.get(account.Id).CodigoCidadeFormula__c ||
				account.BillingPostalCode != oldAccounts.get(account.Id).BillingPostalCode ||
				account.Name != oldAccounts.get(account.Id).Name ||
				account.NomeFantasia__c != oldAccounts.get(account.Id).NomeFantasia__c ||
				account.DDD__c != oldAccounts.get(account.Id).DDD__c ||
				account.Phone != oldAccounts.get(account.Id).Phone ||
				account.ContatoFormula__c != oldAccounts.get(account.Id).ContatoFormula__c ||
				account.InscricaoEstadual__c != oldAccounts.get(account.Id).InscricaoEstadual__c ||
				account.OwnerId != oldAccounts.get(account.Id).OwnerId ||
				account.ShippingStreet != oldAccounts.get(account.Id).ShippingStreet ||
				account.BairroEntrega__c != oldAccounts.get(account.Id).BairroEntrega__c ||
				account.NomeCidade__c != oldAccounts.get(account.Id).NomeCidade__c ||
				account.ShippingPostalCode != oldAccounts.get(account.Id).ShippingPostalCode ||
				account.MunicipioEntregaFormula__c != oldAccounts.get(account.Id).MunicipioEntregaFormula__c ||
				account.CodigoEntregaFormula__c != oldAccounts.get(account.Id).CodigoEntregaFormula__c ||
				account.SegmentacaoFormula__c != oldAccounts.get(account.Id).SegmentacaoFormula__c ||
				account.Type != oldAccounts.get(account.Id).Type ||
				account.observacoes__c != oldAccounts.get(account.Id).observacoes__c ||
				account.CondicaoPagamentoPadrao__c != oldAccounts.get(account.Id).CondicaoPagamentoPadrao__c ||
				account.temempilhadeira__c != oldAccounts.get(account.Id).temempilhadeira__c ||
				account.Frete__c != oldAccounts.get(account.Id).Frete__c ||
				account.GrupoEconomico__c != oldAccounts.get(account.Id).GrupoEconomico__c ||
				account.Faixa__c != oldAccounts.get(account.Id).Faixa__c ||
				Test.isRunningTest() ) {

				queueList.add(new Queue__c(
					EventName__c = QueueEventNames.ACCOUNT_SALESFORCE_TO_TOTVS.name(),
					RecordId__c  = account.Id,
					Status__c    = 'CREATED',
					Payload__c   = AccountIntegrationBO.getJsonRequest( account ),  
					IgnoredByTrigger__c = false 
				));
			}
		}

		//system.debug('queueList: ' + queueList);
		if (queueList.size() > 0){
			insert queueList;
		}
	}
}