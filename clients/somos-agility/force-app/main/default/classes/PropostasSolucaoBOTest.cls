@isTest
public class PropostasSolucaoBOTest {
    @IsTest
    static void testOne(){
        Profile pf = [SELECT Id from Profile where Name = 'Administrador do sistema' OR Name = 'System Administrator' LIMIT 1];

        Account a = new Account();
		a.Name = 'Agility Networks Tecnologia SP';
		insert a;		
        
		User u = new User();	
        u.FirstName = 'User Agility';
        u.LastName = 'Network Teste';
        u.Username = 'user.teste@agilitynetworks.com.br';
        u.Email = 'user.teste@agilitynetworks.com.br';
        u.EmailEncodingKey = 'UTF-8';        
        u.ProfileId = pf.Id;
        u.Alias = 'testUser';
        u.TimeZoneSidKey = 'America/Sao_Paulo';
        u.LanguageLocaleKey = 'pt_BR';
        u.LocaleSidKey = 'pt_BR';        
        insert u;
        
        System.runAs(u) {
            Contact c = new Contact();
            c.AccountId = a.Id;
            c.LastName = 'Contact Test CR';
            c.Contato_Trabalha_Atualmente_na_Empresa__c = 'Sim';
            c.Title = 'Solution Architect';
            insert c;
            
            Contact c1 = new Contact();
            c1.AccountId = a.Id;
            c1.LastName = 'Contact Test CR1';
            c1.Contato_Trabalha_Atualmente_na_Empresa__c = 'Sim';
            c1.Title = 'Gerente de Projetos';
            insert c1;
            
            Opportunity o = new Opportunity();
            o.AccountId = a.id;
            o.Name = 'Opp Teste Agility';
            o.CloseDate = system.today();
            o.StageName = 'OQF';
            insert o;

            o.Or_amentista__c = c.Id;
            update o;

            Propostas_de_Solucao__c prop = new Propostas_de_Solucao__c();
            prop.Oportunidade__c = o.Id;
            insert prop;
            
            prop.StatusPsl__c = 'Proposta enviada ao cliente';
            update prop;
        }
    }
}