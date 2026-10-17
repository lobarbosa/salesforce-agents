public without sharing class AcessoProdutoTriggerHandler {

    public List<AcessoProduto__c> oldList;
    public List<AcessoProduto__c> newList;
    public Map<Id,AcessoProduto__c> oldMap;
    public Map<Id,AcessoProduto__c> newMap;

    public void atualizarPricebook(){

        Set<String> setUserId = new Set<String>();
        Set<String> setDivisaoId = new Set<String>();
        for(AcessoProduto__c ap : newList){
            if(String.isNotBlank(ap.Representante__c)){
                setUserId.add(ap.Representante__c);
                setDivisaoId.add(ap.DivisaoNegocioId__c);
            }
        }

        Map<String,String> mapUserName = new Map<String,String>();
        for(User u : [  SELECT Id, Name FROM User WHERE Id = :setUserId]){
            mapUserName.put(u.Id, u.Name);
        }

        Map<String,DivisaoNegocio__c> mapDivisaoName = new Map<String,DivisaoNegocio__c>();
        for(DivisaoNegocio__c d : [  SELECT Id, Name, Familia__c FROM DivisaoNegocio__c WHERE Id = :setDivisaoId]){
            mapDivisaoName.put(d.Id, d);
        }

        List<AcessoProduto__c> updateAcessoProduto = new List<AcessoProduto__c>();
        for(AcessoProduto__c ap : newList){
            if(Trigger.isInsert || String.IsBlank(ap.PriceBookId__c) || ap.DivisaoNegocioId__c != oldMap.get(ap.Id)?.DivisaoNegocioId__c){

                String nomeUsuario = mapUserName.get(ap.Representante__c);
                DivisaoNegocio__c divisaoNegocio = mapDivisaoName.get(ap.DivisaoNegocioId__c);

                Pricebook2 newPB = new Pricebook2(
                    Name = nomeUsuario + ' | ' + divisaoNegocio.Name,
                    Description = nomeUsuario + ' | ' + divisaoNegocio.Name,
                    IsActive = true
                );

                if(String.isNotBlank(ap.PriceBookId__c)){
                    newPB.Id = ap.PriceBookId__c;
                }
                upsert newPB;
                String pricebookId = newPB.Id;

                List<String> lstFiltro = divisaoNegocio.Familia__c.split(';');
                System.debug('lstFiltro: ' + lstFiltro);

                Map<Id,PricebookEntry> mapPBE = new Map<Id,PricebookEntry>();
                for(PricebookEntry pbe : [  SELECT  Id, Product2Id
                                            FROM    PricebookEntry 
                                            WHERE   Pricebook2Id = :pricebookId ]){
                    mapPBE.put(pbe.Product2Id, pbe);
                }
                System.debug('mapPBE: ' + mapPBE);

                // Produtos a serem removidos
                List<PricebookEntry> lstDelPBE = new List<PricebookEntry>();
                lstDelPBE = [   SELECT  Id
                                FROM    PricebookEntry
                                WHERE   Pricebook2Id = :pricebookId
                                AND     Product2Id NOT IN (SELECT Id FROM Product2 WHERE IsActive = true AND Family = :lstFiltro)    ];

                if(!lstDelPBE.isEmpty()){
                    delete lstDelPBE;
                }

                // Produtos a serem incluídos
                List<PricebookEntry> lstStandardPBE = new List<PricebookEntry>();
                lstStandardPBE = [  SELECT  Id, Product2Id, UnitPrice
                                    FROM    PricebookEntry
                                    WHERE   Pricebook2.IsActive = true
                                    AND     Pricebook2.IsStandard = true
                                    AND     IsActive = true
                                    AND     Product2Id NOT IN :mapPBE.keyset()
                                    AND     Product2Id IN (SELECT Id FROM Product2 WHERE IsActive = true AND Family = :lstFiltro)];

                List<PricebookEntry> lstNewPBE = new List<PricebookEntry>();
                for(PricebookEntry pbe : lstStandardPBE){
                    PricebookEntry newPBE = new PricebookEntry(
                        Pricebook2Id = pricebookId,
                        Product2Id = pbe.Product2Id,
                        UnitPrice = pbe.UnitPrice,
                        IsActive = true
                    );
                    lstNewPBE.add(newPBE);
                }

                if(!lstNewPBE.isEmpty()){
                    insert lstNewPBE;
                }

                if(String.isBlank(ap.PriceBookId__c)){
                    AcessoProduto__c updateAP = new AcessoProduto__c (
                        Id = ap.Id,
                        PriceBookId__c = pricebookId
                    );
                    updateAcessoProduto.add(updateAP);
                }
            }
        }

        if(!updateAcessoProduto.isEmpty()){
            update updateAcessoProduto;
        }

    }

    public void inativarPricebook(){

        Set<String> setPricebookId = new Set<String>();
        for(AcessoProduto__c ap : oldList){
            if(String.isNotBlank(ap.PriceBookId__c)){
                setPricebookId.add(ap.PriceBookId__c);
            }
        }

        if(!setPricebookId.isEmpty()){
            List<Pricebook2> lstPB = new List<Pricebook2>();
            lstPB = [ SELECT Id, IsActive FROM Pricebook2 WHERE Id = :setPricebookId];

            for(Pricebook2 pb : lstPB){
                pb.IsActive = false;
            }
            update lstPB;
        }
    }

}