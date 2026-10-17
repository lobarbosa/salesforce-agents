public class SolicitacaoPassagemAereaTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
        SolicitacaoPassagemAereaBO.atualizarValorTotal((List<Solicitacao_de_Passagem_Aerea__c>)Trigger.new);
    }

    public override void beforeUpdate() {
        SolicitacaoPassagemAereaBO.atualizarValorTotal((List<Solicitacao_de_Passagem_Aerea__c>)Trigger.new);
    }

    public override void afterInsert() {
        SolicitacaoPassagemAereaBO.atualizarValorProjeto((List<Solicitacao_de_Passagem_Aerea__c>)Trigger.new);
    }

    public override void afterUpdate() {
        SolicitacaoPassagemAereaBO.atualizarValorProjeto((List<Solicitacao_de_Passagem_Aerea__c>)Trigger.new);
    }
}