@isTest
private class MeusCreditosControllerTest {
    
    @isTest
    static void testGetAccountDataWithValidUser() {
        // Criação de uma Account fictícia
        Account acc = new Account(
            Name = 'Conta Teste',
        	NomeFantasia__c = 'Conta Teste Credito',
        	Phone = '3333-3333');
        insert acc;
        
        // Criação de um Contact associado à conta
        Contact c = new Contact(
            FirstName = 'Teste', 
            LastName = 'Contato', 
            AccountId = acc.Id,
        	Phone = '(11)2222-2222');
        insert c;
        
        // Criação de um User fictício
        Profile p = [SELECT Id FROM Profile WHERE Name = 'B2B User' LIMIT 1];
        User u = new User(
            Username = 'testeuser@example.com',
            Alias = 'tuser',
            Email = 'testeuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Sao_Paulo',
            ContactId = c.Id,
            LastName = 'Teste User'
        );
        insert u;
        
        // Execução como o usuário recém-criado
        System.runAs(u) {
            Account result = MeusCreditosController.getAccountData();
            System.assertNotEquals(null, result);
        }
    }

    @isTest
    static void testGetAccountDataWithNoContact() {
        // Criação de um usuário sem contato
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Usuário Padrão' LIMIT 1];
        User u = new User(
            Username = 'semcontato@example.com',
            LastName = 'Sem Contato',
            Alias = 'scuser',
            Email = 'semcontato@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Sao_Paulo'
        );
        insert u;

        System.runAs(u) {
            Account result = MeusCreditosController.getAccountData();
            System.assertEquals(null, result);
        }
    }
}