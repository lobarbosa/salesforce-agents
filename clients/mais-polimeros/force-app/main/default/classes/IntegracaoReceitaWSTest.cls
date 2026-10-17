@isTest
public with sharing class IntegracaoReceitaWSTest {
    @testSetup
    static void testSetup(){

        Account acc = new Account(

            beeCnpj__CNPJ__c = '19.248.604/0001-80',
            Name = 'Test Acc 01',
            NomeFantasia__c = 'nome fantasia'

        );
        insert acc;

        Lead lead = new Lead(

            LastName = 'Test Lead 01',
            Company = 'Test Company',
            Status = 'Novo'

        );
        insert lead;




    }

    @isTest 
    static void consultarDadosReceitaWSTest() {

        Account acc = [SELECT beeCnpj__CNPJ__c FROM Account LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new IntegracaoReceitaWSCalloutMock());
        Test.startTest();
         IntegracaoReceitaWS.consultarDadosReceitaWS(acc.beeCnpj__CNPJ__c);
        Test.stopTest();

    }

    @isTest
    static void atualizarObjetoTest() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Lead lead   = [SELECT Id FROM Lead    LIMIT 1];

        Test.startTest();
         IntegracaoReceitaWS.atualizarObjeto(    acc.Id,
                                                'Account',
                                                '00.000.000/0000-00',
                                                'Razao Social',
                                                'Natureza Juridica',
                                                'tipo',
                                                'Telefone',
                                                '2022-01-01',
                                                'Situacao Cadastral',
                                                'Motivo Situacao Cadastral',
                                                '01/01/2022',
                                                '00000000',
                                                'Rua Cobranca',
                                                'Cidade Cobranca',
                                                'Estado Cobranca',
                                                'Pais Cobranca',
                                                'AtvEconomica Principal',
                                                'AtvEconomica Secundaria',
                                                'Bairro Cobranca');

         IntegracaoReceitaWS.atualizarObjeto(   lead.Id,
                                                'Lead',
                                                '00.000.000/0000-00',
                                                'Razao Social',
                                                'Natureza Juridica',
                                                'tipo',
                                                'Telefone',
                                                '01/01/2022',
                                                'Situacao Cadastral',
                                                'Motivo Situacao Cadastral',
                                                '01/01/2022',
                                                '00000000',
                                                'Rua',
                                                'Cidade',
                                                'Estado',
                                                'Pais',
                                                'AtvEconomica Principal',
                                                'AtvEconomica Secundaria',
                                                'Bairro'
                                                );
        Test.stopTest();


    }

    @isTest 
    static void consultarDadosObjetoTest() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Lead lead   = [SELECT Id FROM Lead    LIMIT 1];

        Test.startTest();
         IntegracaoReceitaWS.consultarDadosObjeto(acc.Id , 'Account');
         IntegracaoReceitaWS.consultarDadosObjeto(lead.Id, 'Lead');
        Test.stopTest();

    }

}