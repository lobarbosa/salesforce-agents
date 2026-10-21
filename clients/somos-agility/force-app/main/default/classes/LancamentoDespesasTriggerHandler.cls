public class LancamentoDespesasTriggerHandler extends TriggerHandler {
    
    public override void afterInsert() {
        LancamentoDespesasBO.atualizarValorProjeto((List<Lancamento_de_Despesas__c>)Trigger.new);
    }
    
    public override void afterUpdate() {
        LancamentoDespesasBO.atualizarValorProjeto((List<Lancamento_de_Despesas__c>)Trigger.new);
    }
}