public with sharing class MeusCreditosController {
    @AuraEnabled
    public static Account getAccountData() {
        Id userId = UserInfo.getUserId();
        User usr = [SELECT Contact.AccountId FROM User WHERE Id = :userId LIMIT 1];
        if (usr.Contact.AccountId == null) {
            return null;
        }
        return [
            SELECT SaldoLimiteMaisPolimeros__c, SaldoLimiteBv__c, SaldoLimiteSifra__c
            FROM Account
            WHERE Id = :usr.Contact.AccountId
            LIMIT 1
        ];
    }
}