public class QuoteProcessorController {
    @AuraEnabled
    public static Queue__c getQuoteQueue(Id recordId){
        Quote quote = [ SELECT Id, SincronizaTotvs__c, OpportunityId, Status, Opportunity.CodigoReceptorFormula__c, Opportunity.TipoDeFrete__c, Opportunity.Unidade_Filial__r.Codigo__c, Opportunity.Account.Codigo__c, Opportunity.CondicaoPagamento__r.codigo__c, Opportunity.Owner.CodVendedor__c FROM Quote WHERE id=:recordId ];
        return QuoteBO.getInstance().criaFilaIntegracaoInsert( quote );
    }

    @AuraEnabled
    public static Boolean btnIsVisible(Id recordId){
        Quote quote = [ SELECT Id, OpportunityId, Status FROM Quote WHERE id=:recordId ];
        if((quote.Status.Equals('Fechado ganha')) || (quote.Status.Equals('Fechado perdido')))
            return false;
        return true;
    }

    @AuraEnabled
    public static Queue__c sendToTotvs(Queue__c queue){
        QuoteIntegrationBO.executeQueue(queue.Id,queue.RecordId__c,queue.EventName__c,queue.Payload__c);

        return QueueDAO.getInstance().getOneQueueById(queue.Id);
    }

    @AuraEnabled
    public static String getMessage(Id recordId){
        Quote quote     = [ SELECT Id, AccountId FROM Quote WHERE id=:recordId ];
        Account account = [ SELECT Id, mensagemTOTVS__c FROM Account WHERE id=:quote.AccountId ];
        return account.mensagemTOTVS__c;
    }
}