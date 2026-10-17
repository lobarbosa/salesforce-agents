@isTest
private class AccountTaskGPSControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Account',
            NomeFantasia__c = 'Test Account'
        );
        insert testAccount;
    }
    
    @isTest
    static void testConstructor() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        AccountTaskGPSController controller = new AccountTaskGPSController(sc);
        Test.stopTest();
        
        System.assertNotEquals(null, controller.newTask, 'Task should be initialized');
        System.assertEquals(acc.Id, controller.newTask.WhatId, 'Task should be linked to the account');
    }
    
    @isTest
    static void testSalvaAtividade() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        AccountTaskGPSController controller = new AccountTaskGPSController(sc);
        
        controller.valueLat = '37.7749';
        controller.valueLong = '-122.4194';
        controller.newTask.Tipo__c = 'Prospecção';
        
        Test.startTest();
        PageReference result = controller.salvaAtividade();
        Test.stopTest();
        
        Task createdTask = [SELECT Id, WhatId, Status, ActivityDate, Type, Subject, 
                          Latitude__c, Longitude__c 
                          FROM Task 
                          WHERE WhatId = :acc.Id 
                          LIMIT 1];
        
        System.assertEquals(acc.Id, createdTask.WhatId, 'Task should be linked to the account');
        System.assertEquals('Completo', createdTask.Status, 'Status should be Completo');
        System.assertEquals(Date.today(), createdTask.ActivityDate, 'ActivityDate should be today');
        System.assertEquals('Check in - Prospecção', createdTask.Type, 'Type should be Check in - Prospecção');
        System.assertEquals('Check in - Prospecção', createdTask.Subject, 'Subject should be Check in - Prospecção');
        System.assertEquals('37.7749', createdTask.Latitude__c, 'Latitude should match');
        System.assertEquals('-122.4194', createdTask.Longitude__c, 'Longitude should match');
        
        System.assertNotEquals(null, result, 'PageReference should not be null');
    }
    
   
}