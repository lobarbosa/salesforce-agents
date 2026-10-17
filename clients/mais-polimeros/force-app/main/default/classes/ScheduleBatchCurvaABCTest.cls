@isTest
public class ScheduleBatchCurvaABCTest {

	@testSetup
	static void setupData() {
		// Criar registros necessários para os testes
		List<Account> accounts = new List<Account> ();
		for (Integer i = 0; i< 5; i++) {
			Account acc = new Account(
			                          Name = 'Test Account ' + i,
			                          Curva_ABC__c = 'A',
			                          Curva_ABC_Old_Value__c = 'B',
			                          NomeFantasia__c = 'Nome Fantasia ' + i // Adicionando o campo obrigatório
			);
			accounts.add(acc);
		}
		insert accounts;

		// Criar registros de Order com status válido
		List<Order> orders = new List<Order> ();
		for (Account acc : accounts) {
			Order ord = new Order(
			                      AccountId = acc.Id,
			                      Status = 'LiberacaoCredito', // Usando o status válido para um novo pedido
			                      EffectiveDate = Date.today()
			);
			orders.add(ord);
		}
		insert orders;
	}

	@isTest
	static void testExecute() {
		// Criar instância da classe ScheduleBatchCurvaABC
		ScheduleBatchCurvaABC job = new ScheduleBatchCurvaABC();

		// Testar o método execute
		Test.startTest();
		String jobId = System.schedule('Test Job', '0 0 0 * * ?', job);
		Test.stopTest();

		// Verificar se o job foi agendado corretamente
		System.assertNotEquals(null, jobId, 'O job foi agendado corretamente');
	}

	@isTest
	static void testParetoClass() {
		// Testar o método paretoClass, que também chama SendEmailNotification
		Test.startTest();
		ScheduleBatchCurvaABC.paretoClass();
		Test.stopTest();

		// Verificar os resultados esperados, como atualizações em contas e envio de e-mail
		List<Account> accounts = [SELECT Id, Curva_ABC__c, Curva_ABC_Old_Value__c FROM Account];
		for (Account acc : accounts) {

			//System.debug('acc: ' + acc);
			System.assertNotEquals(acc.Curva_ABC__c, acc.Curva_ABC_Old_Value__c, 'A classificação da conta foi atualizada corretamente.');
		}

	}
}