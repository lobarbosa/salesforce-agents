@isTest
private class MetaUpdateDailyTest {
    @testSetup static void setup() {
        List<Meta__c> lstMeta = new List<Meta__c>();
        lstMeta.add(new Meta__c(Name = 'Meta Fluxo',
                               Vendedor__c = '005f4000004mSmyAAE',
                               Status__c = 'Aberta',
                               MesMeta__c = Date.today() - 14
                              ));
        insert lstMeta; 
    }
 @isTest  static  void UpdateMetaAtual()
	{   
		MetaUpdateDaily ExecuteUpdate =  new MetaUpdateDaily();
    	Database.executeBatch(ExecuteUpdate,12);
	}
}