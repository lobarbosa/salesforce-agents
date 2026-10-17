global class ScheduleRefreshTokenMSProject implements Schedulable {
    global void execute(SchedulableContext ctx) {
        MSProjectTokenIntegrations.refreshTokens();
    }
}

//String sch = '0 0 23 * * ? *';
//String jobID = System.schedule('Refresh MSProject Tokens', sch, new ScheduleRefreshTokenMSProject());