public Without Sharing class OpportunityDAO {
    private static final OpportunityDAO instance = new OpportunityDAO();
    private OpportunityDAO(){}

    public static OpportunityDAO getInstance() {
        return instance;
    }

    public List<OpportunityLineItem> getAllOpItems(Id opId){
        return [SELECT Id, DataEntrega__c, Quantity, UnitPrice, ComissaoEditavel__c, Preco_Unitario_Com_Impostos__c,
        CodigoTOTVS__c, TESEditavel__c, Status__c, CodigoTOTVSAutoInc__c, NumeroPediClin__c, NumeroItemCli__c,IPI__c
        FROM OpportunityLineItem 
        WHERE OpportunityId =: opId];
    }

    public Opportunity getOpportunityIntegration(Id opId){
        return [
            SELECT Id, MensagemTOTVS__c, CodigoTOTVS__c, StageName,
            CodigoReceptor__c, ObservacoesLogistica__c,InformacoesParaLogistica__c, Coleta__c, 
            TipoDeFrete__c, TipoConta__c, Unidade_Filial__r.Codigo__c, DespesasAces__c, FormaDePagamento__c,
            Account.Codigo__c, Account.ObservacoesLogistica__c, CondicaoPagamento__r.Codigo__c, Description,
            ValorComissao__c, Transportadora__c, ContaReceptor__r.Codigo__c, ContaReceptor__r.ObservacoesLogistica__c, TESReceptor__c,
            CondicaoPagamentoReceptor__r.Name, CondicaoPagamentoReceptor__r.Codigo__c, TES__c, CodigoReceptorFormula__c, RecordTypeId, Owner.CodVendedor__c
            FROM Opportunity
            WHERE Id =: opId Limit 1
        ];
    }

    public String getProduto(String description){
		Product2 ret  = [ SELECT Id FROM Product2 WHERE Name=:description LIMIT 1 ];
        return ret.Id;
    }

    public List<OpportunityLineItem> getItensForPrice(Id opId){
        return [    SELECT  Id,
                            Product2.Name,
                            Opportunity.Unidade_Filial__r.Codigo__c, 
                            TESEditavel__c, 
                            Quantity,
                            DataEntrega__c, 
                            Opportunity.Account.Codigo__c, 
                            Opportunity.Owner.CodVendedor__c, 
                            Opportunity.CondicaoPagamento__r.codigo__c,
                            Opportunity.TES__c
                    FROM    OpportunityLineItem 
                    WHERE   OpportunityId = :opId ];		
    }

    public String getAccountId(Id oppId){
		Opportunity ret = [ SELECT AccountId FROM Opportunity WHERE Id=:oppId LIMIT 1 ];
        return ret.AccountId;
    }

}