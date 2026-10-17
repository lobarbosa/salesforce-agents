public without sharing class DivisaoNegocioTriggerHandler {

    public List<DivisaoNegocio__c> oldList;
    public List<DivisaoNegocio__c> newList;
    public Map<Id,DivisaoNegocio__c> oldMap;
    public Map<Id,DivisaoNegocio__c> newMap;

    public void consisteFamilia(){
        List<DivisaoNegocio__c> lstDivisao = new List<DivisaoNegocio__c>();
        lstDivisao = [SELECT Id, Name, Familia__c FROM DivisaoNegocio__c];

        if(!lstDivisao.isEmpty()){
            for(DivisaoNegocio__c newDivisao : newList){
                List<String> lstFamiliaNew = newDivisao.Familia__c.split(';');

                for(DivisaoNegocio__c divisao : lstDivisao){
                    if(newDivisao.Id != divisao.Id){
                        for(String dv : divisao.Familia__c.split(';')){
                            if(lstFamiliaNew.contains(dv)){
                                newDivisao.addError('Família ' + dv + ' já inserida na divisão ' + divisao.Name);
                                break;
                            }
                        }
                    }
                }
            }
        }
    }


    public void atualizaPriceBooks(){

        for(DivisaoNegocio__c newDivisao : newList){

            DivisaoNegocio__c oldDivisao = oldMap.get(newDivisao.Id);
            Set<String> setFamiliaOld = new Set<String>(oldDivisao.Familia__c.split(';'));
            Set<String> setFamiliaNew = new Set<String>(newDivisao.Familia__c.split(';'));

            System.debug('Divisão: ' + newDivisao);
            Set<String> setPricebookId = new Set<String>();
            for(AcessoProduto__c ap : [ SELECT  PriceBookId__c
                                        FROM    AcessoProduto__c
                                        WHERE   DivisaoNegocioId__c = :newDivisao.Id    ]){
                setPricebookId.add(ap.PriceBookId__c);
            }
            System.debug('setPricebookId: ' + setPricebookId);

            // Itens removidos
            Set<String> itensRemovidos = new Set<String>();
            itensRemovidos.addAll(setFamiliaOld);
            itensRemovidos.removeAll(setFamiliaNew);

            if(!itensRemovidos.isEmpty()){
                System.debug('Itens removidos: ' + itensRemovidos);

                List<PricebookEntry> lstDeletePBE = new List<PricebookEntry>();

                for(PricebookEntry pbe : [  SELECT  Id, IsActive
                                            FROM    PricebookEntry
                                            WHERE   Pricebook2Id = :setPricebookId
                                            AND     Product2.Family = :itensRemovidos   ]){

                    if(pbe.IsActive){
                        pbe.IsActive = false;
                        lstDeletePBE.add(pbe);
                    }
                }

                System.debug('lstDeletePBE: ' + lstDeletePBE);
                System.debug('lstDeletePBE: ' + lstDeletePBE.size());
                update lstDeletePBE;
            }

            // Itens adicionados
            Set<String> itensAdicionados = new Set<String>();
            itensAdicionados.addAll(setFamiliaNew);
            itensAdicionados.removeAll(setFamiliaOld);

            if(!itensAdicionados.isEmpty()){
                System.debug('Itens adicionados: ' + itensAdicionados);

                // Produtos a serem incluídos
                List<PricebookEntry> lstStandardPBE = new List<PricebookEntry>();
                lstStandardPBE = [  SELECT  Id, Product2Id, UnitPrice
                                    FROM    PricebookEntry
                                    WHERE   Pricebook2.IsActive = true
                                    AND     Pricebook2.IsStandard = true
                                    AND     IsActive = true
                                    AND     Product2Id IN (SELECT Id FROM Product2 WHERE IsActive = true AND Family = :itensAdicionados)];
                System.debug('lstStandardPBE: ' + lstStandardPBE);
                System.debug('lstStandardPBE: ' + lstStandardPBE.size());

                List<PricebookEntry> lstNewPBE = new List<PricebookEntry>();
                for(PricebookEntry pbe : lstStandardPBE){
                    for(String pricebookId : setPricebookId){
                        PricebookEntry newPBE = new PricebookEntry(
                            Pricebook2Id = pricebookId,
                            Product2Id = pbe.Product2Id,
                            UnitPrice = pbe.UnitPrice,
                            IsActive = true
                        );
                        lstNewPBE.add(newPBE);
                    }
                }

                System.debug('lstNewPBE: ' + lstNewPBE);
                System.debug('lstNewPBE: ' + lstNewPBE.size());

                if(!lstNewPBE.isEmpty()){
                    // insert lstNewPBE;

                    Database.UpsertResult[] lstResult = Database.upsert(lstNewPBE, false);
                    for(Integer index = 0, size = lstResult.size(); index < size; index++) {
                        if(!lstResult[index].isSuccess()){
                            System.debug('Erro no registro: ' + lstNewPBE[index].Pricebook2Id + ' | ' + lstNewPBE[index].Product2Id);
                            for(Database.Error err : lstResult[index].getErrors()){
                                System.debug('Detalhe: ' + err.getStatusCode() + ': ' + err.getMessage());
                            }
                        }
                    }
                }



                // Produtos a serem atualizados
                List<PricebookEntry> lstUpdatePBE = new List<PricebookEntry>();
                lstUpdatePBE = [  SELECT  Id, IsActive
                                    FROM    PricebookEntry
                                    WHERE   IsActive = false
                                    AND     Pricebook2Id = :setPricebookId
                                    AND     Product2.Family = :itensAdicionados   ];
                System.debug('lstUpdatePBE: ' + lstUpdatePBE);
                System.debug('lstUpdatePBE: ' + lstUpdatePBE.size());

                for(PricebookEntry pbe : lstUpdatePBE){
                    pbe.IsActive = true;
                }
                update lstUpdatePBE;
            }

        }
    }

}