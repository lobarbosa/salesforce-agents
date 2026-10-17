@IsTest
public with sharing class AcessoProdutoTriggerHandlerTest {

    @IsTest
    public static void maintest() {

        DivisaoNegocio__c dv = new DivisaoNegocio__c(
            Name = 'Divisão Teste',
            Familia__c = 'ABS'
        );
        insert dv;

        AcessoProduto__c ap = new AcessoProduto__c(
            Name = 'Divisão Teste',
            Familia__c = 'ABS',
            DivisaoNegocioId__c = dv.Id,
            Representante__c = UserInfo.getUserId()
        );
        insert ap;

        delete ap;

    }

}