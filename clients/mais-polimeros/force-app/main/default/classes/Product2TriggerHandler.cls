public without sharing class Product2TriggerHandler {

    public List<Product2> oldList;
    public List<Product2> newList;
    public Map<Id,Product2> oldMap;
    public Map<Id,Product2> newMap;

    public void atualizaPriceBooks(){

        List<PricebookEntry> lstNewPBE = new List<PricebookEntry>();
        List<PricebookEntry> lstDelPBE = new List<PricebookEntry>();

        for(Product2 prd : newList){

            for(AcessoProduto__c ap : [ SELECT  PriceBookId__c
                                        FROM    AcessoProduto__c
                                        WHERE   DivisaoNegocioId__c IN (SELECT Id FROM DivisaoNegocio__c WHERE Familia__c INCLUDES (:prd.Family))   ]){

                PricebookEntry newPBE = new PricebookEntry(
                    Pricebook2Id = ap.PriceBookId__c,
                    Product2Id = prd.Id,
                    UnitPrice = 0,
                    IsActive = true
                );
                lstNewPBE.add(newPBE);
            }

            if(oldMap != null){
                Product2 oldPrd = oldMap.get(prd.Id);
                System.debug('oldPrd.Family: ' + oldPrd.Family);
                System.debug('prd.Family: ' + prd.Family);

                if(prd.Family != oldPrd.Family){
                    System.debug('Entrou');
                    System.debug('prd.Id: ' + prd.Id);
                    System.debug('oldPrd.Family: ' + oldPrd.Family);

                    Set<String> setPB = new Set<String>();
                    for(AcessoProduto__c ap : [ SELECT  PriceBookId__c
                                                FROM    AcessoProduto__c
                                                WHERE   DivisaoNegocioId__c IN (SELECT Id FROM DivisaoNegocio__c WHERE Familia__c INCLUDES (:oldPrd.Family))   ]){

                        setPB.add(ap.PriceBookId__c);
                    }

                    lstDelPBE = [   SELECT  Id
                                    FROM    PricebookEntry
                                    WHERE   Pricebook2.IsStandard = false
                                    AND     Pricebook2.Id IN :setPB
                                    AND     Product2Id = :prd.Id    ];
                }
            }

        }

        System.debug('lstNewPBE: ' + lstNewPBE);
        System.debug('lstNewPBE: ' + lstNewPBE.size());

        if(!lstNewPBE.isEmpty()){
            Database.SaveResult[] lstResult = Database.insert(lstNewPBE, false);
            for(Integer index = 0, size = lstResult.size(); index < size; index++) {
                if(!lstResult[index].isSuccess()){
                    System.debug('Erro no registro: ' + lstNewPBE[index].Pricebook2Id + ' | ' + lstNewPBE[index].Product2Id);
                    for(Database.Error err : lstResult[index].getErrors()){
                        System.debug('Detalhe: ' + err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }

        System.debug('lstDelPBE: ' + lstDelPBE);
        System.debug('lstDelPBE: ' + lstDelPBE.size());

        if(!lstDelPBE.isEmpty()){
            Database.DeleteResult[] lstResult = Database.delete(lstDelPBE, false);
            for(Integer index = 0, size = lstResult.size(); index < size; index++) {
                if(!lstResult[index].isSuccess()){
                    System.debug('Erro no registro: ' + lstDelPBE[index].Id);
                    for(Database.Error err : lstResult[index].getErrors()){
                        System.debug('Detalhe: ' + err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }

    }

}