/**
 * EPLAST-33. Dispara o calculo diario dos sinais comerciais (fase 1, que encadeia a fase 2).
 * Agendamento (pos-deploy, nao e metadata): CommercialSignalScheduler.scheduleDaily(CommercialSignalScheduler.JOB_NAME);
 */
public with sharing class CommercialSignalScheduler implements Schedulable {

    public static final String JOB_NAME = 'EPLAST33 Sinais Comerciais';
    // O cron roda no fuso do usuario que agenda (America/Sao_Paulo, UTC-3): 01:00 local = 04:00 UTC,
    // longe dos jobs existentes (02:00, 06:00, 15:47, 17:36 UTC). Quem agendar de outro fuso ajusta a hora.
    public static final String CRON_DAILY_0400_UTC = '0 0 1 * * ?';

    public void execute(SchedulableContext sc) {
        CommercialSignalService.Settings s = CommercialSignalService.loadSettings();
        Database.executeBatch(new CommercialSignalGroupStatsBatch(s, Date.today(), true), s.batchSize);
    }

    public static Id scheduleDaily(String jobName) {
        return System.schedule(jobName, CRON_DAILY_0400_UTC, new CommercialSignalScheduler());
    }
}
