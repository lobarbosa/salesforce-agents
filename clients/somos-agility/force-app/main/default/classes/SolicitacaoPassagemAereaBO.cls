public class SolicitacaoPassagemAereaBO {

    public static void atualizarValorTotal(List<Solicitacao_de_Passagem_Aerea__c> solicitacoes) {
        for(Solicitacao_de_Passagem_Aerea__c solicitacao : solicitacoes) {
            solicitacao.ValorTotal__c = calcularValorTotalSolicitacao(solicitacao);
        }
    }

    public static void atualizarValorProjeto(List<Solicitacao_de_Passagem_Aerea__c> solicitacoes) {
        Set<Id> projetosIds = new Set<Id>();

        for(Solicitacao_de_Passagem_Aerea__c solicitacao : solicitacoes) {
            if(solicitacao.Relacionado_ao_Projeto__c != null) {
                projetosIds.add(solicitacao.Relacionado_ao_Projeto__c);
            }
        }

        Map<Id, PPM_Project__c> mapProjetos = new Map<Id, PPM_Project__c>([SELECT Id, (SELECT Id, ValorTotal__c FROM Solicita_o_de_Passagem_A_rea__r) FROM PPM_Project__c WHERE Id IN: projetosIds]);

        for(PPM_Project__c projeto : mapProjetos.values()) {
            Double valorTotal = 0;
            for(Solicitacao_de_Passagem_Aerea__c solicitacao : projeto.Solicita_o_de_Passagem_A_rea__r) {
                valorTotal += (solicitacao.ValorTotal__c == null ? 0 : solicitacao.ValorTotal__c);
            }

            projeto.DespesasRealizadasPassagens__c = valorTotal;  
        }

        if(mapProjetos.size() > 0) {
            try{
                update mapProjetos.values(); 
            }catch(Exception e) {
                throw new CustomException('Erro ao atualizar o projeto para somatória de valores: ' + e.getMessage());
            }
        }
    }
    
    private static Double calcularValorTotalSolicitacao(Solicitacao_de_Passagem_Aerea__c solicitacao) {
        return (((valorVazio(solicitacao.Valor_Unitario_da_Locacao_de_Veiculo__c) * valorVazio(solicitacao.Quantidade_de_Diarias__c)) + 
        valorVazio(solicitacao.Valor_Unitario_da_Passagem_da_Ida__c) + valorVazio(solicitacao.Valor_Unitario_da_Passagem_da_Volta__c) + valorVazio(solicitacao.Reemissao_se_Aplicavel__c)) * 
        valorVazio(solicitacao.Quantidade_de_Passageiros__c)) * valorVazio(solicitacao.Cambio_Turismo__c) +
         (valorVazio(solicitacao.Valor_Unitario_da_Hospedagem__c) * valorVazio(solicitacao.Quantidade_de_Diarias__c) * valorVazio(solicitacao.Cambio_Turismo__c));
    }

    private static Decimal valorVazio(Decimal valor) {
        return valor == null ? 0 : valor;
    }

    public class CustomException extends Exception {}
}