public Without Sharing class OrderDAO {

    private static final OrderDAO instance = new OrderDAO();
    private OrderDAO(){}

    public static OrderDAO getInstance() {
        return instance;
    }

    public Order getOrderIntegration(Id opId){
        return [
            SELECT Id, CodigoTOTVS__c, CodigoReceptor__c, MensagemTOTVS__c, BloqueioFinanceiro__c, OpportunityId, Vendedor__c,
                    (SELECT Id, CodigoTOTVSAutoInc__c, Status__c, PricebookEntry.Product2.Name FROM OrderItems)
            FROM Order
            WHERE Id =: opId
        ];
    }

    public Order getOrderIntegrationWithItems(Id ordId){
        return [
                SELECT Id, MensagemTOTVS__c, CodigoTOTVS__c, 
                        CodigoReceptor__c, ObservacoesLogistica__c,InformacoesParaLogistica__c, Coleta__c, 
                        TipoFrete__c, Account.Type, UnidadeFilial__r.Codigo__c, FormaPagamento__c,
                        Account.Id, Account.Codigo__c, Account.ObservacoesLogistica__c, CondicaoPagamento__r.Codigo__c, Description,
                        Transportadora__c, ContaReceptor__r.Codigo__c, ContaReceptor__r.ObservacoesLogistica__c, TESReceptor__c,
                        CondicaoPagamentoReceptor__r.Name, CondicaoPagamentoReceptor__r.Codigo__c, TES__c, Opportunity.RecordTypeId,
                        DataEntrega__c,DataPrevisaoEntrega__c, Frete__c, Vendedor__r.CodVendedor__c, Vendedor__c,
                        (SELECT Id, DataEntrega__c, Quantity, UnitPrice, ComissaoEditavel__c, PrecoUnitarioCImposto__c,
                                CodigoPedidoTOTVS__c, TESEditavel__c, Status__c, CodigoTOTVSAutoInc__c, NumeroPediClin__c, NumeroItemCli__c,PercentualIPI__c,Product2Id,
                                PricebookEntry.Product2.Name, ValorFrete__c, Pedido_Elegivel_fixo__c, Pedido_Elegivel__c, Upselling__c
                        FROM OrderItems
                        WHERE Product2.Description != 'Produto generico para entrega utilizado na loja B2B'
                        ORDER BY CodigoTOTVSAutoInc__c NULLS LAST, CreatedDate)
                FROM Order
                WHERE Id =: ordId
            ];
    }

    public static List<OrderItem> getOrderItems(List<String> lstItemIds){
        return [    SELECT  Id
                            , OrderId
                            , DataEntrega__c
                            , Quantity
                            , UnitPrice
                            , ComissaoEditavel__c
                            , PrecoUnitarioCImposto__c
                            , CodigoPedidoTOTVS__c
                            , TESEditavel__c
                            , Status__c
                            , CodigoTOTVSAutoInc__c
                            , NumeroPediClin__c
                            , NumeroItemCli__c
                            , PercentualIPI__c
                            , Product2Id
                            , PricebookEntryId
                            , PricebookEntry.Product2.Name
                            , ValorFrete__c
                            , BloqueioCalcFrete__c
                            , Comissao__c
                            , PercentualDesconto__c
                            , PercentualComissao__c
                            , PercentualICMS__c
                            , PrecoUnitarioSImposto__c
                            , ValorComissao__c
                            , QuantidadeDevolvida__c
                            , ValorDevolvido__c
                            , Data_entrada__c
                    FROM    OrderItem
                    WHERE   Id IN :lstItemIds
            ];
    }

    public static OrderItem getOrderItemByOppItemId(String oppItemId){
    
        List<OpportunityLineItem> lstOppItems = [	SELECT  Id
															, Product2Id
															, Opportunity.Unidade_Filial__r.Codigo__c
															, Opportunity.CodigoTOTVS__c
													FROM    OpportunityLineItem
													WHERE   Id = :oppItemId		];
		System.debug('lstOppItems: ' + lstOppItems);

		if(lstOppItems == null || lstOppItems.size() == 0){
			return null;
		} else {

			System.debug('lstOppItems[0].Product2Id: ' + lstOppItems[0].Product2Id);
			System.debug('lstOppItems[0].Opportunity.Unidade_Filial__r.Codigo__c: ' + lstOppItems[0].Opportunity.Unidade_Filial__r.Codigo__c);
			System.debug('lstOppItems[0].Opportunity.CodigoTOTVS__c: ' + lstOppItems[0].Opportunity.CodigoTOTVS__c);

			List<OrderItem> lstOrderItem = [	SELECT	Id
												FROM	OrderItem
												WHERE 	Product2Id = :lstOppItems[0].Product2Id
												AND 	CodigoPedidoTOTVS__c = :lstOppItems[0].Opportunity.CodigoTOTVS__c 
												AND		Filial__c = :lstOppItems[0].Opportunity.Unidade_Filial__r.Codigo__c ];
			System.debug('lstOrderItem: ' + lstOrderItem);

			if(lstOrderItem == null || lstOrderItem.size() == 0) {
				return null;
			} else {
				return lstOrderItem[0];
			}

		}

    }
}