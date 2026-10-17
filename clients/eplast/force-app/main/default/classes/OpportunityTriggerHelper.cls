public with sharing class OpportunityTriggerHelper implements Queueable, Database.AllowsCallouts {
    private Account[] accounts;

    public OpportunityTriggerHelper(Opportunity[] opps) {
        this.accounts = this.getAccountsFromOpportunities(opps);
    }

    public void execute(QueueableContext context){
        for(Account acc : this.accounts){
            ProtheusGetClientModel protheusClientInfo = (ProtheusGetClientModel) ProtheusAPI.getClientByCNPJ(AccountUtility.cleanCNPJ(acc.CompanyDocument__c));

            if(protheusClientInfo != null)
                (new UpdateAccountWithProtheusInfo(acc, protheusClientInfo)).execute(null);
        }
    }

    private Account[] queryAccounts(Opportunity[] opps){
        String[] accountIds = new String[]{};
        
        for(Opportunity opp : opps)
            if(opp.AccountId != null)
                accountIds.add(opp.AccountId);

        Account[] queriedAccounts = [
                                        SELECT 
                                            Id, 
                                            CompanyDocument__c,
                                            ProtheusId__c,
                                            Store__c,
                                            StateRegistration__c,
                                            LimitUsed__c,
                                            LimitAmount__c,
                                            //AvailableCreditLimit__c,
                                            CNAE__c,
                                            Overdue__c,
                                            Parent.LimitAmount__c,
                                            Parent.LimitUsed__c,
                                            //Parent.AvailableCreditLimit__c,
                                            Parent.Overdue__c
                                        FROM Account 
                                        WHERE 
                                            Id IN :accountIds
                                    ];

        return (queriedAccounts.size() > 0 ? queriedAccounts : new Account[]{});
    }

    public Account[] getAccountsFromOpportunities(Opportunity[] opps){
        return queryAccounts(opps);
    }
}