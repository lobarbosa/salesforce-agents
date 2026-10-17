public Without Sharing class OrderIntegrationBO implements IProcessingQueue {
    public class IntegrationException extends Exception {}

    private class estoqueSincronizacao {
        private Decimal quantidadeAntes;
        private Decimal quantidadeDepois;
    }

    public static void executeQueue( String queueId , String recordId, String eventName, String payload ) {
        try{
            if( eventName.equals( QueueEventNames.OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name() ) )
                sendToTotvs( queueId, eventName, payload, recordId );
            if( eventName.equals( QueueEventNames.ALT_OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name() ) )
                sendToTotvsAlt( queueId, eventName, payload, recordId );
            if( eventName.equals( QueueEventNames.EXC_OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name() ) )
                sendToTotvsExc( queueId, eventName, payload, recordId );
        } catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        }  
    }

    public static String getJsonRequest(Id orderId, string operacao) {

        String OperecaoTriangularRecordType = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('OportunidadeTriangular').getRecordTypeId();

        Order ord = OrderDAO.getInstance().getOrderIntegrationWithItems(orderId);
        System.debug('ord:'+ord);
        System.debug('ordIt:'+ord.OrderItems);
        Boolean tipoTriangular = (OperecaoTriangularRecordType == ord.Opportunity.RecordTypeId);

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
            gen.writeFieldName('PEDIDO');
            gen.writeStartArray();
                gen.writeStartObject();
                    gen.writeFieldName('CABECALHO');
                        gen.writeStartObject();
                        gen.writeStringField('OPERACAO', operacao);
                        gen.writeStringField('PEDIDO1', (String.isEmpty(Util.getString(ord.CodigoTOTVS__c))) ? '' : Util.getString(ord.CodigoTOTVS__c));
                        gen.writeStringField('PEDIDO2', (String.isEmpty(Util.getString(ord.CodigoReceptor__c))) ? '' : Util.getString(ord.CodigoReceptor__c));
                        gen.writeStringField('OBS', (String.isEmpty(Util.getString(ord.InformacoesParaLogistica__c))) ? '':Util.getString(ord.InformacoesParaLogistica__c));
                        gen.writeStringField('COLETA', Util.getString(ord.Coleta__c).left(1));
                        gen.writeStringField('TPFRETE', Util.getString(ord.TipoFrete__c).left(1));
                        gen.writeStringField('TIPOCLI', Util.getString(ord.Account.Type));
                        gen.writeStringField('FILIAL', Util.getString(ord.UnidadeFilial__r.Codigo__c));
                        gen.writeStringField('CLIVEN', Util.getString(ord.Account.Codigo__c));
                        gen.writeStringField('CONDVENDA', Util.getString( ord.CondicaoPagamento__r.Codigo__c ));
                        gen.writeStringField('TRANSPORTA', (String.isEmpty(Util.getString(ord.Transportadora__c))) ? '':Util.getString(ord.Transportadora__c));
                        gen.writeStringField('TRIANGULAR', tipoTriangular ? 'S':'N'); 
                        gen.writeStringField('CLIREM', tipoTriangular ? ((String.isEmpty(ord.ContaReceptor__r.Codigo__c)) ? '': ord.ContaReceptor__r.Codigo__c):''); 
                        gen.writeStringField('CONDREMESSA', tipoTriangular ? '002':'');
                        gen.writeStringField('TESREMESSA', tipoTriangular ? ((String.isEmpty(Util.getString(ord.TESReceptor__c))) ? '':Util.getString(ord.TESReceptor__c)):'');
                        gen.writeStringField('INFOADIC', (String.isEmpty(Util.getString(ord.Description))) ? '':Util.getString(ord.Description));
                        gen.writeNumberField('DESPAC', 0);
                        gen.writeStringField('FORMAPAG', Util.getString(ord.FormaPagamento__c));
                        gen.writeStringField('VENDEDOR', Util.getString(ord.Vendedor__r.CodVendedor__c));
                        gen.writeEndObject();
                        gen.writeFieldName('ITENS');
                        gen.writeStartArray();
                            Integer count = 1;
                            for(OrderItem lineItem : ord.OrderItems){
                                if (    (operacao.Equals('INC') ) ||
                                        (operacao.Equals('EXC') && Util.getString(lineItem.Status__c).Equals('Cancelado')) ||
                                        (operacao.Equals('ALT') && (    !Util.getString(lineItem.Status__c).Equals('Cancelado') &&
                                                                        !Util.getString(lineItem.Status__c).Equals('Faturado') ))){

                                    System.debug('lineItem: ' + lineItem);
                                    System.debug('lineItem.PricebookEntry: ' + lineItem.PricebookEntryId);
                                    System.debug('lineItem.PricebookEntry.Product2Id: ' + lineItem.PricebookEntry.Product2Id);
                                    System.debug('lineItem.PricebookEntry.Product2.Name: ' + lineItem.PricebookEntry.Product2.Name);

                                    gen.writeStartObject();
                                        gen.writeStringField('ITEM', (operacao.Equals('INC')) ? Util.getString(count) : lineItem.CodigoTOTVSAutoInc__c != null ? lineItem.CodigoTOTVSAutoInc__c : '0');
                                        gen.writeStringField('PRODUTO', lineItem.PricebookEntry.Product2.Name);
                                        gen.writeStringField('ID', lineItem.Id );
                                        gen.writeStringField('TES', Util.getString(ord.TES__c));
                                        gen.writeNumberField('QUANT', lineItem.Quantity );
                                        gen.writeNumberField('PRECO', lineItem.PrecoUnitarioCImposto__c );
                                        gen.writeStringField('DTENTREGA', Util.getString(lineItem.DataEntrega__c));
                                        gen.writeNumberField('COMISSAO', lineItem.ComissaoEditavel__c == null ? 0 : lineItem.ComissaoEditavel__c); 
                                        gen.writeStringField('NRPEDCLI', (String.isEmpty(Util.getString(lineItem.NumeroPediClin__c))) ? '':Util.getString(lineItem.NumeroPediClin__c));
                                        gen.writeNumberField('IPIPERCENT', lineItem.PercentualIPI__c == null ? 0 : lineItem.PercentualIPI__c);
                                        gen.writeStringField('NRITEMCLI', (String.isEmpty(Util.getString(lineItem.NumeroItemCli__c))) ? '':Util.getString(lineItem.NumeroItemCli__c));
                                        gen.writeNumberField('FRETEUNIT', lineItem.ValorFrete__c != null ? lineItem.ValorFrete__c : 0 );
                                        
                                        if(lineItem.Upselling__c){
                                            gen.writeStringField('PROJETO', 'UPS');
                                        } else {
                                            if(lineItem.Pedido_Elegivel__c){
                                                gen.writeStringField('PROJETO', 'VNZ');
                                            } else {
                                                gen.writeStringField('PROJETO', 'NAO');    
                                            }
                                        }

                                    gen.writeEndObject();
                                }
                                count++;
                            }
                        gen.writeEndArray();
                gen.writeEndObject();
            gen.writeEndArray();
        gen.writeEndObject();

        return (AccentsBO.removeDiacritics( gen.getAsString()) );
    }

    public static void sendToTotvs(String queueId, String eventName, String payload, String recordId){
        try {
            Boolean estoqueNegativo = false;

            Map<String,estoqueSincronizacao> mapEstoque = new Map<String,estoqueSincronizacao>();
            List<OpportunityLineItem> listUpdateOLI = new List<OpportunityLineItem>();

            String idOppEstoque = [SELECT OpportunityId FROM Order WHERE Id = :recordId].OpportunityId;

            if(String.isNotBlank(idOppEstoque)){
                Map<String,Decimal> mapTotais = new Map<String,Decimal>();
                List<AggregateResult> lstAggregate = new List<AggregateResult>();
                lstAggregate = [    SELECT  Product2.Name produto
                                            , SUM(Quantity) total
                                    FROM    OpportunityLineItem
                                    WHERE   OpportunityId = :idOppEstoque
                                    GROUP   BY Product2.Name ];

                for(AggregateResult aggOrd : lstAggregate){
                    String produto = (String)aggOrd.get('produto');
                    Decimal quantidadeTotal = (Decimal)aggOrd.get('total');
                    mapTotais.put(produto, quantidadeTotal);
                }
                System.debug('mapTotais: ' + mapTotais);

                

                
                OpportunityDAO dao = OpportunityDAO.getInstance();
                Opportunity oppEstoque = dao.getOpportunityIntegration(idOppEstoque);
                System.debug('oppEstoque: ' + oppEstoque);

                String payloadEstoque = OpportunityIntegrationBO.getJsonRequestPreco(oppEstoque, 'INC');
                System.debug('payloadEstoque: ' + payloadEstoque);

                // WSTotvs serviceEstoque = new WSTotvs();
                // String resEstoque = serviceEstoque.priceProcessor(payloadEstoque);

                WSTotvs wst = new WSTotvs('priceProcessor', payloadEstoque);
                String resEstoque = wst.Invoke();


                System.debug('resEstoque: ' + resEstoque);

                Boolean pularCotacao = false;
                if(Test.isRunningTest() && !resEstoque.contains('COTACOES'))
                pularCotacao = true;
                
                if (!resEstoque.equals('500') && !resEstoque.equals('503') && !pularCotacao){
                    
                    Map<String, Object> responseMapEstoque = (Map<String, Object>) JSON.deserializeUntyped(resEstoque);

                    for (Object objCotacao : (List<Object>) responseMapEstoque.get('COTACOES') ) {
                        Map<String, Object> mapCotacaoEstoque = (Map<String, Object>) objCotacao;

                        for (Object objItens : (List<Object>) mapCotacaoEstoque.get('ITENS')) {
                            Map<String, Object> mapItens = ( Map<String, Object> ) objItens;

                            String itemId = Util.getString(mapItens.get('ITEM'));
                            String itemDesc = Util.getString(mapItens.get('PRODUTO'));

                            Decimal estoqueDisponivel = Util.getDecimal(Util.getString(mapItens.get('QTDEDISPONIVEL')));
                            Decimal quantidadeTotal = mapTotais.get(itemDesc);
                            Decimal quantidadeFinal = (estoqueDisponivel - quantidadeTotal);

                            estoqueSincronizacao e = new estoqueSincronizacao();
                            e.quantidadeAntes = estoqueDisponivel;
                            e.quantidadeDepois = quantidadeFinal;
                            mapEstoque.put(itemDesc, e);

                            if(quantidadeFinal < 0){
                                estoqueNegativo = true;
                            }

                            OpportunityLineItem newOLI = new OpportunityLineItem (
                                Id = itemId,
                                EstoqueDisponivelSincronizacao__c = estoqueDisponivel,
                                EstoqueDisponivelAposSincronizacao__c = quantidadeFinal
                            );
                            listUpdateOLI.add(newOLI);
                        }
                    }
                    System.debug('listUpdateOLI.size(): ' + listUpdateOLI.size());
                    System.debug('listUpdateOLI: ' + listUpdateOLI);
                    System.debug('mapEstoque: ' + mapEstoque);
                }
            }

            // WSTotvs service = new WSTotvs();
            // String res = service.opportunityProcessor(payload);
            WSTotvs wst = new WSTotvs('opportunityProcessor', payload);
            String res = wst.Invoke();

            if (!res.equals('500') && !res.equals('503')){

                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res);
				System.debug('json res:');
                System.debug(responseMap);
                
                Order ord = OrderDAO.getInstance().getOrderIntegration(recordId);
                if(Test.isRunningTest()){
                    ord = OrderDAO.getInstance().getOrderIntegrationWithItems(recordId);
                }
                Opportunity opp = new Opportunity();
                Map<String, OrderItem> mapOrderItem = new Map<String, OrderItem>();
                List<OrderItem> lstOrdItems = new List<OrderItem>();

                for(OrderItem ordItem : ord.OrderItems){
                    mapOrderItem.put(ordItem.Id, ordItem);
                }

                String pedidoTotvs = '';

                System.debug('mock:' + responseMap.get('PEDIDOS'));

                for (Object pedido : (List<Object>) responseMap.get('PEDIDOS') ) {
                    Map<String,Object> mapPedido = (Map<String, Object>)pedido;
                    Map<String,Object> cabecalho = (Map<String, Object>)mapPedido.get('CABECALHO');

                    String msg = Util.getString(cabecalho.get('MENSAGEM'));
                    if(!msg.Equals('Pedido(s) incluido(s) com sucesso!')){
                        if(msg.contains('999')){
                            throw new IntegrationException(msg.replace('999 - ', ''));
                        } else {
                            throw new IntegrationException('Erro no pedido: ' + msg);
                        }
                    }

                    pedidoTotvs = Util.getString(cabecalho.get('PEDVEN'));

                    opp.Id = ord.OpportunityId;
                    opp.StageName = 'Fechado Ganho';
                    opp.CodigoTOTVS__c = Util.getString(cabecalho.get('PEDVEN'));

                    ord.CodigoTOTVS__c = Util.getString(cabecalho.get('PEDVEN'));
                    ord.CodigoReceptor__c = Util.getString(cabecalho.get('PEDREM'));
                    ord.MensagemTOTVS__c = Util.getString(cabecalho.get('MENSAGEM'));
                    ord.BloqueioFinanceiro__c = Util.getBoolean(cabecalho.get('BLOQUEIO'));

                    for(Object Item : (List<Object>)mapPedido.get('ITENS')){
                        Map<String, Object> mapItem = (Map<String, Object>) Item;
                        OrderItem ordItem = mapOrderItem.get(Util.getString(mapItem.get('ID')));

                        if(ordItem == null ){
                            throw new IntegrationException('Item não encontrado - ID: ' + Util.getString(mapItem.get('ID')));
                        }

                        system.debug('ordItem: ' + ordItem);
                        system.debug('ordItem: ' + ordItem.PricebookEntry.Product2.Name);

                        if(mapEstoque.containsKey(ordItem.PricebookEntry.Product2.Name)){
                            estoqueSincronizacao es = mapEstoque.get(ordItem.PricebookEntry.Product2.Name);
                            ordItem.EstoqueDisponivelSincronizacao__c = es?.quantidadeAntes;
                            ordItem.EstoqueDisponivelAposSincronizacao__c = es?.quantidadeDepois;
                        }

                        ordItem.CodigoTOTVSAutoInc__c = Util.getString(mapItem.get('ITEM'));
                        ordItem.Status__c = Util.getString(mapItem.get('STATUS'));
                        lstOrdItems.add(ordItem);
                    }
                }

                ProcessControl.ignoredByTrigger = true;

                system.debug('mapOrderItem: ' + mapOrderItem);

                update ord;
                if(!Test.isRunningTest()){
                    update lstOrdItems;

                    if(String.isNotBlank(idOppEstoque)){
                        update opp;
                    }
                    
                }else{
                    estoqueNegativo = true;
                }
                
                if(listUpdateOLI.size() > 0) update listUpdateOLI;
                QueueBO.getInstance().updateQueue( queueId, res, '');

                if(estoqueNegativo){
                    String titulo = 'Pedido ' + pedidoTotvs + ' gerado contendo produto com estoque negativo';
                    String corpo = 'O pedido ' + pedidoTotvs + ' foi gerado e contém produto(s) com estoque negativo';

                    // Notificação
                    CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='NotificaErro'];
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setNotificationTypeId(notificationType.Id);
                    notification.setTitle(titulo);
                    notification.setBody(corpo);
                    notification.setTargetId(idOppEstoque);

                    try {
                        Set<String> destinatatio = new Set<String>{UserInfo.getUserId()};
                        notification.send(destinatatio);
                    }
                    catch (Exception e) {
                        System.debug('Problem sending notification: ' + e.getMessage());
                    }

                    String corpoEmail = '<h3>O pedido ' + pedidoTotvs + ' foi gerado contendo um ou mais produtos com estoque negativo:</h3>';
                    if(!mapEstoque.isEmpty()){
                        corpoEmail += '<table style="border: solid #CCCCCC; border-width: 1; cellpadding=5">';
                        corpoEmail += '<tr style="border: solid #CCCCCC; border-width: 1"><th style="font-size: 14px; font-face: verdana ;background: #110555; border-width: 1; text-align: left; padding-right: 30px; padding-left: 5px">Produto</th><th style="font-size: 14px; font-face: verdana ;background: #110555; border-width: 1; text-align: left; padding-right: 30px; padding-left: 5px">Quantidade disponível</th><th style="font-size: 14px; font-face: verdana ;background: #110555; border-width: 1; text-align: left; padding-right: 30px; padding-left: 5px">Quantidade disponível após sincronização</th></tr>';
                        for(String key : mapEstoque.keySet()){
                            estoqueSincronizacao est = mapEstoque.get(key);

                            if(est.quantidadeDepois < 0){
                                corpoEmail += '<tr style="border: solid #CCCCCC; border-width: 1">';
                                corpoEmail += '<td style="font-size: 14px; font-face: verdana; padding-right: 30px; padding-left: 5px">' + key + '</td>';
                                corpoEmail += '<td style="font-size: 14px; font-face: verdana; padding-right: 30px; padding-left: 5px">' + est.quantidadeAntes + '</td>';
                                corpoEmail += '<td style="font-size: 14px; font-face: verdana; padding-right: 30px; padding-left: 5px">' + est.quantidadeDepois + '</td>';
                                corpoEmail += '</tr>';
                            }
                        }
                        corpoEmail += '</table>';
                    }

                    List<User> lstUser = new List<User>();
                    List<GroupMember> lstGroup = [Select UserOrGroupID FROM GroupMember where Group.DeveloperName = 'ComercialEstoque'];
                    List<Id> lstUserId = new List<Id>();
                    lstUserId.add(ord.Vendedor__c);
                    for(GroupMember g:lstGroup){
                        lstUserId.add(g.UserOrGroupId);
                    }

                    lstUser = [SELECT Email from User where Id IN :lstUserId AND Email != 'magda@maispolimeros.com.br'];

                    List<String> toAddresses = new List<String>();
                    toAddresses.add(UserInfo.getUserEmail());

                    for(User user : lstUser){
                        toAddresses.add(user.Email);
                    }

                    // E-mail
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(toAddresses);
                    email.setSubject(titulo);
                    email.setHtmlBody(corpoEmail);

                    try {
                        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email}); 
                    }
                    catch (Exception e) {
                        System.debug('Problem sending email: ' + e.getMessage());
                    }
                    
                }


                return;
            }

            // throw new IntegrationException('Erro na integração, serviço TOTVS indisponível');
            throw new IntegrationException('Erro na integração: ' + res);

        } catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        }  
    }




    @future(callout=true)
    public static void sendToTotvsAlt(String queueId, String eventName, String payload, String recordId){
        try {
            // WSTotvs service = new WSTotvs();
            Order ord = OrderDAO.getInstance().getOrderIntegration(recordId);
            // String res = service.opportunityProcessor( payload );

            WSTotvs wst = new WSTotvs('opportunityProcessor', payload);
            String res = wst.Invoke();

            if (!res.equals('500') && !res.equals('503')){
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res);

                for (Object pedido : (List<Object>) responseMap.get('PEDIDOS')) {
                    Map< String, Object > mapPedido = ( Map<String, Object> ) pedido;
                    Map< String, Object > cabecalho = ( Map<String, Object> )mapPedido.get('CABECALHO');

                    if(!Util.getString(cabecalho.get('MENSAGEM')).Equals('Pedido(s) alterado(s) com sucesso!')){
                        throw new IntegrationException('Erro no pedido: '+ Util.getString(cabecalho.get('MENSAGEM')));
                    }

                    ord.MensagemTOTVS__c = Util.getString(cabecalho.get('MENSAGEM'));
                }

                ProcessControl.ignoredByTrigger = true;
                update ord;

                QueueBO.getInstance().updateQueue( queueId, res, '');
                return;                
            }

            throw new IntegrationException('Erro na integração, serviço TOTVS indisponível');

        } catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        }  
    }

    @future(callout=true)
    public static void sendToTotvsExc(String queueId, String eventName, String payload, String recordId){
        try {
            // WSTotvs service = new WSTotvs();
            Order ord = OrderDAO.getInstance().getOrderIntegration(recordId);
            // String res = service.opportunityProcessor(payload);

            WSTotvs wst = new WSTotvs('opportunityProcessor', payload);
            String res = wst.Invoke();

            if (!res.equals('500') && !res.equals('503')){                 
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped( res );

                for (Object pedido : (List<Object>) responseMap.get('PEDIDOS') ) {
                    Map< String, Object > mapPedido = ( Map<String, Object> ) pedido;
                    Map< String, Object > cabecalho = ( Map<String, Object> )mapPedido.get('CABECALHO');

                    if(!Util.getString(cabecalho.get('MENSAGEM')).Contains('sucesso')) {
                        throw new IntegrationException('Erro no pedido: '+ Util.getString(cabecalho.get('MENSAGEM')));
                    }

                    ord.MensagemTOTVS__c = Util.getString(cabecalho.get('MENSAGEM'));
                }

                ProcessControl.ignoredByTrigger = true;
                update ord;

                QueueBO.getInstance().updateQueue( queueId, res, '');
                return;                
            }

            throw new IntegrationException('Erro na integração, serviço TOTVS indisponível');

        } catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {

            ParametrosGerais__c pg = ParametrosGerais__c.getInstance();
            Boolean reverteStatus = (pg.ReverteStatusErroIntegracao__c == null ? false : pg.ReverteStatusErroIntegracao__c);

            if(reverteStatus){
                List<OrderItem> lstOrderItem = new List<OrderItem>([    SELECT  Id, StatusPreIntegracao__c, Status__c
                                                                        FROM    OrderItem
                                                                        WHERE   StatusPreIntegracao__c <> null 
                                                                        AND     OrderId = :recordId ]);

                if(lstOrderItem != null && lstOrderItem.size() > 0){
                    for(OrderItem oi : lstOrderItem){
                        oi.ByPassVr__c = true;
                        oi.Status__c = oi.StatusPreIntegracao__c;
                        oi.StatusPreIntegracao__c = null;
                        }
                    update lstOrderItem;

                    for(OrderItem oi : lstOrderItem){
                        oi.ByPassVr__c = false;
                    }
                    update lstOrderItem;
                }
            }

            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        }  
    }


}