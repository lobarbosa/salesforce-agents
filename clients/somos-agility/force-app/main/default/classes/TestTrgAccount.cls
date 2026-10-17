@IsTest(SeeAllData=true)
public with sharing class TestTrgAccount 
{
	static testMethod void testaConta()
	{
		Test.startTest();
		Test.setMock(WebServiceMock.class, new MockServiceAccount());
		
		Account novaConta = new Account();
		novaConta.Name = 'Conta teste';
		novaConta.Raz_o_Social__c = 'Teste Ltda';
		novaConta.CNPJ__c = '63.145.354/0001-44';
		novaConta.Tipo_de_Conta__c = 'Cliente';
		novaConta.Phone = '1125251414';
		novaConta.Website = 'www.google.com.br';
		novaConta.Ownership = 'Privada';
		
		Ramo_de_Atividade__c ram = [SELECT Id FROM Ramo_de_Atividade__c LIMIT 1];
		
		novaConta.Ramo_de_Atividade__c = ram.Id;
		novaConta.Bairro_Cobranca__c = 'Teste';
		novaConta.Numero_de_cobranca__c = '123';
		novaConta.BillingCity = 'São Paulo';
		novaConta.BillingCountry = 'Brasil';
		novaConta.BillingState = 'São Paulo';
		novaConta.BillingPostalCode = '47412000';
		novaConta.BillingStreet = 'Teste';
		
		
		insert novaConta;
		
		Test.stopTest();
		
	}
}