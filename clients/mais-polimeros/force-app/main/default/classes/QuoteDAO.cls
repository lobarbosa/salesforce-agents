public with sharing class QuoteDAO {
	
	private static final QuoteDAO instance = new QuoteDAO();    
	public QuoteDAO() {}
    
    public static QuoteDAO getInstance() {
        return instance;
    }

	/****
	Retorna os códigos dos produtos com base na Cotação
	Quote------> QuoteLineItem ------> Product 
	****/
    public List<QuoteLineItem> getItens(Id quote){
		return [ SELECT Id,
				 Product2.Name,
				 Quote.Opportunity.Unidade_Filial__r.Codigo__c, 
				 TESEditavel__c, 
				 Quantity, DataEntrega__c, 
				 Quote.Opportunity.Account.Codigo__c, 
				 Quote.Opportunity.Owner.CodVendedor__c, 
				 Quote.Opportunity.CondicaoPagamento__r.codigo__c 
				 FROM QuoteLineItem 
				 WHERE QuoteId=:quote ];		
    }

	/****
	Retorna o id do produto
	------> Product 	
	****/
    public String getProduto(String description){
		Product2 ret  = [ SELECT Id FROM Product2 WHERE Name=:description LIMIT 1 ];
        return ret.Id;
    }
    
	public String getAccountId(Id quote){
		Quote ret = [ SELECT AccountId FROM Quote WHERE Id=:quote LIMIT 1 ];
        return ret.AccountId;
    }
	
	/****
	Retorna o TES do item de linha
	Quote ------> Opportunity	
	****/
    public String getTES(Quote quote){		
		Opportunity tesFromOpp  = [ SELECT TES__c FROM Opportunity WHERE Id=:quote.OpportunityId ];		
        return String.valueOf( tesFromOpp.TES__c );
    }

	public Quote getAllFields(Id recordId){
        return[SELECT
              Id, OwnerId, IsDeleted, Name, OpportunityId, Pricebook2Id, ContactId, 
			  QuoteNumber, IsSyncing, ShippingHandling, Tax, Status, ExpirationDate, Description, Subtotal, 
			  TotalPrice, LineItemCount, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, 
			  BillingLatitude, BillingLongitude, BillingGeocodeAccuracy, BillingAddress, ShippingStreet, ShippingCity, 
			  ShippingState, ShippingPostalCode, ShippingCountry, ShippingLatitude, ShippingLongitude, 
			  ShippingGeocodeAccuracy, ShippingAddress, QuoteToStreet, QuoteToCity, QuoteToState, QuoteToPostalCode, 
			  QuoteToCountry, QuoteToLatitude, QuoteToLongitude, QuoteToGeocodeAccuracy, QuoteToAddress, 
			  AdditionalStreet, AdditionalCity, AdditionalState, AdditionalPostalCode, AdditionalCountry, 
			  AdditionalLatitude, AdditionalLongitude, AdditionalGeocodeAccuracy, AdditionalAddress, BillingName, 
			  ShippingName, QuoteToName, AdditionalName, Email, Phone, Fax, ContractId, AccountId, Discount, 
			  GrandTotal, StatusIntegracao__c, MotivoPerda__c, DataPrevisaoEntrega__c, Percent_ICMS__c, NPedidoCompra__c, NomeConta__c, NomeProprietario__c,
			  Preco_Total_Impostos__c, TemDesconto__c, QuantidadeTotal__c, Desconto__c, 
			  DescontoAceito__c, SincronizaTotvs__c
              FROM Quote
              WHERE Id =: recordId LIMIT 1];
    } 

    public List<QuoteLineItem> getAllQuoteLineItem(Id recordId){
        return [SELECT Id, IsDeleted, LineNumber, QuoteId, PricebookEntryId, Quantity, UnitPrice, Discount, 
		ServiceDate, Product2Id, SortOrder, ListPrice, Subtotal, TotalPrice, PrecoUnitarioSImposto__c, Percent_ICMS__c, 
		DataEntrega__c, TESEditavel__c, Desconto__c, Preco_Unitario_Com_Impostos__c, precoUnitarioCImpostoNEditavel__c, 
		SubtotalNEditavel__c, SubtotalCimpostos__c, Data_de_emissao_nota__c, Status__c, Comissao__c, Valor_Frete__c
        FROM QuoteLineItem 
        WHERE QuoteId =: recordId]; 
    }

	public Map<String, UnidadeFilial__c> getAllFilials(){
		Map<String, UnidadeFilial__c> mapFilials = new Map<String, UnidadeFilial__c>();
		for(UnidadeFilial__c filial : [SELECT Id, Name, Codigo__c FROM UnidadeFilial__c]){
			mapFilials.put(filial.codigo__c,filial);
		}
		return mapFilials;
	}  

	public Map<Id, Quote> getMapQuote(Set<Id> recordsId){
		Map<Id, Quote> mapQuotes = new Map<Id, Quote>();
		for(Quote quote : [SELECT Id, Status FROM Quote WHERE Id IN : recordsId]){
			mapQuotes.put(quote.Id, quote);
		}
		return mapQuotes;
	}

}