public class SolicitacaoReembolsoTriggerHandler extends TriggerHandler {

    public override void afterInsert() {
        SolicitacaoReembolsoBO.updateLancamentosDespesas((List<Solicitacao_de_Reembolso__c>)Trigger.new);
    }

    public override void afterUpdate() {
        if(Trigger.isExecuting && Trigger.oldMap.keySet().equals(Trigger.newMap.keySet())) {
            return;
        }
        
        SolicitacaoReembolsoBO.updateLancamentosDespesas((List<Solicitacao_de_Reembolso__c>)Trigger.new);
    }
}