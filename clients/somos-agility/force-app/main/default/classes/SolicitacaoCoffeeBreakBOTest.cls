@isTest
public class SolicitacaoCoffeeBreakBOTest {

    @isTest
    static void testOne(){
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
        
        Solicita_o_de_Coffe__c sol = new Solicita_o_de_Coffe__c();
        sol.Relacionado_ao_Projeto__c = p.Id;
        sol.Solicitante__c = c.Id;
        sol.Fornecedor__c = 'Padaria Letícia';
        sol.PIN__c = [SELECT Id,PIN__c FROM Contact WHERE Id =: c.Id].PIN__c;
        insert sol;
        sol.Quantidade__c = 'Até 10 pessoas';
        update sol;
        sol.Quantidade__c = 'Até 20 pessoas';
        update sol;
        sol.Quantidade__c = 'Até 30 pessoas';
        update sol;
        TriggerHandler.clearbypass('PPMProjectTriggerHandler');
    }
    
    @isTest
    static void testTwo(){
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
        
        Solicita_o_de_Coffe__c sol = new Solicita_o_de_Coffe__c();
        sol.Relacionado_ao_Projeto__c = p.Id;
        sol.Solicitante__c = c.Id;
        sol.Fornecedor__c = 'Padaria Merci';
        sol.PIN__c = [SELECT Id,PIN__c FROM Contact WHERE Id =: c.Id].PIN__c;
        insert sol;
        sol.Quantidade__c = 'Até 10 pessoas';
        update sol;
        sol.Quantidade__c = 'Até 20 pessoas';
        update sol;
        sol.Quantidade__c = 'Até 30 pessoas';
        update sol;
        TriggerHandler.clearbypass('PPMProjectTriggerHandler');
    }
    
    @isTest
    static void testThree(){
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
        
        Solicita_o_de_Coffe__c sol = new Solicita_o_de_Coffe__c();
        sol.Relacionado_ao_Projeto__c = p.Id;
        sol.Solicitante__c = c.Id;
        sol.Fornecedor__c = 'Santa Etienne';
        sol.PIN__c = [SELECT Id,PIN__c FROM Contact WHERE Id =: c.Id].PIN__c;
        insert sol;
        sol.Quantidade__c = 'Até 10 pessoas';
        update sol;
        sol.Quantidade__c = 'Até 20 pessoas';
        update sol;
        sol.Quantidade__c = 'Até 30 pessoas';
        update sol;
        TriggerHandler.clearbypass('PPMProjectTriggerHandler');
    }
}