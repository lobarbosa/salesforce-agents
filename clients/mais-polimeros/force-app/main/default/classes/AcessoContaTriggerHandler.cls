public without sharing class AcessoContaTriggerHandler {

    public List<AcessoConta__c> oldList;
    public List<AcessoConta__c> newList;
    public Map<Id,AcessoConta__c> oldMap;
    public Map<Id,AcessoConta__c> newMap;

    public void handleInsert(){
        List<AccountShare> lstInsertAccShare = new List<AccountShare>();
        for(AcessoConta__c ac : newList){
            if(ac.Inativo__c == false){
                lstInsertAccShare.add(instanceAccountShare(ac.RepresentanteFormula__c, ac.Conta__c));
            }
        }

        System.debug('AcessoContaTriggerHandler - lstInsertAccShare: ' + lstInsertAccShare);
        if(!lstInsertAccShare.isEmpty()){
            Database.SaveResult[] result = Database.insert(lstInsertAccShare, false);
            System.debug('Save result: ' + result);
        }
    }

    public void handleUpdate(){

        System.debug('AcessoContaTriggerHandler - handleUpdate');

        Set<String> setIdRepresentante = new Set<String>();
        Set<String> setIdConta = new Set<String>();
        List<AccountShare> lstInsertAccShare = new List<AccountShare>(); 
        List<AccountShare> lstDelAccountShare;

        for(AcessoConta__c ac : newList){
            Boolean oldInativo = oldMap.get(ac.Id)?.Inativo__c;

            if(oldInativo == true && ac.Inativo__c == false){
                // Registro reativado
                lstInsertAccShare.add(instanceAccountShare(ac.RepresentanteFormula__c, ac.Conta__c));

            } else if(oldInativo == false && ac.Inativo__c == true){
                // Registro inativado
                setIdRepresentante.add(ac.RepresentanteFormula__c);
                setIdConta.add(ac.Conta__c);
            }
        }

        lstDelAccountShare = getDeleteList(setIdRepresentante, setIdConta);
        System.debug('lstDelAccountShare: ' + lstDelAccountShare);

        if(!lstDelAccountShare.isEmpty()){
            Database.DeleteResult[] result = Database.delete(lstDelAccountShare, false);
            System.debug('Delete result: ' + result);
        }

        System.debug('lstInsertAccShare: ' + lstInsertAccShare);
        if(!lstInsertAccShare.isEmpty()){
            Database.SaveResult[] result = Database.insert(lstInsertAccShare, false);
            System.debug('Save result: ' + result);
        }

    }

    public void handleDelete(){

        Set<String> setIdRepresentante = new Set<String>();
        Set<String> setIdConta = new Set<String>();

        for(AcessoConta__c ac : oldList){
            setIdRepresentante.add(ac.RepresentanteFormula__c);
            setIdConta.add(ac.Conta__c);
        }

        List<AccountShare> lstDelAccountShare = getDeleteList(setIdRepresentante, setIdConta);
        if(!lstDelAccountShare.isEmpty()){
            Database.DeleteResult[] result = Database.delete(lstDelAccountShare, false);
            System.debug('Delete result: ' + result);
        }
    }

    private static AccountShare instanceAccountShare(String IdRepresentante, String IdConta){
        AccountShare newAS = new AccountShare (
            UserOrGroupId = IdRepresentante,
            AccountId = IdConta,
            AccountAccessLevel = 'Read',
            CaseAccessLevel = 'None',
            OpportunityAccessLevel = 'None'
        );
        return newAS;
    }

    private static List<AccountShare> getDeleteList(Set<String> setIdRepresentante, Set<String> setIdConta){

        Map<String,List<Id>> mapRepresentanteConta = new Map<String,List<Id>>();
        for(AcessoConta__c ac : [   SELECT  Id, RepresentanteFormula__c, Conta__c
                                    FROM    AcessoConta__c
                                    WHERE   Inativo__c = false
                                    AND     Conta__c = :setIdConta
                                    AND     RepresentanteFormula__c = :setIdRepresentante]){

            List<Id> lstConta;
            if(mapRepresentanteConta.containsKey(ac.RepresentanteFormula__c)){
                lstConta = mapRepresentanteConta.get(ac.RepresentanteFormula__c);
            } else {
                lstConta = new List<Id>();
            }

            lstConta.add(ac.Conta__c);
            mapRepresentanteConta.put(ac.RepresentanteFormula__c, lstConta);
        }
        System.debug('mapRepresentanteConta: ' + mapRepresentanteConta);

        List<AccountShare> lstDelAccountShare = new List<AccountShare>();
        for(AccountShare accShare : [   SELECT  Id, AccountId, UserOrGroupId
                                        FROM    AccountShare
                                        WHERE   AccountId = :setIdConta
                                        AND     UserOrGroupId = :setIdRepresentante
                                        AND     RowCause = 'Manual' ]){

            if(!mapRepresentanteConta.containsKey(accShare.UserOrGroupId)){
                lstDelAccountShare.add(accShare);
            } else {
                List<Id> lstConta = mapRepresentanteConta.get(accShare.UserOrGroupId);
                if(!lstConta.contains(accShare.AccountId)){
                    lstDelAccountShare.add(accShare);
                }
            }
        }
        System.debug('lstDelAccountShare: ' + lstDelAccountShare);
        return lstDelAccountShare;
    }
}