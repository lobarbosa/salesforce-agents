@isTest
public class SolicitacaoPassagemAereaBOTest {

    @isTest
    static void testOne(){
        Account a = new Account();
		a.Name = 'Account Test Marco';
		insert a;
		
		Contact c = new Contact();
		c.LastName = 'Contact Test Marco';
		insert c;
        
        TriggerHandler.bypass('PPMProjectTriggerHandler');
		PPM_Project__c p = new PPM_Project__c();
		p.Conta__c = a.id;
        insert p;
        
        Solicitacao_de_Passagem_Aerea__c sol = new Solicitacao_de_Passagem_Aerea__c();
        sol.Relacionado_ao_Projeto__c = p.Id;
        insert sol;
        update sol;
        TriggerHandler.clearbypass('PPMProjectTriggerHandler');
    }
}