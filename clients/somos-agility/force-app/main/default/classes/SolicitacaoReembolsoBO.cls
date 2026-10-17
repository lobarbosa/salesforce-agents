public class SolicitacaoReembolsoBO {

    public static void updateLancamentosDespesas(List<Solicitacao_de_Reembolso__c> solicitacoes) {
        Set<Id> idsSolicitacoesReembolsos = new Set<Id>();
        
        for(Solicitacao_de_Reembolso__c s : solicitacoes) {
            if(s.Status__c == 'Rejeitado')
                idsSolicitacoesReembolsos.add(s.Id);
        }
        
        List<Lancamento_de_Despesas__c> lancamentos = [SELECT Id FROM Lancamento_de_Despesas__c WHERE Solicitacao_de_Reembolso__c IN: idsSolicitacoesReembolsos];
        
        if(!lancamentos.isEmpty())
           update lancamentos;
    }
}