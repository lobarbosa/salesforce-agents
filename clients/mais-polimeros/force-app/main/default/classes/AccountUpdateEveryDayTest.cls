@isTest
private class AccountUpdateEveryDayTest {
	@testSetup static void setup() {
		List<Account> lstAcc = new List<Account>();
        lstAcc.add(new Account(Name = 'Conta Test',
                                NomeFantasia__c = 'nome fantasia',
                              	Dispara_Flow__c = false
                              ));
        insert lstAcc; 
    }
 @isTest  static  void UpdateFluxoDiario()
 {   AccountUpdateEveryDay ExecuteUpdate =  new AccountUpdateEveryDay();
    	Database.executeBatch(ExecuteUpdate,12);
    }
}