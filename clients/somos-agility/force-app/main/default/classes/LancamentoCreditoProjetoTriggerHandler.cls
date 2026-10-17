public class LancamentoCreditoProjetoTriggerHandler extends TriggerHandler{
    
    public override void afterUpdate() {
        Set<Id> idProjetos = new Set<Id>();
        For(Lancamento_de_Creditos_em_Projeto__c lancamento : (List<Lancamento_de_Creditos_em_Projeto__c>)Trigger.new){
            idProjetos.add(lancamento.Projetos__c);
        }
        LancamentoCreditoProjetoBO.SumarizaLancamentoCreditoProjeto(idProjetos);
        LancamentoCreditoProjetoBO.ConcatenaComentarios(idProjetos);
    }

    public override void afterInsert() {
        Set<Id> idProjetos = new Set<Id>();
        For(Lancamento_de_Creditos_em_Projeto__c lancamento : (List<Lancamento_de_Creditos_em_Projeto__c>)Trigger.new){
            idProjetos.add(lancamento.Projetos__c);
        }
        LancamentoCreditoProjetoBO.SumarizaLancamentoCreditoProjeto(idProjetos);
        LancamentoCreditoProjetoBO.ConcatenaComentarios(idProjetos);
    }
    
     public override void afterDelete() {
        Set<Id> idProjetos = new Set<Id>();
        For(Lancamento_de_Creditos_em_Projeto__c lancamento : (List<Lancamento_de_Creditos_em_Projeto__c>)Trigger.old){
            idProjetos.add(lancamento.Projetos__c);
        }
        LancamentoCreditoProjetoBO.SumarizaLancamentoCreditoProjeto(idProjetos);
         LancamentoCreditoProjetoBO.ConcatenaComentarios(idProjetos);
    }

}