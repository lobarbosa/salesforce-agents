@isTest
public class TestclsListaMarcos {
    static testMethod void TestInsertMarcos()
    {
        
        list<Marcos__c> marcos = new list<Marcos__c>();

		Account a = new Account();
		a.Name = 'Account Test Marco';
		insert a;
		
		Contact c = new Contact();
		c.LastName = 'Contact Test Marco';
		insert c;
		
		PPM_Project__c p = new PPM_Project__c();
		p.Conta__c = a.id;
		insert p;
		
		Marcos__c m = new Marcos__c();
		m.Contato_no_Cliente_1__c = c.id;
		m.Nome_do_Marco__c = 'Test Marco';
		m.Descri_o_do_Marco__c = 'Descrição do Marco';
		m.ID_do_Projeto__c = p.id;
		m.Crit_rios_de_Sucesso_1__c = 'Critérios de Sucesso do Marco';
        m.Observa_o__c = 'Observação do Marco';
        m.Motivo__c = 'Motivo do Marco';
        //m.Classe = 'Outros';
        m.Evid_ncia_Anexo__c = true;
        m.Step__c = 1.0;
        m.Marcos_Finalizado__c = true;

       	insert m;

        test.startTest();
        clsListaMarcos testMarco = new clsListaMarcos();
        testMarco.getmarcos_acts();      
        test.stopTest();
    
    }
}