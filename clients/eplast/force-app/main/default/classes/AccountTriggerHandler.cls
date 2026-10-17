public with sharing class AccountTriggerHandler {
    private Boolean isTriggerExecuting;
    private Integer triggerSize;
    private AccountTriggerHelper helper;
    public static Boolean runTrigger = true;


    public AccountTriggerHandler(Boolean isTriggerExecuting, Integer triggerSize) {
        this.isTriggerExecuting = isTriggerExecuting;
        this.triggerSize = triggerSize;
        this.helper = new AccountTriggerHelper();
    }

    public void validateCNPJ(Account[] newRecords, Account[] oldRecords){
        this.helper.validateCNPJ(newRecords, oldRecords);
    }

    public void fillAccountWithCNPJInfo(Map<Id, Account> newRecordMap){
        this.helper.getAccountInfoFromCNPJ(newRecordMap);
    }

    public void updateAccountCNPJInfo(Map<Id, Account> oldRecordMap, Map<Id, Account> newRecordMap){
        if(runTrigger)
            this.helper.updateAccountInfoFromCNPJ(oldRecordMap, newRecordMap);
    }
}