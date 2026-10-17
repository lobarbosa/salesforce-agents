public class clsListaMarcos{
    public Marcos__c newMarco{get;set;}
    
     public clsListaMarcos(){
        newMarco = new Marcos__c();
    }
    
    List<Marcos__c> marcos_acts = [Select 
        Name,
        Classe__c,
        Contato_no_Cliente_1__c,
        Crit_rios_de_Sucesso_1__c,
        Descri_o_do_Marco__c,
        Evid_ncia_Anexo__c,
        ID_do_Projeto__c,
        Marcos_Finalizado__c,
        Motivo__c,
        Nome_do_Marco__c,
        Observa_o__c,
        Step__c,
        Valor_Financeiro_Aberto__c
        from Marcos__c LIMIT 150];
        
    public List<Marcos__c> getmarcos_acts(){
    return marcos_acts;
    }
}