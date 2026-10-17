@IsTest
public with sharing class B2BUtilTest {

    @TestSetup
    static void makeData(){

        Account testAccount = new Account(
            Name = 'testFirst',
            NomeFantasia__c = 'nome fantasia',
            EmailNFE__c = 'testuse8888r@example.org',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ContaMP').getRecordTypeId()
        );
        insert testAccount;

        WebStore testWebStore = new WebStore(Name='TestWebStore', Type='B2B');
        insert testWebStore;
        
        WebStore webStore = [SELECT Id FROM WebStore WHERE Name='TestWebStore' LIMIT 1];
        WebCart cart = new WebCart(Name='Cart', WebStoreId=webStore.Id, AccountId=testAccount.Id);
        insert cart;
        
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery 1');
        insert cartDeliveryGroup;

        CartItem cartItem = new CartItem(CartId=cart.Id, Type='Product', Name='TestProduct', CartDeliveryGroupId=cartDeliveryGroup.Id);
        insert cartItem;
    }
    
    @IsTest
    public static void getStoreTest(){
        B2BUtil.getStore();
    }

    @IsTest
    public static void getTESTest(){
        String cartId = [SELECT Id FROM WebCart LIMIT 1]?.Id;
        B2BUtil.getTES(cartId);
    }

}