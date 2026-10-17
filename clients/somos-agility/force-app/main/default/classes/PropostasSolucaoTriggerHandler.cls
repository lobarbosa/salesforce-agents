public class PropostasSolucaoTriggerHandler extends TriggerHandler {

    public override void beforeUpdate() {
        PropostasSolucaoBO.preencherHistoricoStatus((List<Propostas_de_Solucao__c>)Trigger.new, (Map<Id, Propostas_de_Solucao__c>)Trigger.oldMap);
    }

    public override void beforeInsert() {
        PropostasSolucaoBO.preencherHistoricoStatus((List<Propostas_de_Solucao__c>)Trigger.new, (Map<Id, Propostas_de_Solucao__c>)Trigger.oldMap);
    }
}