/**
 * @File Name          : AccountIntegrationBO.cls
 * @Description        : 
 * @Author             : Lucas Oliveira
 * @Group              : 
 * @Last Modified By   : Lucas Oliveira
 * @Last Modified On   : 04/09/2019 15:34:27
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
 * 1.0    08/07/2019 18:25:33   Lucas Oliveira     Initial Version
**/
public without sharing class AccountIntegrationBO implements IProcessingQueue { 
    public AccountIntegrationBO() {}
    public class IntegrationException extends Exception {}

    public static void executeQueue( String queueId , String recordId, String eventName, String payload ) {
       
       try{
            if( eventName.equals( QueueEventNames.ACCOUNT_SALESFORCE_TO_TOTVS.name() ) )
                sendToTotvs( queueId, eventName, payload, recordId );
        }catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
            update new Account( Id = recordId, Status_Integracao__c = 'ERRO NO TOTVS');
        }
        
    }

    public static String getJsonRequest( Account account ) {

        String ddd = Util.getString(account.DDD__c).replaceAll('[^0-9]+', '');
        if(ddd.trim().length() > 2){
            ddd = ddd.trim().left(2);
        }

        String fone = Util.getString(account.Phone).replaceAll('[^0-9]+', '');
        if(fone.length() > 4){
            fone = fone.left(4) + '-' + fone.substring(4);    
        }

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
            gen.writeFieldName('CLIENTES');
            gen.writeStartArray();
                    gen.writeStartObject();
                        gen.writeFieldName('CLIENTE');
                        gen.writeStartArray();
                            gen.writeStartObject();                                                                
                                gen.writeStringField( 'CNPJ',              Util.getString( account.beeCnpj__CNPJ__c ).replaceAll('[^0-9]+', '')); 
                                gen.writeStringField( 'ENDERECO',          Util.getString( account.BillingStreet  ));
                                gen.writeStringField( 'BAIRRO',            Util.getString( account.BairroCobranca__c ) );
                                gen.writeStringField( 'MUNICIPIO',         Util.getString( account.NomeCidadeFormula__c ) );                               
                                gen.writeStringField( 'UF',                Util.getString( account.MunicipioFormula__c ) );
                                gen.writeStringField( 'PAIS',              Util.getString( account.CodigoPaisFormula__c ) );
                                gen.writeStringField( 'CODIGOMUNICIPIO',   Util.getString( account.CodigoCidadeFormula__c ) );
                                gen.writeStringField( 'CEP',               Util.getString( account.BillingPostalCode ).replaceAll('[^0-9]+', ''));
                                gen.writeStringField( 'RAZAOSOCIAL',       Util.getString( account.Name ) );
                                gen.writeStringField( 'NREDUZ',            Util.getString( account.NomeFantasia__c ) );
                                // gen.writeStringField( 'DDD',               Util.getString( account.DDD__c ).replaceAll('[^0-9]+', ''));
                                gen.writeStringField( 'DDD',               ddd);
                                // gen.writeStringField( 'TELEFONE',          Util.getString( account.Phone ).replaceAll('[^0-9]+', ''));
                                gen.writeStringField( 'TELEFONE',          fone);
                                gen.writeStringField( 'CONTATO',           Util.getString( account.ContatoFormula__c ) );
                                //gen.writeStringField( 'EMAILNFE',          Util.getString( account.EmailNFE__c ) ); gravado no retorno, pois o e-mail nfe é cadastrado no totvs
                                gen.writeStringField( 'INSCRICAOESTADUAL', Util.getString( account.InscricaoEstadual__c ) );
                                gen.writeStringField( 'VENDEDOR',          Util.getString( account.OwnerFormula__c ) );
                                gen.writeStringField( 'ENDERECOENTREGA',   Util.getString( account.ShippingStreet ) );
                                gen.writeStringField( 'BAIRROENTREGA',     Util.getString( account.BairroEntrega__c ) );
                                gen.writeStringField( 'MUNICIPIOENTREGA',  Util.getString( account.NomeCidade__c ) );
                                gen.writeStringField( 'CEPENTREGA',        Util.getString( account.ShippingPostalCode ).replaceAll('[^0-9]+', ''));
                                gen.writeStringField( 'UFENTREGA',         Util.getString( account.MunicipioEntregaFormula__c ) );
                                gen.writeStringField( 'CODMUNENTREGA',     Util.getString( account.CodigoEntregaFormula__c ) );                               
                                gen.writeStringField( 'SEGMENTO',          Util.getString( account.SegmentacaoFormula__c   ) );
                                gen.writeStringField( 'TIPO',              Util.getString( account.Type ).left(1) );
                                gen.writeStringField( 'OBSERVACOES',       Util.getString( account.observacoes__c ) );                                
                                gen.writeStringField( 'CONDPAG',           Util.getString( account.CondicaoPagamentoPadrao__c ) );                                
                                gen.writeStringField( 'TEMEMPILHADEIRA',   Util.getString( account.temempilhadeira__c ) );
                                //gen.writeStringField( 'DIADASEMANA',       Util.getString( account.diadasemana__c ) );
                                //gen.writeStringField( 'HORAINICIAL',       Util.getString( account.horarioinicial__c ) );
                                //gen.writeStringField( 'HORAFINAL',         Util.getString( account.horariofinal__c ) );
                                gen.writeStringField( 'FRETE',             Util.getString( account.Frete__c == 'CCIF' ? 'C' : '' ) );                      
                                gen.writeStringField( 'GrupoEconomico__c', Util.getString(account.GrupoEconomico__c));
                                gen.writeStringField( 'Faixa__c',             Util.getString( account.Faixa__c == 'Sim' ? '1' : '' ) );
                            gen.writeEndObject();
                        gen.writeEndArray();
                    gen.writeEndObject();
            gen.writeEndArray();
        gen.writeEndObject(); 
        // MunicipioEntrega__r.UF__c, MunicipioEntrega__r.UF__c, ContatoPrincipal__r.Name
        //return (gen.getAsString()); 
        System.debug('AccentsBO.removeDiacritics( gen.getAsString() )');
        System.debug(AccentsBO.removeDiacritics( gen.getAsString() ));
        return (AccentsBO.removeDiacritics( gen.getAsString() ));
    }

    @future(callout=true)
    public static void sendToTotvs(String queueId, String eventName, String payload, String recordId){
        
        try {
            ProcessControl.ignoredByTrigger = true;
            
            // WSTotvs service                         =  new WSTotvs();

            WSTotvs wst = new WSTotvs('accountProcessor', payload);
            String res = wst.Invoke();

            List<Account>    accountForUpdate       =  new List<Account>();


            if (!res.equals('500')){                
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped( res );
 
                for (Object objCliente : (List<Object>) responseMap.get('CLIENTES') ) {
                    Map<String, Object> mapCliente = ( Map<String, Object> ) objCliente;

                    for (Object objItens : (List<Object>) mapCliente.get('CLIENTE')) {
                        Map<String, Object> mapItens = ( Map<String, Object> ) objItens;

                        // obsLogistica = Util.getString( mapItens.get('OBSLOGISTICA'));

                        accountForUpdate.add( new Account(          Id                         = recordId,
                                                                    Codigo__c                  = Util.getString( mapItens.get('CODIGO')),
                                                                    EmailNFE__c                = Util.getString( mapItens.get('EMAILNFE')),
                                                                    //CondicaoPagamentoPadrao__c = Util.getString( mapItens.get('CONDICAOPAGTO')), // 27/08/2019 - Nilson solicitou retirar o campo
                                                                    Status_Integracao__c       = Util.getString( mapItens.get('MENSAGEM')).left(200)        // 27/08/2019 - Nilson solicitou retirar o campo                                                                 
                                                                    //ObservacoesLogistica__c    = obsLogistica                                                               
                                                                ));
                    }
                }
                
                QueueBO.getInstance().updateQueue( queueId, res, '');                
                ProcessControl.ignoredByTrigger = true;
                update accountForUpdate;
                return;                
            }

            ProcessControl.ignoredByTrigger = true;
            update new Account( Id = recordId, Status_Integracao__c = 'ERRO NO TOTVS -> ' + res );
            
            throw new IntegrationException('Erro na integração');
        
        }catch( DmlException ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
        } catch( Exception ex ) {
            QueueBO.getInstance().updateQueue( queueId, eventName + ' / ' + ex.getMessage() + ' / ' + ex.getStackTraceString() );
            update new Account( Id = recordId, Status_Integracao__c = 'ERRO NO TOTVS');
        }  
    }

    @InvocableMethod
    public static void buscaEstoque(List<String> recordId) {

        Account acc = [SELECT Id, Codigo__c FROM Account WHERE Id = :recordId];

        List<AggregateResult> lstAggregate = new List<AggregateResult>();
        lstAggregate = [    SELECT  Order.AccountId conta
                                    , Order.FormaPagamento__c formaPagto
                                    , SUM(ValorTotalComICMSeIPI__c) valorTotal
                            FROM    OrderItem
                            WHERE   Order.AccountId = :recordId
                            AND     Status__c IN('Nao faturado', 'Bloqueado')
                            GROUP BY Order.AccountId, Order.FormaPagamento__c];

        Map<String,Decimal> mapPedidoAberto = new Map<String,Decimal>();
        for(AggregateResult aggOrd : lstAggregate){
            String formaPagamento = (String)aggOrd.get('formaPagto');
            Decimal total = (Decimal)(aggOrd.get('valorTotal'));
            mapPedidoAberto.put(formaPagamento, total);
        }
        System.debug('mapPedidoAberto: ' + mapPedidoAberto);

        List<AggregateResult> lstAggregateMais = new List<AggregateResult>();
        lstAggregateMais = [    SELECT  SUM(ValorTotalComICMSeIPI__c) valorTotal
                                FROM    OrderItem
                                WHERE   Order.AccountId = :recordId
                                AND     Status__c IN('Nao faturado', 'Bloqueado')
                                AND     Order.FormaPagamento__c IN ('DE- Depósito', 'DP - Duplicata')
                                AND     Order.CondicaoPagamento__r.Name NOT IN('000')
                                GROUP BY Order.AccountId];

        Decimal totalPedidoMais = 0;
        for(AggregateResult aggOrd : lstAggregateMais){
            totalPedidoMais += (Decimal)aggOrd.get('valorTotal');
        }
        System.debug('totalPedidoMais: ' + totalPedidoMais);


        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
            gen.writeStringField('cdCliente', acc.Codigo__c);
        gen.writeEndObject();
        system.debug('payload: ' + gen.getAsString());

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HTTPResponse response = new HTTPResponse();

        IntegrationParams__c ip = IntegrationParams__c.getInstance();
        request.setEndpoint(ip.URI_API__c + '/USDBAPICLI');
        request.setMethod('POST');
        request.setTimeout(30000);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(gen.getAsString());
        request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode((Blob.valueOf(ip.Username__c + ':' + ip.Password__c))));

        system.debug('request: ' + request);

        response = http.send(request);
        system.debug('response: ' + response);

        if (response.getStatusCode() != 201 && response.getStatusCode() != 200) {
            system.debug('Erro no response');
        } else {
            system.debug('Response Body: ' + response.getBody());
            Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
            system.debug('responseMap: ' + responseMap);
            system.debug(responseMap.get('cliente'));

            for (Object cliente : (List<Object>) responseMap.get('cliente')) {
                Map<String, Object> mapItens = ( Map<String, Object> ) cliente;

                // Dados do cliente
                Acc.CadastroAprovado__c = Util.getBoolean(Util.getString(mapItens.get('statusCliente')));
                Acc.DataHoraUltimaAtualizacao__c = System.now();

                // Limite de Crédito
                Date vencimento = Util.getString(mapItens.get('proxVencmento')).replace('/', '').trim() == '' ?  null : Util.getDate(Util.getString(mapItens.get('proxVencmento')));
                Acc.DataProximoVencimento__c = vencimento;
                Acc.LimiteCred__c = Util.getDecimal(Util.getString(mapItens.get('credDisp')));
                Acc.TotalAtrasados__c = Util.getDecimal(Util.getString(mapItens.get('totalAtrasado')));
                Acc.TotalAbertos__c = Util.getDecimal(Util.getString(mapItens.get('totalAberto')));
                Acc.CreditoTotal__c = Util.getDecimal(Util.getString(mapItens.get('limitTotal')));
                Acc.ValorPedidoAbertoMais__c = totalPedidoMais;
                
                // Limite de Crédito - SIFRA
                Date vencimentoSifra = Util.getString(mapItens.get('proxVencmento_SF')).replace('/', '').trim() == '' ?  null : Util.getDate(Util.getString(mapItens.get('proxVencmento_SF')));
                Acc.DataProximoVencimentoSifra__c = vencimentoSifra;
                Acc.LimiteTotalSifra__c = Util.getDecimal(Util.getString(mapItens.get('limitTotal_SF')));
                Acc.LimiteCredSifra__c = Util.getDecimal(Util.getString(mapItens.get('credDisp_SF')));
                Acc.TotalAtrasadosSifra__c = Util.getDecimal(Util.getString(mapItens.get('totalAtrasado_SF')));
                Acc.TotalAbertosSifra__c = Util.getDecimal(Util.getString(mapItens.get('totalAberto_SF')));
                Acc.ValorPedidoAbertoSifra__c = mapPedidoAberto.containsKey('SI - SIFRA') ? mapPedidoAberto.get('SI - SIFRA') : 0;

                // Limite de Crédito - BV
                Date vencimentoBV = Util.getString(mapItens.get('proxVencmento_BV')).replace('/', '').trim() == '' ?  null : Util.getDate(Util.getString(mapItens.get('proxVencmento_BV')));
                Acc.DataProximoVencimentoBv__c = vencimentoBV;
                Acc.LimiteTotalBv__c = Util.getDecimal(Util.getString(mapItens.get('limitTotal_BV')));
                Acc.LimiteCredBv__c = Util.getDecimal(Util.getString(mapItens.get('credDisp_BV')));
                Acc.TotalAtrasadosBv__c = Util.getDecimal(Util.getString(mapItens.get('totalAtrasado_BV')));
                Acc.TotalAbertosBv__c = Util.getDecimal(Util.getString(mapItens.get('totalAberto_BV')));
                Acc.ValorPedidoAbertoBV__c = mapPedidoAberto.containsKey('MP - MPAY') ? mapPedidoAberto.get('MP - MPAY') : 0;
            }

            update acc;
        }
    }
}