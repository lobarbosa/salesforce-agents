@isTest
public class CheckinCheckoutControllerTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account', NomeFantasia__c = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'Test', LastName = 'User', AccountId = testAccount.Id);
        insert testContact;
    }

    @isTest
    static void testCheckIn() {
        setupTestData();

        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];

        String idConta = testAccount.Id;
        decimal lat = -23.55053333333;
        decimal lon = -46.63333333333;
        String tipo = 'Visita';
        String comentario = 'Comentário de teste';
        String idContato = testContact.Id;

        Test.startTest();
        CheckinCheckoutController.checkIn(idConta, lat, lon, tipo, comentario, idContato);
        Test.stopTest();

        Task createdTask = [SELECT WhatId, WhoId, Latitude__c, Longitude__c, Description, Status, Type FROM Task WHERE WhatId = :idConta AND WhoId = :idContato LIMIT 1];

        System.assertNotEquals(null, createdTask, 'Task was not created');
        System.assertEquals('Check in - Visita', createdTask.Type, 'Task type should be "Check in - Visita"');
        System.assertEquals('Comentário de teste', createdTask.Description, 'Task comment was not properly saved');
        System.assertEquals(String.valueOf(-23.5505333), createdTask.Latitude__c, 'Latidude was not properly saved');
        System.assertEquals(String.valueOf(-46.6333333), createdTask.Longitude__c, 'Longitude was not properly saved');
    }

    @isTest
    static void testGetSearchRelated() {
        setupTestData();

        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Test.startTest();
        List<Contact> resultContacts = CheckinCheckoutController.getSearchRelated(testAccount.Id);
        Test.stopTest();

        System.assertNotEquals(null, resultContacts, 'Contact\'s list was not returned');
        System.assertEquals(true, resultContacts.size() > 0, 'No contact found');
        System.assertEquals('Test User', resultContacts[0].Name, 'The name of the returned contact is incorrect');
    }
}