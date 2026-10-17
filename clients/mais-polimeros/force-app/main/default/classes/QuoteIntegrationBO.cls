public with sharing class QuoteIntegrationBO implements IProcessingQueue {
    public class IntegrationException extends Exception {}
    public static void executeQueue( String queueId , String recordId, String eventName, String payload ) {
        try{

            if( eventName.equals( QueueEventNames.QUOTE_SALESFORCE_TO_TOTVS.name() ) )
                sendToTotvs( queueId, eventName, payload, recordId );

        } catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        }            
        
    }

    public static String getJsonRequest( Quote quote, String operacao ) { 
        List<QuoteLineItem>  itens  = QuoteDAO.getInstance().getItens( quote.Id );  
        JSONGenerator gen           = JSON.createGenerator(true);

        gen.writeStartObject();
            gen.writeFieldName('COTACOES');
            gen.writeStartArray();
                gen.writeStartObject();
                    gen.writeStringField( 'FILIAL',            Util.getString( quote.Opportunity.Unidade_Filial__r.Codigo__c ) );
                    gen.writeStringField( 'CLIENTE',           Util.getString( quote.Opportunity.Account.Codigo__c ) );
                    gen.writeStringField( 'CONDICAOPAGAMENTO', Util.getString( quote.Opportunity.CondicaoPagamento__r.codigo__c ) );
                    //gen.writeStringField( 'VENDEDOR',          Util.getString( quote.Opportunity.Owner.CodVendedor__c ) );
                    gen.writeStringField( 'OPERACAO',          operacao );
                    gen.writeStringField( 'TPFRETE',           Util.getString( quote.Opportunity.TipoDeFrete__c ).left(1));
                    gen.writeStringField( 'CLIREM',            (String.isEmpty(quote.Opportunity.CodigoReceptorFormula__c)) ? '': quote.Opportunity.CodigoReceptorFormula__c);
                    gen.writeFieldName('ITENS');
                    gen.writeStartArray();
                    for (QuoteLineItem item : itens) {                        
                        gen.writeStartObject();
                            gen.writeStringField( 'ITEM',               Util.getString( item.Id ) );
                            gen.writeStringField( 'PRODUTO',            Util.getString( item.Product2.Name ) ); //O nome é o código, solocitado por Henrique e Andressa
                            gen.writeStringField( 'TES',                Util.getString( item.TESEditavel__c == null ? QuoteDAO.getInstance().getTES( quote ) : item.TESEditavel__c ) );
                            gen.writeNumberField( 'QUANTIDADE',         Util.getDecimal( Util.getString( item.Quantity )) );
                            gen.writeStringField( 'DTENTREGA',          Util.getString( item.DataEntrega__c ) );
                        gen.writeEndObject();                       
                    }
                    gen.writeEndArray();
                gen.writeEndObject();       
            gen.writeEndArray();
        gen.writeEndObject();
        
        return (gen.getAsString()); 
    }

    public static void sendToTotvs(String queueId, String eventName, String payload, String recordId){
        try {
            WSTotvs service                         =  new WSTotvs();
            List<QuoteLineItem> itemLinhaForUpdate  =  new List<QuoteLineItem>();
            List<Estoque__c>    estoqueForInsert    =  new List<Estoque__c>();
            String res                              =  service.priceProcessor( payload );
            String mensagemTotvs;
            String operacao;
            Decimal limiteCredito;
            Boolean bloqueio = false;
            Boolean bloqueioFrete = false;
            string obsLogisticaV;
            string obsLogisticaR;
            Map<String, UnidadeFilial__c> mapFilials = QuoteDAO.getInstance().getAllFilials();

            if (!res.equals('500') && !res.equals('503')){                 
                Map<String, Object> responseMap         = (Map<String, Object>) JSON.deserializeUntyped( res );

                for (Object objCotacao : (List<Object>) responseMap.get('COTACOES') ) {
                    Map<String, Object> mapCotacao = ( Map<String, Object> ) objCotacao;
                    mensagemTotvs = Util.getString( mapCotacao.get('MSGCREDITO') );
                    limiteCredito = Decimal.valueOf( Util.getString( mapCotacao.get('LIMITECREDITO')) );
                    operacao      = Util.getString( mapCotacao.get('OPERACAO') );
                    bloqueio      = Util.getBoolean(mapCotacao.get('BLOQUEIO'));
                    bloqueioFrete = Util.getBoolean(mapCotacao.get('BLQFRETE'));
                    obsLogisticaV = Util.getString(mapCotacao.get('OBSLOGV'));
                    obsLogisticaR = Util.getString(mapCotacao.get('OBSLOGR'));


                    for (Object objItens : (List<Object>) mapCotacao.get('ITENS')) {
                        Map<String, Object> mapItens = ( Map<String, Object> ) objItens;
                        
                        if( operacao == 'INC'){
                            itemLinhaForUpdate.add( new QuoteLineItem(  Id                       = Util.getString( mapItens.get('ITEM') ), 
                                                                        ComissaoEditavel__c      = Util.getDecimal( Util.getString( mapItens.get('COMISSAO')) ),
                                                                        Comissao__c              = Util.getDecimal( Util.getString( mapItens.get('COMISSAO')) ),
                                                                        Percent_ICMS__c          = Util.getDecimal( Util.getString( mapItens.get('ICMS')) ), 
                                                                        IPI__c                   = Util.getDecimal( Util.getString( mapItens.get('IPI')) ), 
                                                                        Valor_Frete__c           = Util.getDecimal( Util.getString( mapItens.get('VALORUNITARIOFRETE')) ), 
                                                                        PrecoUnitarioSImposto__c = Util.getDecimal( Util.getString( mapItens.get('VALORUNITARIOSEMIMP')) ),
                                                                        UnitPrice                = Util.getDecimal( Util.getString( mapItens.get('VALORUNITARIOSEMIMP')) )
                                                                    ));
                            
                        }

                        estoqueForInsert.add( new Estoque__c(       Cotacao__c               = recordId,
                                                                    Produto__c               = QuoteDAO.getInstance().getProduto( Util.getString( mapItens.get('PRODUTO')) ), 
                                                                    horarioConsulta__c       = System.now(), 
                                                                    QAtual__c                = Util.getDecimal( Util.getString( mapItens.get('QTDEATUAL')) ), 
                                                                    QReserva__c              = Util.getDecimal( Util.getString( mapItens.get('QTDERESERVA')) ), 
                                                                    QDisponivel__c           = Util.getDecimal( Util.getString( mapItens.get('QTDEDISPONIVEL')) ),
                                                                    QCompras__c              = Util.getDecimal( Util.getString( mapItens.get('QTDECOMPRAS')) ),
                                                                    QSolCompras__c           = Util.getDecimal( Util.getString( mapItens.get('QTDESOLCOMPRAS')) ),
                                                                    USaida__c                = Util.getDate( mapItens.get('DATAULTIMASAI') ),
                                                                    UnidadeFilial__c         = Util.getString( mapFilials.get( Util.getString( mapItens.get('FILIAL'))).Id )
                                                                ));
                    }
                }
                
                ProcessControl.ignoredByTrigger = true;
                if ( estoqueForInsert   != null ) insert estoqueForInsert;
                if ( itemLinhaForUpdate != null ) update itemLinhaForUpdate; 
                Quote quote = QuoteDAO.getInstance().getAllFields(recordId);
                quote.SincronizaTotvs__c  = false;
                if(quote.Status.Equals('Negociação')){
                    quote.Status = 'Aguardando cliente'; 
                }
                quote.StatusIntegracao__c = 'Sucesso';
                quote.BloqueioFinanceiro__c = bloqueio;
                quote.BloqueioFrete__c = bloqueioFrete;
                quote.TiraAprovacoes__c = true;
                update quote;
                Opportunity op = OpportunityDAO.getInstance().getOpportunityIntegration(quote.OpportunityId);  
                List<Account> accountsToUpdate = new List<Account>();
                Account account = AccountDAO.getInstance().accountById(op.Account.Id);
                Account receptorAccount;
                if(op.ContaReceptor__r != null) receptorAccount = AccountDAO.getInstance().accountById(op.ContaReceptor__r.Id);
                accountsToUpdate.add(account);
                if(op.RecordTypeId.Equals(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Oportunidade').getRecordTypeId())){
                    account.ObservacoesLogistica__c = obsLogisticaV;
                }else{
                    account.ObservacoesLogistica__c = obsLogisticaV;
                    receptorAccount.ObservacoesLogistica__c = obsLogisticaR;
                    accountsToUpdate.add(receptorAccount);
                }      
                update accountsToUpdate;
                update op;
                update new Account(Id = QuoteDAO.getInstance().getAccountId( recordId ), mensagemTOTVS__c = mensagemTotvs + ' Limite de crédito: ' + limiteCredito, LimiteCredito__c = limiteCredito );            
                QueueBO.getInstance().updateQueue( queueId, res, '');
                return;                
            }

            update new Quote(Id = recordId, StatusIntegracao__c = 'Erro no TOTVS'); 
            throw new IntegrationException('Erro na integração, serviço TOTVS indisponível');

        } catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {
            System.debug(ex.getMessage() + ' / ' + ex.getStackTraceString());
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        }  
    }
}