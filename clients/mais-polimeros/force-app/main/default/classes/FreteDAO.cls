public class FreteDAO {
	private static final FreteDAO instance = new FreteDAO();    
	public FreteDAO() {}
    
    public static FreteDAO getInstance() {
        return instance;
    }
	
	public List<Frete__c> getFretes(Set<Id> recordsId){
		return [SELECT Id, OwnerId, IsDeleted, Name, Quantidade__c, 
		ValorUnitariokg__c, UnidadeFilial__r.codigo__c, ValorTotalEstimado__c, 
		Cliente__r.codigo__c, Msg__c FROM Frete__c
		WHERE Id IN :recordsId];
	}
}