@isTest
public with sharing class TestGetAccountFromProtheus {
    @TestSetup
    static void setup(){
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());
        
        Account parentAccount = SendAccountToProtheusTDF.createAccountWithoutStoreField();

        insert parentAccount;

        parentAccount.Store__c = '02';
        parentAccount.ProtheusId__c = '001445';

        update parentAccount;

        // AccountTriggerHandler.runTrigger = false; // this is a trick to prevent trigger from sending Account to Protheus
        
        Account childAccount = SendAccountToProtheusTDF.createAccountWithoutStoreField();
        childAccount.ParentId = parentAccount.Id;

        insert childAccount;

        childAccount.Store__c = '01';
        childAccount.ProtheusId__c = '001442';

        update childAccount;

    }

    @isTest
    public static void getAccountFromProtheusErrorTest(){
        Test.setMock(HttpCalloutMock.class, new MockGetClientFromProtheusResponseBody(true));

        Account acc = [SELECT Id, ProtheusId__c FROM Account WHERE Owner.Alias = 'dummy' AND ParentId = null LIMIT 1];
        Opportunity opp = GetClientFromProtheusTDF.createOpportunity(acc.Id);

        Test.startTest();
            Database.SaveResult result = Database.insert(opp, false);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, Overdue__c FROM Account WHERE Id = :opp.AccountId AND ParentId = null LIMIT 1];

        //Assert.isTrue(result.getErrors().isEmpty());
        Assert.isTrue(result.isSuccess(), 'The insert should have failed');
        Assert.isFalse(result.getErrors().size() > 0, 'There should be at least one error');
        Assert.isFalse(updatedAccount.Overdue__c);
    }

    @isTest
    public static void getAccountFromProtheusOnOppInsertSuccessTest(){
        Test.setMock(HttpCalloutMock.class, new MockGetClientFromProtheusResponseBody(false));

        Account acc = [SELECT Id, ProtheusId__c, Overdue__c FROM Account WHERE Owner.Alias = 'dummy' AND ParentId = null LIMIT 1];
        Opportunity opp = GetClientFromProtheusTDF.createOpportunity(acc.Id);

        Test.startTest();
            Database.SaveResult result = Database.insert(opp, false);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, ProtheusId__c, Overdue__c FROM Account WHERE Id = :opp.AccountId AND ParentId = null LIMIT 1];

        //Assert.isFalse(result.getErrors().isEmpty());
        Assert.isTrue(result.isSuccess(), 'The insert should have failed');
        Assert.isFalse(result.getErrors().size() > 0, 'There should be at least one error');
        Assert.isFalse(updatedAccount.Overdue__c);
    }

    @isTest
    public static void getAccountWithParentAccountFromProtheusOnOppInsertSuccessTest(){
        Test.setMock(HttpCalloutMock.class, new MockGetClientFromProtheusResponseBody(false));

        Account acc = [SELECT Id, ProtheusId__c, Overdue__c FROM Account WHERE Owner.Alias = 'dummy' AND ParentId != null LIMIT 1];
        Opportunity opp = GetClientFromProtheusTDF.createOpportunity(acc.Id);

        Test.startTest();
            Database.SaveResult result = Database.insert(opp, false);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, Parent.Overdue__c, Overdue__c FROM Account WHERE Id = :opp.AccountId AND ParentId != null LIMIT 1];

        //Assert.isFalse(result.getErrors().isEmpty());
        Assert.isTrue(result.isSuccess(), 'The insert should have failed');
        Assert.isFalse(result.getErrors().size() > 0, 'There should be at least one error');
        Assert.isFalse(updatedAccount.Overdue__c);
        Assert.isFalse(updatedAccount.Parent.Overdue__c);
    }

    @isTest
    public static void getAccountFromProtheusOnOppUpdateSuccessTest(){
        Test.setMock(HttpCalloutMock.class, new MockGetClientFromProtheusResponseBody(false));

        Account acc = [SELECT Id, ProtheusId__c FROM Account WHERE Owner.Alias = 'dummy' LIMIT 1];
        Opportunity opp = GetClientFromProtheusTDF.createOpportunity(acc.Id);
        insert opp;

        Test.startTest();
            Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, Overdue__c FROM Account WHERE Id = :opp.AccountId AND ParentId = null LIMIT 1];

        //Assert.isTrue(result.getErrors().isEmpty());
        Assert.isTrue(result.isSuccess(), 'The insert should have failed');
        Assert.isFalse(result.getErrors().size() > 0, 'There should be at least one error');
        Assert.isFalse(updatedAccount.Overdue__c);
    }
}