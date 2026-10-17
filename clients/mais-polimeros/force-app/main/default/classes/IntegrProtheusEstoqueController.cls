public with sharing class IntegrProtheusEstoqueController {

    @InvocableMethod
    public static void buscaEstoque() {

        //WSTotvs wst = new WSTotvs('estoqueFiliaisProcessor', '');
        //String responseBody = wst.Invoke();

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        IntegrationParams__c ip = IntegrationParams__c.getInstance();


         request.setEndpoint(ip.URI_API__c + '/ESTTOTAL');
         //request.setEndpoint('callout:Protheus'.replace('https:', 'http') + '/ESTTOTAL');
         request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode((Blob.valueOf(ip.Username__c + ':' + ip.Password__c))));
        // }

        request.setMethod('GET');
        request.setTimeout(60000);
        HttpResponse response = http.send(request);
        

        if (response.getStatusCode() == 200) {

            Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());

            // Atualiza os produtos em estoque
            List<EstoqueFilial__c> lstEstoque = new List<EstoqueFilial__c>();

            for(Product2 p : [  SELECT  Id
                                        , Name
                                FROM    Product2
                                WHERE   IsActive = true ]) {

                EstoqueFilial__c es = new EstoqueFilial__c(
                            Produto__c = (Id)p.get('Id'),
                            Name = (String)p.get('Name')
                );
                lstEstoque.add(es);
            }
            Database.UpsertResult[] results = Database.upsert(lstEstoque, EstoqueFilial__c.fields.Name, false);

            // Guarda Id do estoque de cada produto
            Map<String,Id> mapEstoqueFilial = new Map<String,Id>();
            for(Integer i = 0, size = results.size(); i < size; i++) {
                if(results[i].isSuccess()) mapEstoqueFilial.put(lstEstoque[i].Name, lstEstoque[i].Id);
            }

            // Zera saldo dos itens
            List<EstoqueFilialItem__c> lstItemEstoque = ([   SELECT  Id
                                                                    , SaldoComprado__c
                                                                    , SaldoEstoque__c
                                                            FROM    EstoqueFilialItem__c    ]);

            for (EstoqueFilialItem__c efi : lstItemEstoque) {
                efi.SaldoComprado__c = 0;
                efi.SaldoEstoque__c = 0;
            }
            update lstItemEstoque;

            // Atualiza Saldo em estoque
            List<EstoqueFilialItem__c> upsItemEstoque = new List<EstoqueFilialItem__c>();

            for (Object objEstoque : (List<Object>) responseMap.get('ESTOQUE')) {
                Map<String, Object> mapEstoque = ( Map<String, Object> ) objEstoque;

                for (Object objItens : (List<Object>) mapEstoque.get('ITENS')) {
                    Map<String,Object> mapItens = (Map<String,Object>) objItens;

                    String estoqueFilial = mapEstoqueFilial.get(Util.getString(mapItens.get('PRODUTO')));

                    if (estoqueFilial != null){
                        String nome = 'F' + Util.getString(mapItens.get('FILIAL')) + '_' + Util.getString(mapItens.get('PRODUTO'));
                        String filial = Util.getString(mapItens.get('FILIAL'));
                        Decimal SaldoComprado = Util.getDecimal((String)mapItens.get('QTDECOMPRAS'));
                        Decimal SaldoEstoque = Util.getDecimal((String)mapItens.get('QTDEDISPONIVEL'));

                        EstoqueFilialItem__c ies = new EstoqueFilialItem__c(
                            EstoqueFilial__c = estoqueFilial,
                            Name = nome,
                            UnidadeFilial__c = filial,
                            SaldoComprado__c = SaldoComprado,
                            SaldoEstoque__c = SaldoEstoque
                        );
                        upsItemEstoque.add(ies);
                    }
                }
            }

            Database.upsert(upsItemEstoque, EstoqueFilialItem__c.Name, false);
        }
    }
}