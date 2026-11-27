/**
 * EPLAST-33. Dispara o calculo diario dos sinais comerciais (fase 1, que encadeia a fase 2).
 * Agendamento (pos-deploy, nao e metadata): CommercialSignalScheduler.scheduleDaily(CommercialSignalScheduler.JOB_NAME);
 *
 * API 67 roda SOQL e DML em user mode. O lote da fase 2 consulta e grava CommercialSignal__c
 * (SELECT SignalKey__c e o upsert) com a visibilidade de quem agendou. Sem leitura desses campos
 * o lote inteiro morre com "No such column 'SignalKey__c'" (QA de 17/11: 13 de 13, nenhum sinal).
 * Quem concede a leitura e o permission set PS_Comercial_SinaisComerciais; perfil Administrador
 * do sistema nao recebe FLS de campo custom so por ser administrador. As consultas de Order em
 * SYSTEM_MODE nao cobrem esse SOQL estatico. scheduleDaily e execute conferem o describe (nao
 * dispara excecao) e falham antes de abrir os lotes, com a mensagem de qual permission set atribuir.
 */
public with sharing class CommercialSignalScheduler implements Schedulable {

    public static final String JOB_NAME = 'EPLAST33 Sinais Comerciais';
    public static final String PERMISSION_SET = 'PS_Comercial_SinaisComerciais';

    public class SignalAccessException extends Exception {}

    /**
     * Campos de CommercialSignal__c que o calculo le e grava. Nomes em minusculas: o mapa do
     * describe devolve a chave assim. signalkey__c vem primeiro porque e o campo do erro da QA.
     */
    @TestVisible
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'signalkey__c', 'account__c', 'type__c', 'product__c', 'productfamily__c', 'dayswithoutpurchase__c',
        'lastpurchasedate__c', 'baseperiodamount__c', 'currentperiodamount__c', 'baseperiodquantity__c',
        'currentperiodquantity__c', 'unitofmeasure__c', 'variationpercent__c', 'reason__c', 'calculationdate__c'
    };
    // O cron roda no fuso do usuario que agenda (America/Sao_Paulo, UTC-3): 01:00 local = 04:00 UTC,
    // longe dos jobs existentes (02:00, 06:00, 15:47, 17:36 UTC). Quem agendar de outro fuso ajusta a hora.
    public static final String CRON_DAILY_0400_UTC = '0 0 1 * * ?';

    /**
     * True se o usuario atual le o objeto e todos os campos do calculo.
     * Describe dinamico: nao lanca "No such column" quando falta FLS.
     * So leitura: o permission set e readable=true / editable=false, e com ele o job grava
     * (DML de Apex do administrador). Exigir isUpdateable bloquearia o caso que ja funciona.
     */
    public static Boolean executorHasSignalAccess() {
        return firstBlockedField() == null;
    }

    /** Falha com mensagem acionavel quando o usuario atual nao tem o permission set. */
    public static void assertSignalAccess() {
        String blocked = firstBlockedField();
        if (blocked == null) {
            return;
        }
        throw new SignalAccessException(
            'EPLAST-33: o usuario ' + UserInfo.getUserName() + ' nao tem acesso aos campos de CommercialSignal__c'
            + ' (primeiro sem leitura: ' + blocked + '). Atribua o permission set ' + PERMISSION_SET
            + ' a esse usuario. O calculo agendado roda com as permissoes de quem agendou'
            + ' (Administrador do sistema sem o permission set nao basta).');
    }

    public void execute(SchedulableContext sc) {
        assertSignalAccess();
        CommercialSignalService.Settings s = CommercialSignalService.loadSettings();
        Database.executeBatch(new CommercialSignalGroupStatsBatch(s, Date.today(), true), s.batchSize);
    }

    public static Id scheduleDaily(String jobName) {
        assertSignalAccess();
        return System.schedule(jobName, CRON_DAILY_0400_UTC, new CommercialSignalScheduler());
    }

    /** Nome do objeto, ou o primeiro campo da lista que o usuario nao le. Null se pode calcular. */
    private static String firstBlockedField() {
        Schema.DescribeSObjectResult obj = Schema.describeSObjects(new List<String>{ 'CommercialSignal__c' })[0];
        if (!obj.isAccessible()) {
            return 'CommercialSignal__c';
        }
        Map<String, Schema.SObjectField> fields = obj.fields.getMap();
        for (String fieldName : REQUIRED_FIELDS) {
            Schema.SObjectField token = fields.get(fieldName);
            if (token == null || !token.getDescribe().isAccessible()) {
                return fieldName;
            }
        }
        return null;
    }
}
