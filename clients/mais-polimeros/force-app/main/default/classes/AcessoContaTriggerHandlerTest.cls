@IsTest
public with sharing class AcessoContaTriggerHandlerTest {

    @IsTest
    public static void maintest() {

        DivisaoNegocio__c dv = new DivisaoNegocio__c(
            Name = 'Divisão Teste',
            Familia__c = 'ABS'
        );
        insert dv;

        AcessoProduto__c ap = new AcessoProduto__c(
            Name = 'Acesso produto teste',
            Familia__c = 'ABS',
            DivisaoNegocioId__c = dv.Id,
            Representante__c = UserInfo.getUserId()
        );
        insert ap;

        Account conta = InstanceToClassCoverage.conta('Conta para teste');
		insert conta;

        AcessoConta__c ac = new AcessoConta__c(
            Conta__c = conta.Id,
            AcessoProduto__c = ap.Id
        );
        insert ac;

        ac.Inativo__c = true;
        update ac;

        ac.Inativo__c = false;
        update ac;

        delete ac;

    }

}