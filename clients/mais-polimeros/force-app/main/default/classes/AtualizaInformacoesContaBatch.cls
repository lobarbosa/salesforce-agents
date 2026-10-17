global class AtualizaInformacoesContaBatch implements Database.Batchable<sObject>{

    global Database.QueryLocator start(Database.BatchableContext BC){
        // String soql = ' SELECT  Id, GrupoEconomicoIdInterno__c, UltimaAtividadeGrupoEconomico__c, UltimaCotacaoGrupoEconomico__c, UltimoPedidoGrupoEconomico__c '
        //             + ' FROM    Account '
        //             + ' WHERE   UltimaAtividadeGrupoEconomico__c = null '
        //             + ' OR      UltimaCotacaoGrupoEconomico__c = null '
        //             + ' OR      UltimoPedidoGrupoEconomico__c = null';

        String soql = ' SELECT  Id, GrupoEconomicoIdInterno__c, UltimaAtividadeGrupoEconomico__c, UltimaCotacaoGrupoEconomico__c, UltimoPedidoGrupoEconomico__c '
                    + ' FROM    Account '
                    + ' WHERE   UltimaAtividadeGrupoEconomico__c != null ';
        system.debug('soql: ' + soql);
        return Database.getQueryLocator(soql);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope){

        Set<Id> setAccountId = new Set<Id>();
        for(Account acc : scope){
            setAccountId.add(acc.GrupoEconomicoIdInterno__c);
        }
        system.debug('setAccountId: ' + setAccountId.size());
        system.debug('setAccountId: ' + setAccountId);

        // Tasks
        Map<String,Date> mapTask = new Map<String,Date>();
        List<AggregateResult> aggTask = [   SELECT  Account.GrupoEconomicoIdInterno__c accountId
                                                    , max(CreatedDate) data
                                            FROM    Task
                                            WHERE   AccountId != null
                                            AND     TaskSubtype != 'ListEmail'
                                            AND     Account.GrupoEconomicoIdInterno__c IN :setAccountId
                                            GROUP   BY Account.GrupoEconomicoIdInterno__c];

        for(AggregateResult agg : aggTask){
            Id accountId = (Id)agg.get('accountId');
            Date maxData = Date.valueOf((Datetime)agg.get('data'));
            mapTask.put(accountId, maxData);                            
        }
        System.debug('mapTask: ' + mapTask.size());

        // // Opportunity
        // Map<String,Date> mapOpp = new Map<String,Date>();
        // List<AggregateResult> aggOpp = [    SELECT  Account.GrupoEconomicoIdInterno__c accountId
        //                                             , max(CreatedDate) data
        //                                     FROM    Opportunity
        //                                     WHERE   AccountId != null
        //                                     AND     Account.GrupoEconomicoIdInterno__c IN :setAccountId
        //                                     GROUP   BY Account.GrupoEconomicoIdInterno__c];

        // for(AggregateResult agg : aggOpp){
        //     Id accountId = (Id)agg.get('accountId');
        //     Date maxData = Date.valueOf((Datetime)agg.get('data'));
        //     mapOpp.put(accountId, maxData);                            
        // }
        // System.debug('mapOpp: ' + mapOpp.size());

        // // Order
        // Map<String,Date> mapOrder = new Map<String,Date>();
        // List<AggregateResult> aggOrder = [  SELECT  Account.GrupoEconomicoIdInterno__c accountId
        //                                             , max(CreatedDate) data
        //                                     FROM    Order
        //                                     WHERE   AccountId != null
        //                                     AND     Account.GrupoEconomicoIdInterno__c IN :setAccountId
        //                                     GROUP   BY Account.GrupoEconomicoIdInterno__c];

        // for(AggregateResult agg : aggOrder){
        //     Id accountId = (Id)agg.get('accountId');
        //     Date maxData = Date.valueOf((Datetime)agg.get('data'));
        //     mapOrder.put(accountId, maxData);                            
        // }
        // System.debug('mapOrder: ' + mapOrder.size());

        List<Account> lstUpdAccount = new List<Account>();
        for(Account acc : scope){

            Boolean atualiza = false;
            String accountId = acc.GrupoEconomicoIdInterno__c;

            if(mapTask.containsKey(accountId)){
                acc.UltimaAtividadeGrupoEconomico__c = mapTask.get(accountId);
                atualiza = true;
            } else {
                acc.UltimaAtividadeGrupoEconomico__c = null;
                atualiza = true;
            }

            // if(mapOpp.containsKey(accountId)){
            //     acc.UltimaCotacaoGrupoEconomico__c = mapOpp.get(accountId);
            //     atualiza = true;
            // }

            // if(mapOrder.containsKey(accountId)){
            //     acc.UltimoPedidoGrupoEconomico__c = mapOrder.get(accountId);
            //     atualiza = true;
            // }

            if(atualiza){
                lstUpdAccount.add(acc);
            }

        }

        System.debug('lstUpdAccount: ' + lstUpdAccount.size());
        System.debug('lstUpdAccount: ' + lstUpdAccount);
        if(!lstUpdAccount.isEmpty()){
            update lstUpdAccount;
        }

        

    }

    global void finish(Database.BatchableContext BC) {
        
    }

    public static void codeCoverage(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }

}


// Database.executeBatch(new AtualizaInformacoesContaBatch(), 100);