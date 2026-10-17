@isTest
public class SolicitacaoMudancaTriggerHandlerTest {
    static testMethod void TestSolicitacaoMudanca(){
        
        list<Solicitacao_de_Mudanca__c> solicitacaoMudanca = new list<Solicitacao_de_Mudanca__c>();
        
        Profile pf = [SELECT Id from Profile where Name = 'Solutions Architect' LIMIT 1];
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
        o.StageName = 'OEG';
        o.Arquiteto_de_Solucoes__c = c.id;
        insert o;
		
		PPM_Project__c p = new PPM_Project__c();
		p.Conta__c = a.id;
        p.Gerente_do_Projeto__c = c1.id;
        p.Compet_ncias_Envolvidas__c = 'CyberSec';
		insert p;
        
        Despesa_Extraordinaria_para_Pre_Venda__c depv = new Despesa_Extraordinaria_para_Pre_Venda__c();
        depv.Oportunidade__c = o.id;
        insert depv;
        
        DSA__c dsa = new DSA__c();
        dsa.Oportunidade__c = o.id;
        
        Solicitacao_de_Mudanca__c cr = new Solicitacao_de_Mudanca__c();
        cr.Projeto__c = p.id;
        cr.Quantidade_de_Horas__c = 10.00;
        cr.Desvio_HC__c = 12;
        cr.status__c = '';
		cr.Diretor_da_Tribo__c = c.id;   
        cr.Diretor_da_Tribo_user__c = u.id;
        cr.Gerente_de_Projetos__c = c1.id;
        cr.Gerente_de_Contas__c = u.id;
        insert cr;
        
        Solicitacao_de_Mudanca__c cr1 = new Solicitacao_de_Mudanca__c();
        //cr.Projeto__c = p.id;
        cr.Quantidade_de_Horas__c = 35.00;
        cr.Desvio_HC__c = 12;
        cr.status__c = 'Pendente Dir Com';
        cr.DSA_relacionado__c = dsa.id;
        cr.depv_relacionado__c = depv.id;
        update cr;
        
        /*Solicitacao_de_Mudanca__c cr2 = new Solicitacao_de_Mudanca__c();
        //cr.Projeto__c = p.id;
        cr.Quantidade_de_Horas__c = 55.00;
        cr.status__c = 'Pendente Dir Com';
        String.isEmpty(cr.dsa_relacionado__c);
        String.isEmpty(cr.depv_relacionado__c);
        update cr;*/
        
        /*Solicitacao_de_Mudanca__c cr3 = new Solicitacao_de_Mudanca__c();
        cr3.Projeto__c = p.id;
        cr3.Quantidade_de_Horas__c = 45.00;
        cr3.status__c = 'Pendente Dir Com';
        String.isEmpty(cr3.depv_relacionado__c);
        cr3.dsa_relacionado__c = dsa.id;
        insert cr3;*/
        
        /*Solicitacao_de_Mudanca__c cr4 = new Solicitacao_de_Mudanca__c();
        //cr3.Projeto__c = p.id;
        cr3.Quantidade_de_Horas__c = 50.00;
        cr3.status__c = 'Pendente Dir Com';
        cr3.depv_relacionado__c = depv.id;
        cr3.dsa_relacionado__c = dsa.id;
        update cr3;*/
        
        
        test.startTest();
        SolicitacaoMudancaTriggerHandler testCr = new SolicitacaoMudancaTriggerHandler();
        testCr.verificaDsaDepv(solicitacaoMudanca);   
        test.stopTest();
    }

    	
}