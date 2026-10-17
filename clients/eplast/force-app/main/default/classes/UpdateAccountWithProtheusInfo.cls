public with sharing class UpdateAccountWithProtheusInfo implements Queueable {
    private Account acc;
    private ProtheusGetClientModel protheusClient;

    public UpdateAccountWithProtheusInfo(Account acc, ProtheusGetClientModel protheusClient) {
        this.acc = acc;
        this.protheusClient = protheusClient;
    }

    public void execute(QueueableContext context){
        this.updateAccount();
    }

    private void updateAccount(){
        this.acc.ProtheusId__c = this.protheusClient.CodigoERP;
        this.acc.Store__c = this.protheusClient.Loja;
        this.acc.StateRegistration__c = this.protheusClient.InscrEst;
        this.acc.Overdue__c = this.protheusClient.Inadimplente == 'S';
        this.acc.LimitUsed__c = Decimal.valueOf(this.protheusClient.CredUso);

        // Update limit-related info on triggered account if it has no parent account. Otherwise, update limit-related info on parent account
        // if(this.acc.Parent == null){
        //     // this.acc.AvailableCreditLimit__c = (this.acc.LimitAmount__c == null ? 0 : this.acc.LimitAmount__c - this.acc.LimitUsed__c);
        // }
        // else {
        //     this.acc.Parent.LimitUsed__c = Decimal.valueOf(this.protheusClient.CredUso);
        //     // this.acc.Parent.AvailableCreditLimit__c = (this.acc.Parent.LimitAmount__c == null ? 0 : this.acc.Parent.LimitAmount__c - this.acc.Parent.LimitUsed__c);
            
        //     update this.acc.Parent;
        // }

    
        if(this.protheusClient.Cnae != null && this.protheusClient.Cnae.length() != 0)
            this.acc.CNAE__c = this.protheusClient.Cnae;

        update this.acc;
    }
}