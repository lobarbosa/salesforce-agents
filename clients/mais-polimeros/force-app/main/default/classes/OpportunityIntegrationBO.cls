/**
 * @File Name          : OpportunityIntegrationBO.cls
 * @Description        : 
 * @Author             : Lucas Oliveira
 * @Group              : 
 * @Last Modified By   : Lucas Oliveira
 * @Last Modified On   : 08/07/2019 18:29:19
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    08/07/2019 18:29:19   Lucas Oliveira     Initial Version
**/
public Without Sharing class OpportunityIntegrationBO implements IProcessingQueue {
    public class IntegrationException extends Exception {}

    public static void executeQueue( String queueId , String recordId, String eventName, String payload ) {
        try{
            if( eventName.equals( QueueEventNames.QUOTE_SALESFORCE_TO_TOTVS.name() ) )
                getFromTotvsPrice(queueId, eventName, payload, recordId);

        } catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        }  
    }

    public static String getJsonRequestPreco(Opportunity op, String operacao) { 
        List<OpportunityLineItem> itens = OpportunityDAO.getInstance().getItensForPrice(op.Id);  
        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
            gen.writeFieldName('COTACOES');
            gen.writeStartArray();
                gen.writeStartObject();
                    gen.writeStringField( 'FILIAL',            Util.getString(op.Unidade_Filial__r.Codigo__c ));
                    gen.writeStringField( 'CLIENTE',           Util.getString(op.Account.Codigo__c));
                    gen.writeStringField( 'CONDICAOPAGAMENTO', Util.getString(op.CondicaoPagamento__r.codigo__c));
                    gen.writeStringField( 'OPERACAO',          operacao);
                    gen.writeStringField( 'TPFRETE',           Util.getString(op.TipoDeFrete__c).left(1));
                    gen.writeStringField( 'CLIREM',            (String.isEmpty(op.CodigoReceptorFormula__c)) ? '': op.CodigoReceptorFormula__c);
                    gen.writeStringField('VENDEDOR',            Util.getString(op.Owner.CodVendedor__c));
                    gen.writeFieldName('ITENS');
                    gen.writeStartArray();
                    for (OpportunityLineItem item : itens) {                        
                        gen.writeStartObject();
                            gen.writeStringField( 'ITEM',               Util.getString(item.Id ));
                            gen.writeStringField( 'PRODUTO',            Util.getString(item.Product2.Name)); //O nome é o código, solocitado por Henrique e Andressa
                            gen.writeStringField( 'TES',                Util.getString(item.Opportunity.TES__c));
                            gen.writeNumberField( 'QUANTIDADE',         Util.getDecimal(Util.getString(item.Quantity)));
                            gen.writeStringField( 'DTENTREGA',          Util.getString(item.DataEntrega__c));
                        gen.writeEndObject();                       
                    }
                    gen.writeEndArray();
                gen.writeEndObject();       
            gen.writeEndArray();
        gen.writeEndObject();
        
        return (gen.getAsString()); 
    }

    public static void getFromTotvsPrice(String queueId, String eventName, String payload, String recordId){
        try {

            // WSTotvs service =  new WSTotvs();
            List<OpportunityLineItem> itemLinhaForUpdate =  new List<OpportunityLineItem>();
            List<Estoque__c> estoqueForInsert = new List<Estoque__c>();
            // String res = service.priceProcessor(payload);

            WSTotvs wst = new WSTotvs('priceProcessor', payload);
            String res = wst.Invoke();

            String mensagemTotvs;
            String operacao;
            Decimal limiteCredito;
            Decimal limiteCreditoBv;
            Decimal limiteCreditoSifra;
            Boolean bloqueio = false;
            Boolean bloqueioFrete = false;
            string obsLogisticaV;
            string obsLogisticaR = '';
            Map<String, UnidadeFilial__c> mapFilials = QuoteDAO.getInstance().getAllFilials();

            if (!res.equals('500') && !res.equals('503')){                 
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res);

                for (Object objCotacao : (List<Object>) responseMap.get('COTACOES') ) {
                    Map<String, Object> mapCotacao = (Map<String, Object>) objCotacao;

                    mensagemTotvs = Util.getString( mapCotacao.get('MSGCREDITO') );
                    
                    limiteCredito = Decimal.valueOf( Util.getString( mapCotacao.get('LIMITECREDITO')));
                    limiteCreditoBv = Decimal.valueOf( Util.getString( mapCotacao.get('LIMITECREDBV')));
                    limiteCreditoSifra = Decimal.valueOf( Util.getString( mapCotacao.get('LIMITECREDSI')));

                    operacao      = Util.getString( mapCotacao.get('OPERACAO') );
                    bloqueio      = Util.getBoolean(mapCotacao.get('BLOQUEIO'));
                    bloqueioFrete = Util.getBoolean(mapCotacao.get('BLQFRETE'));
                    obsLogisticaV = Util.getString(mapCotacao.get('OBSLOGV'));
                    obsLogisticaR = Util.getString(mapCotacao.get('OBSLOGR'));

                    for (Object objItens : (List<Object>) mapCotacao.get('ITENS')) {
                        Map<String, Object> mapItens = ( Map<String, Object> ) objItens;

                        if( operacao == 'INC'){
                            itemLinhaForUpdate.add( new OpportunityLineItem(  Id                       = Util.getString( mapItens.get('ITEM') ), 
                                                                        ComissaoEditavel__c      = Util.getDecimal( Util.getString( mapItens.get('COMISSAO')) ),
                                                                        Comissao__c              = Util.getDecimal( Util.getString( mapItens.get('COMISSAO')) ),
                                                                        Percent_ICMS__c          = Util.getDecimal( Util.getString( mapItens.get('ICMS')) ), 
                                                                        IPI__c                   = Util.getDecimal( Util.getString( mapItens.get('IPI')) ), 
                                                                        ValorFrete__c           = Util.getDecimal( Util.getString( mapItens.get('VALORUNITARIOFRETE')) ), 
                                                                        PrecoUnitarioSImposto__c = Util.getDecimal( Util.getString( mapItens.get('VALORUNITARIOSEMIMP')) ),
                                                                        UnitPrice                = Util.getDecimal( Util.getString( mapItens.get('VALORUNITARIOSEMIMP')) )
                                                                    ));
                            
                        }

                        estoqueForInsert.add( new Estoque__c(       Oportunidade__c          = recordId,
                                                                    Produto__c               = OpportunityDAO.getInstance().getProduto( Util.getString( mapItens.get('PRODUTO')) ), 
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

                List<Estoque__c> lstEstoque = new List<Estoque__c>( [   SELECT  Id
                                                                        FROM    Estoque__c
                                                                        WHERE   Oportunidade__c = :recordId ]);

                if (lstEstoque != null && lstEstoque.size() > 0) delete lstEstoque;
                if ( estoqueForInsert   != null ) insert estoqueForInsert;
                if ( itemLinhaForUpdate != null ) update itemLinhaForUpdate;

                Opportunity op = OpportunityDAO.getInstance().getOpportunityIntegration(recordId);
                op.StatusIntegracao__c = 'Sucesso';
                op.BloqueioFinanceiro__c = bloqueio;
                op.BloqueioFrete__c = bloqueioFrete;
                op.TiraAprovacoes__c = true;
                op.DescontoAceito__c = null;

                List<Account> accountsToUpdate = new List<Account>();

                Account account = AccountDAO.getInstance().accountById(op.Account.Id);
                account.ObservacoesLogistica__c = obsLogisticaV;
                accountsToUpdate.add(account);

                Account receptorAccount;
                if(op.ContaReceptor__r != null) receptorAccount = AccountDAO.getInstance().accountById(op.ContaReceptor__r.Id);

                if(!op.RecordTypeId.Equals(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Oportunidade').getRecordTypeId())){
                    if (obsLogisticaR != null && obsLogisticaR != '' && obsLogisticaR != 'undefined'){
                        receptorAccount.ObservacoesLogistica__c = obsLogisticaR;
                        accountsToUpdate.add(receptorAccount);
                    }
                }

                update accountsToUpdate;
                update op;



                update new Account( Id = OpportunityDAO.getInstance().getAccountId(recordId),
                                    mensagemTOTVS__c = mensagemTotvs + ' Limite de crédito: ' + limiteCredito,
                                    LimiteCredito__c = limiteCredito,
                                    LimiteCredSifra__c = limiteCreditoSifra,
                                    LimiteCredBv__c = limiteCreditoSifra
                                );            
                QueueBO.getInstance().updateQueue(queueId, res, '');
                return;                
            }

            update new Opportunity(Id = recordId, StatusIntegracao__c = 'Erro no TOTVS'); 
            throw new IntegrationException('Erro na integração, serviço TOTVS indisponível');

        } catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {
            System.debug(ex.getMessage() + ' / ' + ex.getStackTraceString());
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        }
    }
}