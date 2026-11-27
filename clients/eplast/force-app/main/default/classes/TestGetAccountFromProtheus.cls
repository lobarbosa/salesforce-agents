@isTest
public with sharing class TestGetAccountFromProtheus {
    @TestSetup
    static void setup(){
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJSuccessResponse());
        TriggerUtility.bypassTrigger = true;

        Account parentAccount = contaParaOportunidade('TESTE EPLAST Apex Matriz', '(11)33334444');
        insert parentAccount;
        parentAccount.Store__c = '02';
        parentAccount.ProtheusId__c = '001445';
        update parentAccount;

        Account childAccount = contaParaOportunidade('TESTE EPLAST Apex Filial', '(11)33335555');
        childAccount.CompanyDocument__c = SearchAccountInfoByCNPJTDF.CNPJ_OUTRO;
        childAccount.ParentId = parentAccount.Id;
        insert childAccount;
        childAccount.Store__c = '01';
        childAccount.ProtheusId__c = '001442';
        update childAccount;
    }

    private static Account contaParaOportunidade(String name, String phone){
        Account acc = SendAccountToProtheusTDF.createAccountWithoutStoreField();
        acc.Name = name;
        acc.Phone = phone;
        acc.CompanyName__c = 'TESTE EPLAST COMERCIO LTDA';
        acc.BillingCity = 'Cidade Teste';
        acc.BillingState = 'SP';
        acc.BillingStreet = 'Rua Teste 100';
        acc.BillingPostalCode = '01310100';
        acc.BillingNeighborhood__c = 'Bairro Teste';
        acc.CNAE__c = '6201501';
        acc.Email__c = 'teste.eplast.apex@example.com';
        return acc;
    }

    @isTest
    public static void getAccountFromProtheusErrorTest(){
        Test.setMock(HttpCalloutMock.class, new MockGetClientFromProtheusResponseBody(true));

        Account acc = [SELECT Id, ProtheusId__c FROM Account WHERE Name = 'TESTE EPLAST Apex Matriz' LIMIT 1];
        Opportunity opp = GetClientFromProtheusTDF.createOpportunity(acc.Id);

        Test.startTest();
            Database.SaveResult result = Database.insert(opp, false);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, Overdue__c FROM Account WHERE Id = :opp.AccountId LIMIT 1];

        Assert.isTrue(result.isSuccess(), 'A oportunidade deveria ser gravada mesmo sem cliente no ERP');
        Assert.areEqual(0, result.getErrors().size());
        Assert.isFalse(updatedAccount.Overdue__c, 'Sem retorno do ERP a conta não fica inadimplente');
    }

    @isTest
    public static void getAccountFromProtheusOnOppInsertSuccessTest(){
        Test.setMock(HttpCalloutMock.class, new MockGetClientFromProtheusResponseBody(false));

        Account acc = [SELECT Id, ProtheusId__c, Overdue__c FROM Account WHERE Name = 'TESTE EPLAST Apex Matriz' LIMIT 1];
        Opportunity opp = GetClientFromProtheusTDF.createOpportunity(acc.Id);

        Test.startTest();
            Database.SaveResult result = Database.insert(opp, false);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, ProtheusId__c, Overdue__c FROM Account WHERE Id = :opp.AccountId LIMIT 1];

        Assert.isTrue(result.isSuccess(), 'A oportunidade deveria ser gravada');
        Assert.areEqual(0, result.getErrors().size());
        Assert.isTrue(updatedAccount.Overdue__c, 'Inadimplente S deve marcar a conta');
    }

    @isTest
    public static void getAccountWithParentAccountFromProtheusOnOppInsertSuccessTest(){
        Test.setMock(HttpCalloutMock.class, new MockGetClientFromProtheusResponseBody(false));

        Account acc = [SELECT Id, ProtheusId__c, Overdue__c FROM Account WHERE Name = 'TESTE EPLAST Apex Filial' LIMIT 1];
        Opportunity opp = GetClientFromProtheusTDF.createOpportunity(acc.Id);

        Test.startTest();
            Database.SaveResult result = Database.insert(opp, false);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, Parent.Overdue__c, Overdue__c FROM Account WHERE Id = :opp.AccountId LIMIT 1];

        Assert.isTrue(result.isSuccess(), 'A oportunidade da filial deveria ser gravada');
        Assert.areEqual(0, result.getErrors().size());
        Assert.isTrue(updatedAccount.Overdue__c, 'Inadimplente S deve marcar a filial');
        Assert.isFalse(updatedAccount.Parent.Overdue__c, 'A matriz não é atualizada neste fluxo');
    }

    @isTest
    public static void getAccountFromProtheusOnOppUpdateSuccessTest(){
        Test.setMock(HttpCalloutMock.class, new MockGetClientFromProtheusResponseBody(false));

        Account acc = [SELECT Id, ProtheusId__c FROM Account WHERE Name = 'TESTE EPLAST Apex Matriz' LIMIT 1];
        Opportunity opp = GetClientFromProtheusTDF.createOpportunity(acc.Id);
        insert opp;

        Test.startTest();
            Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, Overdue__c FROM Account WHERE Id = :opp.AccountId LIMIT 1];

        Assert.isTrue(result.isSuccess(), 'A atualização da oportunidade deveria ser gravada');
        Assert.areEqual(0, result.getErrors().size());
        Assert.isTrue(updatedAccount.Overdue__c, 'Inadimplente S deve marcar a conta');
    }
}
