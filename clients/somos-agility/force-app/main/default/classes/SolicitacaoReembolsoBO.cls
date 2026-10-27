public class SolicitacaoReembolsoBO {

    // Trava de recursão por transação: uma SR já re-processada numa determinada etapa
    // (Status_de_Aprovacao_e_Etapas__c) não é processada de novo na mesma transação.
    // Necessário porque field update de aprovação (sem reevaluateOnChange) dispara o
    // afterUpdate de novo com Trigger.old ainda apontando para o valor anterior à DML
    // original (seção 5 do design SOMOSAGILITY-10).
    @TestVisible
    private static Set<String> solicitacoesJaProcessadas = new Set<String>();

    public static void updateLancamentosDespesas(List<Solicitacao_de_Reembolso__c> solicitacoes) {
        Set<Id> idsSolicitacoesReembolsos = new Set<Id>();

        for (Solicitacao_de_Reembolso__c s : solicitacoes) {
            String chave = s.Id + '::' + s.Status_de_Aprovacao_e_Etapas__c;
            if (solicitacoesJaProcessadas.contains(chave)) {
                continue;
            }
            solicitacoesJaProcessadas.add(chave);
            idsSolicitacoesReembolsos.add(s.Id);
        }

        if (idsSolicitacoesReembolsos.isEmpty()) {
            return;
        }

        List<Lancamento_de_Despesas__c> lancamentos = [
            SELECT Id
            FROM Lancamento_de_Despesas__c
            WHERE Solicitacao_de_Reembolso__c IN :idsSolicitacoesReembolsos
            AND Relacionado_ao_Projeto__c != null
        ];

        if (lancamentos.isEmpty()) {
            return;
        }

        List<Database.SaveResult> resultados = Database.update(lancamentos, false);
        for (Integer i = 0; i < resultados.size(); i++) {
            if (!resultados[i].isSuccess()) {
                for (Database.Error erro : resultados[i].getErrors()) {
                    System.debug(
                        LoggingLevel.ERROR,
                        'SolicitacaoReembolsoBO.updateLancamentosDespesas: falha ao re-salvar ' +
                        'Lancamento_de_Despesas__c ' + lancamentos[i].Id + ': ' +
                        erro.getStatusCode() + ' - ' + erro.getMessage()
                    );
                }
            }
        }
    }
}
