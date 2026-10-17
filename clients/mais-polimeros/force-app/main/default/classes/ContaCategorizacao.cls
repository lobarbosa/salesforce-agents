public without sharing class ContaCategorizacao implements Schedulable {

    public void execute(SchedulableContext sc) {

        User usuarioLogado = [ SELECT Id, ByPassPB__c FROM User WHERE Id = :UserInfo.getUserId()    ];

        Boolean desativarByPass = null;
        Boolean byPass = usuarioLogado.ByPassPB__c;
        if(byPass == false) {

            usuarioLogado.ByPassPB__c = true;
            update usuarioLogado;            
            desativarByPass = true;
        }

		atualizarClassificacao(desativarByPass);
    }

    @future
    public static void atualizarClassificacao(Boolean desativarByPass) {
      
        try {

            ParametrosGerais__c pg = ParametrosGerais__c.getInstance();     // Custom settings

            Decimal percentualLimite = ((pg.PercentualCorteClassificacao__c == null ? 0.99 : pg.PercentualCorteClassificacao__c) * -1);
            
            percentualLimite = math.abs(percentualLimite/100);

            Datetime dataAtual = Datetime.now();
            Map<String,Integer> mapData = new Map<String,Integer>();
            for(Integer i = 0; i < 6; i++) {

                dataAtual = dataAtual.addMonths(-1);                    
                String key = dataAtual.format('yyyy-MM'); 
                mapData.put(key, 6-i);

            }

            // seleciona GROUPID, ANO, MES e VOLUMETOTAL
            List<AggregateResult> lstAggregate = new List<AggregateResult>();
            lstAggregate =  [ SELECT      Order.Account.GrupoEconomicoIdInterno__c groupId, 
                                                calendar_year(DataEntrega__c) ano, 
                                                calendar_month(DataEntrega__c) mes, 
                                                SUM(Quantity) volumeTotal
                                    FROM        OrderItem 
                                    WHERE       DataEntrega__c >= LAST_N_MONTHS:6
                                    AND         DataEntrega__c < THIS_MONTH
                                    AND         Status__c NOT IN      ('Cancelado') 
                                    GROUP BY    Order.Account.GrupoEconomicoIdInterno__c, calendar_year(DataEntrega__c), calendar_month(DataEntrega__c)
                                    ORDER BY    Order.Account.GrupoEconomicoIdInterno__c, calendar_year(DataEntrega__c), calendar_month(DataEntrega__c) ];
            
            
            System.debug('lstAggregate'+ lstAggregate.size());
            Map<Id,ClassificacaoWrapper> mapClassificacao = new Map<Id,ClassificacaoWrapper>();
            for(AggregateResult aggOrd : lstAggregate) {

                // String accountId = (String)aggOrd.get('accId');
                // String classificacaoAtual = (String)aggOrd.get('accClassificacao');
                String  groupId = (String)aggOrd.get('groupId');
                String  ano = String.valueOf(aggOrd.get('ano'));
                String  mes = '0' + String.valueOf(aggOrd.get('mes'));
                String  keyData = ano + '-' + mes.right(2);
                Decimal volumeTotal = (Decimal)aggOrd.get('volumeTotal');
                //mapData contem os ultimos 6 meses
                if(mapData.containsKey(keyData)) {

                    //verifica se o grupo já foi adicionado no mapClassificacao
                    ClassificacaoWrapper wrp;
                    if(mapClassificacao.containsKey(groupId)) {
                        wrp = mapClassificacao.get(groupId);

                    } else {
                        wrp = new ClassificacaoWrapper();
                        wrp.groupId = groupId;
                        // wrp.classificacaoAtual = classificacaoAtual;
                    }

                    if(volumeTotal > 0) {
                        wrp.volumeTotal += volumeTotal;
                        wrp.quantidadeMesesCompra++;
                    }

                    //associa o volume de compra a determinado mes
                    Integer index = mapData.get(keyData);
                    switch on index {
                        when 1 {
                            wrp.mes1 = keyData;
                            wrp.totalMes1 = volumeTotal;
                        }
                        when 2 {
                            wrp.mes2 = keyData;
                            wrp.totalMes2 = volumeTotal;
                        }
                        when 3 {
                            wrp.mes3 = keyData;
                            wrp.totalMes3 = volumeTotal;
                        }
                        when 4 {
                            wrp.mes4 = keyData;
                            wrp.totalMes4 = volumeTotal;
                        }
                        when 5 {
                            wrp.mes5 = keyData;
                            wrp.totalMes5 = volumeTotal;
                        }
                        when 6 {
                            wrp.mes6 = keyData;
                            wrp.totalMes6 = volumeTotal;
                        }
                    }

                    mapClassificacao.put(groupId, wrp);
                }
            }

            // Verifica frequência
            List<Account> lstUpdateAccount = new List<Account>();
            for(ClassificacaoWrapper c : mapClassificacao.values()) {

                Decimal valorMedio = 0;
                if(c.volumeTotal != null && c.volumeTotal > 0) {
                    valorMedio = (c.volumeTotal / 6);

                }

                Decimal margemMes1 = 0;
                Decimal margemMes2 = 0;
                Decimal margemMes3 = 0;
                Decimal margemMes4 = 0;
                Decimal margemMes5 = 0;
                Decimal margemMes6 = 0;

                if(valorMedio != null && valorMedio > 0) {

                    margemMes1 = math.abs((1 - (c.totalMes1 / valorMedio)));
                    margemMes2 = math.abs((1 - (c.totalMes2 / valorMedio)));
                    margemMes3 = math.abs((1 - (c.totalMes3 / valorMedio)));
                    margemMes4 = math.abs((1 - (c.totalMes4 / valorMedio)));
                    margemMes5 = math.abs((1 - (c.totalMes5 / valorMedio)));
                    margemMes6 = math.abs((1 - (c.totalMes6 / valorMedio)));

                }
                //TIPO A --> Grupo Econômico que comprou conosco nos em todos os últimos 6 meses, mantendo a média de volume  
                if(c.quantidadeMesesCompra == 6) {
                    
                    if( margemMes1 < percentualLimite &&
                        margemMes2 < percentualLimite &&
                        margemMes3 < percentualLimite &&
                        margemMes4 < percentualLimite &&
                        margemMes5 < percentualLimite &&
                        margemMes6 < percentualLimite   ) {

                        c.accountRate = 'Tipo A';

                    } else {
                        // Comprou os seis meses, mas não manteve a frequência.
                        c.accountRate = 'Tipo B';

                    }

                } else if (c.quantidadeMesesCompra == 5) {
                    // TIPO B --> Grupo Econômico que nos últimos 6 meses, comprou conosco em 5 meses. 
                    c.accountRate = 'Tipo B';
               
                } else if (c.quantidadeMesesCompra == 4) {
                    //TIPO C --> Grupo Econômico que nos últimos 6 meses, comprou conosco em 4 meses. 
                    c.accountRate = 'Tipo C';

                } else if (c.quantidadeMesesCompra == 3) {
                    //TIPO D --> Grupo Econômico que nos últimos 6 meses, comprou conosco em 3 meses. 
                    c.accountRate = 'Tipo D';

                } else if (c.quantidadeMesesCompra == 2 || c.quantidadeMesesCompra == 1) {
                    //TIPO E --> Grupo Econômico que nos últimos 6 meses, comprou conosco em 2 e ou 1 mês  
                    c.accountRate = 'Tipo E';

                } 

                Account newAcc = new Account(
                    Id = c.groupId,
                    Classificacao__c = c.accountRate
                    
                );
                lstUpdateAccount.add(newAcc);

            }

            List<Account> lstUpdateAccountInativo = [   SELECT      Id
                                                        FROM        Account
                                                        WHERE       Classificacao__c != 'Tipo SC'
                                                        AND         Id 
                                                        NOT IN :    mapClassificacao.keySet()   ];

            if(!lstUpdateAccountInativo.isEmpty()) {
                for(Account acc : lstUpdateAccountInativo) {
                    acc.Classificacao__c = 'Tipo SC';

                }
            }

            update lstUpdateAccount;
            update lstUpdateAccountInativo;

            if(desativarByPass != null && desativarByPass == true) {

                User usuarioLogado = [  SELECT Id, ByPassPB__c FROM User WHERE Id = :UserInfo.getUserId()    ];
                usuarioLogado.ByPassPB__c = false;
                update usuarioLogado;     

            }

            enviarNotificacao('Processamento concluído com sucesso');

        } catch (Exception ex) {

            String erro = ex.getMessage()  + '|' + ex.getStackTraceString();
            System.debug('ERRO (ATUALIZARCLASSIFICAÇÃO): ' + erro);

            if (!Test.isRunningTest()) {
                enviarNotificacao('Erro durante o processamento: ' + erro);
            }
        }
    }

    private static void enviarNotificacao(String corpo) {

        CustomNotificationType notificationType = [ SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'NotificaErro'    ];
        List<Group> lstGrupo = [    SELECT Id FROM Group WHERE Type = 'Regular' AND DeveloperName = 'NotificacoesSistema' LIMIT 1   ];

        if(lstGrupo != null && !lstGrupo.isEmpty()) {

            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTitle('Atualização de Classificação de conta');
            notification.setBody(corpo);
            notification.setTargetId(UserInfo.getUserId());

            try {
                Set<String> destinatatio = new Set<String>{lstGrupo[0].Id};
                notification.send(destinatatio);

            }
            catch (Exception e) {
                System.debug('Problem sending notification: ' + e.getMessage());

            }
        }
    }

    private class ClassificacaoWrapper {

        // private String accountId;
        private String  groupId;
        private String  accountRate;
        private String  classificacaoAtual;
        private Decimal volumeTotal = 0;
        private Integer quantidadeMesesCompra = 0;
        private String  mes1;
        private Decimal totalMes1 = 0;
        private String  mes2;
        private Decimal totalMes2 = 0;
        private String  mes3;
        private Decimal totalMes3 = 0;
        private String  mes4;
        private Decimal totalMes4 = 0;
        private String  mes5;
        private Decimal totalMes5 = 0;
        private String  mes6;
        private Decimal totalMes6 = 0;

    }
}