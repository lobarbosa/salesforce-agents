@isTest
public class LancamentoDespesasBOTest {

    @isTest
    static void testOne() {
        Account a = new Account();
        a.Name = 'Account Agility Test';
        insert a;
        
        Contact c = new Contact();
        c.AccountId = a.Id;
        c.LastName = 'Contact Test';
        c.CPF__c = '34313663096';
        c.Data_de_Nascimento__c = System.today();
        c.Contato_Trabalha_Atualmente_na_Empresa__c = 'Sim';
        insert c;
        
        TriggerHandler.bypass('PPMProjectTriggerHandler');
        PPM_Project__c p = new PPM_Project__c();
        p.Conta__c = a.id;
        insert p;
        
        Solicitacao_de_Reembolso__c sol = new Solicitacao_de_Reembolso__c();
        sol.PIN__c = [SELECT Id, PIN__c FROM Contact LIMIT 1].PIN__c;
        sol.Solicitante__c = c.Id;
        insert sol;
        
        Lancamento_de_Despesas__c desp = new Lancamento_de_Despesas__c();
        desp.Solicitacao_de_Reembolso__c = sol.Id;
        desp.Relacionado_ao_Projeto__c = p.Id;
        desp.Relacionado_a_Conta__c = a.Id;
        insert desp;
        
        update desp;
    }
}