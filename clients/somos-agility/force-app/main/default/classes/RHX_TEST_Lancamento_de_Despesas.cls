@isTest(SeeAllData=true)
public class RHX_TEST_Lancamento_de_Despesas {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM Lancamento_de_Despesas__c LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Lancamento_de_Despesas__c()
            );
        }
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}