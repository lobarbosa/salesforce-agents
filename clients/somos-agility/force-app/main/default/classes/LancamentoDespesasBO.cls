public class LancamentoDespesasBO {

    public static void atualizarValorProjeto(List<Lancamento_de_Despesas__c> solicitacoes) {
        Set<Id> projetosIds = new Set<Id>();

        for(Lancamento_de_Despesas__c solicitacao : solicitacoes) {
            if(solicitacao.Relacionado_ao_Projeto__c != null) {
                projetosIds.add(solicitacao.Relacionado_ao_Projeto__c);
            }
        }

        Map<Id, PPM_Project__c> mapProjetos = new Map<Id, PPM_Project__c>([SELECT Id, (SELECT Id, Valor_Total_da_Despesa__c FROM Lan_amento_de_Despesas__r WHERE Status_da_SR__c != 'Rejeitado') FROM PPM_Project__c WHERE Id IN: projetosIds]);

        for(PPM_Project__c projeto : mapProjetos.values()) {
            Double valorTotal = 0;
            for(Lancamento_de_Despesas__c solicitacao : projeto.Lan_amento_de_Despesas__r) {
                valorTotal += (solicitacao.Valor_Total_da_Despesa__c  == null ? 0 : solicitacao.Valor_Total_da_Despesa__c );
            }
            projeto.DespesasRealizadasAtividades__c = valorTotal;  
        }

        if(mapProjetos.size() > 0) {
            try{
                update mapProjetos.values(); 
            }catch(Exception e) {
                throw new CustomException('Erro ao atualizar o projeto para somatória de valores: ' + e.getMessage());
            }
        }
    }

    public class CustomException extends Exception {}
}