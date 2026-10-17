public with sharing class AccountTriggerHelper {
    public void validateCNPJ(Account[] records, Account[] oldRecords){
        Boolean hasOldRecords = (oldRecords != null && !oldRecords.isEmpty());

        for(Integer index = 0; index < records.size(); index++)
            if(!hasOldRecords || records[index].CompanyDocument__c != oldRecords[index].CompanyDocument__c)
                if(!AccountUtility.validateCNPJ(records[index].CompanyDocument__c))
                	records[index].CompanyDocument__c.addError('CNPJ incompleto ou inválido');
    }

    public void getAccountInfoFromCNPJ(Map<Id, Account> newRecordMap){
        Map<Id, Account> mappedAccounts = new Map<Id, Account>(AccountUtility.getAccountsById(newRecordMap.keySet()));

        for(Account acc : newRecordMap.values())
            System.enqueueJob(new UpdateAccountCompanyInfo(mappedAccounts.get(acc.Id)));
    }

    public void updateAccountInfoFromCNPJ(Map<Id, Account> oldRecordMap, Map<Id, Account> newRecordMap){
        Map<Id, Account> mappedAccounts = new Map<Id, Account>(AccountUtility.getAccountsById(newRecordMap.keySet()));

        for(Account acc : newRecordMap.values()){
            Account oldAccount = oldRecordMap.get(acc.Id);

            if(acc.CompanyDocument__c != oldAccount.CompanyDocument__c)
                System.enqueueJob(new UpdateAccountCompanyInfo(mappedAccounts.get(acc.Id)));
            else
                System.enqueueJob(new SendAccountToProtheus(mappedAccounts.get(acc.Id)));
        }
    }    
}