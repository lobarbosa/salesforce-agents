public without sharing class SolicitacaoMudancaTriggerHandler {
    
    public static Boolean        run;
    public List<Solicitacao_de_Mudanca__c> oldRecordsList;
    public List<Solicitacao_de_Mudanca__c> newRecordsList;
    
    static {
        run = true;
    }
    
    /*public void afterInsert(){
    }*/
    
    /*public void beforeInsert(){
        
    }*/
    
    public void afterUpdate(){
        verificaDsaDepv(newRecordsList);
    }
    
    /*public void beforeUpdate(){
        
    }*/
    
    public void verificaDsaDepv(List<Solicitacao_de_Mudanca__c> context){
        
        List<Solicitacao_de_Mudanca__c> filteredContext = new List<Solicitacao_de_Mudanca__c>();
        
        
        for(Solicitacao_de_Mudanca__c solicitacaoMudanca : context){
            if(solicitacaoMudanca.status__c != ''){
                filteredContext.add(solicitacaoMudanca);
            }
        }
        
        system.debug('Lista' + filteredContext);
        system.debug(!filteredContext.isEmpty());
        if(!filteredContext.isEmpty()){
            system.debug('Lista Entrou no if' + filteredContext);
            for(Solicitacao_de_Mudanca__c solicitacaoMudanca : filteredContext){
                if(solicitacaoMudanca.status__c == 'Pendente Dir Com' /*|| solicitacaoMudanca.status__c == 'Pendente GC'*/){
                    system.debug('entrou no if do status');
                    system.debug('solicitacaoMudanca' + solicitacaoMudanca);
                    if(String.isEmpty(solicitacaoMudanca.DSA_relacionado__c) && String.isEmpty(solicitacaoMudanca.DEPV_relacionado__c)){
                        system.debug('entrou no if do campo');
                        newRecordsList[0].addError('Para esta aprovação é necessário o preenchimento do campo DSA ou DEPV. Por favor retorne ao registro e preencha os campos.');
                    }
                }
            }
        }
    }
}