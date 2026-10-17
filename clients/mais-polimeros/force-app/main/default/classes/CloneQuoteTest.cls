@isTest
private class CloneQuoteTest {
	
	@isTest static void test_method_one() {
		
		Account conta              = InstanceToClassCoverage.conta('Conta para teste');
		Opportunity oportunidade   = InstanceToClassCoverage.oportunidade('Oportunidade para teste');
		UnidadeFilial__c filial    = InstanceToClassCoverage.filial();
		Quote cotacao = InstanceToClassCoverage.cotacao('Cotacao para teste');
		Product2 produto           = InstanceToClassCoverage.produto('ABS-AE8000');
		Id lista		       = Test.getStandardPricebookId();
		CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();	
		
		insert condicaoPagamento;
		insert filial;
		insert conta;
		insert produto;

		oportunidade.AccountId         = conta.id;
		oportunidade.Unidade_Filial__c = filial.id;
		oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;

		insert oportunidade;
		oportunidade.StageName = 'Negociação';
		update oportunidade;

		cotacao.Pricebook2Id   = lista;
		cotacao.OpportunityId  = oportunidade.id;
		insert cotacao;

		// PricebookEntry produtoList = new PricebookEntry( UnitPrice = 10, Pricebook2Id = lista, product2Id = produto.Id, isActive = true, UseStandardPrice = false ); 
		// insert produtoList;
        List<PricebookEntry> pbel = [   SELECT  Id
                                        FROM    PricebookEntry
                                        WHERE   Product2Id      = :produto.Id
                                        AND     Pricebook2Id    = :lista       
                                        AND     isActive        = true      ];

		QuoteLineItem itemDeLinha = new QuoteLineItem( Product2Id = produto.Id, PricebookEntryId = pbel[0].Id, UnitPrice = 15, TESEditavel__c = '521',  PrecoUnitarioSImposto__c = 20.00, Quantity = 25, QuoteId = cotacao.Id ); 
		insert itemDeLinha;

		update cotacao;

		Test.startTest();		
		
		CloneQuote.toCloneQuote(cotacao.Id);	
		
		Test.stopTest();

	}
	
}