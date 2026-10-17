@IsTest
public with sharing class DivisaoNegocioTriggerHandlerTest {

    @TestSetup
    static void makeData(){

        DivisaoNegocio__c dv = new DivisaoNegocio__c(
            Name = 'Divisão Teste',
            Familia__c = 'ABS'
        );
        insert dv;

    }
    
    @IsTest
    public static void maintest() {

        DivisaoNegocio__c dv = new DivisaoNegocio__c(
            Name = 'Divisão Teste',
            Familia__c = 'ABS'
        );

        try{
            insert dv;
        } catch (Exception ex) {
            
        }

    }

}