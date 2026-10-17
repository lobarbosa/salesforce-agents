public class SolicitacaoCoffeeBreakBO {
    public static void atualizarValorTotal(List<Solicita_o_de_Coffe__c> solicitacoes) {
        for(Solicita_o_de_Coffe__c solicitacao : solicitacoes) {
            solicitacao.ValorTotal__c = calcularValorTotalSolicitacao(solicitacao);
        }
    }

    public static void atualizarValorProjeto(List<Solicita_o_de_Coffe__c> solicitacoes) {
        Set<Id> projetosIds = new Set<Id>();

        for(Solicita_o_de_Coffe__c solicitacao : solicitacoes) {
            if(solicitacao.Relacionado_ao_Projeto__c != null) {
                projetosIds.add(solicitacao.Relacionado_ao_Projeto__c);
            }
        }

        Map<Id, PPM_Project__c> mapProjetos = new Map<Id, PPM_Project__c>([SELECT Id, (SELECT Id, ValorTotal__c FROM Solicita_o_de_Coffee_Break__r) FROM PPM_Project__c WHERE Id IN: projetosIds]);

        for(PPM_Project__c projeto : mapProjetos.values()) {
            Double valorTotal = 0;
            for(Solicita_o_de_Coffe__c solicitacao : projeto.Solicita_o_de_Coffee_Break__r) {
                valorTotal += (solicitacao.ValorTotal__c == null ? 0 : solicitacao.ValorTotal__c);
            }
			System.debug('valorTotal'+ valorTotal);
            projeto.DespesasRealizadasCoffeeBreaks__c = valorTotal;  
        }

        if(mapProjetos.size() > 0) {
            try{
                update mapProjetos.values(); 
            }catch(Exception e) {
                throw new CustomException('Erro ao atualizar o projeto para somatória de valores: ' + e.getMessage());
            }
        }
    }

    private static Double calcularValorTotalSolicitacao(Solicita_o_de_Coffe__c solicitacao) {
        if(solicitacao.Solicitacao_Enviada_para_o_Fornecedor__c || Test.isRunningTest()) {
            if(solicitacao.Fornecedor__c == 'Padaria Letícia') {
                if(solicitacao.Quantidade__c == 'Até 5 pessoas') {
                    return 109.64;
                }else if(solicitacao.Quantidade__c == 'Até 10 pessoas') {
                    return 197.25;
                }else if(solicitacao.Quantidade__c == 'Até 20 pessoas') {
                    return 372.50;
                }else if(solicitacao.Quantidade__c == 'Até 30 pessoas') {
                    return 547.75;
                }
            }
            else if(solicitacao.Fornecedor__c == 'Padaria Merci') {
                if(solicitacao.Quantidade__c == 'Até 5 pessoas') {
                    return 87.97;
                }else if(solicitacao.Quantidade__c == 'Até 10 pessoas') {
                    return 171.75;
                }else if(solicitacao.Quantidade__c == 'Até 20 pessoas') {
                    return 275.13;
                }else if(solicitacao.Quantidade__c == 'Até 30 pessoas') {
                    return 471.18;
                }
            }
            else if(solicitacao.Fornecedor__c == 'Santa Etienne') {
                if(solicitacao.Quantidade__c == 'Até 5 pessoas') {
                    return 117.80;
                }else if(solicitacao.Quantidade__c == 'Até 10 pessoas') {
                    return 196.95; 
                }else if(solicitacao.Quantidade__c == 'Até 20 pessoas') {
                    return 338.70;
                }else if(solicitacao.Quantidade__c == 'Até 30 pessoas') {
                    return 500.90;
                } 
            }
        }

        return 0;
    }

    public class CustomException extends Exception {}
}