public class SolicitacaoCoffeeBreakTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
        SolicitacaoCoffeeBreakBO.atualizarValorTotal((List<Solicita_o_de_Coffe__c>)Trigger.new);
    }

    public override void beforeUpdate() {
        SolicitacaoCoffeeBreakBO.atualizarValorTotal((List<Solicita_o_de_Coffe__c>)Trigger.new);
    }

    public override void afterInsert() {
        SolicitacaoCoffeeBreakBO.atualizarValorProjeto((List<Solicita_o_de_Coffe__c>)Trigger.new);
    }

    public override void afterUpdate() {
        SolicitacaoCoffeeBreakBO.atualizarValorProjeto((List<Solicita_o_de_Coffe__c>)Trigger.new);
    }
}