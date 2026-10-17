public Without Sharing class AccountDAO {
	
	private static final AccountDAO instance = new AccountDAO();    
	public AccountDAO() {}
    
    public static AccountDAO getInstance() {
        return instance;
    }

    public class NewAccountErrorException extends Exception {}

    public String accountByTOTVS(String Id){
        try{
            return [SELECT Id FROM Account WHERE Codigo__c =: Id.trim()].Id;
        }catch(Exception ex){
            //insert new Account( Name = 'CONTA '+ Id, Codigo__c = Id );
            //return String.valueOf( Account.Id ); 
            throw new NewAccountErrorException('Cliente '+Id+' não encontrado');
        }
    }

    public Account accountById(Id recordId){
        return [
            SELECT ObservacoesLogistica__c
            FROM Account
            WHERE Id =: recordId
        ];
    }
}