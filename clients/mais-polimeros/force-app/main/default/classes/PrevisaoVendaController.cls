public with sharing class PrevisaoVendaController {

    @AuraEnabled
    public static List<ComboBoxWrapper> getMesesPrevisao(){

        List<ComboBoxWrapper> result = new List<ComboBoxWrapper>();
        for(PrevisaoVenda__c prev : [   SELECT  Id
                                                , Name
                                                , Aberto__c
                                                , tolabel(Mes__c)
                                                , Ano__c
                                                , InicioPrenchimento__c
                                                , FimPreenchimento__c
                                        FROM    PrevisaoVenda__c
                                        ORDER   BY Ano__c DESC, Mes__c DESC
                                        LIMIT 24    ]){

            ComboBoxWrapper newItem = new ComboBoxWrapper();
            newItem.value = prev.Id;
            newItem.label = prev.Mes__c + '/' + prev.Ano__c;
            newItem.description = (prev.Aberto__c ? '' : '(Fechado)');
            result.add(newItem);
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<ComboBoxWrapper> getLogins(String idPrevisao){
        
        List<ComboBoxWrapper> result = new List<ComboBoxWrapper>();

        ComboBoxWrapper usuarioLogado = new ComboBoxWrapper();
        usuarioLogado.value = UserInfo.getUserId();
        usuarioLogado.label = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        usuarioLogado.description = UserInfo.getUserEmail();
        result.add(usuarioLogado);
        
        if(Schema.sObjectType.PrevisaoVenda__c.isCreateable()){
            for(User user : [   SELECT  Id
                                , Name
                                , Email
                        FROM    User
                        WHERE   Id IN ( SELECT  OwnerId
                                        FROM    ItemPrevisaoVenda__c
                                        WHERE   PrevisaoVenda__c = :idPrevisao  )   ]){

                if(user.Id != UserInfo.getUserId()){
                    ComboBoxWrapper newItem = new ComboBoxWrapper();
                    newItem.value = user.Id;
                    newItem.label = user.Name;
                    newItem.description = user.Email;
                    result.add(newItem);
                }
            }
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<PrevisaoWrapper> getPrevisao(String idPrevisao, String idUsuario, Boolean todos){

        System.debug('getPrevisao idPrevisao: ' + idPrevisao);
        System.debug('getPrevisao idUsuario: ' + idUsuario);
        System.debug('getPrevisao todos: ' + todos);

        Boolean aberto = [SELECT Aberto__c FROM PrevisaoVenda__c WHERE Id = :idPrevisao]?.Aberto__c;

        List<Product2> lstProduto = new List<Product2>();
        if(todos){
            lstProduto = [  SELECT   Id
                                    , Name
                                    , Description
                                    , DescritivoFamilia__c
                                    , Fabricante__c
                            FROM    Product2
                            WHERE   IsActive = true
                            ORDER   BY Name ];
        } else {
            lstProduto = [  SELECT   Id
                                        , Name
                                        , Description
                                        , DescritivoFamilia__c
                                        , Fabricante__c
                                FROM    Product2
                                WHERE   Id IN ( SELECT  Product2Id
                                                FROM    OpportunityLineItem
                                                WHERE   Opportunity.OwnerId = :idUsuario
                                                AND     Product2.IsActive = true    )
                                                ORDER   BY Name     ];
        }


        List<AggregateResult> lstAgg = new List<AggregateResult>();
        lstAgg = [  SELECT  Product2Id prd, Order.UnidadeFilial__r.Codigo__c filial, sum(Quantity) qtd
                    FROM    OrderItem
                    WHERE   Order.EffectiveDate = LAST_N_MONTHS:12
                    AND     Order.Vendedor__c = :idUsuario
                    GROUP   BY Product2Id, Order.UnidadeFilial__r.Codigo__c ];

        Map<String,Decimal> mapMedia = new Map<String,Decimal>();
        for(AggregateResult agg : lstAgg){
            String produto = (String)agg.get('prd');
            String filial = (String)agg.get('filial');
            Decimal media = ((Decimal)agg.get('qtd') / 12).setScale(0);
            String key = produto + '_' + filial;
            mapMedia.put(key, media);
        }
        System.debug('mapMedia: ' + mapMedia);


        Map<String,PrevisaoWrapper> mapProduto = new Map<String,PrevisaoWrapper>();
        for(Product2 product : lstProduto ){
            PrevisaoWrapper newItem = new PrevisaoWrapper();
            newItem.itemId = product.Id;
            newItem.ownerId = idUsuario;
            newItem.produtoId = product.Id;
            newItem.produtoCodigo = product.Name;
            newItem.produtoDescricao = product.Description;
            newItem.produtoFamilia = product.DescritivoFamilia__c;
            newItem.produtoFabricante = product.Fabricante__c;
            newItem.controlEditField = aberto;
            newItem.mediaGO = null;
            newItem.quantidadeGO = null;
            newItem.mediaPR = null;
            newItem.quantidadePR = null;
            newItem.mediaSC = null;
            newItem.quantidadeSC = null;
            newItem.mediaSP = null;
            newItem.quantidadeSP = null;
            newItem.mediaRS = null;
            newItem.quantidadeRS = null;
            newItem.mediaRS08 = null;
            newItem.quantidadeRS08 = null;

            if(mapMedia.containsKey(product.Id + '_04')){
                newItem.mediaGO = mapMedia.get(product.Id + '_04');
            }

            if(mapMedia.containsKey(product.Id + '_02')){
                newItem.mediaPR = mapMedia.get(product.Id + '_02');
            }

            if(mapMedia.containsKey(product.Id + '_08')){
                newItem.mediaRS08 = mapMedia.get(product.Id + '_08');
            }

            if(mapMedia.containsKey(product.Id + '_06')){
                newItem.mediaRS = mapMedia.get(product.Id + '_06');
            }

            if(mapMedia.containsKey(product.Id + '_07')){
                newItem.mediaSC = mapMedia.get(product.Id + '_07');
            }

            System.debug('product.Id: ' + product.Id);

            if(mapMedia.containsKey(product.Id + '_01')){
                newItem.mediaSP = mapMedia.get(product.Id + '_01');
            }

            mapProduto.put(product.Id, newItem);
        }


        for(ItemPrevisaoVenda__c itemPrevisao : [   SELECT  Id
                                                            , Name
                                                            , Produto__c
                                                            , Produto__r.Name
                                                            , Produto__r.Description
                                                            , Produto__r.DescritivoFamilia__c
                                                            , Produto__r.Fabricante__c
                                                            , Qtd_Cajamar__c
                                                            , QuantidadeGO__c
                                                            , QuantidadePR__c
                                                            , QuantidadeSC__c
                                                            , QuantidadeSP__c
                                                            , QuantidadeRS__c
                                                            , QuantidadeRS08__c
                                                    FROM    ItemPrevisaoVenda__c   
                                                    WHERE   PrevisaoVenda__c  = :idPrevisao
                                                    AND     OwnerId = :idUsuario   ]){

            String idProduto = itemPrevisao.Produto__c;

            PrevisaoWrapper item;
            if(mapProduto.containsKey(idProduto)){
                item = mapProduto.get(idProduto);
                item.itemId = itemPrevisao.Id;
            } else {
                item = new PrevisaoWrapper();
                item.itemId = itemPrevisao.Id;
                item.ownerId = idUsuario;
                item.produtoId = idProduto;
                item.produtoCodigo = itemPrevisao.Produto__r.Name;
                item.produtoDescricao = itemPrevisao.Produto__r.Description;
                item.produtoFamilia = itemPrevisao.Produto__r.DescritivoFamilia__c;
                item.produtoFabricante = itemPrevisao.Produto__r.Fabricante__c;
                item.controlEditField = aberto;   
            }

            item.quantidadeGO = itemPrevisao.QuantidadeGO__c;
            item.quantidadePR = itemPrevisao.QuantidadePR__c;
            item.quantidadeSC = itemPrevisao.QuantidadeSC__c;
            item.quantidadeSP = itemPrevisao.QuantidadeSP__c;
            item.quantidadeRS = itemPrevisao.QuantidadeRS__c;
            item.quantidadeRS08 = itemPrevisao.QuantidadeRS08__c;

            mapProduto.put(idProduto, item);
        }

        return mapProduto.values();
    }

    @AuraEnabled
    public static void saveProdutos(String idPrevisao, String idUsuario, List<Object> lstRecords){
        System.debug('lstRecords: ' + lstRecords);

        if(lstRecords.isEmpty()){
            throw new AuraHandledException('Não foram encontradas atualizações em previsões');
        } else {
            List<ItemPrevisaoVenda__c> lstUpsertPrevisao = new List<ItemPrevisaoVenda__c>();

            for(Object record : lstRecords){
                Map<Object,Object> registro = (Map<Object,Object>)record;
                Map<Object,Object> campos = (Map<Object,Object>)registro.get('fields');

                String recordId = String.valueOf(campos.get('itemId'));

                Double quantidadeGO = null;
                Double quantidadePR = null;
                Double quantidadeSC = null;
                Double quantidadeSP = null;
                Double quantidadeRS = null;
                Double quantidadeRS08 = null;

                if(String.isNotBlank((String)campos.get('quantidadeGO'))){
                    quantidadeGO = Double.valueOf(campos.get('quantidadeGO'));
                }
                if(String.isNotBlank((String)campos.get('quantidadePR'))){
                    quantidadePR = Double.valueOf(campos.get('quantidadePR'));
                }
                if(String.isNotBlank((String)campos.get('quantidadeSC'))){
                    quantidadeSC = Double.valueOf(campos.get('quantidadeSC'));
                }
                if(String.isNotBlank((String)campos.get('quantidadeSP'))){
                    quantidadeSP = Double.valueOf(campos.get('quantidadeSP'));
                }
                if(String.isNotBlank((String)campos.get('quantidadeRS'))){
                    quantidadeRS = Double.valueOf(campos.get('quantidadeRS'));
                }
                if(String.isNotBlank((String)campos.get('quantidadeRS08'))){
                    quantidadeRS08 = Double.valueOf(campos.get('quantidadeRS08'));
                }

                ItemPrevisaoVenda__c newPrevisao = new ItemPrevisaoVenda__c (
                    PrevisaoVenda__c = idPrevisao,
                    QuantidadeGO__c = quantidadeGO,
                    QuantidadePR__c = quantidadePR,
                    QuantidadeSC__c = quantidadeSC,
                    QuantidadeSP__c = quantidadeSP,
                    QuantidadeRS__c = quantidadeRS,
                    QuantidadeRS08__c = quantidadeRS08
                );
    
                if(recordId.left(3) != Product2.getSObjectType().getDescribe().getKeyPrefix()){
                    newPrevisao.Id = recordId;
                } else {
                    newPrevisao.Id = null;
                    newPrevisao.Produto__c = recordId;
                    newPrevisao.OwnerId = idUsuario;
                }

                lstUpsertPrevisao.add(newPrevisao);
            }
            upsert lstUpsertPrevisao;
        }
    }

    public class ComboBoxWrapper {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public String description;
    }

    public class PrevisaoWrapper {
        @AuraEnabled public String itemId;
        @AuraEnabled public String ownerId;
        @AuraEnabled public String produtoId;
        @AuraEnabled public String produtoCodigo;
        @AuraEnabled public String produtoDescricao;
        @AuraEnabled public String produtoFamilia;
        @AuraEnabled public String produtoFabricante;
        @AuraEnabled public Decimal mediaGO;
        @AuraEnabled public Decimal quantidadeGO;
        @AuraEnabled public Decimal mediaPR;
        @AuraEnabled public Decimal quantidadePR;
        @AuraEnabled public Decimal mediaSC;
        @AuraEnabled public Decimal quantidadeSC;
        @AuraEnabled public Decimal mediaSP;
        @AuraEnabled public Decimal quantidadeSP;
        @AuraEnabled public Decimal mediaRS;
        @AuraEnabled public Decimal quantidadeRS;
        @AuraEnabled public Decimal mediaRS08;
        @AuraEnabled public Decimal quantidadeRS08;
        @AuraEnabled public Boolean controlEditField;
    }

}