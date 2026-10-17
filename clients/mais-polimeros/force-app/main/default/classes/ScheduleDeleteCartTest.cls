@isTest
public class ScheduleDeleteCartTest {

    @isTest
    static void testScheduleOnNonLastDayOfMonth() {
        // Simulação da data para um dia que não é o último do mês
        Date notLastDay = Date.today().toStartOfMonth().addDays(15);

        // Início do teste
        Test.startTest();

        // Agendando a classe para executar
        ScheduleDeleteCart scheduler = new ScheduleDeleteCart();
        String cronExp = '0 59 23 * * ?';
        System.schedule('Test Schedule Delete Cart', cronExp, scheduler);

        // Parar o teste
        Test.stopTest();

        // Verificar se nenhum batch foi iniciado
        List<AsyncApexJob> jobs = [SELECT Id, JobType, Status FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assertEquals(0, jobs.size(), 'O batch não deve ser executado em dias que não sejam o último do mês.');
    }
}