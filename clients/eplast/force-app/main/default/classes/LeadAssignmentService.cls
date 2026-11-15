/**
 * EPLAST-35. Ponte minima entre o Flow Lead_AfterInsert_AplicaRegraAtribuicao e a regra de
 * atribuicao nativa de Lead (Distribuicao_Regional_Leads). Flow nao tem elemento que dispare
 * regra de atribuicao; so Apex via Database.DMLOptions. A regua continua na regra nativa
 * (editavel em Setup, sem deploy): esta classe apenas pede para a plataforma aplica-la.
 *
 * without sharing (decisao do design, secao 2.2): a reatribuicao precisa trocar o dono do
 * Lead independentemente do acesso de quem o criou (usuario de integracao). A classe so
 * recebe Ids, nao expoe dado e so reaplica a regra ativa; nao ha entrada livre do usuario.
 */
public without sharing class LeadAssignmentService {

    /**
     * Acao invocavel pelo Flow. Recebe os Ids dos Leads criados e reaplica a regra padrao.
     * Bulk: 1 SOQL e 1 DML para a lista inteira.
     */
    @InvocableMethod(
        label='Aplicar regra de atribuicao padrao ao Lead'
        description='EPLAST-35. Reaplica a regra de atribuicao ativa de Lead aos Ids informados (ignora Leads convertidos).'
    )
    public static void aplicarRegraPadrao(List<Id> leadIds) {
        if (leadIds == null || leadIds.isEmpty()) {
            return;
        }

        List<Lead> leads = [
            SELECT Id
            FROM Lead
            WHERE Id IN :new Set<Id>(leadIds)
            AND IsConverted = false
        ];
        if (leads.isEmpty()) {
            return;
        }

        Database.DMLOptions options = new Database.DMLOptions();
        options.assignmentRuleHeader.useDefaultRule = true;
        options.optAllOrNone = false;

        List<Database.SaveResult> results = Database.update(leads, options);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                // Sem dado pessoal na mensagem: so Id do Lead e codigo do erro.
                System.debug(LoggingLevel.ERROR, 'EPLAST-35 LeadAssignmentService falhou. Lead=' + leads[i].Id
                    + ' status=' + results[i].getErrors()[0].getStatusCode());
            }
        }
    }
}
