public class SolicitacaoReembolsoTriggerHandler extends TriggerHandler {

    public override void afterInsert() {
        SolicitacaoReembolsoBO.updateLancamentosDespesas((List<Solicitacao_de_Reembolso__c>)Trigger.new);
    }

    public override void afterUpdate() {
        Map<Id, Solicitacao_de_Reembolso__c> oldMap = (Map<Id, Solicitacao_de_Reembolso__c>) Trigger.oldMap;
        List<Solicitacao_de_Reembolso__c> mudaram = new List<Solicitacao_de_Reembolso__c>();

        for (Solicitacao_de_Reembolso__c s : (List<Solicitacao_de_Reembolso__c>) Trigger.new) {
            Solicitacao_de_Reembolso__c o = oldMap.get(s.Id);
            if (s.Status_de_Aprovacao_e_Etapas__c != o.Status_de_Aprovacao_e_Etapas__c || s.Status__c != o.Status__c) {
                mudaram.add(s);
            }
        }

        if (!mudaram.isEmpty()) {
            SolicitacaoReembolsoBO.updateLancamentosDespesas(mudaram);
        }
    }
}
