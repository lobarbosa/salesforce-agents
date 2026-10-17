@istest
public with sharing class ProcessoAprovacaoOppTest {
    
    @TestSetup
    static void makeData(){
        User us = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name='Mais Polimeros Admin' LIMIT 1];

        Account conta = InstanceToClassCoverage.conta('Conta para teste');
        conta.beeCnpj__CNPJ__c = '71673990000177';

        insert conta;
        CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
        UnidadeFilial__c filial    = InstanceToClassCoverage.filial();
		insert condicaoPagamento;
		insert filial;

        Id lista = Test.getStandardPricebookId();
        Product2 produto = InstanceToClassCoverage.produto('ABS-AE8000');
        insert produto;

		Opportunity oportunidade = InstanceToClassCoverage.oportunidade('Oportunidade para teste');
        oportunidade.AccountId = conta.Id;
        oportunidade.Pricebook2Id = lista;
        oportunidade.Unidade_Filial__c = filial.id;
	    oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;
        insert oportunidade;

        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(oportunidade.Id);

        // Submit on behalf of a specific submitter
        req1.setSubmitterId(us.Id); 


        // Submit the record to specific process and skip the criteria evaluation
        req1.setProcessDefinitionNameOrId('Aprovacao_Commodities1');
        req1.setSkipEntryCriteria(true);

        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);

    }


    @istest
    public static void testarAlterarStatus() {
        Test.startTest();
        ProcessInstanceWorkitem procWork = [SELECT id From ProcessInstanceWorkitem Limit 1];
        List<User> lstUs = [SELECT Id FROM User WHERE IsActive=true  AND Profile.Name='Mais Polimeros Admin'];
        User us2 = [SELECT Id FROM User WHERE IsActive=true AND Profile.Name='Mais Polimeros Admin'  LIMIT 1];
        for(User us: lstUs){
            ProcessoAprovacaoOpp.montarRelatorio( us.Id);
        }
        ProcessoAprovacaoOpp.alterarStatus('Approve', us2.Id, 'Teste', procWork.Id);
        Test.stopTest();
    }
    
}