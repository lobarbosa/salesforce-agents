@isTest
private class AccountUpdate13MesesTest {
    @testSetup static void setup() {
        List<Account> lstAcc = new List<Account>();
        lstAcc.add(new Account(Name = 'Conta Test', NomeFantasia__c = 'nome fantasia',
                              	Dispara_Flow__c = false, DisparaFluxoMensal__c = false                               	
                              ));
        insert lstAcc; 
    }
 @isTest  static  void UpdateFluxo13meses()
 {   AccountUpdate13Meses ExecuteUpdate =  new AccountUpdate13Meses();
    	Database.executeBatch(ExecuteUpdate,12);
    }
}