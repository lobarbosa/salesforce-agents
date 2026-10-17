public without sharing  class BathDeleteCart implements Database.Batchable<sObject>
{
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        Id storeId =[Select id,Name from WebStore where Name='Loja Mais Polímeros'].Id;
        List<String> Status = new List<String>{'Active','Checkout'};
        String query = 'SELECT Id FROM WebCart WHERE Status IN:Status AND WebStoreId =:storeId';
       
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<WebCart> scope)
    {
        System.debug('SCOPE - ' + scope);
       
        Delete scope;
        
    }
    
    public void finish(Database.BatchableContext BC) {
    }
}