@isTest public class LancamentoCreditoProjetoBO_Test {
    
    @isTest static void test(){
        
        Account a = new Account();
        a.Name = 'Account Agility Test';
        insert a;
        
        TriggerHandler.bypass('PPMProjectTriggerHandler');
        PPM_Project__c p = new PPM_Project__c();
        p.Conta__c = a.id;
        insert p;
        
        Lancamento_de_Creditos_em_Projeto__c lancamento = new Lancamento_de_Creditos_em_Projeto__c();
        lancamento.Projetos__c = p.Id;
        Insert lancamento;
        
        lancamento.Analista_Credito_HC__c=2;
        update lancamento;
        
        Delete lancamento;
        
    }

}