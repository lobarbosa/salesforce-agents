public with sharing class SendAccountToProtheus implements Queueable, Database.AllowsCallouts {
    private Account acc;
    public SendAccountToProtheus(Account acc) {
        this.acc = acc;
    }
    public void execute(QueueableContext context){
        if(checkFields())
            ProtheusAPI.sendClientToProtheus(this.acc);         
    }
    private Boolean checkFields() {
    Map<String, String> phoneParts = PhoneUtility.getPhoneInParts(this.acc.Phone);
    
    if(this.acc.Store__c == null || this.acc.Store__c.length() == 0) {
        return false;
    }
    if(this.acc.CompanyName__c == null || this.acc.CompanyName__c.length() == 0) {
        return false;
    }
    if(this.acc.BillingCity == null || this.acc.BillingCity.length() == 0) {
        return false;
    }
    if(this.acc.BillingState == null || this.acc.BillingState.length() == 0) {
        return false;
    }
    if(this.acc.BillingStreet == null || this.acc.BillingStreet.length() == 0) {
        return false;
    }
    if(this.acc.BillingPostalCode == null || this.acc.BillingPostalCode.length() == 0) {
        System.debug('BillingPostalCode is null or empty');
        return false;
    }
    if(this.acc.BillingNeighborhood__c == null || this.acc.BillingNeighborhood__c.length() == 0) {
        return false;
    }
    if(phoneParts == null) {
        return false;
    }
    if(this.acc.CNAE__c == null || this.acc.CNAE__c.length() == 0) {
        return false;
    }
    if(this.acc == null || this.acc.Owner.ProtheusSellerId__c == null || this.acc.Owner.ProtheusSellerId__c.length() == 0) {
        return false;
    }
    return true;
}
}