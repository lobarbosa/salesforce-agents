@isTest
public class ChangeItemTest {
    @IsTest
    static void test_method_one(){

        CondicaoPagamento__c condicaoPagamento = InstanceToClassCoverage.condicaoPagamento();
        UnidadeFilial__c filial    = InstanceToClassCoverage.filial();
		insert condicaoPagamento;
		insert filial;

        Id lista = Test.getStandardPricebookId();
        Product2 produto = InstanceToClassCoverage.produto('ABS-AE8000');
        insert produto;

        Account conta = InstanceToClassCoverage.conta('Conta para teste');
        insert conta;

		Opportunity oportunidade = InstanceToClassCoverage.oportunidade('Oportunidade para teste');
        oportunidade.AccountId = conta.Id;
        oportunidade.Pricebook2Id = lista;
        oportunidade.Unidade_Filial__c = filial.id;
	    oportunidade.CondicaoPagamento__c = condicaoPagamento.Id;
        insert oportunidade;

        // PricebookEntry produtoList = new PricebookEntry( UnitPrice = 10, Pricebook2Id = lista, Product2Id = produto.Id, isActive = true, UseStandardPrice = false ); 
		// insert produtoList;
        List<PricebookEntry> pbel = [   SELECT  Id
                                        FROM    PricebookEntry
                                        WHERE   Product2Id      = :produto.Id
                                        AND     Pricebook2Id    = :lista       
                                        AND     isActive        = true      ];

        OpportunityLineItem oppLine = new OpportunityLineItem(OpportunityId = oportunidade.Id, CodigoTOTVSAutoInc__c = '1', Product2Id = produto.Id, Quantity = 10, UnitPrice = 1, PricebookEntryId = pbel[0].Id, DataEntrega__c = System.today());
        insert oppLine;
        
        Test.startTest();
            RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf('{  "Items": [    {      "id": "'+oppLine.Id+'",      "status": "Faturado"    }  ]}');
            RestContext.request = req;
			RestResponse res = new RestResponse();
			RestContext.response = res;
			RESTChangeItem.changeStatusItem();
        Test.stopTest();
        
    }

    @IsTest
    static void test_method_two(){
        
        Test.startTest();
            RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf('{  "Items": [    {      "status": "Faturado"    }  ]}');
            RestContext.request = req;
			RestResponse res = new RestResponse();
			RestContext.response = res;
			RESTChangeItem.changeStatusItem();
        Test.stopTest();
        
    }
}